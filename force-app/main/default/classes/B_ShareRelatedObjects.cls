/**
* @author Cloud Consulting Group - Patrick Driller, Jochen Litzinger
* @date 2022
*
* @group Batch
*
* @description Sharing Calculation Job for the 360° view of the account
*/

global class B_ShareRelatedObjects implements Database.Batchable<SObject>, Schedulable {
    private static String PROCESS = 'Share Related Objects';
    private List<RelatedSharingObjects__mdt> configs;
    private Integer currentConfigIndex;

    global void execute(SchedulableContext sc) {
        List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
        Database.executeBatch(new B_ShareRelatedObjects(configs,0), SharingUtil.getShareRelatedObjectsBatchSize());
    }

    public B_ShareRelatedObjects(List<RelatedSharingObjects__mdt> configs, Integer currentConfigIndex) {
        this.configs = configs;
        this.currentConfigIndex = currentConfigIndex;
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        return Database.getQueryLocator('SELECT Account__c FROM AccountSharingCalculation__c ORDER BY Id');
    }
        
    public void execute(Database.BatchableContext BC, List<AccountSharingCalculation__c> records){
        String subject;

        try {
            List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
            RelatedSharingObjects__mdt sharingSetting = configs[currentConfigIndex];
            subject = 'Process ' + sharingSetting.ObjectName__c;

            calculateRelatedObjectSharingChunk(records, configs , subject);            
        } catch (Exception e) {
            System.debug('B_ShareRelatedObjects EXCEPTION');
            System.debug(e.getMessage());
            ErrorUtil.logExceptionError(PROCESS, subject, e);
        }
    }
        
    public void finish(Database.BatchableContext BC){
        if (!Test.isRunningTest()) {
            if (currentConfigIndex < configs.size()) {
                Database.executeBatch(new B_ShareRelatedObjects(configs,(currentConfigIndex+1)), SharingUtil.getShareRelatedObjectsBatchSize());
            }
        }
    }

    private void calculateRelatedObjectSharingChunk(List<AccountSharingCalculation__c> sharingCalculations, 
                                                    List<RelatedSharingObjects__mdt> configs, String subject)
    {
        Set<Id> allAccountIds = new Set<Id>();
        Set<String> groupNames = new Set<String>();

        List<SObject> objectsToDelete = new List<SObject>();
        List<SObject> objectsToInsert = new List<SObject>();
        
        List<SharingGroup__mdt> sharingGroups = SharingUtil.getAllSharingGroupTypes();
        Map<Id, String> recordTypeIdToDeveloperName = SharingUtil.getRecordTypesFromConfigs(configs);
        RelatedSharingObjects__mdt sharingSetting = configs[currentConfigIndex];
        
        for (AccountSharingCalculation__c accSha : sharingCalculations) {
            if (accSha.Account__c != null && allAccountIds.contains(accSha.Account__c) == false) { //why check for existing IDs in a SET?!
                allAccountIds.add(accSha.Account__c);
            }
        }
        System.debug('allAccountIds: ' + allAccountIds);

        Map<Id, Account> allAccounts = new Map<Id, Account>([SELECT Id, 
                                                                    OwnerId,
                                                                    Owner.ExtFinancialAdvisorId__c,
                                                                    MultipleOwners__c,
                                                                    ExtCustomerNumber__c,
                                                                    PersonContactId,
                                                                    HideForHierarchy__c,
                                                                    HideForAssistantsAndDeputies__c,
                                                                    (SELECT Id, UserOrGroupId FROM Shares WHERE RowCause = 'Manual')
                                                            FROM Account 
                                                            WHERE Id IN :allAccountIds]);

        Set<Id> userIds = new Set<Id>();
        for (Account acc : allAccounts.values()) {
            // Multi Owner Group
            if (String.isNotBlank(acc.ExtCustomerNumber__c)) {
                groupNames.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c));
            }
            // VB Groups
            if (String.isNotBlank(acc.Owner.ExtFinancialAdvisorId__c)) {
                for (SharingGroup__mdt sharingGroup : sharingGroups) {
                    groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, acc.Owner.ExtFinancialAdvisorId__c));
                }
            }
            userIds.add(acc.OwnerId);
        }

        List<Group> groups = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN :groupNames];

        Map<String, Id> groupNameToId = new Map<String, Id>();
        for (Group groupObj : groups) {
            groupNameToId.put(groupObj.DeveloperName, groupObj.Id);
        }
                
        String recTypeFilter = '';        
        String query = 'SELECT Id, OwnerId, ' + sharingSetting.ReferenceFieldAccount__c + ', ' + 
                        ' (SELECT Id, UserOrGroupId FROM Shares WHERE RowCause = \'Manual\') ' + 
                        ' FROM ' + sharingSetting.ObjectName__c + 
                        ' WHERE ' + sharingSetting.ReferenceFieldAccount__c + ' IN :allAccountIds';

        if (String.isNotBlank(sharingSetting.RecordTypeName__c)) {
            recTypeFilter = sharingSetting.RecordTypeName__c;
            query += ' AND RecordType.DeveloperName = :recTypeFilter';
        }
                    
        System.debug('calculateRelatedObjectSharingChunk.query: ' + query);
        Map<Id, SObject> objects = new Map<Id, SObject>(Database.query(query));  
        System.debug('objects: ' + objects);                  
        for (SObject obj : objects.values()) {
            userIds.add((Id)obj.get('OwnerId'));
        }

        Map<Id,User> ownersById = new Map<Id,User>([SELECT ID, ExtFinancialAdvisorId__c 
                                                    FROM User
                                                    WHERE ID in :userIds]);

        List<sObject> objsShares;
        User objOwner;
        String groupName;
        Id groupId;

        for (SObject obj : objects.values()) {
            Account parent = allAccounts.get(((Id)obj.get(sharingSetting.ReferenceFieldAccount__c)));
            
            //delete all existing Sharing records before
            objsShares = obj.getSObjects('Shares');
            if (objsShares != null) {
                for (SObject share : objsShares) {
                    objectsToDelete.add(share);
                }
            }

            objOwner = ownersById.get((Id)obj.get('OwnerId'));
            
            if (parent.MultipleOwners__c == true) {                    
                //Make sure we have a customer number
                if (String.isBlank(parent.ExtCustomerNumber__c)) {
                    throw new SharingUtil.SharingException('ExtCustomerNumber__c not set for Account ' + parent.Id);
                }

                if (sharingSetting.UseMultipleOwnership__c != null && sharingSetting.UseMultipleOwnership__c == true) { //object type "shared"
                    groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, parent.ExtCustomerNumber__c);
                    groupId = groupNameToId.get(groupName);
                    
                    if (String.isNotBlank(groupId)) {
                        objectsToInsert.add(SharingUtil.createApexShareForSObject(sharingSetting, obj.Id, groupId));
                    }
                } 
                else { //object typ "VB only"
                    //share with the owner´s groups (respect hiding as defined by account)                    
                        for (SharingGroup__mdt sharingGroup : sharingGroups) {                 
                        groupName = SharingUtil.getGroupNameBySetting(sharingGroup, objOwner.ExtFinancialAdvisorId__c);
                        groupId = groupNameToId.get(groupName);
                        if (String.isNotBlank(groupId) && SharingUtil.isHidden(parent, sharingGroup, sharingSetting) == false) {
                            objectsToInsert.add(SharingUtil.createApexShareForSObject(sharingSetting, obj.Id, groupId));
                        }
                    }
                }
            } else {                 
                for (SharingGroup__mdt sharingGroup : sharingGroups) {                        
                    groupName = SharingUtil.getGroupNameBySetting(sharingGroup, parent.Owner.ExtFinancialAdvisorId__c);
                    groupId   = groupNameToId.get(groupName);
                    if (String.isNotBlank(groupId) && SharingUtil.isHidden(parent, sharingGroup, sharingSetting) == false) {
                        objectsToInsert.add(SharingUtil.createApexShareForSObject(sharingSetting, obj.Id, groupId));
                    }
                }
            }
        } 

        CCG_Log.create(PROCESS, subject, '', 'Shares to be deleted/inserted: ' + objectsToDelete.size() + '/' + objectsToInsert.size());
        CCG_Log.send();
                         
        DMLHelper dmlHelper = null;        
        if (!objectsToDelete.isEmpty()) {
            Database.deleteResult[] results = Database.delete(objectsToDelete, false);
            dmlHelper = new DMLHelper(results);
            ErrorUtil.processDMLErrors(process, subject, dmlHelper, true);
        }       
       
        if (!objectsToInsert.isEmpty()) {
            Database.saveResult[] results = Database.insert(objectsToInsert, false);
            dmlHelper = new DMLHelper(results);
            ErrorUtil.processDMLErrors(process, subject, dmlHelper, true);
        }        
        
        if (Test.isRunningTest()) {
            deleteSharingCalculations(sharingCalculations, subject);
        }
        else if (currentConfigIndex == configs.size()-1) {
            deleteSharingCalculations(sharingCalculations, subject);
        }
    }

    private void deleteSharingCalculations(List<AccountSharingCalculation__c> sharingCalculations, String subject) {
        delete sharingCalculations;        
        CCG_Log.create(PROCESS, subject, '', 'Process completed.');
        CCG_Log.send();
    }
}