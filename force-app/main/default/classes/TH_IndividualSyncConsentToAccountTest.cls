@isTest
public class TH_IndividualSyncConsentToAccountTest {
    
    @isTest
    static void testConsentTriggeredUpdate(){
        List<Account> accounts = TestDataUtility.createPersonAccount(2);
        List<Individual> indvls = TestDataUtility.createIndividual(1);

        Test.startTest();
        // Query of the test data is requiered, otherwise SystemAssert always fails
        // see: Knowledeg Entry: https://help.salesforce.com/s/articleView?id=000318949&type=1 
        Account accl = new Account();
        accl = [SELECT HasOptedOutProcessing__pc, FinServ__MarketingOptOut__pc
                FROM Account 
                WHERE Id = :accounts[0].id];
        
        // Assign Indiviudal to Account
        accounts[0].PersonIndividualId = indvls[0].Id;
        accounts[0].HasOptedOutProcessing__pc = false;
        accounts[0].FinServ__MarketingOptOut__pc = true;
        accounts[1].PersonIndividualId = indvls[0].Id;
        accounts[1].HasOptedOutProcessing__pc = true;
        accounts[1].FinServ__MarketingOptOut__pc = true;

        update accounts;
        
        // init/setup individual consent
        indvls[0].HasOptedOutProcessing = true;
        indvls[0].HasOptedOutSolicit = true;
        
        update indvls;
        
        accl = [SELECT HasOptedOutProcessing__pc, FinServ__MarketingOptOut__pc
                FROM Account 
                WHERE Id = :accounts[0].id];
        
        System.assertEquals(true, accl.HasOptedOutProcessing__pc);
        System.assertEquals(true, accl.FinServ__MarketingOptOut__pc);

        // toggle consent and check the second one
        indvls[0].HasOptedOutProcessing = false;
        indvls[0].HasOptedOutSolicit = false;

        update indvls;
        
        accl = [SELECT HasOptedOutProcessing__pc, FinServ__MarketingOptOut__pc
                FROM Account 
                WHERE Id = :accounts[1].id];
        
        System.assertEquals(false, accl.HasOptedOutProcessing__pc);
        System.assertEquals(false, accl.FinServ__MarketingOptOut__pc);
        
        // toggle just one consent and check on account
        indvls[0].HasOptedOutSolicit = true;

        update indvls;
        
        accl = [SELECT HasOptedOutProcessing__pc, FinServ__MarketingOptOut__pc
                FROM Account 
                WHERE Id = :accounts[0].id];
        
        System.assertEquals(false, accl.HasOptedOutProcessing__pc);
        System.assertEquals(true, accl.FinServ__MarketingOptOut__pc);        

        // toggle just one consent and check on the other account
        indvls[0].HasOptedOutProcessing = true;

        update indvls;
        
        accl = [SELECT HasOptedOutProcessing__pc, FinServ__MarketingOptOut__pc
                FROM Account 
                WHERE Id = :accounts[1].id];
        
        System.assertEquals(true, accl.HasOptedOutProcessing__pc);
        System.assertEquals(true, accl.FinServ__MarketingOptOut__pc);        
        
        Test.stopTest();
    }    
}