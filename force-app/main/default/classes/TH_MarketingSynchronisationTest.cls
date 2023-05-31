@isTest
public class TH_MarketingSynchronisationTest {

   @TestSetup
    static void makeData(){
        User integrationUser = TestDataUtility.getIntegrationTestUser();
        System.runAs(integrationUser) {
            List<Account> accounts = TestDataUtility.createPersonAccount(2);
        
            List<Individual> individuals = TestDataUtility.createIndividual(2);
            List<ContactPointTypeConsent> cptcList = new List<ContactPointTypeConsent>();

            cptcList.add(
            new ContactPointTypeConsent(
                Name = 'Consent Email',
                ContactPointType = 'Email',
                PartyId = individuals[0].Id,
                PrivacyConsentStatus = 'OptIn',
                EffectiveFrom = System.now(),
                CaptureContactPointType = 'Web',
                CaptureSource = 'Testclass',
                CaptureDate = System.now()
            )
            );

            insert cptcList;
            accounts[0].PersonIndividualId = individuals[0].Id;
            accounts[0].FinServ__MarketingOptOut__pc = false;
            accounts[0].HasOptedOutProcessing__pc = false;
            accounts[1].FinServ__MarketingOptOut__pc = false;
            accounts[1].HasOptedOutProcessing__pc = false;
            update accounts;
        }
    }  

    @isTest
    public static void testSyncMConAccountBeforeUpdate() {
        //Date dt1 =  Date.newInstance(2002, 12, 27);
        User integrationUser = TestDataUtility.getIntegrationTestUser();
        System.runas(integrationUser) {
            List<Account> accounts = [SELECT FinServ__MarketingOptOut__pc, HasOptedOutProcessing__pc, FinServ__Age__pc, FinServ__Status__c, MarketingCloudSync__pc, PersonIndividualId FROM Account];
            List<Individual> individuals = [SELECT Id FROM Individual ];
            
            Contact cont = [SELECT Birthdate FROM Contact WHERE AccountId = :accounts[0].Id];
            
            cont.Birthdate = Date.newInstance(2002, 12, 27);
            update cont;

            // Case 1: Status != Legacy && MarketingOptOut = false && Age >= 18  && HasOptedOutProcessing__pc = false
            System.assertEquals(true, [SELECT  MarketingCloudSync__pc FROM Account  WHERE Id = :accounts[0].Id].MarketingCloudSync__pc);
            
            // Case 2: Status != Legacy && MarketingOptOut = false && Age < 18 && HasOptedOutProcessing__pc = false
            Account acc1 = [SELECT PersonIndividualId FROM ACCOUNT WHERE Id = :accounts[1].Id];
            acc1.PersonIndividualId = individuals[0].Id;
            update acc1;
            Contact cont1 = [SELECT Birthdate FROM Contact WHERE AccountId = :acc1.Id];
            cont1.Birthdate = Date.newInstance(2022, 12, 27);
            update cont1;
            System.assertEquals(false, [SELECT  MarketingCloudSync__pc FROM Account  WHERE Id = :accounts[1].Id].MarketingCloudSync__pc);
            
            // Case 3: Status != Legacy && MarketingOptOut = true && Age >= 18 && HasOptedOutProcessing__pc = true
            Contact cont2 = [SELECT Birthdate FROM Contact WHERE AccountId = :acc1.Id];
            cont2.Birthdate = Date.newInstance(2022, 12, 27);
            update cont2;
            acc1.PersonIndividualId = individuals[1].Id;
            update acc1;

            System.assertEquals(false, [SELECT  MarketingCloudSync__pc FROM Account  WHERE Id = :accounts[1].Id].MarketingCloudSync__pc);
        }        
    }

    @isTest
    public static void testUpdateSyncMConInsertOfCampaignMember() {
        User integrationUser = TestDataUtility.getIntegrationTestUser();
        System.runas(integrationUser) {
            List<Account> accounts = [SELECT FinServ__MarketingOptOut__pc, HasOptedOutProcessing__pc, FinServ__Age__pc, FinServ__Status__c, MarketingCloudSync__pc FROM Account];
            accounts[0].MarketingCloudSync__pc = true;
            update accounts;

            List<Contact> contactList = [SELECT Id, MarketingCloudSync__c FROM Contact WHERE AccountId in :accounts];

            System.debug('Contact   list: ' + contactList);

            List<Campaign> l_camp = TestDataUtility.createCampaign(1); 
            insert l_camp;
            // Create test campaign members
            CampaignMember cm1 = new CampaignMember(CampaignId = l_camp[0].Id, ContactId = contactList[0].Id);
            CampaignMember cm2 = new CampaignMember(CampaignId = l_camp[0].Id, ContactId = contactList[1].Id);
            List<CampaignMember> newCampaignMembers = new List<CampaignMember> {cm1, cm2};

            insert newCampaignMembers;

            List<CampaignMember> cms = [SELECT MarketingCloudSync__c from CampaignMember];
            System.debug('CampaignMember List: ' +  cms);

            // Verify that the SyncMC__c field on the campaign members is updated correctly
            System.assertEquals(true, cms[0].MarketingCloudSync__c);
            System.assertEquals(false, cms[1].MarketingCloudSync__c);
        }
    }
}