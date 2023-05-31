/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Test
 *
 * @description Test for TH_ToastEvent
 */
@isTest
public class TH_ToastEventTest {
    private static final Integer NUMBER_OF_ACCOUNTS = 1;

    @TestSetup
    static void testSetup(){
        // create TestVB for ToastEvent
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(1);
        }
    }

    @isTest
    static void testUpdateAccount_HouseholdAddress() {
        // helper class for subscribe the platform event
        String userSessionId = C_SessionUtil.getSessionId();
        
        TH_ToastEventTestService.events = new List<SObject>();
        User vbUser = [SELECT Id FROM USER WHERE Alias = 'mumax1' LIMIT 1];
        
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
    
        for(Account account : accountMap.values()) {
            account.OwnerId = vbUser.Id;
        }
        
        update accountMap.values();

        Test.startTest();
        System.runAs(vbUser) {
            for(Account account : accountMap.values()) {
                account.PersonMailingStreet = 'Wegweiser 12';
                account.PersonMailingCity = 'Musterhausen';
                account.PersonMailingPostalCode = '12345';
                account.PersonMailingCountry = 'Germany';
            }
            update accountMap.values();
        }
        Test.stopTest();

        List<ToastEvent__e> events = TH_ToastEventTestService.events;
        Integer amountOfUpdateEvents = 0;
        for(ToastEvent__e event : events) {
            if(event.Key__c == 'Acc_AddressChanged') {
                
                System.assert(accountMap.containsKey(event.RecordId__c));
                amountOfUpdateEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfUpdateEvents);
    }

    @isTest
    static void testUpdateAccount_AdditionalAddress() {
        // helper class for subscribe the platform event
        String userSessionId = C_SessionUtil.getSessionId();
        
        TH_ToastEventTestService.events = new List<SObject>();
        User vbUser = [SELECT Id FROM USER WHERE Alias = 'mumax1' LIMIT 1];
        
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
    
        for(Account account : accountMap.values()) {
            account.OwnerId = vbUser.Id;
            account.PreferredPostalAddress__pc = 'AdditionalAddress';
        }
        
        update accountMap.values();

        Test.startTest();
        System.runAs(vbUser) {
            for(Account account : accountMap.values()) {
                account.PersonOtherStreet = 'Wegweiser 12';
                account.PersonOtherCity = 'Musterhausen';
                account.PersonOtherPostalCode = '12345';
                account.PersonOtherCountry = 'Germany';
            }
            update accountMap.values();
        }
        Test.stopTest();

        List<ToastEvent__e> events = TH_ToastEventTestService.events;
        Integer amountOfUpdateEvents = 0;
        for(ToastEvent__e event : events) {
            if(event.Key__c == 'Acc_AddressChanged') {
                
                System.assert(accountMap.containsKey(event.RecordId__c));
                amountOfUpdateEvents++;
            }
        }
        // no event should fired
        System.assertEquals(0, amountOfUpdateEvents);
    }
}