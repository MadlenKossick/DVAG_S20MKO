/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Registration Handler
*
* @description Authentification Registration Handler for Microsoft Active Directory
*/

global class C_MicrosoftADSamlHandler implements Auth.SamlJitHandler {
    private String PROCESS = 'Microsoft AD SAML Handler';

    private class JitException extends Exception{}

    private static final String PROFILE_NOT_FOUND = System.Label.RegistrationHandlerProfileNotFound;
    
    @TestVisible
    private static final String NO_FEDERATIONID = System.Label.RegistrationHandlerFedIdRequeried;

    @TestVisible
    private static final String NO_LICENCE_LEFT = System.Label.RegistrationHandlerNoLicenceLeft;

    @TestVisible
    private static final String NO_SYSADMIN_ROLE = System.Label.RegistrationHandlerNoAccessRights;

    @TestVisible
    private static final String SYSADMIN_PROFILE_NAME = System.Label.RegistrationHandlerADIDProfileName;

    
	global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
		String federationIdentifier, Map<String, String> attributes, String assertion)
    {
        MicrosoftAdSamlClaims claims = new MicrosoftAdSamlClaims(attributes);
        checkAccess(claims.role);

        if (String.isNotBlank(federationIdentifier)) {
            claims.onPremisessamAccountname = federationIdentifier;
        }

        User usr = getUserByFederationId(claims.onPremisessamAccountname);
        
        if (usr == null) {
            usr = createUserRecord(claims);
        }

		return usr;
	}

	global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
		String federationIdentifier, Map<String, String> attributes, String assertion) 
    {
        MicrosoftAdSamlClaims claims = new MicrosoftAdSamlClaims(attributes);
        checkAccess(claims.role);

        if (String.isNotBlank(federationIdentifier)) {
            claims.onPremisessamAccountname = federationIdentifier;
        }

        updateUserRecord(claims);
	}

    private User createUserRecord(MicrosoftAdSamlClaims userData){
        try {
            User usr = new User();
            usr.IsActive = true;
            usr.FederationIdentifier = userData.onPremisessamAccountname;
            usr.username = userData.emailAddress + getSandboxPrefix();
            usr.email = userData.emailAddress;
            usr.lastName = userData.surName;
            usr.firstName = userData.givenName;
            String alias = userData.givenName.left(3) + userData.surName;
            //Alias must be 8 characters or less
            if(alias.length() > 8) {
                alias = alias.substring(0, 8);
            }
            usr.alias = alias;
            usr.languagelocalekey = UserInfo.getLanguage();
            usr.localesidkey = UserInfo.getLocale();
            usr.emailEncodingKey = 'UTF-8';
            usr.timeZoneSidKey = 'Europe/Berlin';
            usr.profileId = getProfileIdByName(SYSADMIN_PROFILE_NAME);

            if (Test.isRunningTest() && userData.throwLicenseLimit == true) {
                usr.username = 'i am not valid';
                insert usr;
            }

            return usr;
        } catch (DmlException dmx) {
            ErrorUtil.logExceptionError(PROCESS, 'Create User Record', dmx);
            for (Integer i = 0; i < dmx.getNumDml(); i++)
            {
                if (dmx.getDmlType(i) == StatusCode.LICENSE_LIMIT_EXCEEDED || Test.isRunningTest())
                {
                    throw new JitException(NO_LICENCE_LEFT);
                }
            }        
        }

        return null;
    }

    private User updateUserRecord(MicrosoftAdSamlClaims userdata){
        User usr = getUserByFederationId(userdata.onPremisessamAccountname);

        Id sysAdminProfileId = getProfileIdByName(SYSADMIN_PROFILE_NAME);
        Boolean valueChanged = FALSE;

        if (usr.FirstName == null || usr.FirstName.equals(userdata.givenName) == false) {
            usr.FirstName = userdata.givenName;    
            valueChanged = true;
        }

        if (usr.LastName == null || usr.LastName.equals(userdata.surName) == false) {
            usr.LastName = userdata.surName;
            valueChanged = true;
        }

        if (usr.Email == null || usr.Email.equals(userdata.emailAddress) == false) {
            usr.Email = userdata.emailAddress;
            valueChanged = true;
        }

        if (usr.ProfileId.equals(sysAdminProfileId) == false) {
            usr.ProfileId = sysAdminProfileId;
            valueChanged = true;
        }

        if (valueChanged) {
            update usr;
        }

        return null;
    }

    private User getUserByFederationId(String fedid){
        if (String.isBlank(fedid)) {
            throw new JitException(NO_FEDERATIONID);
        }

        List<User> users = [SELECT Id, 
                                   FederationIdentifier,
                                   FirstName,
                                   LastName,
                                   Email,
                                   UserName,
                                   ProfileId
                            FROM   User
                            WHERE  FederationIdentifier =: fedid];

        if (users.isEmpty()) {
            return null;
        } else if (users.size() > 1) {
            ErrorUtil.logError(process, 'FederationId not unique', 'FederationId', 'Error', JSON.serializePretty(users));
        }
        
        return users[0]; //How to handle more than one user?
    }

    @TestVisible
    private Id getProfileIdByName(String profileName){
        Profile profileRecord = [SELECT Id 
                                 FROM   Profile
                                 WHERE  Name = :profileName
                                 LIMIT 1];
        if (profileRecord == null) {
            throw new JitException(PROFILE_NOT_FOUND + profileName);
        }

        return profileRecord.Id;
    }

    private Boolean checkAccess(String roleName){
        if (String.isNotBlank(roleName) && roleName.equalsIgnoreCase('systemadministrator')) {
            return true;
        }
        else {
            throw new JitException(NO_SYSADMIN_ROLE);
        }
    }

    private String getSandboxPrefix(){
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];

        if (org != null && org.IsSandbox) {
            System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
            return '.' + d.getSandboxName();
        }

        return '';
    }

    @TestVisible
    private class MicrosoftAdSamlClaims {
        public String displayName;
        public String tenantId;
        public String identityProvider;
        public String objectIdentifier;
        public String givenName;
        public String name;
        public String authnmethodsreferences;
        public String onPremisessamAccountname;
        public String surName;
        public String role;
        public String emailAddress;

        // only for test coverage
        public Boolean throwLicenseLimit;

        public MicrosoftAdSamlClaims(Map<String, String> input){
            this.displayName = '';
            this.tenantId = '';
            this.identityProvider = '';
            this.objectIdentifier = '';
            this.givenName = '';
            this.name = '';
            this.onPremisessamAccountname = '';
            this.surName = '';
            this.role = '';
            this.emailAddress = '';
            this.throwLicenseLimit = false;

            for(String claimKey : input.keySet()){
                String claimValue = input.get(claimKey);
                String claimKeyOnly = claimKey.substringAfterLast('/');

                switch on claimKeyOnly {
                    when 'displayname' {
                        this.displayName = claimValue;
                    }
                    when 'tenantid' {
                        this.tenantId = claimValue;
                    }
                    when 'identityprovider' {
                        this.identityProvider = claimValue;
                    }
                    when 'objectidentifier' {
                        this.objectIdentifier = claimValue;
                    }
                    when 'givenname' {
                        this.givenName = claimValue;
                    }
                    when 'name' {
                        this.name = claimValue;
                    }
                    when 'onpremisessamaccountname' {
                        this.onPremisessamAccountname = claimValue;
                    }
                    when 'surname' {
                        this.surName = claimValue;
                    }
                    when 'role' {
                        this.role = claimValue;
                    }
                    when 'emailaddress' {
                        this.emailAddress = claimValue;
                    }
                    when 'throwLicenseLimit' {
                        this.throwLicenseLimit = claimValue == '1';
                    }
                    when else {}
                }
            }
        }
    }
}