/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Updates the Groups whenever an Assistant or Duputy was added or changed
 */

public class TH_DeputyAssistantSharing {
    private static String PROCESS = 'Deputy Assistant Sharing';

    /* ASSISTANTS */
    @future
    public static void addNewAssistantsToGroupsFuture(Set<Id> advToAssIds){
        List<AssistantToAdvisor__c> assistants = [SELECT Id,
                                                        Advisor__c,
                                                        Advisor__r.ExtFinancialAdvisorId__c,
                                                        Advisor__r.name,
                                                        Assistant__c,
                                                        Assistant__r.ExtFinancialAdvisorId__c,
                                                        Assistant__r.name
                                                  FROM  AssistantToAdvisor__c
                                                  WHERE Id IN :advToAssIds];

        Map<Id, List<String>> advisorIdToGroupName = new Map<Id, List<String>>();

        for (AssistantToAdvisor__c assistant : assistants) {
            if (assistant.Advisor__c == null || String.isBlank(assistant.Advisor__r.ExtFinancialAdvisorId__c)) {
                System.debug('DBG: WARNING: assistant entry' + assistant.id + ' has no advisor information, skipping.');
                continue;
            }
            //get the sharing group to add the assistant to
            String groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, 
                                                              assistant.Advisor__r.ExtFinancialAdvisorId__c);
            System.debug('DBG: Adding assistant ' + assistant.Assistant__c + '-' + assistant.assistant__r.name + ' to group ' + groupName);
            if(advisorIdToGroupName.containsKey(assistant.Assistant__c)) {
                advisorIdToGroupName.get(assistant.Assistant__c).add(groupName);
            } else {
                advisorIdToGroupName.put(assistant.Assistant__c, new List<String> { groupName });
            }
        }
        addAssOrDepToGroups(advisorIdToGroupName);
    }

    public static void deleteAssistantsFromGroups(List<AssistantToAdvisor__c> advToAss){
        deleteAssOrDepFromGroups((List<sObject>)advToAss, SharingUtil.SharingGroup.Assistants);
    }

    /* DEPUTIES */
    @future
    public static void addNewDeputiesToGroupsFuture(Set<Id> advToDepIds){
        List<DeputyToAdvisor__c> deputies = [SELECT Id,
                                                    Advisor__c,
                                                    Advisor__r.ExtFinancialAdvisorId__c,
                                                    Deputy__c
                                             FROM   DeputyToAdvisor__c
                                             WHERE  Id IN :advToDepIds];

        Map<Id, List<String>> deputyIdToGroupName = new Map<Id, List<String>>();
        for (DeputyToAdvisor__c deputy : deputies) {
            if (deputy.Advisor__c == null || String.isBlank(deputy.Advisor__r.ExtFinancialAdvisorId__c)) {
                continue;
            }

            String groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, 
                                                              deputy.Advisor__r.ExtFinancialAdvisorId__c);
            if(deputyIdToGroupName.containsKey(deputy.Deputy__c)) {
                deputyIdToGroupName.get(deputy.Deputy__c).add(groupName);
            } else {
                deputyIdToGroupName.put(deputy.Deputy__c, new List<String> { groupName });
            }
        }

        addAssOrDepToGroups(deputyIdToGroupName);
    }

    public static void deleteDeputiesFromGroups(List<DeputyToAdvisor__c> advToDep){
        deleteAssOrDepFromGroups((List<sObject>)advToDep, SharingUtil.SharingGroup.Deputies);
    }

    /* HELPER */
    private static void addAssOrDepToGroups(Map<Id, List<String>> assOrDepIdToGroupNames){
        if (assOrDepIdToGroupNames.isEmpty()) {
            return;
        }

        Set<String> groupNames = new Set<String>();
        for (List<String> groupNameList : assOrDepIdToGroupNames.values()) {
            groupNames.addAll(groupNameList);
        }
        
        List<Group> groups = [SELECT Id, 
                                     DeveloperName
                              FROM   Group
                              WHERE  DeveloperName IN :groupNames];        
        
        Map<String, Id> groupNameToId = new Map<String, Id>();
        for (Group groupObj : groups) {
            groupNameToId.put(groupObj.DeveloperName, groupObj.Id);
        }
        
        List<GroupMember> groupMembersToInsert = new List<GroupMember>();
        for (Id assOrDepId : assOrDepIdToGroupNames.keySet()) {            
            for (String groupName : assOrDepIdToGroupNames.get(assOrDepId)) {
                groupMembersToInsert.add(SharingUtil.createGroupMember(groupNameToId.get(groupName),assOrDepId));                
            }
        }
        
        Database.saveResult[] results = Database.insert(groupMembersToInsert, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert Assistant/Deputy failed', dmlHelper, true);
    }

    private static void deleteAssOrDepFromGroups(List<SObject> objs, SharingUtil.SharingGroup type){
        Map<Id, String> objectIdToGroupName = getObjectIdToAdvisorGroupNameMapByObjs(objs, type);
        if (objectIdToGroupName.isEmpty()) {
            return;
        }

        String groupNameLike = SharingUtil.getGroupNameByType(type, '') + '%';
        List<GroupMember> groupMembers = [SELECT Id, 
                                                 Group.DeveloperName,
                                                 GroupId,
                                                 UserOrGroupId
                                          FROM   GroupMember
                                          WHERE  UserOrGroupId IN :objectIdToGroupName.keySet()
                                          AND    Group.DeveloperName LIKE :groupNameLike];
        Set<Id> groupMemberToDelete = new Set<Id>();
        for (GroupMember groupMember : groupMembers) {
            String groupName = objectIdToGroupName.get(groupMember.UserOrGroupId);
            if (String.isNotBlank(groupName) && groupName == groupMember.Group.DeveloperName) {
                groupMemberToDelete.add(groupMember.Id);
            }
        }
        
        deleteGroupMembersFuture(groupMemberToDelete);
    }

    private static Map<Id, String> getObjectIdToAdvisorGroupNameMapByObjs(List<sObject> objs, SharingUtil.SharingGroup type){
        Set<Id> allAdvisors = new Set<Id>();
        for (sObject obj : objs) {
            String advisorId = String.valueOf(obj.get('Advisor__c'));
            if (String.isNotBlank(advisorId) && allAdvisors.contains(advisorId) == false) {
                allAdvisors.add(advisorId);
            }
        }

        List<User> advisors = [SELECT Id, 
                                      ExtFinancialAdvisorId__c
                               FROM   User
                               WHERE  Id IN :allAdvisors];
        Map<Id, String> userIdToAdvisorId = new Map<Id, String>();
        for (User usr : advisors) {
            userIdToAdvisorId.put(usr.Id, usr.ExtFinancialAdvisorId__c);
        }

        Map<Id, String> advisorIdToGroupName = new Map<Id, String>();
        for (SObject obj : objs) {
            String advExternalId = userIdToAdvisorId.get(String.valueOf(obj.get('Advisor__c')));
            if (String.isBlank(advExternalId)) {
                 continue;
            }

            String groupName = SharingUtil.getGroupNameByType(type, advExternalId);
            if (type == SharingUtil.SharingGroup.Assistants) {
                advisorIdToGroupName.put(String.valueOf(obj.get('Assistant__c')), groupName);
            }
            else if(type == SharingUtil.SharingGroup.Deputies){
                advisorIdToGroupName.put(String.valueOf(obj.get('Deputy__c')), groupName);
            }
        }

        return advisorIdToGroupName;
   }

    @future
    private static void deleteGroupMembersFuture(Set<Id> groupMemberIds){
        List<GroupMember> groupMembersToDelete = new List<GroupMember>();
        for (Id groupMemberId : groupMemberIds) {
            groupMembersToDelete.add(new GroupMember(Id = groupMemberId));
        }
        
        Database.deleteResult[] results = Database.delete(groupMembersToDelete, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Delete Group Members Future failed', dmlHelper, true);
    }    
}