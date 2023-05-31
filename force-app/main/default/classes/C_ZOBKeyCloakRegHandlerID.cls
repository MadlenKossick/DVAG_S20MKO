/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Registration Handler
*
* @description Authentification Registration Handler for ZOB KeyCloak internal service
*/

global class C_ZOBKeyCloakRegHandlerID implements Auth.RegistrationHandler {
    private static final String COMMUNITY_NAME = System.Label.RegistrationHandlerCommunityName;
    private static final String RH_LOG_NAME = System.Label.RegistrationHandlerLogName;
    private static final String AUTH_PROVIDER_TYP = 'Innendienst';
    
    global boolean canCreateUser(Auth.UserData data) {
        Boolean retVal = (data != null 
                          && data.email != null
                          && data.lastName != null
                          && data.firstName != null);

        String rolesCommaSeparated = data.attributeMap.get('roles');

        if (String.isBlank(rolesCommaSeparated)) {
            retVal = false;
        } else {
            retVal = ZOBKeyCloakUtil.getMappingByRole(rolesCommaSeparated, AUTH_PROVIDER_TYP) != null;
        }
                
        return retVal;
    }
    
    global User createUser(Id portalId, Auth.UserData data){
        if(!canCreateUser(data)) {
            return null;
        }

        User authUser = ZOBKeyCloakUtil.getUserByFederationId(data.userName);

        if (authUser == null) {
            authUser = createUserRecord(data);
        } else {
            ZOBKeyCloakUtil.updateUserRecord(authUser.Id, data, AUTH_PROVIDER_TYP);
        }

        if (authUser != null) {
            ZOBKeyCloakUtil.updateUserPhoto(authUser.Id, ZOBKeyCloakUtil.getCommunityId(COMMUNITY_NAME), authUser.FederationIdentifier);
        }

        return authUser;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        ZOBKeyCloakUtil.updateUserRecord(userId, data, AUTH_PROVIDER_TYP);
    }

    private User createUserRecord(Auth.UserData userData){
        try {
            User usr = new User();
            usr.IsActive = true;
            usr.FederationIdentifier = userData.userName;
            usr.username = userData.email + ZOBKeyCloakUtil.getSandboxPrefix();
            usr.email = userData.email;
            usr.lastName = userData.lastName;
            usr.firstName = userData.firstName;
            String alias = userData.lastName.left(3) + userData.firstName;
            //Alias must be 8 characters or less
            if(alias.length() > 8) {
                alias = alias.substring(0, 8);
            }
            usr.alias = alias;
            usr.languagelocalekey = UserInfo.getLanguage();
            usr.localesidkey = UserInfo.getLocale();
            usr.emailEncodingKey = 'UTF-8';
            usr.timeZoneSidKey = 'Europe/Berlin';
            usr.profileId = ZOBKeyCloakUtil.getProfileId(userData, AUTH_PROVIDER_TYP);
            
            ZOBKeyCloakUtil.doDmlInsertWithErrorLog(usr);
            ZOBKeyCloakUtil.assignPermissionSetIfNeeded(usr, userData, AUTH_PROVIDER_TYP);

            return usr;
        } catch(Exception e) {
            ErrorUtil.logExceptionError('Innendienst Registration Handler', 'License limit exceeded!', e);
        }

        return null;
    }

    public class ZOBKeyCloakSSOIDException extends Exception {}
}