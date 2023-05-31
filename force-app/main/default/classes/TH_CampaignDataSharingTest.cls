@IsTest
public class TH_CampaignDataSharingTest {
   
    @TestSetup
    static void setupTestData(){               
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(1);
        }
    }

    @isTest
    static void handleCampaign(){

        List<Campaign> l_camp = TestDataUtility.createCampaign(3);
        l_camp[0].RequiredBusinessLicenses__c = '34i';
        l_camp[0].AvailabilityForDistributionCompany__c = '4400003';

        l_camp[1].RequiredBusinessLicenses__c = '34i';
        l_camp[1].AvailabilityForDistributionCompany__c = '4400001';

        l_camp[2].RequiredBusinessLicenses__c = '';
        l_camp[2].AvailabilityForDistributionCompany__c = '4400001';

        Test.startTest();
        // insert campaign process -> first campaign no match and for the second campaign was created the sharing
        insert l_camp;

        List<CampaignShare> l_campShare1 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
        System.assertEquals(0, l_campShare1.size());

        List<CampaignShare> l_campShare2 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[1].Id];
        System.assertEquals(1, l_campShare2.size());
        
        List<CampaignShare> l_campShare3 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[2].Id];
        System.assertEquals(1, l_campShare3.size());

        // update campaign process -> first campaign matched
        l_camp[0].AvailabilityForDistributionCompany__c = '4400003;4400001';
        update l_camp;
        
        l_campShare1 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
        System.assertEquals(1, l_campShare1.size());

        // update campaign no distributed company-> no sharing for this campaign
        l_camp[0].AvailabilityForDistributionCompany__c = '';
        update l_camp;
        
        l_campShare1 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
        System.assertEquals(0, l_campShare1.size());

        // update campaign no required business license -> vb was set (all user)
        l_camp[0].AvailabilityForDistributionCompany__c = '4400001';
        l_camp[0].RequiredBusinessLicenses__c = '';
        update l_camp;
        
        l_campShare1 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
        System.assertEquals(1, l_campShare1.size());

        Test.stopTest();
    }

    @isTest
    static void handleBusinessLicense(){

        List<Campaign> l_camp = TestDataUtility.createCampaign(2);

        l_camp[0].RequiredBusinessLicenses__c = '34d;34i';
        l_camp[0].AvailabilityForDistributionCompany__c = '4400001;4400003';
        
        l_camp[1].RequiredBusinessLicenses__c = '';
        l_camp[1].AvailabilityForDistributionCompany__c = '4400001';
        insert l_camp;

        List<Contact> l_con = [SELECT Id FROM Contact WHERE DistributionCompany__c = '4400001'];

        Test.startTest();

        BusinessLicense busLicense = new BusinessLicense(LicenseClass = '34d', 
                                                            Status = 'Verified',
                                                            ContactId = l_con[0].Id,
                                                            Name = '34d'
        );
        insert busLicense;       

        List<CampaignShare> l_campShare1 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
        System.assertEquals(1, l_campShare1.size());

        
        List<CampaignShare> l_campShare2 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[1].Id];
        System.assertEquals(1, l_campShare2.size());

        busLicense.Status = 'Inactive';
        update busLicense;
       
        l_campShare1 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
        System.assertEquals(0, l_campShare1.size());

        List<BusinessLicense> l_businessLicense = [SELECT Id FROM BusinessLicense WHERE ContactId = :l_con[0].Id];
        delete l_businessLicense;
        
        l_campShare2 = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[1].Id];
        System.assertEquals(1, l_campShare2.size());
        Test.stopTest();
    }

    @isTest
    static void handleContact(){    
        Test.startTest();

        List<User> users = [SELECT Id
                            FROM User
                            WHERE Alias = 'MRDIL'];
        System.runAs(users[0]) {

            List<Campaign> l_camp = TestDataUtility.createCampaign(1);

            l_camp[0].RequiredBusinessLicenses__c = '34i';
            l_camp[0].AvailabilityForDistributionCompany__c = '4400003';
            insert l_camp;
    
            List<CampaignShare> l_campShare = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
            System.assertEquals(0, l_campShare.size());      

            List<Contact> l_con = [SELECT Id FROM Contact WHERE DistributionCompany__c = '4400001'];
            l_con[0].DistributionCompany__c = '4400003';
            update l_con[0];

             l_campShare = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
            System.assertEquals(1, l_campShare.size());
        
            l_con[0].DistributionCompany__c = '';
            update l_con[0];

            l_campShare = [SELECT Id FROM CampaignShare WHERE CampaignId = :l_camp[0].Id];
            System.assertEquals(0, l_campShare.size());
        }
        
        Test.stopTest();
    }
}