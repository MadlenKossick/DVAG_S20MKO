@IsTest
public class TH_UserPermissionSettingTest {
    @TestSetup
    static void setupTestData(){   
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(1);
        }
    }

    @isTest
    static void handleUserPermissionSettings(){
        Test.startTest();
        Test.stopTest();
        User u = [SELECT Id FROM User WHERE Alias = 'mumax1' LIMIT 1];

        List<PermissionSetAssignment> lst_permSet = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :u.Id];
        System.assertNotEquals(null, lst_permSet);
    }
}