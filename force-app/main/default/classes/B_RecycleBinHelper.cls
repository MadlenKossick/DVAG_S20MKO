/**
* @author Cloud Consulting Group
* @date 2023
*
* @group Batch, Scheduleable
*
* @description should run asychron to clean the recycleBin
*/

global class B_RecycleBinHelper implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts
{
    private static String PROCESS = 'RecycleBin cleaning';
    private String objectDel;

    public B_RecycleBinHelper(String objectDel) {
        this.objectDel = objectDel;
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {	
        String query = 'SELECT Id, Name FROM ' + this.objectDel + ' WHERE isDeleted = true ALL ROWS';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> records)
    {
        String subject;

        try {
            subject = 'Process Error ' + this.objectDel;
            Database.emptyRecycleBin(records);
        } catch (Exception e) {
            ErrorUtil.logExceptionErrorAPI(process, subject, e);
        }
    }

    public void finish(Database.BatchableContext BC){}
}