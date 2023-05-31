@IsTest
public class TH_UserGroupsTest {
    private static final STRING FEDERATION_ID = 'vb4711';
    
    @TestSetup
    static void setupTestData() {
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(4711);
        }
    }

    @isTest
    static void handleUserGroups() {        
        
        User usr = [SELECT Id 
                    FROM User 
                    WHERE FederationIdentifier =  :FEDERATION_ID
                    LIMIT 1];
        
        String groupFilter = '%'+FEDERATION_ID;
        
        List<Group> groups = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName LIKE :groupFilter
                              ];
        System.assertEquals(SharingUtil.getAllSharingGroupTypes().size(), groups.size());

        List<AgentSharingCalculation__c> lst_agentShare = [SELECT Id
                                                           FROM AgentSharingCalculation__c
                                                           WHERE Agent__c = :usr.Id
                                                        ];
        System.assertNotEquals(null, lst_agentShare);
    }    
}