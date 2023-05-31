/**
* @author Cloud Consulting Group - Patrick Driller
* @date 2022
*
* @group Utility
*
* @description EWE Service Utility Class
* Einwilligungserklaerungen API Version 1.0
* https://developer-portal.dvag/teams/120/apis/1645/versions/1646/swagger/
*
* POST einwilligungserklaerungen Status Codes
* 400 Fehlerhafte Anfrage
* 401 Keine Authentifizierung
* 403 Keine Berechtigung
* 409 Einladungsemail wurde bereits versendet
* 500 Unerwarteter Fehler
* 501 Salesforce Fehler
*/

public class EWEUtil {
    @InvocableMethod(label='Start EWE Process' description='Create consent form, send email, return backlink and redirect after consent is given' category='EWE')
    public static List<String> startEWEProcess(List<Id> personAccountIds) {
        List<String> returnCode = new List<String>();

        Id authProviderId = getAuthProviderId('zob_app_web_salesforce_ad');

        List<Account> accountToConsent = [SELECT Id,
                                                 FirstName,
                                                 LastName,
                                                 PersonEmail,
                                                 AccountNumber,                                                 
                                                 ExtCustomerIdOki__c,
                                                 Owner.FederationIdentifier,
                                                 Owner.Email 
                                          FROM   Account 
                                          WHERE  Id IN: personAccountIds];

        for (Account personAccount : accountToConsent) {
            returnCode.add(String.valueOf(sendRequest(authProviderId, personAccount, '')));
        }

        return returnCode;
    }

    private static Integer sendRequest(Id authProviderId, Account personAccount, String accToken){
        String accessToken = accToken;
        
        if (String.isBlank(accToken)) {
            accessToken = Auth.AuthToken.getAccessToken(authProviderId, 'Open ID connect');    
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EinwilligungenAPI');
        req.setMethod('POST');
        req.setTimeout(20000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization','Bearer ' + accessToken);
        req.setBody(getJsonBodyForPostEinwilligungserklaerungen(personAccount));
        Http http = new Http();
        HTTPResponse res = null;

        try {
            res = http.send(req);
        } catch (Exception e) {
            CCG_Log.create('EWE Service', 'einwilligungserklaerungen call failed', personAccount.Id, e.getMessage());
            CCG_Log.send();
            return 501;
        }

        if (res.getStatusCode() == 401 && String.isBlank(accToken)) {
            Map<String, String> tokens = Auth.AuthToken.refreshAccessToken(authProviderId, 'Open ID connect', accessToken);
            return sendRequest(authProviderId, personAccount, tokens.get('AccessToken'));
        }

        return res.getStatusCode(); 
    }

    private static Id getAuthProviderId(String developerName){
        String devNameBox = developerName + '%';
        return [SELECT Id FROM AuthProvider WHERE DeveloperName LIKE :devNameBox LIMIT 1].Id;
    }

    private static String getJsonBodyForPostEinwilligungserklaerungen(Account personAccount){
        return JSON.serialize(new EWE_Einwilligungserklaerung(personAccount.PersonEmail,
                                                              personAccount.FirstName,
                                                              personAccount.LastName,
                                                              personAccount.ExtCustomerIdOki__c,
                                                              personAccount.AccountNumber,
                                                              personAccount.Owner.FederationIdentifier, 
                                                              personAccount.Owner.Email, 
                                                              true));
    }

    private class EWE_Einwilligungserklaerung
    {
        public EWE_Person person;
        public EWE_Vermoegensberater vermoegensberater;

        public Boolean einladungsEmailVersenden;

        public EWE_Einwilligungserklaerung(String emailPerson, String vornamePerson, String nachnamePerson, String idPerson, String nummerPerson, String idVB, String emailVB, Boolean einladungsEmailVersenden){
            this.einladungsEmailVersenden = einladungsEmailVersenden;
            this.person = new EWE_Person(emailPerson, vornamePerson, nachnamePerson, idPerson, nummerPerson);
            this.vermoegensberater = new EWE_Vermoegensberater(idVB, emailVB);
        }
    }

    private class EWE_Person
    {
        public String id;
        public String nummer;
        public String vorname;
        public String nachname;
        public String emailAdresse;

        public EWE_Person(String emailAdresse, String vorname, String nachname, String id, String nummer){
            this.id = id;
            this.nummer = nummer;
            this.emailAdresse = emailAdresse;
            this.vorname = vorname;
            this.nachname = nachname;
        }
    }

    private class EWE_Vermoegensberater
    {
        public String id;
        public String emailAdresse;
        public String mandant; // enum DVAG, DVAG_WIEN, ALLFINANZ, ALLFINANZ_AG, UNBEKANNT

        public EWE_Vermoegensberater(String id, String emailAdresse) {
            this.id = id;
            this.emailAdresse = emailAdresse;
            this.mandant = 'DVAG';
        }
    }
}