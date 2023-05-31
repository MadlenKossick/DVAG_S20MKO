/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Logic for sharing the related objects
 */


public without sharing class TH_RelatedObjectSharing {
    private static String PROCESS = 'Related Object Sharing';

    public static void createSharingForSObjectByInsert(List<SObject> newlist){      
        if (newlist.isEmpty() == false) {
            createSharingForSObject(newlist, TriggerOperation.AFTER_INSERT);
        }
    }

    public static void createSharingForSObjectByUpdate(Map<Id, SObject> oldmap, Map<Id, SObject> newmap){
        List<SObject> newlist = new List<SObject>();

        for (SObject obj : newmap.values()) {
            SObject objOld = oldmap.get(obj.Id);

            if (objOld != null && objOld.get('OwnerId') != null && obj.get('OwnerId') != null 
                && (objOld.get('OwnerId') != obj.get('OwnerId'))) {
                newlist.add(obj);
            }
        }

        if (newlist.isEmpty() == false) {
            createSharingForSObject(newlist, TriggerOperation.AFTER_UPDATE);            
        }
    }

    /* Calculates sharing for object trigger, only record type separated */
    private static void createSharingForSObject(List<SObject> objects, TriggerOperation triggerOp){
        List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
        Map<Id, String> recordTypeIdToDeveloperName = SharingUtil.getRecordTypesFromConfigs(configs);
        RelatedSharingObjects__mdt setting = null;

        String objectName = objects[0].Id.getSobjectType().getDescribe().getName();
        
        for (RelatedSharingObjects__mdt sharingSetting : configs) {
            //We found the sharing setting for the object to process
            if (sharingSetting.ObjectName__c == objectName) {
                //In case the sharing settings is RecordType-specific, check if this is the record type we are dealing with
                if (String.isNotBlank(sharingSetting.RecordTypeName__c) 
                    && recordTypeIdToDeveloperName.get(String.valueOf(objects[0].get('RecordTypeId'))) != sharingSetting.RecordTypeName__c) {
                    continue; //Not the record type we are looking for
                }                
                setting = sharingSetting; //We found the setting
                break;
            }
        }

        if (setting == null) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        //get all the accounts from where to get the sharing
        for (SObject obj : objects) {
            String accId = String.valueOf(obj.get(setting.ReferenceFieldAccount__c));
            if (String.isNotBlank(accId) && accountIds.contains(accId) == false) {
                accountIds.add(accId);
            }

            String ownerId = String.valueOf(obj.get('OwnerId'));
            if (ownerId != null && ownerIds.contains(ownerId) == false) {
                ownerIds.add(ownerId);
            }
        }

        Map<Id, Account> accountById = new Map<Id, Account>([SELECT Id,
                                                                    Name, 
                                                                    Owner.ExtFinancialAdvisorId__c,
                                                                    MultipleOwners__c,
                                                                    ExtCustomerNumber__c,
                                                                    HideForHierarchy__c,
                                                                    HideForAssistantsAndDeputies__c
                                                            FROM   Account
                                                            WHERE  Id IN :accountIds]);
        Map<Id, User> userById          = new Map<Id, User>([SELECT Id, 
                                                                    ExtFinancialAdvisorId__c
                                                            FROM   User
                                                            WHERE  Id IN :ownerIds]);

        List<SharingGroup__mdt> sharingGroupsTypes = SharingUtil.getAllSharingGroupTypes();
        List<String>            groupNames    = new List<String>();
        
        for (User usr : userById.values()) {
            for (SharingGroup__mdt sharingGroup : sharingGroupsTypes) {                
                groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, usr.ExtFinancialAdvisorId__c));
            }
        }

        for (Account acc : accountById.values()) {
            if (String.isNotBlank(acc.ExtCustomerNumber__c)) {
                groupNames.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c));                
            } else {
                System.debug('DBG: WARNING - No customer number set for Account ' + acc);
            }
        }

        //Get all the groups we need and store in a map to retrieve ID by group name
        List<Group> groups = [SELECT Id, Name
                              FROM Group
                              WHERE DeveloperName IN :groupNames];

        Map<String, Id> groupIdByName = new Map<String, Id>();
        for (Group groupObj : groups) {
            groupIdByName.put(groupObj.Name, groupObj.Id);
        }

        List<SObject> objectSharesToInsert = new List<SObject>();
        for (SObject obj : objects) {            
            Account acc = accountById.get(String.valueOf(obj.get(setting.ReferenceFieldAccount__c)));
            User    owner = userById.get(String.valueOf(obj.get('OwnerId')));

            if (acc == null || owner == null) {
                System.debug('DBG: WARNING Parent Account '+acc+' or Owner '+owner+' is null.');
                continue;
            }

            //in case the Account is not multi-owner OR the object type is not shared between owners
            if (acc.MultipleOwners__c == false || setting.UseMultipleOwnership__c == false) {
                //if not hidden for hierarchy, add Manager group
                if (!acc.HideForHierarchy__c && setting.UseHierarchy__c ) {
                    String grpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Hierarchy, owner.ExtFinancialAdvisorId__c);
                    Id grpId = groupIdByName.get(grpName);
                    objectSharesToInsert.add(SharingUtil.createApexShareForSObject(setting, obj.Id, grpId)); 
                }
                //if not hidden for Assistants & Deputies, add Assistants group and Deputies group
                if (!acc.HideForAssistantsAndDeputies__c) {
                    String grpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, owner.ExtFinancialAdvisorId__c);
                    Id grpId = groupIdByName.get(grpName);
                    objectSharesToInsert.add(SharingUtil.createApexShareForSObject(setting, obj.Id, grpId)); 
                    
                    grpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, owner.ExtFinancialAdvisorId__c);
                    grpId = groupIdByName.get(grpName);
                    objectSharesToInsert.add(SharingUtil.createApexShareForSObject(setting, obj.Id, grpId)); 
                }                            
            } else {
                //This is a multi-Owner Account AND the object is to be shared among all  
                String grpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);
                Id grpId = groupIdByName.get(grpName);
                objectSharesToInsert.add(SharingUtil.createApexShareForSObject(setting, obj.Id, grpId)); 
            } 
        }    
        
        Database.saveResult[] results = Database.insert(objectSharesToInsert, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert Shares failed', dmlHelper, true);
    }
}