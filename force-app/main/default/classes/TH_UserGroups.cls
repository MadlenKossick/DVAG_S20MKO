/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description create public groups for new User
 */

public class TH_UserGroups {
    private static String PROCESS = 'User Groups';

    public static void handleUserGroups(Map<Id, SObject> users) {
        List<Group> groupsToInsert = new List<Group>();
        Set<Id> usersToCalculate = new Set<Id>();
        Id vbProfile = RecordTypeHelper.getUserProfileIdFieldSalesUser(); 

        for (User newUser : (List<User>)users.values()) {            
            if (newUser.ProfileId != vbProfile) {
                continue;
            }
            
            if (newUser.ExtFinancialAdvisorId__c == null) {
                System.debug('DBG| Missing ExtFinancialAdvisorId__c for newUser ' + newUser.Id);
                continue;
            }            

            for (SharingGroup__mdt sharingGroup : SharingUtil.getAllSharingGroupTypes()) {
                groupsToInsert.add(SharingUtil.createGroup(SharingUtil.getGroupNameBySetting(sharingGroup, newUser.ExtFinancialAdvisorId__c)));
            }    

            usersToCalculate.add(newUser.Id);
        }
        
        Database.saveResult[] results = Database.insert(groupsToInsert, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert Group failed', dmlHelper, true);

        createAgentCalculationFuture(usersToCalculate);
    }

    // add the user to list of AgentSharingCalculation__c 
    @future    
    private static void createAgentCalculationFuture(Set<Id> userIds) {
        List<AgentSharingCalculation__c> agentShares = new List<AgentSharingCalculation__c>();
        
        List<User> users = [SELECT  Id, ExtFinancialAdvisorId__c 
                            FROM    User
                            WHERE   Id IN :userIds
        ];
        
        for (User user : users) {
            agentShares.add(new AgentSharingCalculation__c(
                Agent__c = user.Id,
                UniqueKey__c = user.ExtFinancialAdvisorId__c
            ));  
        }

        Database.upsertResult[] results = Database.upsert(agentShares, AgentSharingCalculation__c.Fields.UniqueKey__c, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Upsert Agent Sharing Calculation failed', dmlHelper, true);
    }
}