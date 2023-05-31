/**
* @author Cloud Consulting Group - Patrick Driller
* @date 2022
*
* @group Batch
*
* @description Can be called from the Sharing Cockpit to fill the temporary objects
*/

global class B_InsertSharingCalculations implements Database.Batchable<SObject>, Database.Stateful
{
    String sObjectName = '';

    public B_InsertSharingCalculations(String sObjectName){
        this.sObjectName = sObjectName;
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        String query = '';
        if (sObjectName == 'AgentSharingCalculation__c') {
            if(Test.isRunningTest()){
                query = 'SELECT Id, ExtFinancialAdvisorId__c FROM User WHERE ContactId != NULL AND IsActive = TRUE AND ExtFinancialAdvisorId__c != NULL AND CreatedDate = TODAY ORDER BY Id';
            } else {
                query = 'SELECT Id, ExtFinancialAdvisorId__c FROM User WHERE ContactId != NULL AND IsActive = TRUE AND ExtFinancialAdvisorId__c != NULL ORDER BY Id';
            }
        }
        else if (sObjectName == 'AccountSharingCalculation__c') {
            query = 'SELECT Id FROM Account ORDER BY Id';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> records)
    {
        if (sObjectName == 'AgentSharingCalculation__c') {
            List<AgentSharingCalculation__c> objsToUpsert = new List<AgentSharingCalculation__c>();
            for (sObject obj : records) {
                String advId = String.valueOf(obj.get('ExtFinancialAdvisorId__c'));
                User usr = new User(ExtFinancialAdvisorId__c = advId);

                objsToUpsert.add(new AgentSharingCalculation__c(
                    Agent__r = usr,
                    UniqueKey__c = advId
                ));
            }
            Database.upsert(objsToUpsert, AgentSharingCalculation__c.Fields.UniqueKey__c, false);
        }
        else if (sObjectName == 'AccountSharingCalculation__c') {
            List<AccountSharingCalculation__c> objsToUpsert = new List<AccountSharingCalculation__c>();
            for (sObject obj : records) {
                objsToUpsert.add(
                    new AccountSharingCalculation__c(
                      Account__c = obj.Id,
                      UniqueKey__c = obj.Id)
                );
            }
            Database.upsert(objsToUpsert, AccountSharingCalculation__c.Fields.UniqueKey__c, false);
        }
    }

    public void finish(Database.BatchableContext bc)
    {
    }
}