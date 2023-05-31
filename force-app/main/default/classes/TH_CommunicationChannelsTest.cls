@isTest
public class TH_CommunicationChannelsTest {
    @TestSetup
    static void makeData(){

        // Create a test Contact record
        Contact contact = new Contact();
        contact.LastName = 'TestContact';
        contact.Email = 'testEmail@test.com';
        contact.FinServ__LinkedIn__c = 'https://www.linkedin.com/in/test';
        contact.MobilePhone = '555-555-5555';
        contact.Phone = '555-555-5555';
        contact.ExtEmailIdOki__c = 'testEmailId';
        contact.ExtLinkedInIdOki__c = 'testLinkedInId';
        contact.ExtMobileIdOki__c = 'testMobileId';
        contact.ExtPhoneIdOki__c = 'testPhoneId';
        insert contact;
        
        // Create a test Account record
        List<Account> testObj = TestDataUtility.createPersonAccount(1);
        testObj[0].PersonEmail = 'testEmail@test.com';
        testObj[0].FinServ__LinkedIn__pc = 'https://www.linkedin.com/in/test';
        testObj[0].PersonMobilePhone = '555-555-5555';
        testObj[0].PersonHomePhone = '555-555-5555';
        testObj[0].Website = 'http://test.de';
        testObj[0].PersonOtherStreet = 'Musterweg 1';
        testObj[0].PersonOtherPostalCode = '12345';
        testObj[0].PersonOtherCity = 'Test';
        testObj[0].PersonOtherCountry = 'Germany';
        testObj[0].ExtEmailIdOki__pc = 'testEmailId';
        testObj[0].ExtLinkedInIdOki__pc = 'testLinkedInId';
        testObj[0].ExtMobileIdOki__pc = 'testMobileId';
        testObj[0].ExtPhoneIdOki__pc = 'testPhoneId';
        testObj[0].ExtWebsiteIdOki__c = 'testWebsiteId';
        testObj[0].ExtOtherAddressIdOki__pc = 'testOtherAddressId';
        update testObj;

    }

    @isTest
    static void testDeleteOkiIdsContacts() {
        
        Contact cont = [SELECT Email, FinServ__LinkedIn__c, MobilePhone, Phone 
                        FROM Contact LIMIT 1];

        // Update the email field to null
        cont.Email = null;
        cont.FinServ__LinkedIn__c = null;
        cont.MobilePhone = null;
        cont.Phone = null;

        test.startTest();
        update cont;
        test.stopTest();

        // Verify that the extEmail field was also set to null
        Contact updatedObj = [SELECT ExtEmailIdOki__c, ExtLinkedInIdOki__c, ExtMobileIdOki__c, 
                                    ExtPhoneIdOki__c 
                                FROM Contact 
                                WHERE Id = :cont.Id
                                LIMIT 1];

        System.assertEquals(null, updatedObj.ExtEmailIdOki__c);
        System.assertEquals(null, updatedObj.ExtLinkedInIdOki__c);
        System.assertEquals(null, updatedObj.ExtMobileIdOki__c);
    }

    @isTest
    static void testDeleteOkiIdsAccounts() {
        
        Account account = [SELECT PersonEmail, FinServ__LinkedIn__pc, PersonMobilePhone, PersonHomePhone, 
                                Website, PersonOtherStreet 
                            FROM Account LIMIT 1];

        // Update the email field to null
        account.PersonEmail = null;
        account.FinServ__LinkedIn__pc = null;
        account.PersonMobilePhone = null;
        account.PersonHomePhone = null;
        account.Website = null;
        account.PersonOtherStreet = null;
        account.PersonOtherPostalCode = null;
        account.PersonOtherCity = null;
        account.PersonOtherCountry = null;

        test.startTest();
        update account;
        test.stopTest();

        // Verify that the extEmail field was also set to null
        Account updatedObj = [SELECT ExtEmailIdOki__pc, ExtLinkedInIdOki__pc, ExtMobileIdOki__pc, 
                                        ExtPhoneIdOki__pc, ExtWebsiteIdOki__c, ExtOtherAddressIdOki__pc
                                FROM Account 
                                WHERE Id = :account.Id
                                LIMIT 1];

        System.assertEquals(null, updatedObj.ExtEmailIdOki__pc);
        System.assertEquals(null, updatedObj.ExtLinkedInIdOki__pc);
        System.assertEquals(null, updatedObj.ExtMobileIdOki__pc);
        System.assertEquals(null, updatedObj.ExtPhoneIdOki__pc);
        System.assertEquals(null, updatedObj.ExtWebsiteIdOki__c);
        System.assertEquals(null, updatedObj.ExtOtherAddressIdOki__pc);
    }
}