/**
 * @author Jochen Litzinger, Cloud Consulting Group
 * @date 2023
 *
 * @group Utils
 *
 * @description controller for the LWC ccgUtils
 *
 */

public without sharing class LC_UtilsController {
    @testVisible 
    static private Map<String, List<sObject>> metadataByKey = new Map<String, List<sObject>>();

    @AuraEnabled(cacheable=false)
    public static Boolean getLogSetting(String componentName) {
        if (String.isBlank(componentName)) throw new AuraHandledException('Invalid component Name!');
                
        if (!metadataByKey.containsKey(componentName)) {
            // get settings
            List<LogRecordingConfiguration__mdt> logConfigs = [SELECT EnableLog__c from LogRecordingConfiguration__mdt 
                                                                WHERE ComponentName__c = :componentName];
            metadataByKey.put(componentName, logConfigs);
        }        
        List<LogRecordingConfiguration__mdt> configs = metadataByKey.get(componentName);  
                
        if(!configs.isEmpty()) {
            return configs.get(0).EnableLog__c;
        }

        return false;
    }

    @AuraEnabled
    public static void createLog(String process, String subject, String recordId, String data) {
        if (String.isBlank(process) || String.isBlank(subject)) {
            throw new AuraHandledException('Invalid process or subject!');
        }

        CCG_LogRecording__c logRecording = new CCG_LogRecording__c();
        logRecording.Process__c = process;
        logRecording.Subject__c = subject;
        logRecording.Data__c = data;
        logRecording.RecordId__c = recordId;
        logRecording.ExceptionType__c = '';
        logRecording.ExceptionStackTrace__c = '';
        logRecording.ExceptionMessage__c = '';
            
        logRecording.DML__c = Limits.getDMLStatements();
        logRecording.SOQL__c = Limits.getQueries();
        logRecording.Callouts__c = Limits.getCallouts();
        logRecording.CPUTime__c = Limits.getCpuTime();
        logRecording.QueryRows__c = Limits.getQueryRows();
        logRecording.HeapSize__c = Limits.getHeapSize();
        logRecording.RunningUserId__c = UserInfo.getUserId();

        insert logRecording;
    }

    @AuraEnabled
    public static void createErrorLog(String process, String subject, String recordId, 
            String errorType, String errorMessage, String errorStack) {

        if (String.isBlank(process) || String.isBlank(subject) || String.isBlank(errorMessage)) {
            throw new AuraHandledException('Invalid process, subject or error message!');
        }

        CCG_LogRecording__c logRecording = new CCG_LogRecording__c();
        logRecording.Process__c = process;
        logRecording.Subject__c = subject;
        logRecording.Data__c = 'ERROR';
        logRecording.RecordId__c = recordId;
        logRecording.ExceptionType__c = errorType;
        logRecording.ExceptionStackTrace__c = errorStack;
        logRecording.ExceptionMessage__c = errorMessage;
                    
        logRecording.DML__c = Limits.getDMLStatements();
        logRecording.SOQL__c = Limits.getQueries();
        logRecording.Callouts__c = Limits.getCallouts();
        logRecording.CPUTime__c = Limits.getCpuTime();
        logRecording.QueryRows__c = Limits.getQueryRows();
        logRecording.HeapSize__c = Limits.getHeapSize();
        logRecording.RunningUserId__c = UserInfo.getUserId();

        insert logRecording;
    }
}