public with sharing class TH_MarketingSynchronisation {
    
    public static void setSynMcOnInsert(List<Account> newAccounts) {
        for (Account newAccount : newAccounts) {
            if (newAccount.FinServ__MarketingOptOut__pc == false 
                && newAccount.FinServ__Age__pc >= 18 
                && newAccount.FinServ__Status__c !='Legacy' 
                && newAccount.HasOptedOutProcessing__pc  == false
            ) {
                newAccount.MarketingCloudSync__pc = true;
            }
        }
    }

    public static void setSynMcOnUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
           
            if (newAccount.FinServ__MarketingOptOut__pc != oldAccount.FinServ__MarketingOptOut__pc 
                || newAccount.FinServ__Age__pc != oldAccount.FinServ__Age__pc 
                || newAccount.FinServ__Status__c != oldAccount.FinServ__Status__c
                || newAccount.HasOptedOutProcessing__pc != oldAccount.HasOptedOutProcessing__pc
            ) {                    
                if (newAccount.FinServ__MarketingOptOut__pc == false 
                    && newAccount.FinServ__Age__pc >= 18 
                    && newAccount.FinServ__Status__c != 'Legacy' 
                    && newAccount.HasOptedOutProcessing__pc == false
                    && newAccount.MarketingCloudSync__pc != true
                ) {
                    newAccount.MarketingCloudSync__pc = true;
                }else if (
                    (newAccount.FinServ__MarketingOptOut__pc == true 
                        || newAccount.FinServ__Age__pc < 18 
                        || newAccount.FinServ__Status__c == 'Legacy'
                        || newAccount.HasOptedOutProcessing__pc == true)
                    && newAccount.MarketingCloudSync__pc == true) {
                    newAccount.MarketingCloudSync__pc = false;
                }
            }
        }
    }

    public static void updateSyncMConCampainMember(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newAccounts) {
            Account oldAccount = oldAccountsMap.get(acc.Id);
            if (acc.MarketingCloudSync__pc != oldAccount.MarketingCloudSync__pc) {
                accountIds.add(acc.Id);
            }
        }
        if (!accountIds.isEmpty()) {
            List<CampaignMember> campaignMembers = [SELECT Id FROM CampaignMember WHERE AccountId IN :accountIds];
            Map<Id,CampaignMember> campaignMembersMap = new Map<Id,CampaignMember>(campaignMembers);
            Map<Id,Boolean> accountSyncMcMap = new Map<Id,Boolean>();
            for (Account acc : newAccounts) {
                if(accountIds.contains(acc.Id)){
                    accountSyncMcMap.put(acc.Id, acc.MarketingCloudSync__pc);
                }
            }
            for (Id accountId : accountIds) {
                if(campaignMembersMap.containsKey(accountId)){
                    campaignMembersMap.get(accountId).MarketingCloudSync__c = accountSyncMcMap.get(accountId);
                }
            }
            update campaignMembersMap.values();
        }
    }

    public static void updateSyncMConInsertOfCampaignMember(List<CampaignMember> newCampaignMembers) {
        Set<Id> contactIds = new Set<Id>();
        for (CampaignMember cm : newCampaignMembers) {
            contactIds.add(cm.ContactId);
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, MarketingCloudSync__c FROM Contact WHERE Id IN :contactIds]);
        for (CampaignMember cm : newCampaignMembers) {
            if (contacts.containsKey(cm.ContactId)) {
                cm.MarketingCloudSync__c = contacts.get(cm.ContactId).MarketingCloudSync__c;
            }
        }
    }
                
}