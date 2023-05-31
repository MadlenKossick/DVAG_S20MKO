/**
 * @author CCG Jochen Litzinger
 * @date 2023
 *
 * @group Test
 *
 * @description Test for LC_SetPrimaryHousehold
 */

@isTest
public class LC_SetPrimaryHouseholdTest {

    private static final String ADVISOR_NUMBER = '4711';

    @TestSetup
    static void createTestData() {        
        User testVB;
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            testVb = TestDataUtility.createCommunityAccountContact(Integer.valueOf(ADVISOR_NUMBER));
        }        
    }

    @isTest
    static void getHouseholdAccounts() {        
        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        User testVb = TestDataUtility.getTestVbUser(ADVISOR_NUMBER);
        TestDataUtility.createAccountContactRelation(2,testVb);

        List<Account> personAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :recTypeId];
        LC_SetPrimaryHousehold.ACRWrapper acrwr = LC_SetPrimaryHousehold.getHouseholdAccounts(personAccounts[0].Id);
        List<LC_SetPrimaryHousehold.ACRS> records = acrwr.records;

        System.assertEquals(!records.isEmpty(),true, 'No records found!');

        String objType = 'AccountContactRelation';
        String op = 'update';
        String data = '{"Id":"' + records[0].Id + '","FinServ__PrimaryGroup__c":true}';
        LC_SetPrimaryHousehold.manageRecords(data, objType, op);

        List<AccountContactRelation> rc = [SELECT Id, AccountId, FinServ__PrimaryGroup__c FROM AccountContactRelation WHERE Id = :records[0].Id];
        System.assertEquals(rc[0].FinServ__PrimaryGroup__c, true, 'Invalid Primary Group update!');
    }

    @isTest 
    static void manageRecordsTest() {
        String objType = 'Account';
        String op = 'insert';        
        User testVb = TestDataUtility.getTestVbUser(ADVISOR_NUMBER);
        TestDataUtility.createAccountContactRelation(2,testVb);

        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdHousehold();
        String data = '{"RecordTypeId":"' + recTypeId + '","Name":"JL TEST ACC"}';

        LC_SetPrimaryHousehold.manageRecords(data, objType, op);
        List<Account> tmpaccs = [SELECT Id, Name from Account WHERE Name = 'JL TEST ACC' limit 1];
        System.assertEquals(!tmpaccs.isEmpty(), true, 'No accounts inserted!');
        
        List<AccountContactRelation> acrs = [SELECT Id, AccountId, FinServ__PrimaryGroup__c FROM AccountContactRelation];
        objType = 'AccountContactRelation';
        op = 'update';
        data = '{"Id":"' + acrs[0].Id + '","FinServ__PrimaryGroup__c":true}';
        LC_SetPrimaryHousehold.manageRecords(data, objType, op);
        List<AccountContactRelation> rc = [SELECT Id, AccountId, FinServ__PrimaryGroup__c FROM AccountContactRelation WHERE Id = :acrs[0].Id];
        System.assertEquals(rc[0].FinServ__PrimaryGroup__c, true, 'Invalid Primary Group update!');
        System.debug('rc:' + rc);

        List<Account> accs = [SELECT Id FROM Account];
        Integer totals = accs.size();
        System.debug('totals:' + totals);

        objType = 'List<Account>';
        op = 'delete';
        data = '[{"Id":"' + tmpaccs[0].Id + '"}]';
        LC_SetPrimaryHousehold.manageRecords(data, objType, op);
        accs = [SELECT Id FROM Account];
        System.assertEquals(accs.size() < totals, true, 'Invalid AccountC deletion!');
    }

    @isTest 
    static void manageRecordsErrorTest() {
        String objType = 'List<Account>';
        String op = 'insert';
                
        String data = '[{"Name":"Name","RecordTypeId":"1234"}]';

        try {
            LC_SetPrimaryHousehold.manageRecords(data, objType, op);
            System.assertEquals(false, true, 'No exception thrown');
        }
        catch (Exception ex) {
        } 
    }
}