/**
* @author Cloud Consulting Group - Jochen Litzinger
* @date 2023
*
* @group Utility
*
* @description Log Recording Utility Test Class
*/

@isTest
public class ErrorUtilTest {
    @IsTest
    static void processDMLErrorsTest(){
        String jsonSuccess = '[{"success":true,"id":"0013000000abcde"}]';
        String jsonError = '[{"success":false,"errors":[{"message":"error","statusCode":"DML_EXCEPTION"}]}, ' + 
                            '{"success":false,"errors":[{"message":"error 2","statusCode":"DML_EXCEPTION"}]}, ' +
                            '{"success":false,"errors":[{"message":"error 3","statusCode":"DML_EXCEPTION"}]}]';

        Database.SaveResult[] sr = (List<Database.SaveResult>)JSON.deserialize(jsonSuccess, List<Database.SaveResult>.class);
        Database.SaveResult[] srError = (List<Database.SaveResult>)JSON.deserialize(jsonError, List<Database.SaveResult>.class);

        Test.startTest();
        DMLHelper dmlHelper = new DMLHelper(sr);
        ErrorUtil.processDMLErrors('process', 'subject', dmlHelper, true);

        dmlHelper = new DMLHelper(srError);
        ErrorUtil.processDMLErrors('process', 'subject', dmlHelper, true);

        dmlHelper = new DMLHelper(srError);
        ErrorUtil.processDMLErrors('process', 'subject', dmlHelper, false);
        Test.stopTest();

        List<CCG_LogRecording__c> logs = [SELECT Id
                                          from CCG_LogRecording__c];
        System.assertEquals(!logs.isEmpty(), true, 'Invalid error logs');

        Database.DeleteResult[] dr = (List<Database.DeleteResult>)JSON.deserialize(jsonSuccess, List<Database.DeleteResult>.class);
        Database.DeleteResult[] drError = (List<Database.DeleteResult>)JSON.deserialize(jsonError, List<Database.DeleteResult>.class);
        dmlHelper = new DMLHelper(dr);
        dmlHelper = new DMLHelper(drError);

        Database.UpsertResult[] usr = (List<Database.UpsertResult>)JSON.deserialize(jsonSuccess, List<Database.UpsertResult>.class);
        Database.UpsertResult[] usrError = (List<Database.UpsertResult>)JSON.deserialize(jsonError, List<Database.UpsertResult>.class);
        dmlHelper = new DMLHelper(usr);
        dmlHelper = new DMLHelper(usrError);
    }

    @isTest
    public static void logExceptionErrorTest(){
        Test.startTest();
        ErrorUtil.logExceptionError('Process', 'Subject', new AssertException('test'));
        Test.stopTest();

        List<CCG_LogRecording__c> logs = [SELECT Id
                                          from CCG_LogRecording__c];
        System.assertEquals(!logs.isEmpty(), true, 'Invalid error logs');
    }

    @isTest
    public static void logErrorTest(){
        Test.startTest();
        ErrorUtil.logError('Process', 'Subject', 'Type', 'Message', 'Stack');
        Test.stopTest();
        
        List<CCG_LogRecording__c> logs = [SELECT Id
                                          from CCG_LogRecording__c];
        System.assertEquals(!logs.isEmpty(), true, 'Invalid error logs');
    }

    @isTest
    public static void logErrorAPITest(){
        Test.startTest();
        ErrorUtil.logErrorAPI('Process', 'Subject', 'Type', 'Message', 'Stack');
        Test.stopTest();
    }
}