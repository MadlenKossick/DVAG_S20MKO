@isTest
private class HandleCampaignControllerTest {
   
    @testSetup
    static void createTestData() {
        Campaign cp = new Campaign();
        cp.Name = 'Test Campaign';
        insert cp;

        List<Contact> conlist = new List<Contact>();
        for(Integer i = 0; i < 3; i++) {
            Contact ctc = new Contact();
            ctc.LastName = 'Test' + i;
            ctc.FirstName = 'Contact';
            conlist.add(ctc);
        }
        insert conlist;

          }

    @isTest
    static void testInit() {
        // Test the init method
        HandleCampaignController controller = new HandleCampaignController();
        controller.init();      
        // Assert that the campaignList property is not null and contains at least one Campaign
        System.assertNotEquals(null, controller.campaignList);
        System.assert(controller.campaignList.size() > 0);
    }
    

    @isTest
    static void testSendCampaignData() {

        // Call the sendCampaignData method
        try{
        List<Id> contactIds = new List<Id>();
        Campaign cmp = [SELECT Id, Name FROM Campaign LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 3];
        for(Contact c : contacts) {
            contactIds.add(c.Id);
        }
        Test.startTest();
        Boolean result = HandleCampaignController.sendCampaignData(contactIds, cmp.Id);
        Test.stopTest();

        // Verify that campaign members were added
        List<CampaignMember> campaignMembers = [SELECT Id FROM CampaignMember WHERE CampaignId = :cmp.Id];
        System.assertEquals(3, campaignMembers.size(), 'There should be 3 campaign members');
        System.assertEquals(true, result, 'Result should be true');
        System.debug('the contact Ids are ' + contactIds);
             
       
        } 
        catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
        }
        
    }
        
        
    @isTest
    static void testSendCampaignDataFailure() {
            
       try{
           List<Id> contactIds = new List<Id>();
        Campaign cmp = [SELECT Id, Name FROM Campaign LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 3];
           
        Test.startTest();
        Boolean resultFail = HandleCampaignController.sendCampaignData(contactIds,cmp.Id);
        Test.stopTest();
         //Verify that duplicate  campaign members are not  added
         System.assertEquals(false, resultFail, 'Result should be false');
        }
        
         catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
        }
        
            
            
            
      }
         

}