/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Testclass
 *
 * @description Testclass for C_SharingJobScheduler
 */

@IsTest
public class C_SharingJobSchedulerTest {
    
    @TestSetup
    static void testSetup(){
        TestDataUtility.getIntegrationTestUser();
    }

   @isTest
   static void startAgentBatchTest(){
      Test.startTest();
      C_SharingJobScheduler.startBatch('Agent');
      Test.stopTest();
   }

   @isTest
   static void start360ObjectsTest(){
      Test.startTest();
      C_SharingJobScheduler.startBatch('360Objects');
      Test.stopTest();
   }

   @isTest
   static void getJobHistoryTest(){
      Test.startTest();
      String jobId = System.schedule(
        'CAL Sharing Group Hierachy in Apex Test',
        '0 0 23 * * ?',
        new B_CalculateGroupHierarchy()
      );
      Test.stopTest();

      List<C_SharingJobScheduler.BatchJobHistory> jobs = C_SharingJobScheduler.getJobHistory();
      System.assert(jobs.size() > 1);
   }

   @isTest
   static void getCurrentlyScheduledCronsTest(){
      Test.startTest();
      List<CronTrigger> jobs = C_SharingJobScheduler.getCurrentlyScheduledCrons('%Sharing%');
      System.assert(jobs.size() == 0);
      Test.stopTest();
   }

   @isTest
   static void scheduleJobAccountEvery5Minutes(){
      Test.startTest();
      C_SharingJobScheduler.scheduleJob('every5minutes', 'agent');
      Test.stopTest();
   }

   @isTest
   static void scheduleJobAccountEvery15Minutes(){
      Test.startTest();
      C_SharingJobScheduler.scheduleJob('every15minutes', 'agent');
      Test.stopTest();
   }

   @isTest
   static void scheduleJobAccountEvery30Minutes(){
      Test.startTest();
      C_SharingJobScheduler.scheduleJob('every30minutes', 'agent');
      Test.stopTest();
   }

   @isTest
   static void scheduleJobAgreementEvery5Minutes(){
      Test.startTest();
      C_SharingJobScheduler.scheduleJob('every5minutes', '360Objects');
      Test.stopTest();
   }

   @isTest
   static void scheduleJobAgreementEvery15Minutes(){
      Test.startTest();
      C_SharingJobScheduler.scheduleJob('every15minutes', '360Objects');
      Test.stopTest();
   }

   @isTest
   static void scheduleJobAgreementEvery30Minutes(){
      Test.startTest();
      C_SharingJobScheduler.scheduleJob('every30minutes', '360Objects');
      Test.stopTest();
   }

   @isTest
   static void deleteScheduledJobTest(){
      Test.startTest();
      C_SharingJobScheduler.deleteScheduledJob(new List<String>{'testid'});
      Test.stopTest();
   }

    @isTest
    static void addAgentSharingCalculationsAll(){
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(1);
        }

        List<AgentSharingCalculation__c> agentCalculationsBefore = [SELECT Id
                                                                    FROM   AgentSharingCalculation__c];

        delete agentCalculationsBefore;

        Test.startTest();
        C_SharingJobScheduler.addAgentSharingCalculations('');
        Test.stopTest();

        List<AgentSharingCalculation__c> agentCalculation = [SELECT Id
                                                             FROM   AgentSharingCalculation__c];
        system.assert(agentCalculation.size() > 0);
    }

    @isTest
    static void addAgentSharingCalculation(){
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(1);
        }

        List<User> users = [SELECT Id FROM User WHERE CreatedDate = TODAY];
        List<String> userIds = new List<String>();

        for (User usr : users) {
            userIds.add(usr.Id);
        }

        List<AgentSharingCalculation__c> agentCalculationsBefore = [SELECT Id
                                                                    FROM   AgentSharingCalculation__c];

        delete agentCalculationsBefore;
        Test.startTest();
        C_SharingJobScheduler.addAgentSharingCalculations(String.join(userIds, ', '));
        Test.stopTest();

        List<AgentSharingCalculation__c> agentCalculation = [SELECT Id
                                                             FROM   AgentSharingCalculation__c];
        system.assert(agentCalculation.size() > 0);
    }

    @isTest
    static void addAccountSharingCalculationsAll(){
        TestDataUtility.createPersonAccount(2);

        List<AccountSharingCalculation__c> acccountCalculationsBefore = [SELECT Id
                                                                         FROM   AccountSharingCalculation__c];

        delete acccountCalculationsBefore;

        Test.startTest();
        C_SharingJobScheduler.addAccountSharingCalculations('');
        Test.stopTest();

        List<AccountSharingCalculation__c> accountCalculation = [SELECT Id
                                                                 FROM   AccountSharingCalculation__c];
        system.assert(accountCalculation.size() == 2);
    }

    @isTest
    static void addAccountSharingCalculation(){
        TestDataUtility.createPersonAccount(1);

        List<Account> accounts = [SELECT Id FROM Account];
        List<String> accountIds = new List<String>();

        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        List<AccountSharingCalculation__c> acccountCalculationsBefore = [SELECT Id
                                                                         FROM   AccountSharingCalculation__c];

        delete acccountCalculationsBefore;

        Test.startTest();
        C_SharingJobScheduler.addAccountSharingCalculations(String.join(accountIds, ', '));
        Test.stopTest();

        List<AccountSharingCalculation__c> accountCalculation = [SELECT Id
                                                                 FROM   AccountSharingCalculation__c];
        system.assert(accountCalculation.size() == 1);
    }
}