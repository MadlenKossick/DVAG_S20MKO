/**
* @author Cloud Consulting Group - Patrick Driller
* @date 2022
*
* @group Batch, Scheduleable
*
* @description Sharing Calculation Job to add hierarchy structure to the public group
*/

global class B_CalculateGroupHierarchy implements Database.Batchable<SObject>, Schedulable, Database.Stateful, Database.AllowsCallouts
{
    private static String PROCESS = 'Calculate Group Hierarchy';

    // Scheduleable
    global void execute(SchedulableContext sc){
        Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
    }

    Boolean     init = false;
    Map<Id, Id> contactIdToReportsToId = new Map<Id, Id>();
    Map<Id, Id> contactIdToUserId = new Map<Id, Id>();
    Map<Id, Id> userIdToContactId = new Map<Id, Id>();

    List<AgentSharingCalculation__c> agentSharingCalculations = new List<AgentSharingCalculation__c>();

    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        return Database.getQueryLocator('SELECT Id, Agent__c, UniqueKey__c FROM AgentSharingCalculation__c LIMIT 10000');
    }

    public void execute(Database.BatchableContext BC, List<sObject> records)
    {
        if (!init) {
            List<User> communityUsers = [SELECT Id, 
                                                ContactId, 
                                                Contact.ReportsToId
                                         FROM   User
                                         WHERE  ContactId != null
                                         ORDER BY Id];

            for (User usr : communityUsers) {
                contactIdToReportsToId.put(usr.ContactId, usr.Contact.ReportsToId);
                contactIdToUserId.put(usr.ContactId, usr.Id);
                userIdToContactId.put(usr.Id, usr.ContactId);
            }

            init = true;
        }

        try {
            calculateAgentHierarchyChunk((List<AgentSharingCalculation__c>)records, contactIdToReportsToId, contactIdToUserId, userIdToContactId);
        } catch (Exception e) {
            ErrorUtil.logExceptionErrorAPI(process, 'Batch Chunk Error Agent Hierarchy Calculation', e);
        }

        agentSharingCalculations.addAll((List<AgentSharingCalculation__c>)records);
    }

    public void finish(Database.BatchableContext bc){
        CCG_Log.create(process, 'Agent Hierarchy Calculation', '', 'Batch Finished');
        CCG_Log.sendAPI();
        
        // in finish because of MIXED_DML_OPERATION
        Database.deleteResult[] results = Database.delete(agentSharingCalculations, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(process, 'Deletion sharing calculations failed', dmlHelper, true);

        if (agentSharingCalculations.size() >= 10000) {
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
        }
    }

    private static void calculateAgentHierarchyChunk(List<AgentSharingCalculation__c> sharingCalculations, Map<Id, Id> contactIdToReportsToId, Map<Id, Id> contactIdToUserId, Map<Id, Id> userIdToContactId){
        Map<String, Id> groupNameToAgentUserId = new Map<String, Id>();
        for (AgentSharingCalculation__c agentShaCal : sharingCalculations) {
            groupNameToAgentUserId.put(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Hierarchy, agentShaCal.UniqueKey__c), agentShaCal.Agent__c);
        }

        Map<Id, Group> groupIdToGroup = new Map<Id, Group>([SELECT Id, 
                                                                   DeveloperName,
                                                                   (SELECT  Id, 
                                                                            UserOrGroupId
                                                                    FROM    GroupMembers)
                                                            FROM Group 
                                                            WHERE DeveloperName IN :groupNameToAgentUserId.keySet()]);

        List<GroupMember> groupMemberToInsert = new List<GroupMember>();
        List<GroupMember> groupMemberToDelete = new List<GroupMember>();
        Set<Id>           addedUsersOverall = new Set<Id>();

        for (Group agentGroup : groupIdToGroup.values()) {
            for (GroupMember groupMember : agentGroup.GroupMembers) {
                groupMemberToDelete.add(groupMember);
            }

            Id agentGroupOwnerUserId = groupNameToAgentUserId.get(agentGroup.DeveloperName);
            Id reportsToId = contactIdToReportsToId.get(userIdToContactId.get(agentGroupOwnerUserId));

            if (reportsToId == null) {
                  continue;
            }
   
            do {
               Id reportsToUserId = contactIdToUserId.get(reportsToId);
               groupMemberToInsert.add(SharingUtil.createGroupMember(agentGroup.Id, reportsToUserId));
               reportsToId = contactIdToReportsToId.get(reportsToId);
            } while (reportsToId != null);
        }
        
        Database.deleteResult[] results = Database.delete(groupMemberToDelete, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(process, 'Deletion Group Members failed', dmlHelper, true);
        
        Database.saveResult[] svResults = Database.insert(groupMemberToInsert, false);
        dmlHelper = new DMLHelper(svResults);
        ErrorUtil.processDMLErrors(process, 'Insert Group Members failed', dmlHelper, true);
    }
}