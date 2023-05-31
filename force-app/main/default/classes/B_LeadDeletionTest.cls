/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Testclass
 *
 * @description Tests for lead deletion batch
 */

@IsTest
public class B_LeadDeletionTest {
    @TestSetup
    static void testSetup(){
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(1);

            User u = [SELECT Id, ContactId 
                    FROM User 
                    WHERE Alias = 'mumax1' 
                    LIMIT 1];
            List<Lead> leads = TestDataUtility.createLeads(4, u.ContactId, null);
            Test.setCreatedDate(leads[0].id, System.now().addDays(-10));
            Test.setCreatedDate(leads[1].id, System.now().addDays(-20));
            Test.setCreatedDate(leads[2].id, System.now().addDays(-30));
            Test.setCreatedDate(leads[3].id, System.now().addDays(-40));
        }
    }

    @IsTest
    static void testLeadDeletionBatch(){
        
        Test.startTest();
        Database.executeBatch(new B_LeadDeletion(), Integer.valueOf(Label.Lead_BatchSize));
        Test.stopTest();

        List<Lead> accShaCals = [SELECT Id FROM Lead];
        System.assert(accShaCals.size() == 2);
    }

    @IsTest
    static void testLeadDeletionBatchSchedulable(){
        Test.startTest();
        
        B_LeadDeletion leadBatch = new B_LeadDeletion();
        String sched = '00 30 * * * ?';
        System.schedule('B_LeadDeletion', sched, leadBatch); 

        Test.stopTest();
    }
}