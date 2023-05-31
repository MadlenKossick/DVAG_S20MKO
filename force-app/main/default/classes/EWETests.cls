/**
* @author Cloud Consulting Group - Patrick Driller
* @date 2022
*
* @group Testclass
*
* @description Testclass for EWE Service
* Einwilligungserklaerungen API Version 1.0
* https://developer-portal.dvag/teams/120/apis/1645/versions/1646/swagger/
*
* POST einwilligungserklaerungen Status Codes
* 201 Einwilligungserklaerung zur geforderten UUID
* 400 Fehlerhafte Anfrage
* 401 Keine Authentifizierung
* 403 Keine Berechtigung
* 409 Einladungsemail wurde bereits versendet
* 500 Unerwarteter Fehler
* 501 Salesforce Fehler
*/

@isTest
public class EWETests {
    @TestSetup
    static void setupTestData(){
        TestDataUtility.createPersonAccount(1);
    }

    testmethod public static void startEWEProcessTest() {
        Account testAccount = [SELECT Id
                               FROM Account 
                               LIMIT 1];
        List<String> statusCode = new List<String>();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EWETestMock());

        statusCode = EWEUtil.startEWEProcess(new List<Id>{testAccount.Id});
        Test.stopTest();

        System.assertEquals(statusCode[0], '201');
    }

    testmethod public static void startEWEProcessTestException() {
        Account testAccount = [SELECT Id
                               FROM Account 
                               LIMIT 1];
        Test.startTest();
        EWEUtil.startEWEProcess(new List<Id>{testAccount.Id});
        Test.stopTest();
    }
}