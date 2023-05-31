public class CampaignStagingBatch implements Database.Batchable<sObject>{
    public List<Id> contactIds;
    public String campId;
    public CampaignStagingBatch(String campId,List<Id> contactIds){
        this.contactIds = contactIds;
        this.campId = campId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> newContactIds  = new Set<Id>(contactIds);
        String query = 'Select Id From Contact where Id IN :contactIds';
        return  Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> contactList) {
        List<Campaign_Staging__c> campStgList = new List<Campaign_Staging__c>();
        for(Contact con : contactList){
            Campaign_Staging__c campStaging = new Campaign_Staging__c();
            campStaging.Campaign_Id__c = campId;
            campStaging.Contact_Id__c = con.Id;
            campStgList.add(campStaging);            
        }
        List<Database.SaveResult> saveResultList = Database.insert(campStgList,false);
        
    }
    
    public void finish(Database.BatchableContext bc) {
        List<AsyncApexJob> asyncJobs  = [SELECT Id, ApexClass.Name, Status, JobType, TotalJobItems
                                         FROM AsyncApexJob
                                         WHERE ApexClass.Name = 'CampaignStagingBatch'
                                         AND Status != 'Completed' LIMIT 1] ;
        if (asyncJobs.isEmpty()) {
            Database.executeBatch(new CampaignControllerBatch(campId),2000);
        }        
    }
}