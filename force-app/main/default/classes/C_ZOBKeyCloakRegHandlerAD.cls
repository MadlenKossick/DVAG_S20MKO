/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Registration Handler
*
* @description Authentification Registration Handler for ZOB KeyCloak external service
*/

global class C_ZOBKeyCloakRegHandlerAD implements Auth.RegistrationHandler {
    private static final String NO_USER_FOUND = System.Label.RegistrationHandlerNoUser;
    private static final String COMMUNITY_NAME = System.Label.RegistrationHandlerCommunityName;
    private static final String AUTH_PROVIDER_TYP = 'Außendienst';
    private static final String AUTH_PROVIDER_NAME = 'ZOB KeyCloak Außendienst';
    
    global boolean canCreateUser(Auth.UserData data) {
        Boolean retVal = (data != null 
                          && data.email != null
                          && data.lastName != null
                          && data.firstName != null);

        String rolesCommaSeparated = data.attributeMap.get('roles');

        if (String.isBlank(rolesCommaSeparated)) {
            retVal = false;
        }
        else {
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
            throw new ZOBKeyCloakSSOADException(NO_USER_FOUND);
        }else {
            ZOBKeyCloakUtil.updateUserRecord(authUser.Id, data, AUTH_PROVIDER_TYP);
            ZOBKeyCloakUtil.updateContactRecord(data);
        }

        return authUser;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        ZOBKeyCloakUtil.updateUserRecord(userId, data, AUTH_PROVIDER_TYP);
        ZOBKeyCloakUtil.updateContactRecord(data);
    }

    global Id confirmUser(Id inputUserId, Id tpalId, Id portalId, Auth.UserData data) {        
        System.debug('confirmUser input Userid: ' + inputUserId);
        
        User userByFedId = ZOBKeyCloakUtil.getUserByFederationId(data.userName);        
        System.debug('userByFedId: ' + userByFedId);
        Id verifiedUserID = String.valueOf(userByFedId.Id).left(15);
        
        if (userByFedId == null) { 
            throw new ZOBKeyCloakSSOADException(NO_USER_FOUND);
        } else if (inputUserId == verifiedUserID) {
            System.debug('Valid User, nothing to do.');
            return inputUserId;
        } else {         
            /*User change, we need to revoke the token for the inactive user as workaround  for W-11571051*/
            System.debug('Old User: <'+inputUserId+'>, revoking token');
            System.debug('New User: <'+ verifiedUserID +'>');
            
            AuthProvider authProvider = [SELECT Id, ProviderType 
                        FROM AuthProvider 
                        WHERE FriendlyName = :AUTH_PROVIDER_NAME
                        LIMIT 1];

            Boolean result;
            
            result = ZOBKeyCloakUtil.revokeToken(inputUserId, authProvider);
            System.debug(result?'Success!':'Failed');
            
            return  verifiedUserID;
        }
    }

    public class ZOBKeyCloakSSOADException extends Exception {}
}