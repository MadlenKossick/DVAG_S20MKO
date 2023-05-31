/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Util
*
* @description Util Methods authentification for ZOB KeyCloak Inhouse Service & External Service
*/

public with sharing class ZOBKeyCloakUtil {
    private static final String NO_FEDERATIONID = System.Label.RegistrationHandlerFedIdRequeried;
    private static final String PROFILE_NOT_FOUND = System.Label.RegistrationHandlerProfileNotFound;
    private static final String ZOB_ROLE_NOT_FOUND = System.Label.RegistrationHandlerZOBRoleNotFound;
    private static final String CONTACT_NOT_FOUND = System.Label.RegistrationHandlerContactNotFound;
    private static final String VB_INFO_ENDPOINT = System.Label.RegistrationHandlerVBInfoEndpointURL;
    private static final String RH_LOG_NAME = System.Label.RegistrationHandlerLogName;
    private static final String DML_ERROR = System.Label.RegistrationHandlerDMLError;
    private static final String COMMUNITY_NAME = System.Label.RegistrationHandlerCommunityName;
    private static final String AUTH_PROVIDER_TYP_AD = 'Außendienst';
    private static final String DO_UPDATE = System.Label.RegistrationHandlerDoUpdate; // update record only in produktion org

    public static User updateUserRecord(Id userId, Auth.UserData userdata, String authProviderTyp){
        User usrBySfId = null;
        User usrByFedId = null;

        //if (userId == null) {
            usrByFedId = getUserByFederationId(userdata.userName);
        // }
        // else {
            usrBySfId = getUserBySalesforceId(userId);
        //}
        User usr = usrByFedId;

        Id profileId = getProfileId(userData, authProviderTyp);
        Boolean valueChanged = FALSE;
        Boolean profileChanged = FALSE;

        clearPermissionSetsCreatedByZOB(usr);
        
        if (DO_UPDATE == 'true' || Test.isRunningTest()) {
            if (usr.FirstName == null || usr.FirstName.equals(userdata.firstName) == false) {
                usr.FirstName = userdata.firstName;    
                valueChanged = true;
            }

            if (usr.LastName == null || usr.LastName.equals(userdata.lastName) == false) {
                usr.LastName = userdata.lastName;
                valueChanged = true;
            }

            if (usr.Email == null || usr.Email.equals(userdata.email) == false) {
                usr.Email = userdata.email;
                valueChanged = true;
            }  
        }

        if (usr.ProfileId.equals(profileId) == false) {
            usr.ProfileId = profileId;
            profileChanged = true;
        }

        if (usr.IsActive == false) {
            usr.IsActive = true;
            valueChanged = true;
        }  

        if (valueChanged || profileChanged)  {
            doDmlUpdateWithErrorLog(usr);
        }

        if (profileChanged) {
            assignPermissionSetIfNeeded(usr, userdata, authProviderTyp);
        }

        if (authProviderTyp.equals(AUTH_PROVIDER_TYP_AD)) {
            updateUserPhoto(usr.Id, getCommunityId(COMMUNITY_NAME), usr.FederationIdentifier);
            createExternalDataUserAuth(usr.Id);  
        }

        return null;
    }

    public static void createExternalDataUserAuth(String userId){
        String namedCredentialDeveloperName = 'EinwilligungenAPI';

        NamedCredential nc =   [SELECT Id, AuthProviderId 
                                FROM NamedCredential
                                WHERE DeveloperName = :namedCredentialDeveloperName 
                                LIMIT 1];

        AuthProvider provider = [SELECT Id, DeveloperName 
                                 FROM AuthProvider
                                 WHERE Id = :nc.AuthProviderId 
                                 LIMIT 1];

        List<ExternalDataUserAuth> userAuth = [SELECT Id 
                                               FROM ExternalDataUserAuth 
                                               WHERE UserId = :userId
                                               AND AuthProviderId = :provider.Id 
                                               AND ExternalDataSourceId = :nc.id 
                                               LIMIT 1];
        
        if(userAuth.isEmpty()){
            Map<String,String> flowInputs = new Map<String,String> {
                'AuthProviderId' => provider.Id, 
                'NamedCredentialId' => nc.Id,
                'UserId' => userId
            };

            Flow.Interview.AuthHelperFlow authHelper = new Flow.Interview.AuthHelperFlow(flowInputs);
            authHelper.start();
        }
    }

    public static User updateContactRecord(Auth.UserData userdata){
        User usr = getUserByFederationId(userdata.userName);

        if (usr.ContactId == null) {
            throw new RegistrationHandlerException(CONTACT_NOT_FOUND);
        }

        Contact con = getCommunityContact(usr.ContactId);
        Boolean valueChanged = FALSE;
        
        if (DO_UPDATE == 'true' || Test.isRunningTest()) {
            if (con.FirstName == null || con.FirstName.equals(userdata.firstName) == false) {
                con.FirstName = userdata.firstName;    
                valueChanged = true;
            }

            if (con.LastName == null || con.LastName.equals(userdata.lastName) == false) {
                con.LastName = userdata.lastName;
                valueChanged = true;
            }

            if (con.Email == null || con.Email.equals(userdata.email) == false) {
                con.Email = userdata.email;
                valueChanged = true;
            }
        }

        if (valueChanged) {
            doDmlUpdateWithErrorLog(usr);
        }

        return null;
    }

    public static User getUserByFederationId(String fedid){
        if (String.isBlank(fedid)) {
            throw new RegistrationHandlerException(NO_FEDERATIONID);
        }

        List<User> users = [SELECT Id, 
                                   FederationIdentifier,
                                   FirstName,
                                   LastName,
                                   Email,
                                   UserName,
                                   ProfileId,
                                   ContactId,
                                   IsActive
                            FROM   User
                            WHERE  FederationIdentifier =: fedid];
        
        User returnUser = null;        
        System.debug('User record found: ' + users.size());
        
        for (User usr : users) {
            System.debug('User: ' + usr);
            if (returnUser == null) {
                returnUser = usr;
            } else if (usr.IsActive) {
                returnUser = usr;
            }
        }
        
        return  returnUser;
    }

    private static User getUserBySalesforceId(String usrid){
        List<User> users = [SELECT Id, 
                                   FederationIdentifier,
                                   FirstName,
                                   LastName,
                                   Email,
                                   UserName,
                                   ProfileId,
                                   ContactId,
                                   IsActive
                            FROM   User
                            WHERE  Id =: usrid];

        if (users.isEmpty()) {
            return null;
        }
        
        return users[0]; // catch more than one user?
    }

    public static Contact getCommunityContact(String sfid){
        List<Contact> contact =    [SELECT  Id, 
                                            FirstName,
                                            LastName,
                                            Email
                                    FROM   Contact
                                    WHERE  Id =: sfid];

        if (contact.isEmpty()) {
            return null;
        }
        
        return contact[0];
    }


    public static Id getProfileId(Auth.UserData userData, String authProviderTyp){
        String rolesCommaSeparated = userData.attributeMap.get('roles');
        String salesforceProfileDeveloperName = '';

        ZOBProfileMapping__mdt mapping = getMappingByRole(rolesCommaSeparated, authProviderTyp);
        if (mapping != null && mapping.SalesforceProfile__c != null) {
            salesforceProfileDeveloperName = mapping.SalesforceProfile__c;
        }

        if (String.isBlank(salesforceProfileDeveloperName)) {
            throw new RegistrationHandlerException(ZOB_ROLE_NOT_FOUND + rolesCommaSeparated);
        }

        Profile profileRecord = [SELECT Id 
                                 FROM   Profile
                                 WHERE  Name = :salesforceProfileDeveloperName
                                 LIMIT 1];

        if (profileRecord == null) {
            throw new RegistrationHandlerException(PROFILE_NOT_FOUND + salesforceProfileDeveloperName);
        }

        return profileRecord.Id;
    }

    public static List<ZOBProfileMapping__mdt> getConfigurations() {
        if (Test.isRunningTest()) {
            return C_ZOBKeyCloakRegHandlerTest.getProfileMappingConfigurationsMock();
        }
        else {
            return [SELECT  Id, ZOBRole__c, ZOBRole2__c, ZOBRole3__c, AuthorizationProvider__c, SalesforceProfile__c, PermissionSetName__c FROM ZOBProfileMapping__mdt];
        }
    }

    public static String getSandboxPrefix(){
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];

        if (org != null && org.IsSandbox) {
            System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
            return '.' + d.getSandboxName();
        }

        return '';
    }

    public static Id getCommunityId(String communityName) {        
        if (Test.isRunningTest() == false && ConnectApi.Communities.getCommunities() != null) {
            for (ConnectApi.Community community : ConnectApi.Communities.getCommunities().communities) { if (community.name.equalsIgnoreCase(communityName)) return community.id;}
        }

        return null;
    }

    public static ZOBProfileMapping__mdt getMappingByRole(String rolesCommaSeparated, String authProviderTyp)
    {
        String rolesString = rolesCommaSeparated != null ? rolesCommaSeparated : '';
        rolesString = rolesString.deleteWhitespace();
        rolesString = rolesString.removeStart('[');
        rolesString = rolesString.removeEnd(']');
        List<String> roles = rolesString.split(',');

        if (roles.isEmpty()) {
            return null;
        }

        List<ZOBProfileMapping__mdt> profileMapping = getConfigurations();

        for (ZOBProfileMapping__mdt roleMapping : profileMapping) {
            if (roleMapping.AuthorizationProvider__c.equals(authProviderTyp) == false) {
                continue;
            }

            Integer passValues = 0;
            Integer neededValueToPass = 3;

            if (roleMapping.ZOBRole3__c == null) {
                neededValueToPass--;
            }

            if (roleMapping.ZOBRole2__c == null) {
                neededValueToPass--;
            }

            if (neededValueToPass != roles.size()) {
                continue;
            }

            if (roles.size() > 0 && (roleMapping.ZOBRole__c != null && roles.contains(roleMapping.ZOBRole__c))) {
                passValues = passValues + 1;
            }

            if (roles.size() > 1 && (roleMapping.ZOBRole2__c != null && roles.contains(roleMapping.ZOBRole2__c))) {
                passValues++;
            } 

            if (roles.size() > 2 && (roleMapping.ZOBRole3__c != null && roles.contains(roleMapping.ZOBRole3__c))) {
                passValues++;
            }

            if (passValues == neededValueToPass) {
                return roleMapping;
            }
        }

        return null;
    }

    @future(callout=true)
    public static void updateUserPhoto(String userId, String communityId, String vbNummer){        
        try {
            String endpointUrl = VB_INFO_ENDPOINT;

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpointUrl.replace('{1}', vbNummer));
            req.setMethod('GET');
            HttpResponse res = h.send(req);

            // No body found in HTTP response
            if(res.getStatusCode() == 404) {
                return;
            }

            XmlStreamReader reader = res.getXmlStreamReader();
            String pictureURL = '';

            if (reader != null) {
                while(reader.hasNext()) {
                    if (reader.getEventType() == XmlTag.CHARACTERS) {
                        String xmlContent = reader.getText();
                        if(String.isNotBlank(xmlContent) && xmlContent.endsWith('/600x600')){
                            pictureURL = xmlContent;
                            break;
                        }
                    }
                    reader.next();
                }
            }

            if(String.isBlank(pictureURL)) return;

            req.setEndpoint(pictureURL);
            req.setMethod('GET');
            res = h.send(req);
    
            if(res.getStatusCode() == 303 && res.getHeader('Location') != null) {
                req.setEndpoint(res.getHeader('Location'));
                res = h.send(req);
            }

            if(res.getStatusCode() >= 200 && res.getStatusCode() < 300 && Test.isRunningTest() == false) {
                ConnectApi.UserProfiles.setPhoto(communityId, userId, new ConnectApi.BinaryInput(res.getBodyAsBlob(), 'image/png', 'userphoto.png'));

                doDmlUpdateWithErrorLog(new User(Id = userId, UserPreferencesShowProfilePicToGuestUsers = true));
            }
        } catch (Exception e) {
            ErrorUtil.logExceptionError(RH_LOG_NAME, 'User Photo cannot be updated via SSO ' 
                    + 'userId = ' + userId + ', vbNummer = ' + vbNummer, e);
        }
    }

    public static boolean doDmlUpdateWithErrorLog(sObject obj){        
        Database.SaveResult updateResult = Database.update(obj, false);

        if (!updateResult.isSuccess()){
            CCG_Log.create(RH_LOG_NAME, DML_Error, obj.Id, updateResult.getErrors().get(0).getMessage());
            CCG_Log.send();
        }

        return updateResult.isSuccess();
    }

    public static boolean doDmlInsertWithErrorLog(sObject obj){        
        Database.SaveResult insertResult = Database.insert(obj, false);

        if (!insertResult.isSuccess()){
            Database.Error error = insertResult.getErrors().get(0);
            CCG_Log.create(RH_LOG_NAME, DML_Error, obj.Id, error.getMessage());
            CCG_Log.send();
        }

        return insertResult.isSuccess();
    }

    public static void assignPermissionSetIfNeeded(User usr, Auth.UserData userdata, String authProviderTyp) {
        String rolesCommaSeparated = userData.attributeMap.get('roles');
        String permissionSetName = '';

        ZOBProfileMapping__mdt mapping = getMappingByRole(rolesCommaSeparated, authProviderTyp);
        if (mapping != null && mapping.PermissionSetName__c != null) {
            permissionSetName = mapping.PermissionSetName__c;
        }

        if (String.isNotBlank(permissionSetName)) {
            assignPermissionSet(usr.Id, permissionSetName);
        }
    }

    private static void clearPermissionSetsCreatedByZOB(User usr){
        List<ZOBProfileMapping__mdt> profileMapping = getConfigurations();
        Set<String> allPermissionSets = new Set<String>();

        for (ZOBProfileMapping__mdt roleMapping : profileMapping) {
            if (String.isNotBlank(roleMapping.PermissionSetName__c) && allPermissionSets.contains(roleMapping.PermissionSetName__c) == false) {
                allPermissionSets.add(roleMapping.PermissionSetName__c);
            }
        }

        if (allPermissionSets.isEmpty()) {
            return;
        }

        List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id 
                                                                  FROM PermissionSetAssignment 
                                                                  WHERE PermissionSet.Name IN :allPermissionSets 
                                                                  AND AssigneeId = :usr.Id];

        if (permissionSetAssignments.isEmpty() == false) {
            delete permissionSetAssignments;
        }
    }

    private static void assignPermissionSet(String usrId, String permissionSetDevName) {
        List<PermissionSet> permissionSets = [SELECT Id
                                              FROM   PermissionSet
                                              WHERE  Name =: permissionSetDevName];

        if (permissionSets.isEmpty() == false) {
            insert new PermissionSetAssignment(PermissionSetId = permissionSets[0].Id, AssigneeId = usrId);
        }
    }

    /* Revoke existing access token (Fix for W-11571051) */
    public static Boolean revokeToken(Id userId, AuthProvider  authProvider) {        
        //public static Boolean revokeAccess(String authProviderId, String providerName, String userId, String remoteIdentifier)         
        Boolean result = false;
        
        List<ThirdPartyAccountLink> thirdParty = [SELECT Id, RemoteIdentifier 
                                                    FROM ThirdPartyAccountLink
                                                    WHERE UserId = :userId];

        if(!thirdParty.IsEmpty()) {
            result = Auth.AuthToken.revokeAccess(authProvider.Id, authProvider.ProviderType, userId, thirdParty[0].RemoteIdentifier);
        }
        
        return result;
    }

    public class RegistrationHandlerException extends Exception {}        
}