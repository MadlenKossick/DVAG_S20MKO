/**
* @author Cloud Consulting Group - Patrick Driller
* @date 2022
*
* @group Utility
*
* @description Sharing Calculation Utility Class
*/

public class SharingUtil {
    public enum SharingGroup {Hierarchy, Deputies, Assistants, Ownership}    
    public static final String ASSITANT_ACCOUNT_IDENTIFIER = 'ASSISTANTS';

    public static Map<String,Type> mapTypeByName = new Map<String,Type>();
    
    public class SharingException extends Exception{}
    
    private static Boolean SET_dataPopulated = false;
    private static Integer SET_GroupHierarchyCalculationBatchSize;
    private static Integer SET_ShareRelatedObjectsBatchSize;

    private static void populateData(){
        SharingCalculationSettings__c scs = SharingCalculationSettings__c.getOrgDefaults();
        SET_GroupHierarchyCalculationBatchSize = Integer.valueOf(scs.GroupHierarchyCalculationBatchSize__c);
        SET_ShareRelatedObjectsBatchSize = Integer.valueOf(scs.RelatedObjectsShareBatchSize__c);

        if (Test.isRunningTest()) {
            SET_GroupHierarchyCalculationBatchSize = 2000;
            SET_ShareRelatedObjectsBatchSize = 2000;
        }
    }

    public static Integer getGroupHierarchyCalculationBatchSize(){
        if (!SET_dataPopulated) {
            populateData();
        }
        return SET_GroupHierarchyCalculationBatchSize;
    }

    public static Integer getShareRelatedObjectsBatchSize(){
        if (!SET_dataPopulated) {
            populateData();
        }
        return SET_ShareRelatedObjectsBatchSize;
    }

    public static String getGroupNameByType(SharingGroup type, String identifier) {
        switch on type {
            //This is the group for "Struktursicht"
            when Hierarchy {
                return 'M_' + identifier;
            }
            //This is the group for "Vertreter"
            when Deputies {
                return 'D_' + identifier;
            }
            //This is the group for "Assistenten"
            when Assistants {
                return 'A_' + identifier;
            }
            //This is the group for "Betreuer (Mehrfachbetreut)"
            when Ownership {
                return 'O_' + identifier;
            }
            when else {
                throw new SharingException('Sharing Group type ' + type + ' not defined');
            }
        }
    }

    public static String getGroupNameBySetting(SharingGroup__mdt setting, String financialAdvisorNumber){
        if (setting == null || String.isBlank(setting.Prefix__c)) {
            throw new SharingException('Sharing Setting not defined');
        }
        return setting.Prefix__c + financialAdvisorNumber;
    }
           
    public static Map<Id, String> getRecordTypesFromConfigs(List<RelatedSharingObjects__mdt> configs){
        List<String> recordTypeNames = new List<String>();
        Map<Id, String> recordTypeIdToDeveloperName = new Map<Id, String>();

        for (RelatedSharingObjects__mdt config : configs) {
            if (String.isNotBlank(config.RecordTypeName__c)) {
                recordTypeNames.add(config.RecordTypeName__c);
            }
        }

        List<RecordType> recordTypes = [SELECT Id, 
                                               DeveloperName
                                        FROM   RecordType
                                        WHERE  DeveloperName IN :recordTypeNames];
     
        for (RecordType recType : recordTypes) {
            recordTypeIdToDeveloperName.put(recType.Id, recType.DeveloperName);
        }

        return recordTypeIdToDeveloperName;
    }

    public static sObject createApexShareForSObject(RelatedSharingObjects__mdt setting, String objId, String groupId){
        //sObject shareCopy = Schema.getGlobalDescribe().get(setting.ApexShareObject__c).newSObject();
        if (!mapTypeByName.containsKey(setting.ApexShareObject__c)) {
            mapTypeByName.put(setting.ApexShareObject__c, Type.forName(setting.ApexShareObject__c));
        }

        sObject shareCopy = (sObject) mapTypeByName.get(setting.ApexShareObject__c).newInstance();
        shareCopy.put('UserOrGroupId', groupId);

        // lead is something different..
        if (setting.ObjectName__c == 'Lead') {
            shareCopy.put('LeadId', objId);
            shareCopy.put('LeadAccessLevel', setting.AccessLevel__c);
        }
        else {
            shareCopy.put('ParentId', objId);
            shareCopy.put('AccessLevel', setting.AccessLevel__c);
        }        

        return shareCopy;
    }
    
    //Visibible/Hidden for Account depends only on Account flags
    public static boolean isHidden(Account acc, SharingGroup__mdt sharingGroup){        
        return isHidden(acc, sharingGroup, null) ;
    }
    
    //Visibible/Hidden for related objects can depend also on sharing setting (e.g. for Leads)
    public static boolean isHidden(Account acc, SharingGroup__mdt sharingGroup, RelatedSharingObjects__mdt sharingSetting){
        Boolean retVal = false;

        // HideForHierarchy__c
        if (acc.HideForHierarchy__c != null && acc.HideForHierarchy__c == true &&             
            sharingGroup.Prefix__c == SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Hierarchy, '')) {
            if (null == sharingSetting)  {
                retVal = true;
            } else if (sharingSetting.UseHierarchy__c != null && sharingSetting.UseHierarchy__c == true) {
                retVal = true;
            }                            
        }

        // HideForAssistantsAndDeputies__c
        if (acc.HideForAssistantsAndDeputies__c != null && acc.HideForAssistantsAndDeputies__c == true && 
            (sharingGroup.Prefix__c == SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, '')
            || sharingGroup.Prefix__c == SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, ''))) {
            retVal = true;
        }

        return retVal;
    }

    public static List<RelatedSharingObjects__mdt> getRelatedSharingObjects(){
        if (Test.isRunningTest()) {
            return SharingTestUtil.getRelatedSharingObjectsTest();
        }
        return RelatedSharingObjects__mdt.getAll().values();
    }

    public static List<SharingGroup__mdt> getAllSharingGroupTypes(){
        if (Test.isRunningTest()) {
            return SharingTestUtil.getAllSharingGroupTypesTest();
        }

        return SharingGroup__mdt.getAll().values();
    }

    public static Group createGroup(String groupName){
        Group grp = new Group( 
            DeveloperName = groupName,
            Name = groupName,
            DoesIncludeBosses = false
        );
        return grp;
    }

    public static GroupMember createGroupMember(ID groupId, Id userId){
        GroupMember member = new GroupMember();
        member.GroupId = groupId;
        member.UserOrGroupId = userId;
        return member;
    }

    public static DeputyToAdvisor__c createDeputyToAdvisor(User advisor, User deputy){
        DeputyToAdvisor__c dep = new DeputyToAdvisor__c();
        dep.advisor__c = advisor.Id;
        dep.deputy__c = deputy.Id;
        dep.UniqueKey__c = advisor.ExtFinancialAdvisorId__c + '-'+ deputy.ExtFinancialAdvisorId__c;
        return dep;
    }

    public static AssistantToAdvisor__c createAssistantToAdvisor(User advisor, User assistant) {
        AssistantToAdvisor__c ass = new AssistantToAdvisor__c();
        ass.assistant__c = assistant.Id;
        ass.advisor__c = advisor.Id;
        ass.UniqueKey__c = advisor.ExtFinancialAdvisorId__c + '-'+ assistant.ExtFinancialAdvisorId__c;
        return ass;
    }

    public static AdvisorToCustomer__c createAdvisorToCustomer(Account customer, User advisor) {
        AdvisorToCustomer__c adv2Cust = new AdvisorToCustomer__c();
        adv2Cust.customer__c = customer.Id;
        adv2Cust.advisor__c = advisor.Id;
        adv2Cust.UniqueKey__c = customer.ExtCustomerNumber__c + '-'+ advisor.ExtFinancialAdvisorId__c;
        return adv2Cust;
    }

    public static AccountSharingCalculation__c createAccountSharingCalculation(Account customer) {
        AccountSharingCalculation__c accShareCalc = new AccountSharingCalculation__c();
        accShareCalc.account__c = customer.Id;
        accShareCalc.UniqueKey__c = customer.ExtCustomerNumber__c;
        return accShareCalc;
    }

    public static AgentSharingCalculation__c createAgentSharingCalculation(User agent) {
        AgentSharingCalculation__c agenSharingCalc = new AgentSharingCalculation__c();
        agenSharingCalc.Agent__c = agent.Id;
        agenSharingCalc.UniqueKey__c = agent.ExtFinancialAdvisorId__c;
        return agenSharingCalc;
    }

    public static Account getAssistantDirectorateAccount() {
        Account asstAcc = [SELECT Id, Name, OwnerId
                            FROM Account
                            WHERE FinServ__SourceSystemId__c = :ASSITANT_ACCOUNT_IDENTIFIER
                            AND RecordTypeId = :RecordTypeHelper.getAccRecordTypeIdDirectorate()];
        return asstAcc;
    }

    /* Helper Function to add AdvisorNumber and calculate Sharing Groups for all Advisors */    
    public static void initVbUser (Id userID, String advisorNumber) {
        Id vbProfileId =  RecordTypeHelper.getUserProfileIdFieldSalesUser();

         User vbUser = [SELECT ID, FirstName, LastName, username, ExtFinancialAdvisorId__c, ContactId, Contact.ExtFinancialAdvisorId__c, IsActive
                              FROM User
                              WHERE id = :userID].get(0);
       
        
        if (String.isBlank(vbUser.ExtFinancialAdvisorId__c)) {
            System.debug('User has no ExtFinancialAdvisorId__c');
            if (String.isBlank(advisorNumber)) {
                System.debug('and no Financial Advisor Id was provided. Aborting..');
                return;
            } else {
                vbUser.ExtFinancialAdvisorId__c = advisorNumber;
            }            
        }

        if (vbUser.ExtFinancialAdvisorId__c !=  vbUser.Contact.ExtFinancialAdvisorId__c ) {
            System.debug('Contact doesnt match User´s ExtFinancialAdvisorId__c, updating');
            Contact tmp = [SELECT id, ExtFinancialAdvisorId__c FROM contact WHERE id = :vbUser.ContactId];
            tmp.ExtFinancialAdvisorId__c = vbUser.ExtFinancialAdvisorId__c;
            update tmp;
        }
    
        update vbUser;

        List<String> groupNames = new List<String>();
        for (SharingGroup__mdt sharingGroup : SharingUtil.getAllSharingGroupTypes()) {
            groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, vbUser.ExtFinancialAdvisorId__c));
        }

        List<Group> vbGroups = [SELECT Id, DeveloperName, Type FROM Group WHERE DeveloperName in :groupNames];
        System.debug('Number of groups found: ' + vbGroups.size());        
        Map<String,Group> groupByName = new Map<String,Group>();
        for (Group tmp : vbGroups) {
            System.debug('DeveloperName: ' + tmp.developerName + ', Type: ' + tmp.type);            
            groupByName.put(tmp.name, tmp);
        }
        
        List<Group> groupsToInsert = new List<Group>();                
        
        if (vbUser.ExtFinancialAdvisorId__c == null) {
            System.debug('Advisor ID still empty: ' + vbUser.username);
            return;
        }

        for (SharingGroup__mdt sharingGroup : SharingUtil.getAllSharingGroupTypes()) {
            String grpName = SharingUtil.getGroupNameBySetting(sharingGroup, vbUser.ExtFinancialAdvisorId__c);
            Group result = groupByName.get(grpName);
            if (result != null) {
                System.debug('Group ' + grpName + ' Already exists: ' + result);
            } else {
                System.debug('Creating Sharing Group ' + grpName);
                groupsToInsert.add(SharingUtil.createGroup(grpName));
            }
        }

        Database.saveResult[] results = Database.insert(groupsToInsert, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors('Init Vb User', 'Insert Group failed', dmlHelper, true);

        AgentSharingCalculation__c agentShare = new AgentSharingCalculation__c(Agent__c = vbUser.Id,UniqueKey__c = vbUser.ExtFinancialAdvisorId__c);
        upsert agentShare UniqueKey__c;
        
        List<Account> accsToUpdate = [SELECT Id, OwnerId, HideForAssistantsAndDeputies__c, HideForHierarchy__c, MultipleOwners__c, ExtCustomerNumber__c, Owner.ExtFinancialAdvisorId__c
                                      FROM Account
                                      WHERE OwnerId = :vbUser.Id ];
        system.debug('Number of Accounts to update sharing: ' + accsToUpdate.size());
        initAccountSharing(accsToUpdate);
    }

    public static void initAccountSharing(List<Account> accountList) {
        List<SharingGroup__mdt> sharingGroups = SharingUtil.getAllSharingGroupTypes();
        List<String>            groupNames    = new List<String>();

        for (Account acc : accountList) {
            for (SharingGroup__mdt sharingGroup : sharingGroups) {
                groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, acc.Owner.ExtFinancialAdvisorId__c));
            }

            // Multi Owner Group
            if (String.isNotBlank(acc.ExtCustomerNumber__c)) {
                groupNames.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c));
            }
        }

        List<Group> groups = [SELECT Id, Name, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN :groupNames];
        Map<String, Id> groupNameToId = new Map<String, Id>();
        for (Group groupObj : groups) {
            groupNameToId.put(groupObj.Name, groupObj.Id);
        }

        List<AccountShare> newAccountShareList = new List<AccountShare>();
        for (Account acc : accountList) {
            if (acc.MultipleOwners__c == true) {
                String groupName   = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);
                Id     groupId     = groupNameToId.get(groupName);

                if (groupId == null) {        
                    continue;
                }

                newAccountShareList.add(
                    new AccountShare(
                        AccountId = acc.Id,
                        AccountAccessLevel = 'Edit',
                        OpportunityAccessLevel = 'None',
                        CaseAccessLevel = 'None',
                        UserOrGroupId = groupId)
                );
            }
            else {
                for (SharingGroup__mdt sharingGroup : sharingGroups) {
                    String groupName   = SharingUtil.getGroupNameBySetting(sharingGroup, acc.Owner.ExtFinancialAdvisorId__c);
                    Id     groupId     = groupNameToId.get(groupName);
                    String groupPrefix = sharingGroup.Prefix__c;
    
                    if (groupId == null || SharingUtil.isHidden(acc, sharingGroup)) {        
                        continue;
                    }
    
                    newAccountShareList.add(
                        new AccountShare(
                            AccountId = acc.Id,
                            AccountAccessLevel = 'Edit',
                            OpportunityAccessLevel = 'None',
                            CaseAccessLevel = 'None',
                            UserOrGroupId = groupId)
                    );
                }   
            }
    }

        insert newAccountShareList;
    }


    /* Helper Function to add AdvisorNumber and calculate Sharing Groups for all Advisors */    
    public static void initVbUserGroups (User user) {
        Id vbProfileId =  RecordTypeHelper.getUserProfileIdFieldSalesUser();

        List<User> vbUsers = [SELECT ID, FirstName, LastName, username, ExtFinancialAdvisorId__c 
                              FROM User
                              WHERE ProfileId = :vbProfileId and IsActive = true AND ExtFinancialAdvisorId__c  = null];

        System.debug('VB Users wihtout Advisor Number: ' + vbUsers.size());
        
        List<User> usersToUpdate = new List<User>();

        for (User usr : vbUsers) {
            if (String.isBlank(usr.ExtFinancialAdvisorId__c)) {
                system.debug('User has no AdvisorId: ' + usr.username);        
                usr.ExtFinancialAdvisorId__c = TestDataUtility.getRandomNumber(7);
                system.debug('Assigned: ' + usr.ExtFinancialAdvisorId__c);
                usersToUpdate.add(usr);
            } 
        }
        
        update usersToUpdate;

        List<Group> groupsToInsert = new List<Group>();        
        List<AgentSharingCalculation__c> agentShares = new List<AgentSharingCalculation__c>();

        for (User newUser : usersToUpdate) {
            if (newUser.ExtFinancialAdvisorId__c == null) {
                System.debug('Advisor ID still emppty: ' + newUser.username);
                continue;
            }

            for (SharingGroup__mdt sharingGroup : SharingUtil.getAllSharingGroupTypes()) {
                groupsToInsert.add(SharingUtil.createGroup(SharingUtil.getGroupNameBySetting(sharingGroup, newUser.ExtFinancialAdvisorId__c)));
            }
    
            agentShares.add(new AgentSharingCalculation__c(Agent__c = newUser.Id,UniqueKey__c = newUser.ExtFinancialAdvisorId__c));          
        }
        
        Database.saveResult[] results = Database.insert(groupsToInsert, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors('Init Vb User Groups', 'Insert Group failed', dmlHelper, true);

        upsert agentShares UniqueKey__c;
    }
}