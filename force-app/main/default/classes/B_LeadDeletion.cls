/**
* @author Cloud Consulting Group
* @date 2023
*
* @group Batch, Scheduleable
*
* @description should run every day and delete all leads with deadline (x days)
*/

global class B_LeadDeletion implements Database.Batchable<SObject>, Schedulable {
    private static String PROCESS = 'Lead Deletion';
    // Scheduleable
    global void execute(SchedulableContext sc){
        Database.executeBatch(new B_LeadDeletion(), Integer.valueOf(Label.Lead_BatchSize));
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        return Database.getQueryLocator('SELECT Id FROM Lead WHERE DeletionDeadlineHelper__c <= 0 LIMIT 10000');
    }

    public void execute(Database.BatchableContext BC, List<sObject> records)
    {
        try {
            Database.deleteResult[] results = Database.delete(records, false);
            DMLHelper dmlHelper = new DMLHelper(results);
            ErrorUtil.processDMLErrors(PROCESS, 'Delete record failed', dmlHelper, true);

        } catch (Exception e) {
            ErrorUtil.logExceptionError(PROCESS, 'Batch Chunk Error Lead Deletion', e);
        }
    }

    public void finish(Database.BatchableContext bc){
        CCG_Log.create(process, 'LeadDeletion is finished', '', 'Batch Finished');
        CCG_Log.send();
    }
}