public class HandleCampaignController {
    public string query{get; set;}
    public string campId{get; set;}
    public List<Campaign> campaignList{get; set;}
    public List<Integer> count{get; set;}
    
    /* To determine the records to perform the bulk action on, extract the SAQL query */
    public PageReference init() {
        query = ApexPages.currentPage().getParameters().get('query');
        campaignList = new List<Campaign>();
        campaignList = [SELECT Id , Name 
                        FROM Campaign ];
        return null;
        
    }
    
    
    @RemoteAction
    public static Boolean  sendCampaignData(List<Id> contactIds, String campId) {  
        Integer flexQueueSize = [SELECT COUNT() FROM AsyncApexJob WHERE Status = 'Holding'];
        if (!contactIds.isEmpty()) {
            
            CampaignStagingBatch batch = new CampaignStagingBatch(campId,contactIds);
            Database.executeBatch(batch);
            return true;
        }
        else{
            return false;
        }  
    }
}