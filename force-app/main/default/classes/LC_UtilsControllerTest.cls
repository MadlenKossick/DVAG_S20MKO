@isTest(SeeAllData=false)
public class LC_UtilsControllerTest {
    @isTest 
    static void createLogTest() {
        String process = 'Process';
        String subject = 'Subject'; 
        String recordId = 'id';
        String data = 'data';

        LC_UtilsController.createLog(process, subject, recordId, data);

        List<CCG_LogRecording__c> records = [SELECT Id from CCG_LogRecording__c];
        System.assertEquals(!records.isEmpty(), true, 'No log recording created!');
    }

    @isTest 
    static void createErrorLogTest() {
        String process = 'Process';
        String subject = 'Subject'; 
        String recordId = 'id';
        String errorType = 'Error type';
        String errorMessage = 'Error message';
        String errorStack = 'Error stack';

        LC_UtilsController.createErrorLog(process, subject, recordId, errorType, errorMessage, errorStack);

        List<CCG_LogRecording__c> records = [SELECT Id, ExceptionMessage__c from CCG_LogRecording__c];
        System.assertEquals(!records.isEmpty(), true, 'No error log recording created!');
        System.assertEquals(records.get(0).ExceptionMessage__c, errorMessage, 'Invalid error message!');
    }

    @isTest static void errorTest() {      
        try {
            String process = 'Process';
            String subject = ''; 
            String recordId = 'id';
            String data = 'data';

            LC_UtilsController.createLog(process, subject, recordId, data);
            System.assertEquals(false, true, 'No log exception thrown!');
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.assertEquals(true, true);
        }

        try {
            String process = 'Process';
            String subject = 'Subject'; 
            String recordId = 'id';
            String errorType = 'Error type';
            String errorMessage = '';
            String errorStack = 'Error stack';
    
            LC_UtilsController.createErrorLog(process, subject, recordId, errorType, errorMessage, errorStack);
            System.assertEquals(false, true, 'No error log exception thrown!');
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.assertEquals(true, true);
        }
    }

    @isTest static void getLogSettingTest() { 
        String componentName = 'Test';
        String jsonString = '[{"DeveloperName":"Setting","ComponentName__c":"' + componentName + '","EnableLog__c":true}]';

        setMetadata(componentName, (List<LogRecordingConfiguration__mdt>) JSON.deserialize(jsonString, List<LogRecordingConfiguration__mdt>.class));

        Boolean rc = LC_UtilsController.getLogSetting(componentName);
        System.assertEquals(rc, true, 'Component is not enabled!');
    }

    @isTest static void getLogSettingEmptyTest() { 
        String componentName = 'Test';
        Boolean rc = LC_UtilsController.getLogSetting(componentName);
        System.assertEquals(rc, false, 'Component is enabled!');
    }

    private static void setMetadata(String key, List<sObject> records) {
        LC_UtilsController.metadataByKey.put(key, records);
        System.debug('setMetadata.metadataByKey');
        System.debug(LC_UtilsController.metadataByKey);
    }
}