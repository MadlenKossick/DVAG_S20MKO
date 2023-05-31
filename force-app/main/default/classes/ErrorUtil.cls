/**
* @author Cloud Consulting Group - Jochen Litzinger
* @date 2023
*
* @group Utility
*
* @description Log Recording Utility Class
*/

public without sharing class ErrorUtil {
    public static void processDMLErrors(String process, String subject, DMLHelper results, Boolean sendSingleError) {
        String errorMessage = process + ' Error(s) \n';
        Boolean hasError = false;
        Integer dmlCounter = 0; // consider DML platform event limit
        Integer maxLogs = 100;
        Integer maxLength = 120000;
        if (Test.isRunningTest()) {
            maxLength = 35;
        }
        
        if (results == null) return;      

        Iterator<DMLHelper.DmlResult> iter = results.iterator();
        while(iter.hasNext()) {
            DMLHelper.DmlResult result = iter.next();
            if(!result.success) {
                if (sendSingleError && dmlCounter < maxLogs) {
                    logError(process, subject, 'DMLException', 'Error', JSON.serializePretty(result));
                }
                else {
                    hasError = true;
                    errorMessage += result.recordId + ', ' + result.errors[0].getMessage() + '\n';

                    if (errorMessage.length() > maxLength && dmlCounter < maxLogs) {
                        logError(process, subject, 'DMLException', 'Error', errorMessage);
                        errorMessage = process + ' Error(s) \n';
                        hasError = false;
                    }
                }                
                dmlCounter++;
            }
        }
        
        // send last errors
        if (hasError) {
            logError(process, subject, 'DMLException', 'Error', errorMessage);
        }
    }
        
    public static void logError(String process, String subject, String type, String message, String stack) {
        CCG_Log.create(process, subject, '', 'ERROR');
        CCG_Log.addException(type, message, stack);
        CCG_Log.send();
    }

    public static void logErrorAPI(String process, String subject, String type, String message, String stack) {
        CCG_Log.create(process, subject, '', 'ERROR');
        CCG_Log.addException(type, message, stack);
        CCG_Log.sendAPI();
    }

    public static void logExceptionError(String Process, String subject, Exception ex) {
        CCG_Log.create(process, subject, '', 'ERROR');
        CCG_Log.addException(ex);
        CCG_Log.send();
    }

    public static void logExceptionErrorAPI(String Process, String subject, Exception ex) {
        CCG_Log.create(process, subject, '', 'ERROR');
        CCG_Log.addException(ex);
        CCG_Log.sendAPI();
    }
}