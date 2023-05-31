public class CampaignControllerBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    public String campId;
    private Integer succesfulRecords =0;
    private Integer failureRecords =0;
    public CampaignControllerBatch(String campId){
        this.campId = campId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        String query = 'Select Id,Campaign_Id__c,Contact_Id__c,TargetObjectId__c From Campaign_Staging__c where Campaign_Id__c =:campId';
        return  Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Campaign_Staging__c> stageList) {
        Map<Id,CampaignMember> campaignMemberMap = new Map<Id,CampaignMember>();
        List<Campaign_Staging__c> csDeleteList = new  List<Campaign_Staging__c>();
        for(Campaign_Staging__c cs : stageList){
            campaignMemberMap.put(cs.Id,new CampaignMember(ContactId = cs.Contact_Id__c,CampaignId = cs.Campaign_Id__c ));
        }
        Database.SaveResult[] srList =  Database.insert(campaignMemberMap.values(),false);
        for(Campaign_Staging__c cs : stageList){       
            if(campaignMemberMap.get(cs.Id).Id != null){             
                succesfulRecords +=1;
                csDeleteList.add(new Campaign_Staging__c(Id=cs.Id));
            }else{            
                failureRecords +=1;
            }
        }
        delete csDeleteList;
    }
    
    public void finish(Database.BatchableContext bc) {
        String runningUserId = UserInfo.getUserId();
        
        // Create a new email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Set the recipients to the running user
        List<String> toAddresses = new List<String>();
        toAddresses.add(runningUserId);
        email.setToAddresses(toAddresses);
        
        // Set the email body and subject
        email.setSubject('Der Batch-Prozess für die Kampagnenselektion wurde erfolgreich beendet.');
        email.setPlainTextBody(succesfulRecords +' Kontakte wurden erfolgreich hinzugefügt, ' + failureRecords +' Kontakte konnten nicht hinzugefügt werden. Ein Systemadministrator kann über ein Skript versuchen, fehlgeschlagene Kontakte nachträglich hinzuzufügen. ' );
        
        // Send the email
        Messaging.sendEmail(new List<Messaging.Email>{email});
    }
    
}