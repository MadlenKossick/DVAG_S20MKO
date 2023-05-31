/**
 * @author DVAG / Marc Habjanic, Gökcan Kirci
 * @date 2022
 *
 * @group Test
 *
 * @description Test for TH_IntegrationEvent
 */
@isTest
public class TH_IntegrationEventTest {

    private static final Integer NUMBER_OF_ACCOUNTS = 2;
    private static final Integer NUMBER_OF_INSURANCEPOLICY = 2;
    private static final Integer NUMBER_OF_FINANCIALACCOUNTS = 2;
    private static final String PHONE_NUMBER = '+49 123456789';
    private static final String FINANCIAL_ADVISOR_NUMBER = '4711';

    public static List<IntegrationEvent__e>  testEvents;

    @TestSetup
    static void testSetup(){
        // create TestVB for ToastEvent
        testEvents = new List<IntegrationEvent__e>();
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(Integer.valueOf(FINANCIAL_ADVISOR_NUMBER));
        }
    } 

    @isTest
    static void testInsertAccount(){
        Test.startTest();
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Insert') {
                ExternalIds externalIds = (ExternalIds)JSON.deserialize(event.ExternalIds__c.replaceAll('__c','').replace('\'', '"'), ExternalIds.class);
                Boolean hasCustomerHostId = false; 
                Boolean hasCustomerOkiId = false; 
                Boolean hasCustomerNumber = false;
                for(Account account : accountMap.values()) {             
                    system.debug('account.ExtCustomerIdHost__c '+account.ExtCustomerIdHost__c );
                    if (account.ExtCustomerIdHost__c == externalIds.ExtCustomerIdHost) {
                        hasCustomerHostId = true;
                    }
                    if (account.ExtCustomerIdOki__c == externalIds.ExtCustomerIdOki) {
                        hasCustomerOkiId = true;
                    }
                    if (account.ExtCustomerNumber__c == externalIds.ExtCustomerNumber) {
                        hasCustomerNumber = true;
                    }
                }
                System.assert(hasCustomerHostId);
                System.assert(hasCustomerOkiId);
                System.assert(hasCustomerNumber);
                System.assertEquals('Account', event.SObject__c); 
                System.assert(accountMap.containsKey(event.RecordId__c));
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }

    @isTest
    static void testUpdateAccount() {
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
    
        for(Account account : accountMap.values()) {
            account.Phone = PHONE_NUMBER;
        }
        Test.startTest();
        update accountMap.values();
        Test.stopTest();
    
        Integer amountOfUpdateEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Update') {
                ExternalIds externalIds = (ExternalIds)JSON.deserialize(event.ExternalIds__c.replaceAll('__c','').replace('\'', '"'), ExternalIds.class);
                Boolean hasCustomerHostId = false; 
                Boolean hasCustomerOkiId = false; 
                Boolean hasCustomerNumber = false; 
                for(Account account : accountMap.values()) {             
                    if (account.ExtCustomerIdHost__c == externalIds.ExtCustomerIdHost) {
                        hasCustomerHostId = true;
                    }
                    if (account.ExtCustomerIdOki__c == externalIds.ExtCustomerIdOki) {
                        hasCustomerOkiId = true;
                    }
                    if (account.ExtCustomerNumber__c == externalIds.ExtCustomerNumber) {
                        hasCustomerNumber = true;
                    }
                }
                System.assert(hasCustomerHostId);
                System.assert(hasCustomerOkiId);
                System.assert(hasCustomerNumber);
                System.assertEquals('Account', event.SObject__c); 
                System.assert(accountMap.containsKey(event.RecordId__c));

                ChangedFields changedFields = (ChangedFields) JSON.deserialize(event.ChangedFields__c.replace('\'', '"'), ChangedFields.class);
                System.assertEquals(PHONE_NUMBER, changedFields.Phone);
                amountOfUpdateEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfUpdateEvents);
    }

    @isTest
    static void testDeleteAccount() {
        List<Account> accounts = TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS);
        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
        Test.startTest();
        delete accounts;
        Test.stopTest();

        Integer amountOfDeleteEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Delete') {
                System.assert(accountMap.containsKey(event.RecordId__c));
                amountOfDeleteEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfDeleteEvents);
    }

    //########### Start Test events for the Account - Houshold ############
    @isTest
    static void testInsertAccountHousehold(){
        Test.startTest();
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createHouseholdAccount(NUMBER_OF_ACCOUNTS));
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Insert') {
                System.assertEquals('Account', event.SObject__c); 
                System.assert(accountMap.containsKey(event.RecordId__c));
                System.assertEquals(RecordTypeHelper.getAccRecordTypeIdHousehold(), event.RecordTypeId__c);
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }

    @isTest
    static void testUpdateAccountHousehold(){
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createHouseholdAccount(NUMBER_OF_ACCOUNTS));
        
        for(Account account : accountMap.values()) {
            account.Name = account.Name + 'Test';
        }
        Test.startTest();
        update accountMap.values();
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Update') {
                System.assertEquals('Account', event.SObject__c); 
                System.assert(accountMap.containsKey(event.RecordId__c));
                System.assertEquals(RecordTypeHelper.getAccRecordTypeIdHousehold(), event.RecordTypeId__c);
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }

    @isTest
    static void testDeleteAccountHousehold(){
        List<Account> accounts = TestDataUtility.createHouseholdAccount(NUMBER_OF_ACCOUNTS);
        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
        Test.startTest();
        delete accounts;
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Delete') {
                System.assertEquals('Account', event.SObject__c); 
                System.assert(accountMap.containsKey(event.RecordId__c));
                System.assertEquals(RecordTypeHelper.getAccRecordTypeIdHousehold(), event.RecordTypeId__c);
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }
    //########### End Test events for the Account - Houshold ############

    //########### Start Test events for the CustomerAdvisorRelationship ############
    @isTest
    static void testInsertCustomerAdvisorRelationship(){
        User vbUser = TestDataUtility.getTestVbUser(FINANCIAL_ADVISOR_NUMBER);
        
        Test.startTest();        
        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
        
        Map<Id, CustomerAdvisorRelationship__c> relMap = new Map<Id, CustomerAdvisorRelationship__c>(TestDataUtility.createCustomerAdvisorRelationship(accountMap.values(), vbUser));
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Insert' && event.SObject__c != 'Account') {
                System.assertEquals('CustomerAdvisorRelationship__c', event.SObject__c); 
                System.assert(relMap.containsKey(event.RecordId__c));
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }

    @isTest
    static void testUpdateCustomerAdvisorRelationship(){
        User vbUser = TestDataUtility.getTestVbUser(FINANCIAL_ADVISOR_NUMBER);

        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
        Map<Id, CustomerAdvisorRelationship__c> relMap = new Map<Id, CustomerAdvisorRelationship__c>(TestDataUtility.createCustomerAdvisorRelationship(accountMap.values(), vbUser));
        
        for(CustomerAdvisorRelationship__c rel : relMap.values()) {
            rel.InformalSalutation__c = true;
        }

        Test.startTest();
        update relMap.values();
        Test.stopTest();


        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Update' && event.SObject__c != 'Account') {
                System.assertEquals('CustomerAdvisorRelationship__c', event.SObject__c); 
                System.assert(relMap.containsKey(event.RecordId__c));
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }

    @isTest
    static void testDeleteCustomerAdvisorRelationship(){
        User vbUser = TestDataUtility.getTestVbUser(FINANCIAL_ADVISOR_NUMBER);

        Map<Id, Account> accountMap = new Map<Id, Account>(TestDataUtility.createPersonAccount(NUMBER_OF_ACCOUNTS));
        Map<Id, CustomerAdvisorRelationship__c> relMap = new Map<Id, CustomerAdvisorRelationship__c>(TestDataUtility.createCustomerAdvisorRelationship(accountMap.values(), vbUser));
        
        Test.startTest();
        delete relMap.values();
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Delete' && event.SObject__c != 'Account') {
                System.assertEquals('CustomerAdvisorRelationship__c', event.SObject__c); 
                System.assert(relMap.containsKey(event.RecordId__c));
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }
    //########### End Test events for the CustomerAdvisorRelationship ############

    //########### Start Test update events for the Insurance Policy ############
    @isTest
    static void testUpdateInsurancePolicy() {
        Account ownerAccount = TestDataUtility.createPersonAccount(1).get(0);
        
        List<InsurancePolicy> insPols = new List<InsurancePolicy>();
        insPols.add(TestDataUtility.createInsurancePolicy(ownerAccount,'120',false));
        insPols.add(TestDataUtility.createInsurancePolicy(ownerAccount,'121',false));        
        
        Map<Id, InsurancePolicy> insPolMap = new Map<Id, InsurancePolicy>(insPols);
        
        Integer i=0;
        for (InsurancePolicy insPol: insPolMap.values()) {
            insPol.Name = insPol.Name + 'i';
            i++;
        }
               
        Test.startTest();
        update insPolMap.values();
        Test.stopTest();

        Integer amountOfUpdateEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Update') {              
                System.assertEquals('InsurancePolicy', event.SObject__c); 
                amountOfUpdateEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_INSURANCEPOLICY, amountOfUpdateEvents);
    }
     //########### End Test update events for the Insurance Policy ############

     //########### Start Test delete events for the Insurance Policy ############
    @isTest
    static void testDeleteInsurancePolicy() {        
        Account ownerAccount = TestDataUtility.createPersonAccount(1).get(0);
        List<InsurancePolicy> insPols = new List<InsurancePolicy>();
        insPols.add(TestDataUtility.createInsurancePolicy(ownerAccount,'520',true));
        insPols.add(TestDataUtility.createInsurancePolicy(ownerAccount,'521',true));        
        Map<Id, InsurancePolicy> insPolMap = new Map<Id, InsurancePolicy>(insPols);

        Test.startTest();
        delete insPols;
        Test.stopTest();

        Integer amountOfDeleteEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Delete') {
                System.assert(insPolMap.containsKey(event.RecordId__c));
                amountOfDeleteEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_INSURANCEPOLICY, amountOfDeleteEvents);
    }
    //########### End Test delete events for the Insurance Policy ############
    
    //########### Start Test update events for the Financial Account ############
    @isTest
    static void testUpdateFinancialAccount() {
        Map<Id, FinServ__FinancialAccount__c> finAccsMap = new Map<Id, FinServ__FinancialAccount__c>(TestDataUtility.createFinancialAccounts(NUMBER_OF_FINANCIALACCOUNTS,false));
         
        for(FinServ__FinancialAccount__c finAcc : finAccsMap.values()) {
            finAcc.FinServ__RenewalDate__c = System.today() + 3;
        }   
        Test.startTest();
        update finAccsMap.values();
        Test.stopTest();

        Integer amountOfUpdateEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Update') {
                System.assertEquals('FinServ__FinancialAccount__c', event.SObject__c); 
                amountOfUpdateEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_INSURANCEPOLICY, amountOfUpdateEvents);
     }
    //########### End Test update events for the Financial Account ############
 
    //########### Start Test delete events for the Financial Account ############
    @isTest
    static void testDeleteFinancialAccount() {
        List<FinServ__FinancialAccount__c> finAccs = TestDataUtility.createFinancialAccounts(NUMBER_OF_FINANCIALACCOUNTS,true);
        Map<Id, FinServ__FinancialAccount__c> finAccsMap = new Map<Id, FinServ__FinancialAccount__c>(finAccs);

        Test.startTest();
        delete finAccs;
        Test.stopTest();

        Integer amountOfDeleteEvents = 0;
        for (IntegrationEvent__e event : testEvents) {
            if (event.Context__c=='Delete') {
                System.assert(finAccsMap.containsKey(event.RecordId__c));
                amountOfDeleteEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_FINANCIALACCOUNTS, amountOfDeleteEvents);
     }
     //########### End Test delete events for the Financial Account ############
    
     //########### Start Test events for the Account Contact Relationship ############
    @isTest
    static void testInsertAccountContactRelation() {
        User vbUser =  TestDataUtility.getTestVbUser(FINANCIAL_ADVISOR_NUMBER);

        Test.startTest();
        Map<Id, AccountContactRelation> accConRelMap = new Map<Id, AccountContactRelation>(TestDataUtility.createAccountContactRelation(NUMBER_OF_ACCOUNTS, vbUser));
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Insert' && event.SObject__c != 'Account') {
                System.assertEquals('AccountContactRelation', event.SObject__c); 
                System.assert(accConRelMap.containsKey(event.RecordId__c));
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfInsertEvents);
    }

    @isTest
    static void testUpdateAccountContactRelation() {
        User vbUser =  TestDataUtility.getTestVbUser(FINANCIAL_ADVISOR_NUMBER);

        Map<Id, AccountContactRelation> accConRelMap = new Map<Id, AccountContactRelation>(TestDataUtility.createAccountContactRelation(NUMBER_OF_ACCOUNTS, vbUser));        
        for(AccountContactRelation accConRel : accConRelMap.values()) {
            accConRel.FinServ__PrimaryGroup__c = true;            
        }

        Test.startTest();
        update accConRelMap.values();
        Test.stopTest();        

        Integer amountOfUpdateEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Update' && event.SObject__c != 'Account') {
                System.assertEquals('AccountContactRelation', event.SObject__c); 
                System.assert(accConRelMap.containsKey(event.RecordId__c));
                amountOfUpdateEvents++;
            }
        }

        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfUpdateEvents);
    }

    @isTest
    static void testDeleteAccountContactRelation() {
        User vbUser =  TestDataUtility.getTestVbUser(FINANCIAL_ADVISOR_NUMBER);
        
        Map<Id, AccountContactRelation> accConRelMap = new Map<Id, AccountContactRelation>(TestDataUtility.createAccountContactRelation(NUMBER_OF_ACCOUNTS, vbUser));

        Test.startTest();
        delete accConRelMap.values();
        Test.stopTest();

        Integer amountOfDeleteEvents = 0;
        for (IntegrationEvent__e event : testEvents) {
            if (event.Context__c=='Delete') {
                System.assert(accConRelMap.containsKey(event.RecordId__c));
                amountOfDeleteEvents++;
            }
        }
        System.assertEquals(NUMBER_OF_ACCOUNTS, amountOfDeleteEvents);
    }
    //########### End Test delete events for the Financial Account ############
    
    @isTest
    static void testInsertCustomerProperty(){
        Integer propertyAmountToBeCreated = 2;
        Test.startTest();
        List<CustomerProperty> cstProps = TestDataUtility.createCustomerProperty(propertyAmountToBeCreated);
        Map<Id, CustomerProperty> propertyMap = new Map<Id, CustomerProperty>(cstProps);
        Test.stopTest();

        Integer amountOfInsertEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c == 'Insert' && event.SObject__c == 'CustomerProperty') {                
                System.assert(propertyMap.containsKey(event.RecordId__c));
                amountOfInsertEvents++;
            }
        }
        System.assertEquals(propertyAmountToBeCreated, amountOfInsertEvents);
    }
    
    @isTest
    static void testUpdateCustomerProperty(){
        Integer propertyAmountToBeCreated = 2;
        String updatePropertyName = 'DefaultModel';
        Map<Id, CustomerProperty> propertyMap = new Map<Id, CustomerProperty>(TestDataUtility.createCustomerProperty(propertyAmountToBeCreated));
        for(CustomerProperty property : propertyMap.values()) {
            property.ModelName = updatePropertyName;
        }   
        Test.startTest();
        update propertyMap.values();
        Test.stopTest();

        Integer amountOfUpdateEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c == 'Update' && event.SObject__c == 'CustomerProperty') {                
                System.assert(propertyMap.containsKey(event.RecordId__c));
                ChangedCustomerPropertyFields changedCustomerPropertyFields= (ChangedCustomerPropertyFields)JSON.deserialize(event.ChangedFields__c.replaceAll('__c','').replace('\'', '"'), ChangedCustomerPropertyFields.class);
                System.assertEquals(updatePropertyName, changedCustomerPropertyFields.ModelName);
                amountOfUpdateEvents++;
            }
        }
        System.assertEquals(propertyAmountToBeCreated, amountOfUpdateEvents);
    }
    
    @isTest
    static void testDeleteCustomerProperty() {
        Integer propertyAmountToBeCreated = 2;
        List<CustomerProperty> customerProperties = TestDataUtility.createCustomerProperty(propertyAmountToBeCreated);
        Map<Id, CustomerProperty> propertyMap = new Map<Id, CustomerProperty>(customerProperties);
        Test.startTest();
        delete customerProperties;
        Test.stopTest();

        Integer amountOfDeleteEvents = 0;
        for(IntegrationEvent__e event : testEvents) {
            if(event.Context__c=='Delete' && event.SObject__c == 'CustomerProperty') {
                System.assert(propertyMap.containsKey(event.RecordId__c));
                amountOfDeleteEvents++;
            }
        }
        System.assertEquals(propertyAmountToBeCreated, amountOfDeleteEvents);
    }

    @isTest
    static void testInsertIntegrationEvent() {
        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        Database.SaveResult sr = EventBus.publish(
            new IntegrationEvent__e(
                RecordId__c = recTypeId,
                Context__c = 'Insert',
                SObject__c = 'Account'
            )
        );
        System.assertEquals(true, sr.isSuccess());
    }

    @isTest
    static void testUpdateIntegrationEvent() {
        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        Database.SaveResult sr = EventBus.publish(
            new IntegrationEvent__e(
                RecordId__c = recTypeId,
                Context__c = 'Update',
                SObject__c = 'Account',
                ChangedFields__c = 'FieldChanges'
            )
        );
        System.assertEquals(true, sr.isSuccess());
    }

    @isTest
    static void testDeleteIntegrationEvent() {
        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        Database.SaveResult sr = EventBus.publish(
            new IntegrationEvent__e(
                RecordId__c = recTypeId,
                Context__c = 'Delete',
                SObject__c = 'Account'
            )
        );
        System.assertEquals(true, sr.isSuccess());
    }

    class ChangedFields{
        public String Phone {get;set;}
    }

    class ExternalIds {
        public String FinancialAdvisorId {get;set;}
        public String ExtCustomerIdHost  {get;set;}
        public String ExtCustomerIdOki   {get;set;}
        public String ExtCustomerNumber  {get;set;}
    }
    
    class ChangedCustomerPropertyFields {
        public String ModelName {get;set;}
    }
}