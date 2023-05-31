/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Testclass
*
* @description Test for the saml authentification registration handler for Microsoft Active Directory
*/
@isTest
public with sharing class C_MicrosoftADSamlHandlerTest {
    private static final String DVAG_BACKOFFICE_USER = System.Label.RegistrationHandlerTestProfileBefore;

    testmethod public static void createUserTest_Positiv() {
        C_MicrosoftADSamlHandler handler = new C_MicrosoftADSamlHandler();
        Map<String, String> attributeMock = getSamlMock('systemadministrator');
        
        Test.startTest();
        User createdUser = handler.createUser(null, null, null, 'u123456', attributeMock, '');
        Test.stopTest();

        System.assertEquals(createdUser.Email, attributeMock.get('/emailaddress'));
        System.assertEquals(createdUser.FirstName, attributeMock.get('/givenname'));
        System.assertEquals(createdUser.LastName, attributeMock.get('/surname'));
        System.assertEquals(createdUser.FederationIdentifier, attributeMock.get('/onpremisessamaccountname'));

        // Check System Administrator Profile
        Id sysAdminProfileId = handler.getProfileIdByName(C_MicrosoftADSamlHandler.SYSADMIN_PROFILE_NAME);
        System.assertEquals(createdUser.ProfileId, sysAdminProfileId);
    }

    testmethod public static void createUserTest_Negativ() {
        C_MicrosoftADSamlHandler handler = new C_MicrosoftADSamlHandler();
        Map<String, String> attributeMock = getSamlMock('standarduser');
        
        Test.startTest();
        try {
            User createdUser = handler.createUser(null, null, null, 'u123456', attributeMock, '');            
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), C_MicrosoftADSamlHandler.NO_SYSADMIN_ROLE);
        }
        Test.stopTest();
    }

    testmethod public static void createUserTest_DmlException() {
        C_MicrosoftADSamlHandler handler = new C_MicrosoftADSamlHandler();
        Map<String, String> attributeMock = getSamlMock('systemadministrator');
        
        Test.startTest();
        attributeMock.put('/throwLicenseLimit', '1');

        try {
            User createdUser = handler.createUser(null, null, null, 'u123456', attributeMock, '');            
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), C_MicrosoftADSamlHandler.NO_LICENCE_LEFT);
        }
        Test.stopTest();
    }

    testmethod public static void createUserTest_NoFederationId() {
        C_MicrosoftADSamlHandler handler = new C_MicrosoftADSamlHandler();
        Map<String, String> attributeMock = getSamlMock('systemadministrator');
        
        Test.startTest();
        attributeMock.put('/onpremisessamaccountname', '');

        try {
            User createdUser = handler.createUser(null, null, null, '', attributeMock, '');            
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), C_MicrosoftADSamlHandler.NO_FEDERATIONID);
        }
        Test.stopTest();
    }

    testmethod public static void updateUserTest() {
        C_MicrosoftADSamlHandler handler = new C_MicrosoftADSamlHandler();
        Map<String, String> attributeMock = getSamlMock('systemadministrator');
        User testUser = handler.createUser(null, null, null, 'u123456', attributeMock, '');
        testUser.ProfileId = handler.getProfileIdByName(DVAG_BACKOFFICE_USER);
        insert testUser;
        
        Test.startTest();
        attributeMock.put('/givenname', 'Max');
        attributeMock.put('/surname', 'Mustermann');
        attributeMock.put('/emailaddress', 'max.mustermann.extern@dvag.com');
        handler.updateUser(testUser.Id, null, null, null, testUser.FederationIdentifier, attributeMock, '');
        Test.stopTest();

        User queriedUser = [SELECT FirstName, LastName, Email, ProfileId
                            FROM User
                            WHERE FederationIdentifier =: testUser.FederationIdentifier LIMIT 1];

        System.assertEquals(queriedUser.Email, attributeMock.get('/emailaddress'));
        System.assertEquals(queriedUser.FirstName, attributeMock.get('/givenname'));
        System.assertEquals(queriedUser.LastName, attributeMock.get('/surname'));

        // Check System Administrator Profile
        Id sysAdminProfileId = handler.getProfileIdByName(C_MicrosoftADSamlHandler.SYSADMIN_PROFILE_NAME);
        System.assertEquals(queriedUser.ProfileId, sysAdminProfileId);
    }


    private static Map<String, String> getSamlMock(String role) {
        Map<String, String> attributes = new Map<String, String>();
        attributes.put('/displayname', 'Zufall, Rainer /Extern');
        attributes.put('/tenantid', '930d042f-8145-48e6-871e-7659c17b56da');
        attributes.put('/identityprovider', 'https://sts.windows.net/930d042f-8145-48e6-871e-7659c17b56da/');
        attributes.put('/objectidentifier', '15742875-f5be-4d6e-9086-87f0d876cfdc');
        attributes.put('/givenname', 'Rainer');
        attributes.put('/name', 'rainer.zufall.extern@dvag.com');
        attributes.put('/onpremisessamaccountname', 'u123456');
        attributes.put('/surname', 'Zufall');
        attributes.put('/role', role);
        attributes.put('/emailaddress', 'Rainer.Zufall.extern@dvag.com');
        attributes.put('/throwLicenseLimit', '0');
        return attributes;
    }
}