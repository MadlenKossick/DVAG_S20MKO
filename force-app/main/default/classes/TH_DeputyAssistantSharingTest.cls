/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Testclass
 *
 * @description Tests for TH_DeputyAssistantSharing
 */

@IsTest
public class TH_DeputyAssistantSharingTest {
    @TestSetup
    static void testSetup() {
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            SharingTestUtil.createTestVbStructure();

            User testUser = SharingTestUtil.createFieldSalesContactUser('APEX', 'TEST', 'thisisonlyfor@apex.test', 'FedTest', SharingTestUtil.directoratePartnerAccount.Id, null);

            AssistantToAdvisor__c assToAdv = SharingUtil.createAssistantToAdvisor(testUser,testUser);
            insert assToAdv;

            DeputyToAdvisor__c depToAdv = SharingUtil.createDeputyToAdvisor(testUser,testUser);
            insert depToAdv;
        }        
    }

    @IsTest
    public static void testCreateNewAssistant(){
        SharingTestUtil.populateVbStructure();
        String groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, SharingTestUtil.vbAX1user.ExtFinancialAdvisorId__c);
        List<GroupMember> groupMembersBefore = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];

        System.assert(groupMembersBefore.size() == 0);

        Test.startTest();
        AssistantToAdvisor__c assToAdv = SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbAX1user, SharingTestUtil.vbBX2user);
        insert assToAdv;
        Test.stopTest();

        List<GroupMember> groupMembersAfter = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];

        System.assert(groupMembersAfter.size() == 1);
    }

    @IsTest
    public static void testDeleteAssistant(){
        String groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, 
                                                          'FedTest');

        List<GroupMember> groupMembersBefore = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];

        System.assert(groupMembersBefore.size() == 1);

        Test.startTest();
        delete [SELECT Id FROM AssistantToAdvisor__c LIMIT 1];
        Test.stopTest();

        List<GroupMember> groupMembersAfter = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];
                                                
        System.assert(groupMembersAfter.size() == 0);
    }

    @IsTest
    public static void testCreateNewDeputy(){
        SharingTestUtil.populateVbStructure();
        String groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, SharingTestUtil.vbAX1user.ExtFinancialAdvisorId__c);
        List<GroupMember> groupMembersBefore = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];

        System.assert(groupMembersBefore.size() == 0);

        Test.startTest();
        DeputyToAdvisor__c depToAdv = SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbAX1user, SharingTestUtil.vbBX2user);
        insert depToAdv;
        Test.stopTest();

        List<GroupMember> groupMembersAfter = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];

        System.assert(groupMembersAfter.size() == 1);
    }

    @IsTest
    public static void testDeleteDeputy(){
        String groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, 'FedTest');

        List<GroupMember> groupMembersBefore = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];

        System.assert(groupMembersBefore.size() == 1);

        Test.startTest();
        List<DeputyToAdvisor__c> tstDeptyRel = [SELECT Id FROM DeputyToAdvisor__c WHERE advisor__r.ExtFinancialAdvisorId__c = 'FedTest'];
        System.assertEquals(1, tstDeptyRel.size());
        delete tstDeptyRel;
        Test.stopTest();

        List<GroupMember> groupMembersAfter = [SELECT Id 
                                                FROM   GroupMember
                                                WHERE  Group.DeveloperName = :groupName];
                                                
        System.assert(groupMembersAfter.size() == 0);
    }
}