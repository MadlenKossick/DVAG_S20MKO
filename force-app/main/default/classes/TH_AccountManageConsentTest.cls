@isTest
private class TH_AccountManageConsentTest {
    
    @isTest
    static void testPersonAccountConsent(){
        // Validate before insert trigger to reset Consent fields with empty IndividualId on PersonAccount
        List<Account> accounts = TestDataUtility.createPersonAccount(2);
        
        Test.startTest();
        // Query of the test data is requiered, otherwise SystemAssert always fails
        // see: Knowledeg Entry: https://help.salesforce.com/s/articleView?id=000318949&type=1 
        Account accl = new Account();
        accl = [SELECT ConsentToProcessStatus__pc, HasOptedOutProcessing__pc, 
                        PersonHasOptedOutOfEmail, ConsentToEmailStatus__pc,
                        PersonDoNotCall, ConsentToCallStatus__pc, 
                        FinServ__MarketingOptOut__pc, ConsentToMarketingStatus__pc, 
                        HasOptedOutForCare__pc
                FROM Account 
                WHERE Id = :accounts[0].id];

        System.assertEquals(null, accl.ConsentToProcessStatus__pc);
        System.assertEquals(true, accl.HasOptedOutProcessing__pc);
        System.assertEquals(true, accl.PersonHasOptedOutOfEmail);    
        System.assertEquals(true, accl.PersonDoNotCall);
        System.assertEquals(true, accl.FinServ__MarketingOptOut__pc);
        System.assertEquals(false, accl.HasOptedOutForCare__pc);
        
        // set all picklist Values -> OptIn (all checkboxes are false)
        accl.ConsentToProcessStatus__pc = 'NotSeen';
        accl.HasOptedOutProcessing__pc = false;
        accl.ConsentToEmailStatus__pc = 'Seen';
        accl.PersonHasOptedOutOfEmail = false;    
        accl.ConsentToCallStatus__pc = 'NotSeen';
        accl.PersonDoNotCall = false;    
        accl.ConsentToMarketingStatus__pc = 'Seen';
        accl.FinServ__MarketingOptOut__pc = false;

        update accl;

        accl = [SELECT ConsentToProcessStatus__pc, HasOptedOutProcessing__pc, 
                        PersonHasOptedOutOfEmail, ConsentToEmailStatus__pc,
                        PersonDoNotCall, ConsentToCallStatus__pc, 
                        FinServ__MarketingOptOut__pc, ConsentToMarketingStatus__pc, 
                        HasOptedOutForCare__pc
                FROM Account 
                WHERE Id = :accounts[0].id];

        System.assertEquals('OptIn', accl.ConsentToProcessStatus__pc);
        System.assertEquals('OptIn', accl.ConsentToEmailStatus__pc);    
        System.assertEquals('OptIn', accl.ConsentToCallStatus__pc);
        System.assertEquals('OptIn', accl.ConsentToMarketingStatus__pc);

        // unchecked all fields -> OptOut (all checkboxes are true)
        accl.HasOptedOutProcessing__pc = true;            
        accl.PersonHasOptedOutOfEmail = true;            
        accl.PersonDoNotCall = true;            
        accl.FinServ__MarketingOptOut__pc = true;

        update accl;

        accl = [SELECT ConsentToProcessStatus__pc, HasOptedOutProcessing__pc, 
                        PersonHasOptedOutOfEmail, ConsentToEmailStatus__pc,
                        PersonDoNotCall, ConsentToCallStatus__pc, 
                        FinServ__MarketingOptOut__pc, ConsentToMarketingStatus__pc, 
                        HasOptedOutForCare__pc
                FROM Account 
                WHERE Id = :accounts[0].id];
        System.assertEquals('OptOut', accl.ConsentToProcessStatus__pc);
        System.assertEquals('OptOut', accl.ConsentToEmailStatus__pc);    
        System.assertEquals('OptOut', accl.ConsentToCallStatus__pc);
        System.assertEquals('OptOut', accl.ConsentToMarketingStatus__pc);
        
        // death contact
        Account accd = new Account();
        accd = [SELECT ConsentToProcessStatus__pc, HasOptedOutProcessing__pc, 
                        PersonHasOptedOutOfEmail, ConsentToEmailStatus__pc,
                        PersonDoNotCall, ConsentToCallStatus__pc, 
                        FinServ__MarketingOptOut__pc, ConsentToMarketingStatus__pc, 
                        HasOptedOutForCare__pc
                  FROM Account 
                  WHERE Id = :accounts[1].Id];

        accd.IsDeceased__pc = true;
        update accd;

        accd = [SELECT ConsentToProcessStatus__pc, HasOptedOutProcessing__pc, 
                        PersonHasOptedOutOfEmail, ConsentToEmailStatus__pc,
                        PersonDoNotCall, ConsentToCallStatus__pc, 
                        FinServ__MarketingOptOut__pc, ConsentToMarketingStatus__pc, 
                        HasOptedOutForCare__pc
                  FROM Account 
                  WHERE Id = :accounts[1].Id];

        System.assertEquals('Fulfilled', accd.ConsentToProcessStatus__pc);
        System.assertEquals('OptOut', accd.ConsentToEmailStatus__pc);    
        System.assertEquals('OptOut', accd.ConsentToCallStatus__pc);
        System.assertEquals('OptOut', accd.ConsentToMarketingStatus__pc);
          
        Test.stopTest();
    }
}