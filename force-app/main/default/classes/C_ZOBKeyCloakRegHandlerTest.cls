/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Testclass
*
* @description Test for the open id connect authentification registration handler for ZOB KeyCloak
*/
@isTest
public with sharing class C_ZOBKeyCloakRegHandlerTest {
    private static final String DVAG_BACKOFFICE_USER = System.Label.RegistrationHandlerTestProfileBefore;
    private static final String NO_USER_FOUND = System.Label.RegistrationHandlerNoUser;
    private static final STRING FEDERATION_ID = 'vb4711';

    @TestSetup
    static void setupTestData(){
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            TestDataUtility.createCommunityAccountContact(4711);
        }
    }

    testmethod public static void updateUser_AD_StandardUserTest() {
        C_ZOBKeyCloakRegHandlerAD handler = new C_ZOBKeyCloakRegHandlerAD();
        String testZOBRole = 'standard-user';

        User testUser = [SELECT Id, FederationIdentifier 
                         FROM User 
                         WHERE FederationIdentifier = :FEDERATION_ID
                         LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        handler.createUser(null, getAuthUserDataMock(testZOBRole, FEDERATION_ID));
        Test.stopTest();

        User queriedUser = [SELECT FirstName, LastName, Email, ProfileId, Profile.Name
                            FROM User
                            WHERE FederationIdentifier =: testUser.FederationIdentifier LIMIT 1];

        List<ZOBProfileMapping__mdt> profileMapping = getProfileMappingConfigurationsMock();
        String salesforceProfileName = '';

        for (ZOBProfileMapping__mdt config : profileMapping) {
            if (config.ZOBRole__c == testZOBRole) {
                salesforceProfileName = config.SalesforceProfile__c;
            }
        }

        System.assertEquals(queriedUser.Profile.Name, salesforceProfileName);
    }

    testmethod public static void updateUser_AD_StandardUserUpdateTest() {
        C_ZOBKeyCloakRegHandlerAD handler = new C_ZOBKeyCloakRegHandlerAD();
        String testZOBRole = 'standard-user';

        User testUser = [SELECT Id, FederationIdentifier 
                         FROM User 
                         WHERE FederationIdentifier = :FEDERATION_ID
                         LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        handler.updateUser(testUser.Id, null, getAuthUserDataMock(testZOBRole, FEDERATION_ID));
        Test.stopTest();

        User queriedUser = [SELECT FirstName, LastName, Email, ProfileId, Profile.Name
                            FROM User
                            WHERE FederationIdentifier =: testUser.FederationIdentifier LIMIT 1];

        List<ZOBProfileMapping__mdt> profileMapping = getProfileMappingConfigurationsMock();
        String salesforceProfileName = '';

        for (ZOBProfileMapping__mdt config : profileMapping) {
            if (config.ZOBRole__c == testZOBRole) {
                salesforceProfileName = config.SalesforceProfile__c;
            }
        }

        System.assertEquals(queriedUser.Profile.Name, salesforceProfileName);
    }

    testmethod public static void updateUser_AD_NoUserTest() {
        C_ZOBKeyCloakRegHandlerAD handler = new C_ZOBKeyCloakRegHandlerAD();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        try {
            handler.createUser(null, getAuthUserDataMock('standard-user', 'imAmNotHere'));
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), NO_USER_FOUND);
        }
        Test.stopTest();
    }

    testmethod public static void updateUser_AD_NoRoleTest() {
        C_ZOBKeyCloakRegHandlerAD handler = new C_ZOBKeyCloakRegHandlerAD();
        User u = null;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        u = handler.createUser(null, getAuthUserDataMock('', ''));
        Test.stopTest();

        System.assertEquals(u, null);
    }

    testmethod public static void updateUser_ID_StandardUserTest() {
        C_ZOBKeyCloakRegHandlerID handler = new C_ZOBKeyCloakRegHandlerID();
        String testZOBRole = 'standard-user';

        User testUser = [SELECT Id, FederationIdentifier 
                         FROM User 
                         WHERE FederationIdentifier = :FEDERATION_ID
                         LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        handler.createUser(null, getAuthUserDataMock(testZOBRole, FEDERATION_ID));
        Test.stopTest();

        User queriedUser = [SELECT FirstName, LastName, Email, ProfileId, Profile.Name
                            FROM User
                            WHERE FederationIdentifier =: testUser.FederationIdentifier LIMIT 1];

        List<ZOBProfileMapping__mdt> profileMapping = getProfileMappingConfigurationsMock();
        String salesforceProfileName = '';

        for (ZOBProfileMapping__mdt config : profileMapping) {
            if (config.ZOBRole__c == testZOBRole) {
                salesforceProfileName = config.SalesforceProfile__c;
            }
        }

        System.assertEquals(queriedUser.Profile.Name, salesforceProfileName);
    }

    testmethod public static void updateUser_ID_StandardUserUpdateTest() {
        C_ZOBKeyCloakRegHandlerID handler = new C_ZOBKeyCloakRegHandlerID();
        String testZOBRole = 'standard-user';

        User testUser = [SELECT Id, FederationIdentifier 
                         FROM User 
                         WHERE FederationIdentifier = :FEDERATION_ID
                         LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        handler.updateUser(testUser.Id, null, getAuthUserDataMock(testZOBRole, FEDERATION_ID));
        Test.stopTest();

        User queriedUser = [SELECT FirstName, LastName, Email, ProfileId, Profile.Name
                            FROM User
                            WHERE FederationIdentifier =: testUser.FederationIdentifier LIMIT 1];

        List<ZOBProfileMapping__mdt> profileMapping = getProfileMappingConfigurationsMock();
        String salesforceProfileName = '';

        for (ZOBProfileMapping__mdt config : profileMapping) {
            if (config.ZOBRole__c == testZOBRole) {
                salesforceProfileName = config.SalesforceProfile__c;
            }
        }

        System.assertEquals(queriedUser.Profile.Name, salesforceProfileName);
    }

    testmethod public static void updateUser_ID_NoUserTest() {
        C_ZOBKeyCloakRegHandlerID handler = new C_ZOBKeyCloakRegHandlerID();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());

        try {
            handler.createUser(null, getAuthUserDataMock('standard-user', FEDERATION_ID));
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), NO_USER_FOUND);
        }
        Test.stopTest();
    }

    testmethod public static void updatePhotoAssertion() {
        C_ZOBKeyCloakRegHandlerID handler = new C_ZOBKeyCloakRegHandlerID();

        Test.startTest();

        try {
            handler.createUser(null, getAuthUserDataMock('standard-user', FEDERATION_ID));
        } catch (Exception e) {
            System.debug('Test assert -> no mock');
        }
        Test.stopTest();
    }

    testmethod public static void updateUser_ID_NoRoleTest() {
        C_ZOBKeyCloakRegHandlerID handler = new C_ZOBKeyCloakRegHandlerID();
        User u = null;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VBInfoPictureMock());
        
        u = handler.createUser(null, getAuthUserDataMock('', 'iAmNotHere'));
        Test.stopTest();

        System.assertEquals(u, null);
    }

    private static Auth.UserData getAuthUserDataMock(String role, String fedId){
        return new Auth.UserData('',
                                 'Rainer',
                                 'Zufall',
                                 'Zufall, Rainer /Extern', // fullname
                                 'rainer.zufall.extern@dvag.com',
                                 '', // link
                                 fedId, // userName
                                 '',
                                 '', // provider
                                 '', // siteLoginUrl
                                 getAttributeMapMock(role)); 
    }

    private static Map<String, String> getAttributeMapMock(String role) {
        Map<String, String> attributes = new Map<String, String>();
        attributes.put('roles', role);
        return attributes;
    }

    public static List<ZOBProfileMapping__mdt> getProfileMappingConfigurationsMock(){
        List<ZOBProfileMapping__mdt> zobProfileMappings = new List<ZOBProfileMapping__mdt>();
        zobProfileMappings.add(new ZOBProfileMapping__mdt(AuthorizationProvider__c = 'Innendienst', PermissionSetName__c = '', DeveloperName = 'StandardUserID', SalesforceProfile__c = 'DVAG Backoffice User', ZOBRole__c = 'standard-user'));
        zobProfileMappings.add(new ZOBProfileMapping__mdt(AuthorizationProvider__c = 'Außendienst', PermissionSetName__c = 'DVAGCampaignManagerPermission', DeveloperName = 'StandardUserAD', SalesforceProfile__c = 'DVAG Field Sales User', ZOBRole__c = 'standard-user'));
        return zobProfileMappings; 
    }
}