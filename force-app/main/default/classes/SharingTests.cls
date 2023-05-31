/**
* @author Salesforce.com - Stefan Talkenberg
* @date 2022
*
* @description FSCEC-1245 Fachliche Testklassse / Regressionstest
*  - Functional Tests for Sharing, base on business requirements, not technical spec
*  - Aims at providing a regression test layer to the Unit Tests (separate Test classes)
* 
*/

@isTest
public class SharingTests {
private static final Id personAccountRecordType = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
    private static final Id directorateAccountRecordType = RecordTypeHelper.getAccRecordTypeIdDirectorate();
    private static List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();

    private static Integer getRelatedObjectIndex(String objectName, String recordTypeName) {
        Integer index = 0;
        for (Integer i = 0; i < configs.size(); i++){
            if (configs[i].ObjectName__c == objectName && configs[i].RecordTypeName__c == recordTypeName) {
                index = i;
            }
        }
        return index;
    }
    
    /*Create and insert all test data*/
    @TestSetup
    public static void createTestData() {
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            SharingTestUtil.createTestVbAssistantDeputyStructure();
        }
    }
    
    /************************************************************************************** Basic Account Visibilty **************************************************************************************/
    /* 
        FSCEC-1231: Sichtbarkeit für neue Assistenten
        (ohne 360 Grad Objekte)
        
        VB BX1 & BX2 mit jeweils 1 Kunden

        A1 ist Assistent für BX1 & BX2        
        A2 ist Assistent für BX1 & BX2

        Assistent A1 sieht 2 Accounts
        Assistent A2 sieht 2 Accounts

        @TODO: Add test for "hidden" customers

    */
    @IsTest
    static void basicVisibilityAddAssistants() {
        SharingTestUtil.populateVbStructure();    
        
        User assistantUsr1 = SharingTestUtil.createFieldSalesContactUser('A1', 'Assistant', 'asssistant.a1@dvag.test', '11111', SharingTestUtil.assistantPartnerAccount.Id, null);
        User assistantUsr2 = SharingTestUtil.createFieldSalesContactUser('A2', 'Assistant', 'asssistant.a2@dvag.test', '22222', SharingTestUtil.assistantPartnerAccount.Id, null);

        //Check visibility without Assistant relations
        List<Account> assistant1Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr1);
        System.assertEquals(0, assistant1Customers.size());
        System.assertEquals(1, SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBX1user).size());
        
        List<Account> assistant2Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr2);
        System.assertEquals(0, assistant2Customers.size());
        System.assertEquals(1, SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBX2user).size());
        
        //Prepare Assistant data
        List<AssistantToAdvisor__c> assistants = new List<AssistantToAdvisor__c>();
        assistants.add(SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX1user, assistantUsr1));                
        assistants.add(SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX2user, assistantUsr1));
        assistants.add(SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX1user, assistantUsr2));
        assistants.add(SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX2user, assistantUsr2));
                                                                  
        //Add assistant relations
        Test.startTest();
        insert assistants;
        Test.stopTest();

        /*
        //Print Group Members for Debugging
        Set<Id> accIds = new Set<Id>();
        accIds.add(SharingTestUtil.leafAX1CustomerAccount.Id);
        accIds.add(SharingTestUtil.leafAX2CustomerAccount.Id);
        accIds.add(SharingTestUtil.leafAY1CustomerAccount.Id);
        accIds.add(SharingTestUtil.leafAY2CustomerAccount.Id);
        SharingTestUtil.printAccountGroupSharesWithMembers(accIds);   
        */

        //Check visibility with assistant relations
        assistant1Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr1);
        System.assertEquals(2, assistant1Customers.size());
        
        assistant2Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr2);
        System.assertEquals(2, assistant2Customers.size());                
    }

     /* 
        FSCEC-1232: Sichtbarkeit Akten nach entfernen eines Assistenten
        (ohne 360 Grad Objekte)
        
        VB BX1 & BX2 mit jeweils 1 Kunden

        A1 ist Assistent für BX1 & BX2        
        A2 ist Assistent für BX1 & BX2

        Assistent A1 sieht 2 Accounts
        Assistent A2 sieht 2 Accounts
        (durch vorhergehende Tests sichergestellt - ggf. in Test Struktur verschieben?)
        
        Entfernen von Beziehung Assistent A1 -> BX2
        Entfernen von Beziehung Assistent A2 -> BX1

        Assistent A1 sieht Account BX1
        Assistent A2 sieht Account BX2
    */
    @IsTest
    static void basicVisibilityDeleteAssistant( ){
        SharingTestUtil.populateVbStructure();    
        
        User assistantUsr1 = SharingTestUtil.createFieldSalesContactUser('A1', 'Assistant', 'asssistant.a1@dvag.test', '11111', SharingTestUtil.assistantPartnerAccount.Id, null);
        User assistantUsr2 = SharingTestUtil.createFieldSalesContactUser('A2', 'Assistant', 'asssistant.a2@dvag.test', '22222', SharingTestUtil.assistantPartnerAccount.Id, null);

        //Check visibility without Assistant relations
        List<Account> assistant1Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr1);
        System.assertEquals(0, assistant1Customers.size());
        System.assertEquals(1, SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBX1user).size());
        
        List<Account> assistant2Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr2);
        System.assertEquals(0, assistant2Customers.size());
        System.assertEquals(1, SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBX2user).size());
        
        //Prepare Assistant data
        AssistantToAdvisor__c a1ToBx1 = SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX1user, assistantUsr1);                
        AssistantToAdvisor__c a1ToBx2 = SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX2user, assistantUsr1);
        AssistantToAdvisor__c a2ToBx1 = SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX1user, assistantUsr2);
        AssistantToAdvisor__c a2ToBx2 = SharingUtil.createAssistantToAdvisor(SharingTestUtil.vbBX2user, assistantUsr2);        
        List<AssistantToAdvisor__c> assistants = new List<AssistantToAdvisor__c>();
        assistants.add(a1ToBx1);
        assistants.add(a1ToBx2);
        assistants.add(a2ToBx1);
        assistants.add(a2ToBx2);
                                                                                  
        //Add assistant relations
        Test.startTest();
        insert assistants;
        //Remove assistant relation
        delete a1ToBx2;
        delete a2ToBx1;
        Test.stopTest();            
                
        //Check visibility
        assistant1Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr1);
        System.assertEquals(1, assistant1Customers.size());
        system.assertEquals(SharingTestUtil.vbBX1customerAccount.id,  assistant1Customers.get(0).Id);   
        
        assistant2Customers = SharingTestUtil.customerAccountsVisibleForUser(assistantUsr2);
        System.assertEquals(1, assistant2Customers.size());
        system.assertEquals(SharingTestUtil.vbBX2customerAccount.id,  assistant2Customers.get(0).Id);   
    }

      /* 
        FSCEC-1233: Sichtbarkeit für neue Vertreter
        (ohne 360 Grad Objekte)
        
        VB BX1 & BX2 mit jeweils 2 Kunden: 1 sichtbar und 1 versteckt für Vertreter
        VB BY1 & BY2 mit jeweils 2 Kunden: 1 sichtbar und 1 versteckt für Vertreter

        Vertreter 1: BY1 ist Vertreter für BX1
        Vertreter 2: BY2 ist Vertreter  für BX1 & BY1

        Vertreter BY1 sieht seine 2 Kunden und den 1, nicht-versteckten von BX1
        Vertreter BY2 sieht seine 2 Kunden und 2 Kunden von Hauptnutzern (je 1 nicht-verstecker von BX1 und BY1)

    */
    @IsTest
    static void basicVisibilityAddDeputy( ){
        SharingTestUtil.populateVbStructure();    
        
        User deputyUsr1 = SharingTestUtil.vbBY1user;
        User deputyUsr2 = SharingTestUtil.vbBY2user;

        List<Account> hiddenCustomers = new List<Account>();
        Account bx1HidddenCustomer = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbBX1user);
        bx1HidddenCustomer.HideForAssistantsAndDeputies__c = true;
        hiddenCustomers.add(bx1HidddenCustomer);
        
        Account bx2HidddenCustomer = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbBX2user);
        bx2HidddenCustomer.HideForAssistantsAndDeputies__c = true;
        hiddenCustomers.add(bx2HidddenCustomer);

        Account by1HidddenCustomer = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbBY1user);
        by1HidddenCustomer.HideForAssistantsAndDeputies__c = true;
        hiddenCustomers.add(by1HidddenCustomer);
        
        Account by2HidddenCustomer = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbBY2user);
        by2HidddenCustomer.HideForAssistantsAndDeputies__c = true;
        hiddenCustomers.add(by2HidddenCustomer);        
        
        //Check visibility without Deputy relations        
        System.assertEquals(1,SharingTestUtil.customerAccountsVisibleForUser(deputyUsr1).size());        
        System.assertEquals(1,SharingTestUtil.customerAccountsVisibleForUser(deputyUsr2).size());        

        //Prepare Deputy data
        List<DeputyToAdvisor__c> deputies = new List<DeputyToAdvisor__c>();
        deputies.add(SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBX1user, deputyUsr1));                
        deputies.add(SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBX1user, deputyUsr2));
        deputies.add(SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBY1user, deputyUsr2));                        
                                                                  
        //Add deputy relations
        Test.startTest();
        insert hiddenCustomers;
        insert deputies;
        Test.stopTest();

        /*
        //Print Group Members for Debugging
        Set<Id> accIds = new Set<Id>();
        accIds.add(SharingTestUtil.leafAX1CustomerAccount.Id);
        accIds.add(SharingTestUtil.leafAX2CustomerAccount.Id);
        accIds.add(SharingTestUtil.leafAY1CustomerAccount.Id);
        accIds.add(SharingTestUtil.leafAY2CustomerAccount.Id);
        SharingTestUtil.printAccountGroupSharesWithMembers(accIds);
        */

        //Check visibility with deputy relations
        Map<Id,Account> deputy1Customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyUsr1));
        //Vertreter BY1 sieht seine 2 Kunden und den 1, nicht-versteckten von BX1
        System.assertNotEquals(null, deputy1Customers.get(SharingTestUtil.vbBY1customerAccount.Id));
        System.assertNotEquals(null, deputy1Customers.get(by1HidddenCustomer.Id));
        System.assertNotEquals(null, deputy1Customers.get(SharingTestUtil.vbBX1customerAccount.Id));
        System.assertEquals(3, deputy1Customers.size());

        Map<Id,Account> deputy2Customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyUsr2));
        //Vertreter BY2 sieht seine 2 Kunden und 2 Kunden von Hauptnutzern (je 1 nicht-verstecker von BX1 und BY1)
        System.assertNotEquals(null, deputy2Customers.get(SharingTestUtil.vbBY2customerAccount.Id));
        System.assertNotEquals(null, deputy2Customers.get(by2HidddenCustomer.Id));
        System.assertNotEquals(null, deputy2Customers.get(SharingTestUtil.vbBX1customerAccount.Id));
        System.assertNotEquals(null, deputy2Customers.get(SharingTestUtil.vbBY1customerAccount.Id));    
        System.assertEquals(4, deputy2Customers.size());
    }

    /* 
        FSCEC-1234: Sichtbarkeit Akten nach entfernen eines Vertreters
        (ohne 360 Grad Objekte)
        
        VB BX1 & BX2 mit jeweils 1 Kunden

        BY1 ist Vertreter für BX1 & BX2        
        BY2 ist Vertreter für BX1 & BX2
        
        BY1 sieht Kunden BY1 & BX1 / BX2
        BY2 sieht Kunden BY2 & BX1 / BX2
        (durch vorhergehende Tests sichergestellt - ggf. in Test Struktur verschieben?)

        Entfernen von Beziehung Vertreter BY1 -> BX2
        Entfernen von Beziehung Vertreter BY2 -> BX1

        Verteter BY1 sieht nur Kunden BY1 und BX1
        Verteter BY2 sieht nur Kunden BY2 und BX2
    */
    @IsTest
    static void basicVisibilityDeleteDeputy( ){
        SharingTestUtil.populateVbStructure();    
        User deputyUsr1 = SharingTestUtil.vbBY1user;
        User deputyUsr2 = SharingTestUtil.vbBY2user;
        
        //Prepare Deputy data
        DeputyToAdvisor__c dBy1ToBx1 = SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBX1user, deputyUsr1);                
        DeputyToAdvisor__c dBy1ToBx2 = SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBX2user, deputyUsr1);
        DeputyToAdvisor__c dBy2ToBx1 = SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBX1user, deputyUsr2);
        DeputyToAdvisor__c dBy2ToBx2 = SharingUtil.createDeputyToAdvisor(SharingTestUtil.vbBX2user, deputyUsr2);        
        
        List<DeputyToAdvisor__c> deputies = new List<DeputyToAdvisor__c>(); 
        deputies.add(dBy1ToBx1);
        deputies.add(dBy1ToBx2);
        deputies.add(dBy2ToBx1);
        deputies.add(dBy2ToBx2);
                                                                                  
        //Add assistant relations
        Test.startTest();
        insert deputies;
        //Remove assistant relation
        delete dBy1ToBx2;
        delete dBy2ToBx1;
        Test.stopTest();            
                
        //Check visibility with resulting deputy relations
        Map<Id,Account> deputy1Customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyUsr1));
        //Verteter BY1 sieht nur Kunden BY1 und BX1        
        System.assertNotEquals(null, deputy1Customers.get(SharingTestUtil.vbBY1customerAccount.Id));
        System.assertNotEquals(null, deputy1Customers.get(SharingTestUtil.vbBX1customerAccount.Id));
        System.assertEquals(2, deputy1Customers.size());

        Map<Id,Account> deputy2Customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyUsr2));
        //Verteter BY2 sieht nur Kunden BY2 und BX2
        System.assertNotEquals(null, deputy2Customers.get(SharingTestUtil.vbBY2customerAccount.Id));
        System.assertNotEquals(null, deputy2Customers.get(SharingTestUtil.vbBX2customerAccount.Id));
        System.assertEquals(2, deputy2Customers.size());
        
    
    }

     /* 
        FSCEC-1239: Sichtbarkeit Akten Mehrfachbetreuung
        (ohne 360 Grad Objekte)        
        
        - Kunden X, Y und Z mehrfachbetreut durch 2 VBs (BX1 & BY1)        
        - AssistentX -> BX1 
        - AssistentY -> BY1
        - BX2 vertritt BX1
        - BY2 vertritt BY1
        
        Zusätzlich, aus dem allgemeinen Testdaten-Setup
        - VB BX vertritt VB AX
        - VB BY vertritt VB BX
        
        1. Kunde X ist mehrfachbetreut durch BX1 & BY1
            a) BX1 & BY1 sehen den Kunden beide
            b) Assistenten X & Y sehen den Kunden
            c) Vertreter BX2 & BY2  sehen den Kunden
            d) Überstellte BX, BY und B sehen den Kunden

        2. Kunde Y (ausgeblendet für Assistenten&Vertreter), mehrfachbetreut durch BX1 & BY1
            a) BX1 & BY1 sehen den Kunden beide
            b) Assistenten X & Y sehen den Kunden nicht
            c) Vertreter BX2 & BY2  sehen den Kunden nicht
            d) Überstellte BX, BY und B sehen den Kunden

        3. Kunde Z (ausgeblendet für Struktursicht), mehrfachbetreut durch BX1 & BY1
            a) BX1 & BY1 sehen den Kunden beide
            b) Assistenten X & Y sehen den Kunden
            c) Vertreter BX2 & BY2  sehen den Kunden
            d) Überstellte BX, BY und B sehen den Kunden nicht 

    */
    @IsTest
    static void basicVisibilityMultiOwner() {
        SharingTestUtil.populateVbStructure();
        User integrationUser = TestDataUtility.getIntegrationTestUser();
        
        User vbBX1 = SharingTestUtil.vbBX1user;
        User vbBY1 = SharingTestUtil.vbBY1user;
        User deputyX = SharingTestUtil.vbBX2user;
        User deputyY = SharingTestUtil.vbBY2user;
        
        List<Account> customers = new List<Account>();
        //Prepare Multi-Owner Customers
        Account customerX = SharingTestUtil.createCustomerAccount(vbBX1);
        customerX.MultipleOwners__c = true;
        customers.add(customerX);
        System.debug('customerX: ' + customerX.Name + ', ExtCustomerNumber__c ' + customerX.ExtCustomerNumber__c + ', Assistant/Deputy: '+  customerX.HideForAssistantsAndDeputies__c + ', Hierarchy: ' + customerX.HideForHierarchy__c);
        
        Account customerY = SharingTestUtil.createCustomerAccount(vbBY1);
        customerY.MultipleOwners__c = true;
        customerY.HideForAssistantsAndDeputies__c = true;        
        customers.add(customerY);
        System.debug('customerY: ' + customerY.Name + ', ExtCustomerNumber__c ' + customerY.ExtCustomerNumber__c + ', Assistant/Deputy: '+  customerY.HideForAssistantsAndDeputies__c + ', Hierarchy: ' + customerY.HideForHierarchy__c);
        
        Account customerZ = SharingTestUtil.createCustomerAccount(vbBX1);
        customerZ.MultipleOwners__c = true;
        customerZ.HideForHierarchy__c = true;
        customers.add(customerZ);
        System.debug('customerZ: ' + customerZ.Name + ', ExtCustomerNumber__c ' + customerZ.ExtCustomerNumber__c + ', Assistant/Deputy: '+  customerZ.HideForAssistantsAndDeputies__c + ', Hierarchy: ' + customerZ.HideForHierarchy__c);
        
        
        //Prepare Deputy data
        List<DeputyToAdvisor__c> deputies = new List<DeputyToAdvisor__c>(); 
        deputies.add(SharingUtil.createDeputyToAdvisor(vbBX1, deputyX));
        deputies.add(SharingUtil.createDeputyToAdvisor(vbBY1, deputyY));
        
        //Assistant data
        User assistantX;
        User assistantY;
        
        Test.startTest();
        
        System.runas(integrationUser) {
            upsert deputies UniqueKey__c;
            
            //Prepare Assistant data
            List<AssistantToAdvisor__c> assistants = new List<AssistantToAdvisor__c>(); 
            assistantX = SharingTestUtil.createFieldSalesContactUser('X', 'Assistant', 'asssistant.x@dvag.test', 'xxx', SharingTestUtil.assistantPartnerAccount.Id, null);
            assistantY = SharingTestUtil.createFieldSalesContactUser('Y', 'Assistant', 'asssistant.y@dvag.test', 'yyy', SharingTestUtil.assistantPartnerAccount.Id, null);
            assistants.add(SharingUtil.createAssistantToAdvisor(vbBX1, assistantX));
            assistants.add(SharingUtil.createAssistantToAdvisor(vbBY1, assistantY));        
            upsert assistants UniqueKey__c;
            upsert customers ExtCustomerNumber__c;
            
            List<AdvisorToCustomer__c> multiOwners  = new  List<AdvisorToCustomer__c>();
            multiOwners.add(SharingUtil.createAdvisorToCustomer(customerX, vbBX1));
            multiOwners.add(SharingUtil.createAdvisorToCustomer(customerX, vbBY1));
            multiOwners.add(SharingUtil.createAdvisorToCustomer(customerY, vbBX1));
            multiOwners.add(SharingUtil.createAdvisorToCustomer(customerY, vbBY1));
            multiOwners.add(SharingUtil.createAdvisorToCustomer(customerZ, vbBX1));
            multiOwners.add(SharingUtil.createAdvisorToCustomer(customerZ, vbBY1));
            upsert multiOwners UniqueKey__c;

            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
        }
        
        Test.stopTest();

        /*
        //Print Group Members for Debugging
        Set<Id> accIds = new Set<Id>();
        accIds.add(customerX.Id);
        accIds.add(customerY.Id);
        accIds.add(customerZ.Id);
        SharingTestUtil.printAccountGroupSharesWithMembers(accIds);
        */
                        
        //Get visible Customer Accounts
        //Owner VBs
        Map<Id,Account> vbBX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbBX1));
        Map<Id,Account> vbBY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbBY1));
        //Hierarchy
        Map<Id,Account> vbBXcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBXuser));
        Map<Id,Account> vbBYcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBYuser));
        Map<Id,Account> vbBcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbBuser));
        //Deputies
        Map<Id,Account> deputyXcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyX));
        Map<Id,Account> deputyYcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyY));
        //Assistants
        Map<Id,Account> assistantXcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantX));
        Map<Id,Account> assistantYcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantY));
        
        // 1. Kunde X ist mehrfachbetreut durch BX1 & BY1
        //     a) BX1 & BY1 sehen den Kunden beide
        System.assertNotEquals(null,vbBX1customers.get(customerX.Id));
        System.assertNotEquals(null,vbBY1customers.get(customerX.Id));
        //     b) Assistenten X & Y sehen den Kunden
        System.assertNotEquals(null,assistantXcustomers.get(customerX.Id));
        System.assertNotEquals(null,assistantYcustomers.get(customerX.Id));
        //     c) Vertreter BX2 & BY2  sehen den Kunden
        System.assertNotEquals(null,deputyXcustomers.get(customerX.Id));
        System.assertNotEquals(null,deputyYcustomers.get(customerX.Id));
        //     d) Überstellte BX, BY und B sehen den Kunden
        System.assertNotEquals(null,vbBXcustomers.get(customerX.Id));
        System.assertNotEquals(null,vbBYcustomers.get(customerX.Id));
        System.assertNotEquals(null,vbBcustomers.get(customerX.Id));

        // 2. Kunde Y (ausgeblendet für Assistenten&Vertreter), mehrfachbetreut durch BX1 & BY1
        //     a) BX1 & BY1 sehen den Kunden beide
        System.assertNotEquals(null,vbBX1customers.get(customerY.Id));
        System.assertNotEquals(null,vbBY1customers.get(customerY.Id));
        //     b) Assistenten X & Y sehen den Kunden nicht
        System.assertEquals(null,assistantXcustomers.get(customerY.Id));
        System.assertEquals(null,assistantYcustomers.get(customerY.Id));
        //     c) Vertreter BX2 & BY2 sehen den Kunden nicht
        System.assertEquals(null,deputyXcustomers.get(customerY.Id));
        System.assertEquals(null,deputyYcustomers.get(customerY.Id));
        //     d) Überstellte BX, BY und B sehen den Kunden
        System.assertNotEquals(null,vbBXcustomers.get(customerY.Id));
        System.assertNotEquals(null,vbBYcustomers.get(customerY.Id));
        System.assertNotEquals(null,vbBcustomers.get(customerY.Id));

        // 3. Kunde Z (ausgeblendet für Struktursicht), mehrfachbetreut durch BX1 & BY1
        //     a) BX1 & BY1 sehen den Kunden beide
        System.assertNotEquals(null,vbBX1customers.get(customerZ.Id));
        System.assertNotEquals(null,vbBY1customers.get(customerZ.Id));
        //     b) Assistenten X & Y sehen den Kunden
        System.assertNotEquals(null,assistantXcustomers.get(customerZ.Id));
        System.assertNotEquals(null,assistantYcustomers.get(customerZ.Id));
        //     c) Vertreter BX2 & BY2  sehen den Kunden
        System.assertNotEquals(null,deputyXcustomers.get(customerZ.Id));
        System.assertNotEquals(null,deputyYcustomers.get(customerZ.Id));
        //     d) Überstellte BX, BY und B sehen den Kunden nicht
        System.assertEquals(null,vbBXcustomers.get(customerZ.Id));
        System.assertEquals(null,vbBYcustomers.get(customerZ.Id));
        System.assertEquals(null,vbBcustomers.get(customerZ.Id)); 
        
        //Kontrolle/Gegenprobe Gesamtzahl sichtbare Kunden
        //VB BX1 & BY1
        // - 3 mehrfachbetreute Kunden
        //-  1 eigenen Kunden
        System.assertEquals(4,vbBX1customers.size());
        System.assertEquals(4,vbBY1customers.size());

        //Assistent X und Y
        // - 2 der 3 mehrfachbetreuten Kunden (1 ausgeblendet für Assistenten/Vertreter)
        // - 1 Kunden des jeweiligen Hauptnutzers
        System.assertEquals(3,assistantXcustomers.size());
        System.assertEquals(3,assistantYcustomers.size());

        //Vertreter X (VB BX2) und Y (VB BY2)
        // - 2 der 3 mehrfachbetreuten Kunden (1 ausgeblendet für Assistenten/Vertreter)
        // - 1 Kunden des jeweiligen Hauptnutzers
        // - jeweils 1 eigenen Kunden
        System.assertEquals(4,deputyXcustomers.size());
        System.assertEquals(4,deputyYcustomers.size());
        
        //Überstellte VB BX & BY
        // - jeweils 1 eigenen Kunden
        // - 2 exklusiven Kunden der jeweils unterstellten VBs (BX1/2 & BY1/2)
        // - zusätzlich 2 der 3 mehrfachbetreuten Kunden der Unterstellten VBs (1 ausgeblendet für Struktursicht)        
        // aus den allgmeinen Testdaten:        
        // - VB BX: zusätzlich 1 Kunde als Vertreter von VB AX
        // - VB BY: zusätzlich 1 Kunde als Vertreter von VB BX
        System.assertEquals(6,vbBXcustomers.size());
        System.assertNotEquals(Null, vbBXcustomers.get(SharingTestUtil.vbAXcustomerAccount.Id));
        System.assertEquals(6,vbBYcustomers.size());
        System.assertNotEquals(Null, vbBXcustomers.get(SharingTestUtil.vbBXcustomerAccount.Id));
        
        //Überstellter VB B
        // - 1 eigener Kunde
        // - 2 exklusive Kunden der direkt unterstellten Ebene "BX/BY"
        // - 4 exklusive Kunden der nächsten unterstellten Ebene "BX1/BX2/BY1/BY2)
        // - zusätzlich 2 der 3 mehrfachbetreuten Kunden der Unterstllten VBs (1 ausgeblendet für Struktursicht)
        System.assertEquals(9,vbBcustomers.size());
    }

    /* 
        FSCEC-1601/FSCEC-1663/FSCEC-1680

        Wechsel zwischen Ein/Ausblenden funktioniert nicht korrekt bei mehrfachbetreuten Kunden

        Kunde X, mehrfachbetreut, ausgeblendet für Alle
        - Sichtbarkeit prüfen: nur die 2 Owner
        - wird eingeblendet
        - Sichtbarkeit prüfen: Struktur, Hierarchie, Owner

        Kunde Y, mehrfachbetreut, eingeblendet für Alle
        - Sichtbarkeit prüfen: Struktur, Hierarchie, Owner
        - wird ausgeblendet
        - Sichtbarkeit prüfen: nur die 2 Owner

    */
    @IsTest
    static void updateMultiOwnerVisibility() {
        SharingTestUtil.populateVbStructure();
        //User integrationUser = TestDataUtility.getIntegrationTestUser();

        User vbAX1 = SharingTestUtil.vbAX1user;
        User vbAY1 = SharingTestUtil.vbAY1user;

        User assistantAX1 = SharingTestUtil.ass1ToAX1;
        User assistantAY1 = SharingTestUtil.ass3ToAY1;

        User deputyAX1 = SharingTestUtil.deputyXtoAx1;
        User deputyAY1 = SharingTestUtil.deputyYtoAy1;

        List<Account> customers = new List<Account>();
        //Multi Ownership Accounts        
        Account customerX = SharingTestUtil.multi4CustomerAccount;
        Account customerY = SharingTestUtil.multi1CustomerAccount;        

        /*
        // System.debug(' -- Members Before --');
        //Print Group Members for Debugging
        Set<Id> accIds = new Set<Id>();
        accIds.add(customerX.Id);
        accIds.add(customerY.Id);        
        SharingTestUtil.printAccountGroupSharesWithMembers(accIds);
        */

        //Get visible Customer Accounts & Check visibility BEFORE
        //Owner VBs
        Map<Id,Account> vbAX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbAX1));
        Map<Id,Account> vbAY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbAY1));
        //Hierarchy
        Map<Id,Account> managerAXcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbAXuser));
        Map<Id,Account> managerAYcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbAYuser));
        //Deputies
        Map<Id,Account> deputyAX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyAX1));
        Map<Id,Account> deputyAY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyAY1));
        //Assistants
        Map<Id,Account> assistantAX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantAX1));
        Map<Id,Account> assistantAY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantAY1));

        //CustomerX - Owners only
        System.assertNotEquals(Null, vbAX1customers.get(customerX.Id));
        System.assertNotEquals(Null, vbAY1customers.get(customerX.Id));
        //No Managers
        System.assertEquals(Null, managerAXcustomers.get(customerX.Id));
        System.assertEquals(Null, managerAYcustomers.get(customerX.Id));
        //No Deputies
        System.assertEquals(Null, deputyAX1customers.get(customerX.Id));
        System.assertEquals(Null, deputyAY1customers.get(customerX.Id));
        //No Assistants
        System.assertEquals(Null, assistantAX1customers.get(customerX.Id));
        System.assertEquals(Null, assistantAY1customers.get(customerX.Id));

        //CustomerY - All
        System.assertNotEquals(Null, vbAX1customers.get(customerY.Id));
        System.assertNotEquals(Null, vbAY1customers.get(customerY.Id));
        //No Managers
        System.assertNotEquals(Null, managerAXcustomers.get(customerY.Id));
        System.assertNotEquals(Null, managerAYcustomers.get(customerY.Id));
        //No Deputies
        System.assertNotEquals(Null, deputyAX1customers.get(customerY.Id));
        System.assertNotEquals(Null, deputyAY1customers.get(customerY.Id));
        //No Assistants
        System.assertNotEquals(Null, assistantAX1customers.get(customerY.Id));
        System.assertNotEquals(Null, assistantAY1customers.get(customerY.Id));                    

        Test.startTest();

        //System.runas(integrationUser) {                        
            customerX.HideForAssistantsAndDeputies__c = false;
            customerX.HideForHierarchy__c = false;
            update customerX;

            customerY.HideForAssistantsAndDeputies__c = true;
            customerY.HideForHierarchy__c = true;
            update customerY;
        //}

        Test.stopTest();
        // System.debug(' -- Members After --');
        // //Print Group Members for Debugging
        // accIds = new Set<Id>();
        // accIds.add(customerX.Id);
        // accIds.add(customerY.Id);        
        // SharingTestUtil.printAccountGroupSharesWithMembers(accIds);

        //Get visible Customer Accounts AFTER            
        //Owner VBs
        vbAX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbAX1));
        vbAY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbAY1));
        //Hierarchy
        managerAXcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbAXuser));
        managerAYcustomers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(SharingTestUtil.vbAYuser));
        //Deputies
        deputyAX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyAX1));
        deputyAY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyAY1));
        //Assistants
        assistantAX1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantAX1));
        assistantAY1customers = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantAY1));

        //Check Visibilty AFTER
        //CustomerX - All
        System.assertNotEquals(Null, vbAX1customers.get(customerX.Id));
        System.assertNotEquals(Null, vbAY1customers.get(customerX.Id));
        //Managers
        System.assertNotEquals(Null, managerAXcustomers.get(customerX.Id));
        System.assertNotEquals(Null, managerAYcustomers.get(customerX.Id));
        //Deputies
        System.assertNotEquals(Null, deputyAX1customers.get(customerX.Id));
        System.assertNotEquals(Null, deputyAY1customers.get(customerX.Id));
        //Assistants
        System.assertNotEquals(Null, assistantAX1customers.get(customerX.Id));
        System.assertNotEquals(Null, assistantAY1customers.get(customerX.Id));

        //CustomerY - Owners only
        System.assertNotEquals(Null, vbAX1customers.get(customerY.Id));
        System.assertNotEquals(Null, vbAY1customers.get(customerY.Id));
        //No Managers
        System.assertEquals(Null, managerAXcustomers.get(customerY.Id));
        System.assertEquals(Null, managerAYcustomers.get(customerY.Id));
        //No Deputies
        System.assertEquals(Null, deputyAX1customers.get(customerY.Id));
        System.assertEquals(Null, deputyAY1customers.get(customerY.Id));
        //No Assistants
        System.assertEquals(Null, assistantAX1customers.get(customerY.Id));
        System.assertEquals(Null, assistantAY1customers.get(customerY.Id));
                    
    }

    /************************************************************************************** 360 Objects - Use Case 1 **************************************************************************************/

    /*********************** Allgemeines zu 360° Objekte Use Case 1 *********************************
          
        360° Objekte Use Case 1:
        - Objekte, die über eine Lookup-Beziehung mit dem Kunden-Account verbunden sind
        - sind für alle Betreuer und deren Assistententen/Vertreter/Überstellte sichtbar
        
        Objekte Use Case 1
        - Financial Goals
        - Financial Accounts (nur Bankverbindungen, KEINE Bankprodukte!)
        - Income and Expenses
        - Assets and Liabilities        
        
        - Kunden X, Y und Z
            - jeder Kunde ist mehrfachbetreut durch 2 VBs (AX1 & AY1)
            - jeder Kunde hat 2 Datensätze (jeweils 1 je VB)
            - Kunde Y ist ausgeblendet für Assistanten/Vertreter
            - Kunde Z ist ausgeblendet für die Struktursicht

        - AssistentX ->  AX1
        - AssistentY ->  AY1
        
        - VertreterX (AX2 -> AX1) 
        - VertreterY (AY2 -> AY1)
        
        //Getestete Anforderungen
        Bei mehrfachbetreuten Kunden sind ALLE Datensätze von UseCase 1 Objekten sichtbar für 
        - alle betreuenden VBs
        - deren Hierarchie (sofern nicht ausgeblendet)
        - Assistenten / Vertreter (sofern nicht ausgeblendet)
        
        1. Ein Mehrfach-Betreuer VB sieht
            a) den eigenen Datensatz alle seiner mehrfachbetreuten Kunden 
            b) den Datensatz des weiteren Betreuers seines mehfachbetreuten Kunden
        2. Die Vertreter
            a) sehen je Betreuer einen Datensatz des mehrfachbetreuten KundenX
            b) sehen NICHT die Datensätze des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen je Betreuer einen Datensatz des für Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
        3. die Vorgesetzten
            a) sehen je Betreuer einen Datensatz des mehrfachbetreuten KundenX
            b) sehen je Betreuer einen Datensatz des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen NICHT die Datensätze des für die Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
    
    *******************************************************************************************************/
    
    /* 
       Financial Goals - Struktursicht
          
        360° Objekt Use Case 1
        - Hierarchie: Ja
        - Mehrfachbetreuung: Ja
        - Assistent/Vertreter: Ja
        
        //Getestete Anforderungen
        - Der VB sieht die FinGoals seiner eigenen Kunden
        - Überstellte VBs sehen zusätzlich die FinGoals der Kunden von unterstellten VBs
        - Die FinGoals der Kunden von VBs in "parallelen" Ästen der Struktur sind nicht sichtbar
        - Die FinGoals von aus der Struktursicht ausgeblendeten Kunden sind für überstellte VBs nicht sichtbar
        - Die FinGoals von aus der Struktursicht ausgeblendeten Kunden sind für den Betreuer-VBs sichtbar

        //Situation
        - VB AX & AY & AX1 & AX2 mit jeweils 1 Kunden
        - die Kunden von AX2 sind aus der Struktursicht ausgeblendet
        - jeder Kunde hat 2 Financial Goals
        
        //Struktursicht
        - VB A sieht die Objekte von AX, AX1 und AY
        - VB AX sieht die Kunden von AX und AX1
        - VB B sieht keines der Objekte
        - Keiner der Überstellten sieht die Objekte von VB AX2
    */
    @IsTest
    static void financialGoalHierarchy() {
        SharingTestUtil.populateVbStructure();        
        
        User integrationUser = TestDataUtility.getIntegrationTestUser();  
        
        User vbAX = SharingTestUtil.vbAXuser;
        Account vbAXAccount = SharingTestUtil.vbAXcustomerAccount;
        System.assert(!vbAXAccount.HideForHierarchy__c);
        
        User vbAY = SharingTestUtil.vbAYuser;
        Account vbAYAccount = SharingTestUtil.vbAYcustomerAccount;
        System.assert(!vbAYAccount.HideForHierarchy__c);
        
        User vbAX1 = SharingTestUtil.vbAX1user;
        Account vbAX1Account = SharingTestUtil.vbAX1customerAccount;    
        System.assert(!vbAX1Account.HideForHierarchy__c);                    
        
        /************************************** Create Financial Goals **************************************/
        List<FinServ__FinancialGoal__c> finGoalList = new List<FinServ__FinancialGoal__c>();        
        FinServ__FinancialGoal__c vbAXfinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAXAccount);
        finGoalList.add(vbAXfinancialGoal1);
        FinServ__FinancialGoal__c vbAXfinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAXAccount);
        finGoalList.add(vbAXfinancialGoal2);
        FinServ__FinancialGoal__c vbAYfinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAYAccount);
        finGoalList.add(vbAYfinancialGoal1);
        FinServ__FinancialGoal__c vbAYfinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAYAccount);
        finGoalList.add(vbAYfinancialGoal2);
        FinServ__FinancialGoal__c vbAX1financialGoal1 = SharingTestUtil.createFinancialGoal(vbAX1Account);
        finGoalList.add(vbAX1financialGoal1);
        FinServ__FinancialGoal__c vbAX1financialGoal2 = SharingTestUtil.createFinancialGoal(vbAX1Account);
        finGoalList.add(vbAX1financialGoal2);        

        //VB with 1 hidden customer
        User vbAX2 = SharingTestUtil.vbAX2user;
        Account vbAX2Account = SharingTestUtil.vbAX2customerAccount;
        FinServ__FinancialGoal__c vbAX2financialGoal = SharingTestUtil.createFinancialGoal(vbAX2Account);
        finGoalList.add(vbAX2financialGoal);
        Account vbAX2hiddenAccount;
        FinServ__FinancialGoal__c vbAX2hiddenFinancialGoal;

        List<AccountSharingCalculation__c> accSharesToInsert = new List<AccountSharingCalculation__c>();
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAXAccount));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAYAccount));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAX1Account));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAX2Account));        
        
        /**************************************  Start TEST  **************************************/
        Test.startTest();
        
        System.runas(integrationUser) {
                
            vbAX2hiddenAccount = SharingTestUtil.createCustomerAccount(vbAX2);
            vbAX2hiddenAccount.HideForHierarchy__c = true;
            insert vbAX2hiddenAccount;        
            vbAX2hiddenFinancialGoal = SharingTestUtil.createFinancialGoal(vbAX2hiddenAccount);
                    
            accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAX2hiddenAccount));
            finGoalList.add(vbAX2hiddenFinancialGoal);
            
            insert finGoalList;            
            upsert accSharesToInsert UniqueKey__c;
            
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
            Integer index = getRelatedObjectIndex('FinServ__FinancialGoal__c', '');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        }

        Test.stopTest();
        /**************************************  End TEST  **************************************/        
        
        /************************************** Check Financial Goals **************************************/        
        //VB A is superior to AX, AY, AX1 and AX2
        Map<Id, FinServ__FinancialGoal__c> visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(7, visibleFinGoals.size());
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAYfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAYfinancialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX2financialGoal.Id));
        //VB AX and A should NOT see the goal of AX2 hidden customer
        System.assertEquals(null,visibleFinGoals.get(vbAX2hiddenFinancialGoal.Id));

        //VB AX is on superior to AX1 and AX2, not AY
        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(5, visibleFinGoals.size());
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX2financialGoal.Id));
        //VB AX and A should NOT see the  goals of AX2 hidden customer
        System.assertEquals(null,visibleFinGoals.get(vbAX2hiddenFinancialGoal.Id));
        
        //VB AX2 should see the Financal goals of his own customer
        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(vbAX2);
        System.assertEquals(2, visibleFinGoals.size());
        System.assertNotEquals(null,visibleFinGoals.get(vbAX2financialGoal.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX2hiddenFinancialGoal.Id));
        
        //VB B is not superior to the others and should not see any Financial Goals
        System.assertEquals(0, SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbBuser).size());
    }

     /* 
        Financial Goals - Sichtbarkeit Vertreter/Assistenten
          
        360° Objekt Use Case 1
        - Hierarchie: Ja
        - Mehrfachbetreuung: Ja
        - Assistent/Vertreter: Ja

        //Ausgangslage
        - AX mit 2 Kunden 
            - 1 Kunde ausgeblendet für Vertreter/Assistenten
            - 2 Financial Goals je Kunde
            - AX ist AX1 überstellt
        - AX1 mit 2 Kunden
            - 1 Kunde ausgeblendet für Vertreter/Assistenten
            - 2 Financial Goals je Kunde

        - BX mit 1 Kunden und 2 Financial Goals
            - BX ist Vertreter von AX
        - BY mit 1 Kunden (ohne Financial Goals)
            - Vertreter von BX
        - B mit 1 Kunden (ohne Financial Goals)
            - ist BX und BY überstellt

        - ASS1 : Assistent für AX1
        - ASS2 : Assistent für AX        
        
        //Getestete Anforderungen
        1. Ein Vertreter sieht
            a) die FinGoals seiner eigenen Kunden
            b) die FinGoals der Kunden des Hauptnutzers
        2. Ein Vertreter sieht NICHT 
            a) die FinGoals von Kunden, die für Vertreter/Assistenten ausgeblendet sind
            b) die FinGoals von Kunden eines dem Hauptnutzer unterstellten VB
            c) die FinGoals von Kunden eines VBs, für den der Hauptnutzer seinerseits ein Vertreter ist
        3. Ein überstellter VB sieht nicht die Kunden eines Hauptnutzers, die ein VB in seiner Rolle als Vertreter dieses Hauptnutzers sieht
        
        4. Ein Assistent sieht die FinGoals der Kunden des Hauptnutzers
        5. Ein Assistent sieht NICHT 
            a) die FinGoals von Kunden eines dem Hauptnutzer unterstellten VB
            b) die FinGoals von Kunden, die für Vertreter/Assistenten ausgeblendet sind
        
    */
    @IsTest
    static void financialGoalDeputyAssistant() {
        SharingTestUtil.populateVbStructure();
        User integrationUser = TestDataUtility.getIntegrationTestUser();
        
        //Create financial goals
        List<FinServ__FinancialGoal__c> finGoalList = new List<FinServ__FinancialGoal__c>();        
        //AX mit 2 Kunden 
        //  - 1 Kunde ausgeblendet für Vertreter/Assistenten
        //  - 2 Financial Goals je Kunde        
        User vbAX = SharingTestUtil.vbAXuser;        
        Account vbAXaccount = SharingTestUtil.vbAXcustomerAccount;
        FinServ__FinancialGoal__c vbAXfinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAXaccount);
        finGoalList.add(vbAXfinancialGoal1);
        FinServ__FinancialGoal__c vbAXfinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAXaccount);
        finGoalList.add(vbAXfinancialGoal2);        
        //Define here for scope, create & insert later
        Account vbAXhiddenAccount; 
        FinServ__FinancialGoal__c vbAXhiddenFinancialGoal1;
        FinServ__FinancialGoal__c vbAXhiddenFinancialGoal2;

        //AX1 mit 2 Kunden
        //  - 1 Kunde ausgeblendet für Vertreter/Assistenten
        //  - 2 Financial Goals je Kunde        
        User vbAX1 = SharingTestUtil.vbAX1user;        
        Account vbAX1account = SharingTestUtil.vbAX1customerAccount;
        FinServ__FinancialGoal__c vbAX1financialGoal1 = SharingTestUtil.createFinancialGoal(vbAX1account);
        finGoalList.add(vbAX1financialGoal1);
        FinServ__FinancialGoal__c vbAX1financialGoal2 = SharingTestUtil.createFinancialGoal(vbAX1account);
        finGoalList.add(vbAX1financialGoal2);     
        //Define here for scope, create & insert later
        Account vbAX1hiddenAccount;         
        FinServ__FinancialGoal__c vbAX1hiddenFinancialGoal1;
        FinServ__FinancialGoal__c vbAX1hiddenFinancialGoal2;    

        //BX mit 1 Kunden und 2 Financial Goals
        User vbBX = SharingTestUtil.vbBXuser; 
        Account vbBXaccount = SharingTestUtil.vbBXcustomerAccount;
        FinServ__FinancialGoal__c vbBXfinancialGoal1 = SharingTestUtil.createFinancialGoal(vbBXaccount);
        finGoalList.add(vbBXfinancialGoal1);
        FinServ__FinancialGoal__c vbBXfinancialGoal2 = SharingTestUtil.createFinancialGoal(vbBXaccount);
        finGoalList.add(vbBXfinancialGoal2);        

        List<AccountSharingCalculation__c> accSharesToInsert = new List<AccountSharingCalculation__c>();
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAXaccount));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAX1Account));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbBXaccount));
        
        
        /**************************************  Start TEST  **************************************/
        Test.startTest();
        
        System.runas(integrationUser) {        
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());

            //AX1  - 1 Kunde ausgeblendet für Vertreter/Assistenten mit 2 Financial Goals
            vbAX1hiddenAccount = SharingTestUtil.createCustomerAccount(vbAX1);
            vbAX1hiddenAccount.HideForAssistantsAndDeputies__c = true;
            insert vbAX1hiddenAccount;
            accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAX1hiddenAccount));
            vbAX1hiddenFinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAX1hiddenAccount);
            finGoalList.add(vbAX1hiddenFinancialGoal1);
            vbAX1hiddenFinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAX1hiddenAccount);                              
            finGoalList.add(vbAX1hiddenFinancialGoal2);

            //AX - 1 Kunde ausgeblendet für Vertreter/Assistenten mit 2 Financial Goals
            vbAXhiddenAccount = SharingTestUtil.createCustomerAccount(vbAX);
            vbAXhiddenAccount.HideForAssistantsAndDeputies__c = true;
            insert vbAXhiddenAccount;
            accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAXhiddenAccount));
            vbAXhiddenFinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAXhiddenAccount);
            finGoalList.add(vbAXhiddenFinancialGoal1);
            vbAXhiddenFinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAXhiddenAccount);                              
            finGoalList.add(vbAXhiddenFinancialGoal2);                    
            
            insert finGoalList;
            upsert accSharesToInsert UniqueKey__c;

            Integer index = getRelatedObjectIndex('getRelatedObjectIndex', '');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        }

        Test.stopTest();
        
        /**************************************  End TEST  **************************************/

        // Print Group Members for Debugging
        // Set<Id> accIds = new Set<Id>();
        // accIds.add(vbAXaccount.Id);
        // accIds.add(vbAX1Account.Id);
        // accIds.add(vbBXaccount.Id);
        // SharingTestUtil.printAccountGroupSharesWithMembers(accIds);             
        
        //  1. Ein Vertreter (BX) sieht
        Map<Id,FinServ__FinancialGoal__c> visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(vbBX);        
        //     a) die FinGoals seiner eigenen Kunden
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        //     b) die FinGoals der Kunden des Hauptnutzers (AX)
        System.assertNotEquals(null,visibleFinGoals.get(vbBXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbBXfinancialGoal2.Id));        
        System.assertEquals(4, visibleFinGoals.size());        

        // 2. Ein Vertreter sieht NICHT 
        //     a) die FinGoals von Kunden, die für Vertreter/Assistenten ausgeblendet sind
        // BX vertritt ist AX, dieser hat 2 Kunden (1 ausgeblendet) mit je 2 FinGoals
        System.assertEquals(null,visibleFinGoals.get(vbAXhiddenFinancialGoal1.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAXhiddenFinancialGoal2.Id));
        //     b) die FinGoals von Kunden eines dem Hauptnutzer unterstellten VB
        // AX1 ist AX unterstellt, BX vertritt AX
        System.assertEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));
        //     c) die FinGoals von Kunden eines VBs, für den der Hauptnutzer seinerseits ein Vertreter ist
        // BY vertritt BX, BX vertritt AX
        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbBYuser);
        System.assertEquals(2, visibleFinGoals.size());
        System.assertNotEquals(null,visibleFinGoals.get(vbBXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbBXfinancialGoal2.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        
        // 3. Ein überstellter VB sieht nicht die Kunden eines Hauptnutzers, die ein VB in seiner Rolle als Vertreter dieses Hauptnutzers sieht        
        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbBuser);
        System.assertNotEquals(null,visibleFinGoals.get(vbBXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbBXfinancialGoal2.Id));
        System.assertEquals(2, visibleFinGoals.size());
    
        // 4. Ein Assistent sieht die FinGoals der Kunden des Hauptnutzers
        // ASS1 ist Assistent für AX1
        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.ass1toAX1);
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));
        System.assertEquals(2, visibleFinGoals.size());
        
        // 5. Ein Assistent sieht NICHT
        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.ass2toAX);
        //     a) die FinGoals von Kunden eines dem Hauptnutzer unterstellten VB
        // ASS2 ist Assistent für AX, AX1 ist AX unterstellt
        System.assertEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        System.assertEquals(2, visibleFinGoals.size());
        //     b) die FinGoals von Kunden, die für Vertreter/Assistenten ausgeblendet sind
        System.assertEquals(null,visibleFinGoals.get(vbAX1hiddenFinancialGoal1.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAX1hiddenFinancialGoal2.Id));

    }


    /* 
        Financial Goals - Sichtbarkeit Mehrfachbetreuung          
        (360° Objekt Use Case 1)

        - Kunden X, Y und Z
            - jeder Kunde ist mehrfachbetreut durch 2 VBs (AX1 & AY1)
            - jeder Kunde hat 2 Datensätze (jeweils 1 je VB)
            - Kunde Y ist ausgeblendet für Assistanten/Vertreter
            - Kunde Z ist ausgeblendet für die Struktursicht

        - AssistentX ->  AX1
        - AssistentY ->  AY1
        
        - VertreterX (AX2 -> AX1) 
        - VertreterY (AY2 -> AY1)
        
        //Getestete Anforderungen
        Bei mehrfachbetreuten Kunden sind ALLE Datensätze von UseCase 1 Objekten sichtbar für 
        - alle betreuenden VBs
        - deren Hierarchie (sofern nicht ausgeblendet)
        - Assistenten / Vertreter (sofern nicht ausgeblendet)
                
        1. Kunde X ist mehrfachbetreut durch AX1 & AY1
            a) AX1 & AY1 sehen beide jeweils 2 Financial Goals des KundenX
            b) Assistenten X & Y sehen beide jeweils die 2 Financial Goals des Kunden
            c) Vertreter X & 2 sehen beide jeweils die 2 Financial Goals des Kunden
            d) Überstellte AX, AY sehen beide jeweils die 2 Financial Goals des Kunden

        2. Kunde Y (ausgeblendet für Assistenten & Vertreter), mehrfachbetreut durch AX1 & AY1
            a) AX1 & AY1 sehen beide jeweils 2 Financial Goals des KundenX
            b) Assistenten X & Y sehen kein Financial Goal des Kunden
            c) Vertreter X & 2 sehen kein Financial Goal des Kunden
            d) Überstellte AX, AY beide jeweils die 2 Financial Goals des Kunden

        3. Kunde Z (ausgeblendet für Struktursicht), mehrfachbetreut durch BX1 & BY1
            a) AX1 & AY1 sehen beide jeweils 2 Financial Goals des KundenX
            b) Assistenten X & Y sehen beide jeweils die 2 Financial Goals des Kunden
            c) Vertreter X & 2 sehen beide jeweils die 2 Financial Goals des Kunden
            d) Überstellte AX, AY sehen kein Financial Goals des Kunden    
    */
    @IsTest
    static void financialGoalMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbAX1 = SharingTestUtil.vbAX1user;
        User vbAY1 = SharingTestUtil.vbAY1user;
        User vbAX = SharingTestUtil.vbAXuser;
        User vbAY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerX = SharingTestUtil.multi1CustomerAccount;
        Account customerY = SharingTestUtil.multi2CustomerAccount;
        Account customerZ = SharingTestUtil.multi3CustomerAccount;

        List<FinServ__FinancialGoal__c> finGoalList = new List<FinServ__FinancialGoal__c>();

        FinServ__FinancialGoal__c custX_AX1finGoal = SharingTestUtil.createFinancialGoal(customerX);
        custX_AX1finGoal.OwnerId = vbAX1.Id;
        finGoalList.add(custX_AX1finGoal);

        FinServ__FinancialGoal__c custX_AY1finGoal = SharingTestUtil.createFinancialGoal(customerX);
        custX_AY1finGoal.OwnerId = vbAY1.Id;
        finGoalList.add(custX_AY1finGoal);

        FinServ__FinancialGoal__c custY_AX1finGoal = SharingTestUtil.createFinancialGoal(customerY);
        custY_AX1finGoal.OwnerId = vbAX1.Id;
        finGoalList.add(custY_AX1finGoal);

        FinServ__FinancialGoal__c custY_AY1finGoal = SharingTestUtil.createFinancialGoal(customerY);
        custY_AY1finGoal.OwnerId = vbAY1.Id;
        finGoalList.add(custY_AY1finGoal);

        FinServ__FinancialGoal__c custZ_AX1finGoal = SharingTestUtil.createFinancialGoal(customerZ);
        custZ_AX1finGoal.OwnerId = vbAX1.Id;
        finGoalList.add(custZ_AX1finGoal);

        FinServ__FinancialGoal__c custZ_AY1finGoal = SharingTestUtil.createFinancialGoal(customerZ);
        custZ_AY1finGoal.OwnerId = vbAY1.Id;
        finGoalList.add(custZ_AY1finGoal);
        
        Test.startTest();
                
            insert finGoalList;
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
            Integer index = getRelatedObjectIndex('FinServ__FinancialGoal__c', '');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        //Print Group Members for Debugging
        // Set<Id> accIds = new Set<Id>();
        // accIds.add(customerX.Id);
        // accIds.add(customerY.Id);
        // accIds.add(customerZ.Id);
        // SharingTestUtil.printAccountGroupSharesWithMembers(accIds);                                    
        
        Map<Id,FinServ__FinancialGoal__c> vbAX1finGoals = SharingTestUtil.financialGoalsVisibleForUser(vbAX1);
        System.assertEquals(6,vbAX1finGoals.size()); //2 finGoals von 3 Customers
        Map<Id,FinServ__FinancialGoal__c> vbAY1finGoals = SharingTestUtil.financialGoalsVisibleForUser(vbAY1);
        System.assertEquals(6,vbAY1finGoals.size()); //2 finGoals von 3 Customers
        //Assistants
        Map<Id,FinServ__FinancialGoal__c> assistantXfinGoals = SharingTestUtil.financialGoalsVisibleForUser(assistantX);
        System.assertEquals(4, assistantXfinGoals.size()); //2 finGoals von 2 Customers (1 ausgeblendet)        
        Map<Id,FinServ__FinancialGoal__c> assistantYfinGoals = SharingTestUtil.financialGoalsVisibleForUser(assistantY);
        System.assertEquals(4, assistantYfinGoals.size()); //2 finGoals von 2 Customers (1 ausgeblendet)        
        //Deputies
        Map<Id,FinServ__FinancialGoal__c> deputyXfinGoals = SharingTestUtil.financialGoalsVisibleForUser(deputyX);
        System.assertEquals(4, deputyXfinGoals.size()); //2 finGoals von 2 Customers (1 ausgeblendet)        
        Map<Id,FinServ__FinancialGoal__c> deputyYfinGoals = SharingTestUtil.financialGoalsVisibleForUser(deputyY);
        System.assertEquals(4, deputyYfinGoals.size()); //2 finGoals von 2 Customers (1 ausgeblendet)        
        //Hierarchy
        Map<Id,FinServ__FinancialGoal__c> vbAXfinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(4, vbAXfinGoals.size()); //2 finGoals von 2 Customers (1 ausgeblendet)        
        Map<Id,FinServ__FinancialGoal__c> vbAYfinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbAYuser);
        System.assertEquals(4, vbAYfinGoals.size()); //2 finGoals von 2 Customers (1 ausgeblendet)

        // 1. Kunde X ist mehrfachbetreut durch AX1 & AY1
        //     a) AX1 & AY1 sehen beide jeweils 2 Financial Goals des KundenX        
        System.assertNotEquals(null,vbAX1finGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,vbAX1finGoals.get(custX_AY1finGoal.Id));
        System.assertNotEquals(null,vbAY1finGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,vbAY1finGoals.get(custX_AY1finGoal.Id));
        //     b) Assistenten X & Y sehen beide jeweils die 2 Financial Goals des Kunden
        System.assertNotEquals(null,assistantXfinGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,assistantXfinGoals.get(custX_AY1finGoal.Id));
        System.assertNotEquals(null,assistantYfinGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,assistantYfinGoals.get(custX_AY1finGoal.Id));
        //     c) Vertreter X & 2 sehen beide jeweils die 2 Financial Goals des Kunden
        System.assertNotEquals(null,deputyXfinGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,deputyXfinGoals.get(custX_AY1finGoal.Id));
        System.assertNotEquals(null,deputyYfinGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,deputyYfinGoals.get(custX_AY1finGoal.Id));
        //     d) Überstellte AX, AY sehen beide jeweils die 2 Financial Goals des Kunden
        System.assertNotEquals(null,vbAXfinGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,vbAXfinGoals.get(custX_AY1finGoal.Id));
        System.assertNotEquals(null,vbAYfinGoals.get(custX_AX1finGoal.Id));
        System.assertNotEquals(null,vbAYfinGoals.get(custX_AY1finGoal.Id));

        // 2. Kunde Y (ausgeblendet für Assistenten & Vertreter), mehrfachbetreut durch AX1 & AY1
        //     a) AX1 & AY1 sehen beide jeweils 2 Financial Goals des KundenX
        System.assertNotEquals(null,vbAX1finGoals.get(custY_AX1finGoal.Id));
        System.assertNotEquals(null,vbAX1finGoals.get(custY_AY1finGoal.Id));
        System.assertNotEquals(null,vbAY1finGoals.get(custY_AX1finGoal.Id));
        System.assertNotEquals(null,vbAY1finGoals.get(custY_AY1finGoal.Id));
        //     b) Assistenten X & Y sehen kein Financial Goal des Kunden
        System.assertEquals(null,assistantXfinGoals.get(custY_AX1finGoal.Id));
        System.assertEquals(null,assistantXfinGoals.get(custY_AY1finGoal.Id));
        System.assertEquals(null,assistantYfinGoals.get(custY_AX1finGoal.Id));
        System.assertEquals(null,assistantYfinGoals.get(custY_AY1finGoal.Id));        
        //     c) Vertreter X & 2 sehen kein Financial Goal des Kunden
        System.assertEquals(null,deputyXfinGoals.get(custY_AX1finGoal.Id));
        System.assertEquals(null,deputyXfinGoals.get(custY_AY1finGoal.Id));
        System.assertEquals(null,deputyYfinGoals.get(custY_AX1finGoal.Id));
        System.assertEquals(null,deputyYfinGoals.get(custY_AY1finGoal.Id));
        //     d) Überstellte AX, AY beide jeweils die 2 Financial Goals des Kunden
        System.assertNotEquals(null,vbAXfinGoals.get(custY_AX1finGoal.Id));
        System.assertNotEquals(null,vbAXfinGoals.get(custY_AY1finGoal.Id));
        System.assertNotEquals(null,vbAYfinGoals.get(custY_AX1finGoal.Id));
        System.assertNotEquals(null,vbAYfinGoals.get(custY_AY1finGoal.Id));

        // 3. Kunde Z (ausgeblendet für Struktursicht), mehrfachbetreut durch BX1 & BY1
        //     a) AX1 & AY1 sehen beide jeweils 2 Financial Goals des KundenX
        System.assertNotEquals(null,vbAX1finGoals.get(custZ_AX1finGoal.Id));
        System.assertNotEquals(null,vbAX1finGoals.get(custZ_AY1finGoal.Id));
        System.assertNotEquals(null,vbAY1finGoals.get(custZ_AX1finGoal.Id));
        System.assertNotEquals(null,vbAY1finGoals.get(custZ_AY1finGoal.Id));
        //     b) Assistenten X & Y sehen beide jeweils die 2 Financial Goals des Kunden
        System.assertNotEquals(null,assistantXfinGoals.get(custZ_AX1finGoal.Id));
        System.assertNotEquals(null,assistantXfinGoals.get(custZ_AY1finGoal.Id));
        System.assertNotEquals(null,assistantYfinGoals.get(custZ_AX1finGoal.Id));
        System.assertNotEquals(null,assistantYfinGoals.get(custZ_AY1finGoal.Id));
        //     c) Vertreter X & 2 sehen beide jeweils die 2 Financial Goals des Kunden
        System.assertNotEquals(null,deputyXfinGoals.get(custZ_AX1finGoal.Id));
        System.assertNotEquals(null,deputyXfinGoals.get(custZ_AY1finGoal.Id));
        System.assertNotEquals(null,deputyYfinGoals.get(custZ_AX1finGoal.Id));
        System.assertNotEquals(null,deputyYfinGoals.get(custZ_AY1finGoal.Id));        
        //     d) Überstellte AX, AY sehen kein Financial Goals des Kunden
        System.assertEquals(null,vbAXfinGoals.get(custZ_AX1finGoal.Id));
        System.assertEquals(null,vbAXfinGoals.get(custZ_AY1finGoal.Id));
        System.assertEquals(null,vbAYfinGoals.get(custZ_AX1finGoal.Id));
        System.assertEquals(null,vbAYfinGoals.get(custZ_AY1finGoal.Id));
        
    }

    
    /************************************************************************************** 360 Objects - Use Case 2 **************************************************************************************/
    
    /*********************** Allgemeines zu 360° Objekte Use Case 2 *********************************
          
        360° Objekte Use Case 2:
        - Objekte, die über eine Lookup-Beziehung mit dem Kunden-Account verbunden sind
        - sind nur für einen Betreuer (dem der Datensatz gehört) und dessen Assistententen/Vertreter/Überstellte sichtbar
        
        Objekte (Batch)
        - Insurance Policies
        - Financial Accounts (alle Bankprodukte, ausser General Accounts -> Bankverbindungen!)
        
        - Kunden X, Y und Z
            - jeder Kunde ist mehrfachbetreut durch 2 VBs (AX1 & AY1)
            - jeder Kunde hat 2 Datensätze (jeweils 1 je VB)
            - Kunde Y ist ausgeblendet für Assistanten/Vertreter
            - Kunde Z ist ausgeblendet für die Struktursicht

        - AssistentX ->  AX1
        - AssistentY ->  AY1
        
        - VertreterX (AX2 -> AX1) 
        - VertreterY (AY2 -> AY1)
        
        //Getestete Anforderungen
        Bei mehrfachbetreuten Kunden sind die Datensätze von UseCase 2 Objekten sichtbar für 
        - den jeweiligen Datensatz-Owner
        - dessen Hierarchie (sofern nicht ausgeblendet)
        - dessen Assistenten / Vertreter (sofern nicht ausgeblendet)
        
        1. Ein Mehrfach-Betreuer VB sieht
            a) den jeweils eigenen Datensatz alle seiner mehrfachbetreuten Kunden 
            b) NICHT den Datensatz des weiteren Betreuers seines mehfachbetreuten Kunden
        2. Die Vertreter
            a) sehen die Datensätze des Hauptnutzers des mehrfachbetreuten KundenX
            b) sehen NICHT die Datensätze des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen die Datensätze des Hauptnutzers des für Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
        3. die Vorgesetzten
            a) sehen die Datensätze des Hauptnutzers des mehrfachbetreuten KundenX
            b) sehen die Datensätze des Hauptnutzers des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen NICHT die Datensätze des für die Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
    
    *******************************************************************************************************/
    


    @isTest
    static void relatedObjectOwnership() {
        SharingTestUtil.populateVbStructure();
        
        User vbA = SharingTestUtil.vbAuser;
        User vbB = SharingTestUtil.vbBuser;
        
        //create a customer account
        Account customer = SharingTestUtil.createCustomerAccount(vbA);
        customer.MultipleOwners__c = true;
        insert customer;        

        //share with 2 VBs
        List<AdvisorToCustomer__c> adv2Cst = new List<AdvisorToCustomer__c>();
        adv2Cst.add(SharingUtil.createAdvisorToCustomer(customer, vbA));
        adv2Cst.add(SharingUtil.createAdvisorToCustomer(customer, vbB));
        insert adv2Cst;
        
        //for each VB, create:
        List<FinServ__FinancialAccount__c> financialAccounts = new List<FinServ__FinancialAccount__c>();
        Id generalAccountRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdGeneralAccount();
        //1 banking account
        FinServ__FinancialAccount__c generalAccountA = SharingTestUtil.createFinancialAccount(customer,vbA,generalAccountRtId,'GeneralAcc A');
        financialAccounts.add(generalAccountA);
        FinServ__FinancialAccount__c generalAccountB = SharingTestUtil.createFinancialAccount(customer,vbB,generalAccountRtId,'GeneralAcc B');
        financialAccounts.add(generalAccountB);
        //1 financial account
        FinServ__FinancialAccount__c bankProductA = SharingTestUtil.createInvestmentAccount(customer,vbA);
        financialAccounts.add(bankProductA);
        FinServ__FinancialAccount__c bankProductB = SharingTestUtil.createInvestmentAccount(customer,vbB);
        financialAccounts.add(bankProductB);
        insert financialAccounts;
        
        List<FinServ__FinancialAccount__c>  finAccs;
        
        Test.startTest();                       
        
        customer.ownerId = vbB.Id;
        update customer;

        Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'GeneralAccount');
        Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'InvestmentAccount');
        Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        Map<Id,FinServ__FinancialAccount__c> accsVbA = SharingTestUtil.financialAccountsVisibleForUser(vbA);
        System.assertEquals(3, accsVbA.size());
        System.assertNotEquals(null, accsVbA.get(generalAccountA.Id));
        System.assertNotEquals(null, accsVbA.get(generalAccountB.Id));
        System.assertNotEquals(null, accsVbA.get(bankProductA.Id));
        System.assertEquals(null, accsVbA.get(bankProductB.Id));
        Map<Id,FinServ__FinancialAccount__c> accsVbB = SharingTestUtil.financialAccountsVisibleForUser(vbB);
        System.assertEquals(3, accsVbB.size());
        System.assertNotEquals(null, accsVbB.get(generalAccountA.Id));
        System.assertNotEquals(null, accsVbB.get(generalAccountB.Id));
        System.assertEquals(null, accsVbB.get(bankProductA.Id));
        System.assertNotEquals(null, accsVbB.get(bankProductB.Id));

    }

    /* 
    *   Sichtbarkeit bei Leads - FSCEC-1819            
        
            Leads sind für den Record Owner sichtbar
            Leads sind für Assistenten & Vertreter des Record Owners sichtbar
            Leads sind NICHT für Überstellte (Struktursicht) sichtbar
            Leads sind NICHT für Mehrfachbetreuer sichtbar

        2 VBs, X (AX1) und Y (AY1)
>
        - AssistentX ->  AX1
        - AssistentY ->  AY1
        
        - VertreterX (AX2 -> AX1) 
        - VertreterY (AY2 -> AY1)
        
        Kunden A & B
        - jeder Kunde ist mehrfachbetreut durch 2 VBs (X & Y)
        - jeder Kunde hat 2 Datensätze (jeweils 1 je VB)
        - Kunde A ist nicht ausgeblendet
        - Kunde B ist ausgeblendet für Struktursicht, Assistanten/Vertreter

    */
    @isTest
    static void leadsMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;
        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi1CustomerAccount;
        customerA.OwnerId = vbX.Id;
        Account customerB = SharingTestUtil.multi4CustomerAccount;
        customerB.OwnerId = vbY.Id;

        List<Lead> leadsToInsert = new List<Lead>();
        
        Lead leadVbxCustA = SharingTestUtil.createLead(customerA);
        leadVbxCustA.ownerId = vbX.Id;
        leadsToInsert.add(leadVbxCustA);

        Lead leadVbyCustA = SharingTestUtil.createLead(customerA);
        leadVbyCustA.ownerId = vbY.Id;
        leadsToInsert.add(leadVbyCustA);

        Lead leadVbxCustB = SharingTestUtil.createLead(customerB);
        leadVbxCustB.ownerId = vbX.Id;
        leadsToInsert.add(leadVbxCustB);

        Lead leadVbyCustB = SharingTestUtil.createLead(customerB);
        leadVbyCustB.ownerId = vbY.Id;
        leadsToInsert.add(leadVbyCustB);


        Test.startTest();

        //System.runAs(TestDataUtility.getIntegrationTestUser()) {
            insert leadsToInsert;
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
            Integer index = getRelatedObjectIndex('Lead', '');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        //}
        
        Test.stopTest();        
        //Record Owner - je 1 Lead von 2 Customers
        Map<Id,Lead> vbXleads = SharingTestUtil.leadsVisibleForUser(vbX);
        System.assertEquals(2,vbXleads.size()); 
        Map<Id,Lead> vbYleads = SharingTestUtil.leadsVisibleForUser(vbY);
        System.assertEquals(2,vbYleads.size()); 
        
        //Assistants - je 1 Lead von 1 Customer (1 ausgeblendet)
        Map<Id,Lead> assistantXleads = SharingTestUtil.leadsVisibleForUser(assistantX);
        System.assertEquals(1, assistantXleads.size());
        Map<Id,Lead> assistantYleads = SharingTestUtil.leadsVisibleForUser(assistantY);
        System.assertEquals(1, assistantYleads.size()); 
        
        //Deputies  - je 1 Lead von 1 Customer (1 ausgeblendet)
        Map<Id,Lead> deputyXleads = SharingTestUtil.leadsVisibleForUser(deputyX);
        System.assertEquals(1, deputyXleads.size());
        Map<Id,Lead> deputyYleads = SharingTestUtil.leadsVisibleForUser(deputyY);
        System.assertEquals(1, deputyYleads.size()); 
        
        //Hierarchy -  Leads werden nie in der Struktursicht geteilt
        Map<Id,Lead> managerXleads = SharingTestUtil.leadsVisibleForUser(managerX);
        System.assertEquals(0, managerXleads.size());
        Map<Id,Lead> managerYleads = SharingTestUtil.leadsVisibleForUser(managerY);
        System.assertEquals(0, managerYleads.size());
        
        
        // Kunde A ist mehrfachbetreut durch VB X & und VB Y
        //     a) X & Y sehen beide jeweils 1 (ihre eigenen) Leads des Kunden
        System.assertNotEquals(null,vbXleads.get(leadVbxCustA.Id));
        System.assertEquals(null,vbXleads.get(leadVbyCustA.Id));
        System.assertEquals(null,vbYleads.get(leadVbxCustA.Id));
        System.assertNotEquals(null,vbYleads.get(leadVbyCustA.Id));
        //     b) Assistenten X & Y sehen beide jeweils 1 Lead ihres Hauptnutzers
        System.assertNotEquals(null,assistantXleads.get(leadVbxCustA.Id));
        System.assertEquals(null,assistantXleads.get(leadVbyCustA.Id));
        System.assertEquals(null,assistantYleads.get(leadVbxCustA.Id));
        System.assertNotEquals(null,assistantYleads.get(leadVbyCustA.Id));
        //     c) Vertreter X & Y sehen beide jeweils 1 Lead ihres Hauptnutzers
        System.assertNotEquals(null,deputyXleads.get(leadVbxCustA.Id));
        System.assertEquals(null,deputyXleads.get(leadVbyCustA.Id));
        System.assertEquals(null,deputyYleads.get(leadVbxCustA.Id));
        System.assertNotEquals(null,deputyYleads.get(leadVbyCustA.Id));
        
        // Kunde B (ausgeblendet für Struktursicht & Assistenten/Vertreter) und mehrfachbetreut durch VBX & VB Y 
        //     a) X & Y sehen beide jeweils 1 (ihre eigenen) Leads des Kunden       
        System.assertNotEquals(null,vbXleads.get(leadVbxCustB.Id));
        System.assertEquals(null,vbXleads.get(leadVbyCustB.Id));
        System.assertEquals(null,vbYleads.get(leadVbxCustB.Id));
        System.assertNotEquals(null,vbYleads.get(leadVbyCustB.Id));
        //     b) Assistenten X & Y sehen beide keine Leads des Kunden B
        System.assertEquals(null,assistantXleads.get(leadVbxCustB.Id));
        System.assertEquals(null,assistantXleads.get(leadVbyCustB.Id));
        System.assertEquals(null,assistantYleads.get(leadVbxCustB.Id));
        System.assertEquals(null,assistantYleads.get(leadVbyCustB.Id));
        //     c) Vertreter X & Y sehen beide  keine Leads des Kunden B
        System.assertEquals(null,deputyXleads.get(leadVbxCustB.Id));
        System.assertEquals(null,deputyXleads.get(leadVbyCustB.Id));
        System.assertEquals(null,deputyYleads.get(leadVbxCustB.Id));
        System.assertEquals(null,deputyYleads.get(leadVbyCustB.Id));
        
    }


    /*********************** Allgemeines Vorgehen Test 360° Objekte Controlled by Parent *********************************
          
        360° Objekte Controlled by Parent
        - Nur für Objekte, die über eine MasterDetail Beziehung mit dem Kunden-Account verbunden sind
        - Das Sharing wird über Salesforce Standards geregelt
        - Entsprechende Einstellung in den OWD
        
        Objekte
        - Customer Property
        - Person Life Events
        
        - Kunden X, Y und Z
            - jeder Kunde ist mehrfachbetreut durch 2 VBs (AX1 & AY1)
            - jeder Kunde hat 2 Datensätze (jeweils 1 je VB)
            - Kunde Y ist ausgeblendet für Assistanten/Vertreter
            - Kunde Z ist ausgeblendet für die Struktursicht

        - AssistentX ->  AX1
        - AssistentY ->  AY1
        
        - VertreterX (AX2 -> AX1) 
        - VertreterY (AY2 -> AY1)
        
        //Getestete Anforderungen
        1. Ein Mehrfach-Betreuer VB sieht
            a) den eigenen Datensatz alle seiner mehrfachbetreuten Kunden 
            b) den Datensatz des weiteren Betreuers seines mehfachbetreuten Kunden
        2. Die Vertreter
            a) sehen je Betreuer einen Datensatz des mehrfachbetreuten KundenX
            b) sehen NICHT die Datensätze des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen je Betreuer einen Datensatz des für Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
        3. die Vorgesetzten
            a) sehen je Betreuer einen Datensatz des mehrfachbetreuten KundenX
            b) sehen je Betreuer einen Datensatz des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen NICHT die Datensätze des für die Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ


        Bei mehrfachbetreuten Kunden sind die Datensätze von "Controlled by Parent" Objekten sichtbar für 
            - alle betreuenden VBs
            - deren Hierarchie (sofern nicht ausgeblendet)
            - Assistenten / Vertreter (sofern nicht ausgeblendet)
        
        1. Ein Mehrfach-Betreuer VB sieht
            a) den jeweils eigenen Datensatz alle seiner mehrfachbetreuten Kunden 
            b) NICHT den Datensatz des weiteren Betreuers seines mehfachbetreuten Kunden
        2. Die Vertreter
            a) sehen die Datensätze des Hauptnutzers des mehrfachbetreuten KundenX
            b) sehen NICHT die Datensätze des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen die Datensätze des Hauptnutzers des für Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
        3. die Vorgesetzten
            a) sehen die Datensätze des Hauptnutzers des mehrfachbetreuten KundenX
            b) sehen die Datensätze des Hauptnutzers des für Assistenten/Vertreter ausgeblendeten, mehrfachbetreuten KundenY
            c) sehen NICHT die Datensätze des für die Struktursicht ausgeblendeten, mehrfachbetreuten KundenZ
    
    *******************************************************************************************************/

    /************************************************************************************** USE CASE 1**************************************************************************************/
        
    /* 
        FSCEC-1415: Sichtbarkeit 360° Objekte -  Use Case 1

        Sichtbarkeit
        - Hierarchie: Ja
        - Mehrfachbetreuung: Ja
        - Assistent/Vertreter: Ja

        Objekte (Batch)
        - Financial Goals
        - Financial Accounts (nur Bankverbindungen, KEINE Bankprodukte!)
        - Income and Expenses
        - Assets and Liabilities
        
        //Situation
        VB AX & AY & AX1 mit jeweils 1 Kunden
        jeder Kunde hat je Kategorie 1 Objekt
        
        //Struktursicht
        VB A sieht die Objekte von AX, AX1 und AY
        VB AX sieht die Kunden von AX und AX1
        
    */
    @IsTest
    static void customer360ObjectsBatchCase1() {
        SharingTestUtil.populateVbStructure();

        User integrationUser = TestDataUtility.getIntegrationTestUser();  

        User vbAY = SharingTestUtil.vbAYuser;
        Account vbAYAccount = SharingTestUtil.vbAYcustomerAccount;
        User vbAX = SharingTestUtil.vbAXuser;
        Account vbAXAccount = SharingTestUtil.vbAXcustomerAccount;
        User vbAX1 = SharingTestUtil.vbAX1user;
        Account vbAX1Account = SharingTestUtil.vbAX1customerAccount;        
        
        //create objects per customer (AX, AY, AX1)
        
        /************************************** Create Financial Goals **************************************/
        List<FinServ__FinancialGoal__c> finGoalList = new List<FinServ__FinancialGoal__c>();        
        FinServ__FinancialGoal__c vbAXfinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAXAccount);
        finGoalList.add(vbAXfinancialGoal1);
        FinServ__FinancialGoal__c vbAXfinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAXAccount);
        finGoalList.add(vbAXfinancialGoal2);
        FinServ__FinancialGoal__c vbAYfinancialGoal1 = SharingTestUtil.createFinancialGoal(vbAYAccount);
        finGoalList.add(vbAYfinancialGoal1);
        FinServ__FinancialGoal__c vbAYfinancialGoal2 = SharingTestUtil.createFinancialGoal(vbAYAccount);
        finGoalList.add(vbAYfinancialGoal2);
        FinServ__FinancialGoal__c vbAX1financialGoal1 = SharingTestUtil.createFinancialGoal(vbAX1Account);
        finGoalList.add(vbAX1financialGoal1);
        FinServ__FinancialGoal__c vbAX1financialGoal2 = SharingTestUtil.createFinancialGoal(vbAX1Account);
        finGoalList.add(vbAX1financialGoal2);
        

        /************************************** Create Banking Accounts **************************************/
        List<FinServ__FinancialAccount__c> bankAccList = new List<FinServ__FinancialAccount__c>();
        FinServ__FinancialAccount__c vbAXbankAccount1 = SharingTestUtil.createBankingAccount(vbAXAccount, SharingTestUtil.vbAXuser);
        bankAccList.add(vbAXbankAccount1);
        FinServ__FinancialAccount__c vbAXbankAccount2 = SharingTestUtil.createBankingAccount(vbAXAccount, SharingTestUtil.vbAXuser);
        bankAccList.add(vbAXbankAccount2); 
        FinServ__FinancialAccount__c vbAYbankAccount1 = SharingTestUtil.createBankingAccount(vbAYAccount, SharingTestUtil.vbAYuser);
        bankAccList.add(vbAYbankAccount1);
        FinServ__FinancialAccount__c vbAYbankAccount2 = SharingTestUtil.createBankingAccount(vbAYAccount, SharingTestUtil.vbAYuser);
        bankAccList.add(vbAYbankAccount2);
        FinServ__FinancialAccount__c vbAX1bankAccount1 = SharingTestUtil.createBankingAccount(vbAX1Account, SharingTestUtil.vbAX1user);
        bankAccList.add(vbAX1bankAccount1);
        FinServ__FinancialAccount__c vbAX1bankAccount2 = SharingTestUtil.createBankingAccount(vbAX1Account, SharingTestUtil.vbAX1user);
        bankAccList.add(vbAX1bankAccount2); 


        /************************************** Create Income And Expenses  **************************************/
        List<IncomeAndExpenses__c> incomeExpList = new List<IncomeAndExpenses__c>();        
        IncomeAndExpenses__c vbAXnetGrossIncome = SharingTestUtil.createIncomeAndExpenseNetGrossIncome(vbAXAccount);
        incomeExpList.add(vbAXnetGrossIncome);
        IncomeAndExpenses__c vbAXincome = SharingTestUtil.createIncomeAndExpenseNetIncome(vbAXAccount);
        incomeExpList.add(vbAXincome);
        IncomeAndExpenses__c vbAYnetGrossIncome = SharingTestUtil.createIncomeAndExpenseNetGrossIncome(vbAYAccount);
        incomeExpList.add(vbAYnetGrossIncome);
        IncomeAndExpenses__c vbAYincome = SharingTestUtil.createIncomeAndExpenseNetIncome(vbAYAccount);
        incomeExpList.add(vbAYincome);
        IncomeAndExpenses__c vbAX1netGrossIncome = SharingTestUtil.createIncomeAndExpenseNetGrossIncome(vbAX1Account);
        incomeExpList.add(vbAX1netGrossIncome);
        IncomeAndExpenses__c vbAX1income = SharingTestUtil.createIncomeAndExpenseNetIncome(vbAX1Account);
        incomeExpList.add(vbAX1income);

        /************************************** Create Assets And Liabilities  **************************************/
        List<FinServ__AssetsAndLiabilities__c> assLiabList = new List<FinServ__AssetsAndLiabilities__c>();
        Id liabilityRT = RecordTypeHelper.getAssetLiabilityRecordTypeIdLiability();
        Id assetRT = RecordTypeHelper.getAssetLiabilityRecordTypeIdAsset();
        
        FinServ__AssetsAndLiabilities__c vbAXliability = SharingTestUtil.createAssetLiability(vbAXAccount,liabilityRT);
        assLiabList.add(vbAXliability);
        FinServ__AssetsAndLiabilities__c vbAXasset = SharingTestUtil.createAssetLiability(vbAXAccount,assetRT);
        assLiabList.add(vbAXasset);
        FinServ__AssetsAndLiabilities__c vbAYliability = SharingTestUtil.createAssetLiability(vbAYAccount,liabilityRT);
        assLiabList.add(vbAYliability);
        FinServ__AssetsAndLiabilities__c vbAYasset = SharingTestUtil.createAssetLiability(vbAYAccount,assetRT);
        assLiabList.add(vbAYasset);
        FinServ__AssetsAndLiabilities__c vbAX1liability = SharingTestUtil.createAssetLiability(vbAX1Account,liabilityRT);
        assLiabList.add(vbAX1liability);
        FinServ__AssetsAndLiabilities__c vbAX1asset = SharingTestUtil.createAssetLiability(vbAX1Account,assetRT);
        assLiabList.add(vbAX1asset);        

        List<AccountSharingCalculation__c> accSharesToInsert = new List<AccountSharingCalculation__c>();
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAXAccount));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAYAccount));
        accSharesToInsert.add(SharingUtil.createAccountSharingCalculation(vbAX1Account));
        
        /**************************************  Start TEST  **************************************/
        Test.startTest();
        
        System.runas(integrationUser) {
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());                        
            
            insert finGoalList;            
            insert incomeExpList;
            insert assLiabList;
            insert bankAccList;
            upsert accSharesToInsert UniqueKey__c;

            Integer batchSize = SharingUtil.getShareRelatedObjectsBatchSize();            
            Database.executeBatch(new B_ShareRelatedObjects(configs, getRelatedObjectIndex('FinServ__FinancialGoal__c', '')), batchSize);
            Database.executeBatch(new B_ShareRelatedObjects(configs, getRelatedObjectIndex('IncomeAndExpenses__c', '')), batchSize);
            Database.executeBatch(new B_ShareRelatedObjects(configs, getRelatedObjectIndex('FinServ__AssetsAndLiabilities__c', '')), batchSize);
            Database.executeBatch(new B_ShareRelatedObjects(configs, getRelatedObjectIndex('FinServ__FinancialAccount__c', 'BankingAccount')), batchSize);
        }

        Test.stopTest();
        /**************************************  End TEST  **************************************/        

        // //Print Group Members for Debugging
        // Set<Id> accIds = new Set<Id>();
        // accIds.add(vbAYAccount.Id);
        // accIds.add(vbAX1Account.Id);
        // accIds.add(vbAXAccount.Id);
        // SharingTestUtil.printAccountGroupSharesWithMembers(accIds);

        //Check Hierarchy - VB A sieht die Objekte von AX, AX1 und AY
        
        /************************************** Check Financial Goals **************************************/
        Map<Id, FinServ__FinancialGoal__c> visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(6, visibleFinGoals.size());
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAYfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAYfinancialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));        

        visibleFinGoals = SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(4, visibleFinGoals.size());
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAXfinancialGoal2.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal1.Id));
        System.assertNotEquals(null,visibleFinGoals.get(vbAX1financialGoal2.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAYfinancialGoal1.Id));
        System.assertEquals(null,visibleFinGoals.get(vbAYfinancialGoal2.Id));
        
        System.assertEquals(0, SharingTestUtil.financialGoalsVisibleForUser(SharingTestUtil.vbBuser).size());

        /************************************** Check Banking Accounts **************************************/
        Map<Id, FinServ__FinancialAccount__c> visibleFinAccs = SharingTestUtil.financialAccountsVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(6, visibleFinAccs.size());
        System.assertNotEquals(null,visibleFinAccs.get(vbAXbankAccount1.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAXbankAccount2.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAYbankAccount1.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAYbankAccount2.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAX1bankAccount1.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAX1bankAccount2.Id));        

        visibleFinAccs = SharingTestUtil.financialAccountsVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(4, visibleFinAccs.size());
        System.assertNotEquals(null,visibleFinAccs.get(vbAXbankAccount1.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAXbankAccount2.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAX1bankAccount1.Id));
        System.assertNotEquals(null,visibleFinAccs.get(vbAX1bankAccount2.Id));
        System.assertEquals(null,visibleFinAccs.get(vbAYbankAccount1.Id));
        System.assertEquals(null,visibleFinAccs.get(vbAYbankAccount2.Id));
        
        System.assertEquals(0, SharingTestUtil.financialAccountsVisibleForUser(SharingTestUtil.vbBuser).size());
        
        /************************************** Check Income and Expenses **************************************/
        Map<Id, IncomeAndExpenses__c> visibleIncExp = SharingTestUtil.incomeAndExpensesVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(6, visibleIncExp.size());
        System.assertNotEquals(null,visibleIncExp.get(vbAXnetGrossIncome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAXincome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAYnetGrossIncome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAYincome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAX1netGrossIncome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAX1income.Id));        

        visibleIncExp = SharingTestUtil.incomeAndExpensesVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(4, visibleIncExp.size());
        System.assertNotEquals(null,visibleIncExp.get(vbAXnetGrossIncome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAXincome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAX1netGrossIncome.Id));
        System.assertNotEquals(null,visibleIncExp.get(vbAX1income.Id));
        System.assertEquals(null,visibleIncExp.get(vbAYnetGrossIncome.Id));
        System.assertEquals(null,visibleIncExp.get(vbAYincome.Id));
        
        System.assertEquals(0, SharingTestUtil.incomeAndExpensesVisibleForUser(SharingTestUtil.vbBuser).size());

        /************************************** Check Assets and Liabilities **************************************/
        Map<Id, FinServ__AssetsAndLiabilities__c> visibleAssLiab = SharingTestUtil.AssetLiabilitiesVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(6, visibleAssLiab.size());
        System.assertNotEquals(null,visibleAssLiab.get(vbAXliability.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAXasset.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAYliability.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAYasset.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAX1liability.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAX1asset.Id));        

        visibleAssLiab = SharingTestUtil.AssetLiabilitiesVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(4, visibleAssLiab.size());
        System.assertNotEquals(null,visibleAssLiab.get(vbAXasset.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAXliability.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAX1asset.Id));
        System.assertNotEquals(null,visibleAssLiab.get(vbAX1liability.Id));
        System.assertEquals(null,visibleAssLiab.get(vbAYasset.Id));
        System.assertEquals(null,visibleAssLiab.get(vbAYliability.Id));
        
        System.assertEquals(0, SharingTestUtil.AssetLiabilitiesVisibleForUser(SharingTestUtil.vbBuser).size());

    }

     /* 
        FSCEC-1415: Sichtbarkeit 360° Objekte -  Master/Detail

        Sichtbarkeit
        - Hierarchie: Ja
        - Mehrfachbetreuung: Ja
        - Assistent/Vertreter: Ja
        
        Objekte (Sichtbarkeit Controlled by Parent)
        - Customer Property        
        - Person Life Events
        
        //Situation
        VB AX & AY & AX1 mit jeweils 1 Kunden
        jeder Kunde hat je Kategorie 1 Objekt
        
        //Struktursicht
        VB A sieht die Objekte von AX, AX1 und AY
        VB AX sieht die Kunden von AX und AX1                
        
        -----                  
    */
    @isTest
    static void customer360ObjectsMasterDetail() {
        SharingTestUtil.populateVbStructure();
        
        User integrationUser = TestDataUtility.getIntegrationTestUser();
        
        User vbAY = SharingTestUtil.vbAYuser;
        Account vbAYAccount = SharingTestUtil.vbAYcustomerAccount;
        User vbAX = SharingTestUtil.vbAXuser;        
        Account vbAXAccount = SharingTestUtil.vbAXcustomerAccount;
        User vbAX1 = SharingTestUtil.vbAX1user;
        Account vbAX1Account = SharingTestUtil.vbAX1customerAccount;
        
        //create 2 objects per type / customer (AX, AY, AX1)
        
        //Customer Property
        Id vehicleRT = RecordTypeHelper.getCustomerProperyRecordTypeIdVehicle();
        CustomerProperty vbAXvehicle1 = SharingTestUtil.createCustomerProperty(vbAXAccount,vehicleRT);
        CustomerProperty vbAXvehicle2 = SharingTestUtil.createCustomerProperty(vbAXAccount,vehicleRT);
        CustomerProperty vbAYvehicle1 = SharingTestUtil.createCustomerProperty(vbAYAccount,vehicleRT);
        CustomerProperty vbAYvehicle2 = SharingTestUtil.createCustomerProperty(vbAYAccount,vehicleRT);
        CustomerProperty vbAX1vehicle1 = SharingTestUtil.createCustomerProperty(vbAX1Account,vehicleRT);
        CustomerProperty vbAX1vehicle2 = SharingTestUtil.createCustomerProperty(vbAX1Account,vehicleRT);
        
        Id realEstateRT = RecordTypeHelper.getCustomerProperyRecordTypeIdRealEstate();    
        CustomerProperty vbAXrealEstate1 = SharingTestUtil.createCustomerProperty(vbAXAccount,realEstateRT);
        CustomerProperty vbAXrealEstate2 = SharingTestUtil.createCustomerProperty(vbAXAccount,realEstateRT);
        CustomerProperty vbAYrealEstate1 = SharingTestUtil.createCustomerProperty(vbAYAccount,realEstateRT);
        CustomerProperty vbAYrealEstate2 = SharingTestUtil.createCustomerProperty(vbAYAccount,realEstateRT);
        CustomerProperty vbAX1realEstate1 = SharingTestUtil.createCustomerProperty(vbAX1Account,realEstateRT);
        CustomerProperty vbAX1realEstate2 = SharingTestUtil.createCustomerProperty(vbAX1Account,realEstateRT);
        
        List<CustomerProperty> cstPropertyList = new List<CustomerProperty>();
        cstPropertyList.add(vbAXvehicle1);
        cstPropertyList.add(vbAXvehicle2);
        cstPropertyList.add(vbAYvehicle1);
        cstPropertyList.add(vbAYvehicle2);
        cstPropertyList.add(vbAX1vehicle1);
        cstPropertyList.add(vbAX1vehicle2);
        cstPropertyList.add(vbAXrealEstate1);
        cstPropertyList.add(vbAXrealEstate2);
        cstPropertyList.add(vbAYrealEstate1);
        cstPropertyList.add(vbAYrealEstate2);       
        cstPropertyList.add(vbAX1realEstate1);
        cstPropertyList.add(vbAX1realEstate2);        
        
        //Person Life Event
        PersonLifeEvent vbAXLifeEvent1 = new PersonLifeEvent(PrimaryPersonId = vbAXAccount.PersonContactId,
                                                            Name = 'VB AX Customer Event',
                                                            EventDate = Datetime.now(),
                                                            EventType = 'CustomerSince',
                                                            OwnerId = vbAXAccount.OwnerId);
        PersonLifeEvent vbAXLifeEvent2 = new PersonLifeEvent(PrimaryPersonId = vbAXAccount.PersonContactId,
                                                            Name = 'VB AX Graduation Event',
                                                            EventDate = Datetime.now(),
                                                            EventType = 'Graduation',
                                                            OwnerId = vbAXAccount.OwnerId);

        PersonLifeEvent vbAYLifeEvent1 = new PersonLifeEvent(PrimaryPersonId = vbAYAccount.PersonContactId,
                                                            Name = 'VB AY Customer Event',
                                                            EventDate = Datetime.now(),
                                                            EventType = 'CustomerSince',
                                                            OwnerId = vbAYAccount.OwnerId);
        PersonLifeEvent vbAYLifeEvent2 = new PersonLifeEvent(PrimaryPersonId = vbAYAccount.PersonContactId,
                                                            Name = 'VB AY Graduation Event',
                                                            EventDate = Datetime.now(),
                                                            EventType = 'Graduation',
                                                            OwnerId = vbAYAccount.OwnerId);

        PersonLifeEvent vbAX1LifeEvent1 = new PersonLifeEvent(PrimaryPersonId = vbAX1Account.PersonContactId,
                                                            Name = 'VB AX1 Customer Event',
                                                            EventDate = Datetime.now(),
                                                            EventType = 'CustomerSince',
                                                            OwnerId = vbAX1Account.OwnerId);                            
        PersonLifeEvent vbAX1LifeEvent2 = new PersonLifeEvent(PrimaryPersonId = vbAX1Account.PersonContactId,
                                                            Name = 'VB AX1 Graduation Event',
                                                            EventDate = Datetime.now(),
                                                            EventType = 'Graduation',
                                                            OwnerId = vbAX1Account.OwnerId);

        List<PersonLifeEvent> prsnLfeEvtList = new List<PersonLifeEvent>();
        prsnLfeEvtList.add(vbAXLifeEvent1);
        prsnLfeEvtList.add(vbAXLifeEvent2);
        prsnLfeEvtList.add(vbAYLifeEvent1);
        prsnLfeEvtList.add(vbAYLifeEvent2);
        prsnLfeEvtList.add(vbAX1LifeEvent1);
        prsnLfeEvtList.add(vbAX1LifeEvent2);
        
        /**************************************  TEST  **************************************/        

        Test.startTest();
        
        System.runas(integrationUser) {
            Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());            
            insert cstPropertyList;       
            //Person Life Event
            insert prsnLfeEvtList;   
            
            //upsert accSharesToInsert UniqueKey__c;
            // Integer index = getRelatedObject('FinServ__FinancialAccount__c', 'BankingAccount');
            //Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        }

        Test.stopTest();

        //Check Hierarchy - VB A sieht die Objekte von AX, AX1 und AY            

        //Customer Properties
        Map<Id,CustomerProperty> visibleProperties = SharingTestUtil.customerPropertiesVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(12, visibleProperties.size());
        System.assertNotEquals(null,visibleProperties.get(vbAXvehicle1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAXvehicle2.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAYvehicle1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAYvehicle2.Id));        
        System.assertNotEquals(null,visibleProperties.get(vbAX1vehicle1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAX1vehicle2.Id));

        System.assertNotEquals(null,visibleProperties.get(vbAXrealEstate1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAXrealEstate2.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAYrealEstate1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAYrealEstate2.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAX1realEstate1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAX1realEstate2.Id));
        
        visibleProperties = SharingTestUtil.customerPropertiesVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(8, visibleProperties.size());
        System.assertNotEquals(null,visibleProperties.get(vbAXvehicle1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAXvehicle2.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAX1vehicle1.Id));        
        System.assertNotEquals(null,visibleProperties.get(vbAX1vehicle2.Id));        
        System.assertNotEquals(null,visibleProperties.get(vbAXrealEstate1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAXrealEstate2.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAX1realEstate1.Id));
        System.assertNotEquals(null,visibleProperties.get(vbAX1realEstate2.Id));
        System.assertEquals(null,visibleProperties.get(vbAYvehicle1.Id));
        System.assertEquals(null,visibleProperties.get(vbAYvehicle2.Id));
        System.assertEquals(null,visibleProperties.get(vbAYrealEstate1.Id));
        System.assertEquals(null,visibleProperties.get(vbAYrealEstate2.Id));
        
        System.assertEquals(0, SharingTestUtil.customerPropertiesVisibleForUser(SharingTestUtil.vbBuser).size());
                     
        //PersonLifeEvents
        Map<Id,PersonLifeEvent> visiblePersonLifeEvents = SharingTestUtil.personLifeEventsVisibleForUser(SharingTestUtil.vbAuser);
        System.assertEquals(6, visiblePersonLifeEvents.size());
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAXLifeEvent1.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAXLifeEvent2.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAYLifeEvent1.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAYLifeEvent2.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAX1LifeEvent1.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAX1LifeEvent2.Id));

        visiblePersonLifeEvents = SharingTestUtil.personLifeEventsVisibleForUser(SharingTestUtil.vbAXuser);
        System.assertEquals(4, visiblePersonLifeEvents.size());
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAXLifeEvent1.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAXLifeEvent2.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAX1LifeEvent1.Id));
        System.assertNotEquals(null,visiblePersonLifeEvents.get(vbAX1LifeEvent2.Id));
        System.assertEquals(null,visiblePersonLifeEvents.get(vbAYLifeEvent1.Id));
        System.assertEquals(null,visiblePersonLifeEvents.get(vbAYLifeEvent2.Id));

        System.assertEquals(0, SharingTestUtil.personLifeEventsVisibleForUser(SharingTestUtil.vbBuser).size());

    }

    
    /* TODO - kein FACHLICHER Test, das gehört in den UnitTest für Agent Sharing Calcualtion
    @IsTest    
    static void checkHierarchyInGroup_UT() {
        //Create a user that is not part of the strucutre and check that nobody can access the account data
        SharingTestUtil.populateVbStructure();
        
        Account checkPartnerAccount = new Account(
            name = 'Check Direktion',
            RecordTypeId = directorateAccountRecordType
        );
        insert checkPartnerAccount;
        
        User checkVBUser = SharingTestUtil.createFieldSalesContactUser('Check', 'VB', 'tst@dvag.tst', '9876', checkPartnerAccount.Id, null);
        Account checkCustomerAccount = new Account(
            RecordTypeId = personAccountRecordType,
            FirstName = checkVBUser.LastName,
            LastName = 'Customer'
        );
        checkCustomerAccount.OwnerId = checkVBUser.Id;
        insert checkCustomerAccount;
        
        List<AgentSharingCalculation__c> agentSharingOpen = [
            SELECT Id
            FROM AgentSharingCalculation__c
        ];
        List<GroupMember> allGroupMember = [
            SELECT Id
            FROM GroupMember
            WHERE Group.DeveloperName LIKE 'M_%'
        ];
        
        Test.startTest();
        Database.executeBatch(
            new B_CalculateGroupHierarchy(),
            SharingUtil.getGroupHierarchyCalculationBatchSize()
        );
        Test.stopTest();
        
        system.debug(
            [
                SELECT Id, Subject__c, ExceptionMessage__c, ExceptionType__c
                FROM CCG_LogRecording__c
                WHERE Process__c LIKE '%Sharing%'
            ]
        );
        
        List<AgentSharingCalculation__c> agentSharingOpenAfter = [
            SELECT Id
            FROM AgentSharingCalculation__c
        ];
        List<GroupMember> allGroupMemberAfter = [
            SELECT Id
            FROM GroupMember
            WHERE Group.DeveloperName LIKE 'M_%'
        ];
        
        system.debug('agentSharingOpen count: ' + agentSharingOpen.size());
        system.debug('allGroupMember count: ' + allGroupMember.size());
        system.debug('agentSharingOpenAfter count: ' + agentSharingOpenAfter.size());
        system.debug('allGroupMemberAfter count: ' + allGroupMemberAfter.size());
        
        System.assertNotEquals(0, agentSharingOpen.size());
        System.assertEquals(0, agentSharingOpenAfter.size());
        System.assert(allGroupMember.size() < allGroupMemberAfter.size());
    }
     */
    
    @isTest
    /* TODO - this is rather a UNIT TEST, as it is checking for shares - not visibility*/
    static void checkBatchScheduleGroupHierarchy() {
        String jobId = System.schedule(
            'CAL Sharing Group Hierachy in Apex Test',
            '0 0 23 * * ?',
            new B_CalculateGroupHierarchy()
        );
        System.assert(String.isNotBlank(jobId));
    }
    
    @IsTest
    static void testInsertAccount_UT() {
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account checkUsersPartnerAccount = new Account(
                name = 'Check Partner Account',
                RecordTypeId = directorateAccountRecordType
            );
            insert checkUsersPartnerAccount;
            
            
            List<SharingTestUtil.ExperienceCloudUserDetails> usersToCreate = new List<SharingTestUtil.ExperienceCloudUserDetails>();
            //User 1
            SharingTestUtil.ExperienceCloudUserDetails testVb1Details = new SharingTestUtil.ExperienceCloudUserDetails();
            testVb1Details.firstName = 'User';
            testVb1Details.lastName = 'One';
            testVb1Details.userName = 'user.one@dvag.com.tst';
            testVb1Details.accountId = checkUsersPartnerAccount.Id;
            testVb1Details.reportsToUsername = null;
            testVb1Details.advisorNumber = 'x12345';
            usersToCreate.add(testVb1Details);
            
            //User 2
            SharingTestUtil.ExperienceCloudUserDetails testVb2Details = new SharingTestUtil.ExperienceCloudUserDetails();
            testVb2Details.firstName = 'User';
            testVb2Details.lastName = 'Two';
            testVb2Details.userName = 'user.two@dvag.com.tst';
            testVb2Details.accountId = checkUsersPartnerAccount.Id;
            testVb2Details.reportsToUsername = 'user.one@dvag.com.tst';
            testVb2Details.advisorNumber = 'y34567';
            usersToCreate.add(testVb2Details);
        
            SharingTestUtil.createExperienceCloudUsers(usersToCreate);
        }
        
        List<User> createdUsers = [
            SELECT
            ID,
            username,
            FirstName,
            LastName,
            AccountID,
            ContactID,
            Contact.ReportsToID,
            Contact.ExtFinancialAdvisorId__c,
            ExtFinancialAdvisorId__c
            FROM User
        ];
        Map<String, User> createdUserMap = new Map<String, User>();
        for (User loopUser : createdUsers) {
            createdUserMap.put(loopUser.username, loopUser);
        }
        
        //Assign the created users
        User testVb1 = createdUserMap.get('user.one@dvag.com.tst');
        User testVb2 = createdUserMap.get('user.two@dvag.com.tst');
        
        List<Account> customerAccountList = new List<Account>();
        customerAccountList.add(
            new Account(
                RecordTypeId = personAccountRecordType,
                FirstName = 'TestX',
                LastName = testVb1.LastName,
                OwnerId = testVb1.Id
            )
        );
        
        customerAccountList.add(
            new Account(
                RecordTypeId = personAccountRecordType,
                FirstName = 'TestY',
                LastName = testVb2.LastName,
                OwnerId = testVb2.Id
            )
        );
        
        Test.startTest();
        insert customerAccountList;
        Test.stopTest();
        
        List<Account> newAccounts = [
            SELECT id, FirstName, LastName
            FROM Account
            WHERE RecordTypeId = :personAccountRecordType
        ];
        
        Account testAccountVb1;
        Account testAccountVb2;
        
        for (Account loopAccount : newAccounts) {
            if (
                loopAccount.FirstName == 'TestX' &&
                loopAccount.LastName == testVb1.LastName
            ) {
                testAccountVb1 = loopAccount;
            }
            if (
                loopAccount.FirstName == 'TestY' &&
                loopAccount.LastName == testVb2.LastName
            ) {
                testAccountVb2 = loopAccount;
            }
        }
        
        String testVb1_managerGroup = SharingUtil.getGroupNameByType( SharingUtil.SharingGroup.Hierarchy, testVb1.ExtFinancialAdvisorId__c); 
        String testVb2_managerGroup = SharingUtil.getGroupNameByType( SharingUtil.SharingGroup.Hierarchy, testVb2.ExtFinancialAdvisorId__c); 
        
        List<AccountShare> newShares = [
            SELECT Id, AccountID, Account.Name, UserOrGroupId, UserOrGroup.Name, RowCause
            FROM AccountShare
            WHERE RowCause = 'Manual' 
            AND AccountID in (:testAccountVb1.Id, :testAccountVb2.Id)
        ];
        
        List<SharingGroup__mdt> sharingGroups = SharingUtil.getAllSharingGroupTypes();
        System.assertEquals(sharingGroups.size() * 2, newShares.size());
        
        Integer shareCount = 0;
        
        for (AccountShare loopShareRec : newShares) {
            if (
                loopShareRec.UserOrGroup.Name == testVb1_managerGroup &&
                loopShareRec.AccountId == testAccountVb1.Id
            ) {
                shareCount++;
            } else if (
                loopShareRec.UserOrGroup.Name == testVb2_managerGroup &&
                loopShareRec.AccountId == testAccountVb2.Id
            ) {
                shareCount++;
            }
        }
        System.assertEquals(2, shareCount);
    }
    
    @isTest
    static void checkBatchScheduleShareRelatedObjects() {
        Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'BankingAccount');
        
        String jobId = System.schedule(
            'CAL Related Objects in Apex Test',
            '0 0 23 * * ?',
            new B_ShareRelatedObjects(configs, index)
        );
        System.assert(String.isNotBlank(jobId));
    }

      /*******************************************************************************
        FSCEC-1918 - Multi-Owner Visibility for Contracts depends on Contract Type
        
        Setup

        2 VBs, X (AX1) und Y (AY1)
        - AssistantX ->  AX1
        - AssistantY ->  AY1        
        - DeputyX (AX2 -> AX1) 
        - DeputyY (AY2 -> AY1)
        
        Customer A & B
        - Customers are multi-owner (each owned by VB X & Y) 
        - jeach Customer has 2 contracts (one per VB)
        - customer A is is hidden for hierarchy, assistants, deputies
        - customer B is not hidden

        Check initial visibility, change of hiding settings, check for results
    *******************************************************************************/

    //FSCEC-1918 - Investment Account (MultiOwner: not shared between owners)
    @isTest
    static void investmentAccountUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;
            
        Id investAccRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdInvestmentAccount();
        List<FinServ__FinancialAccount__c> investmentAccounts = new List<FinServ__FinancialAccount__c>();

        FinServ__FinancialAccount__c custA_XinvAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,investAccRtId,'InvestAcc'+TestDataUtility.getRandomNumber(3));
        investmentAccounts.add(custA_XinvAcc);

        FinServ__FinancialAccount__c custA_YinvAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,investAccRtId,'InvestAcc'+TestDataUtility.getRandomNumber(3));
        investmentAccounts.add(custA_YinvAcc);

        FinServ__FinancialAccount__c custB_XinvAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,investAccRtId,'InvestAcc'+TestDataUtility.getRandomNumber(3));
        investmentAccounts.add(custB_XinvAcc);

        FinServ__FinancialAccount__c custB_YinvAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,investAccRtId,'InvestAcc'+TestDataUtility.getRandomNumber(3));
        custB_YinvAcc.OwnerId = vbY.Id;
        investmentAccounts.add(custB_YinvAcc);

        Map<Id,FinServ__FinancialAccount__c> vbXinvestAcc;
        Map<Id,FinServ__FinancialAccount__c> vbYinvestAcc;
        
        //Assistants
        Map<Id,FinServ__FinancialAccount__c> assistantXinvestAcc;
        Map<Id,FinServ__FinancialAccount__c> assistantYinvestAcc;
        //Deputies
        Map<Id,FinServ__FinancialAccount__c> deputyXinvestAcc;
        Map<Id,FinServ__FinancialAccount__c> deputyYinvestAcc;
        //Hierarchy
        Map<Id,FinServ__FinancialAccount__c> managerXinvestAcc;
        Map<Id,FinServ__FinancialAccount__c> managerYinvestAcc;
        
        Test.startTest();
            insert investmentAccounts;
            
            vbXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
            System.assertEquals(2,vbXinvestAcc.size()); //je 1 Invest Account von 2 Customers
            System.assertNotEquals(null, vbXinvestAcc.get(custA_XinvAcc.Id));
            System.assertNotEquals(null, vbXinvestAcc.get(custB_XinvAcc.Id));
            vbYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
            System.assertEquals(2,vbYinvestAcc.size()); //je 1 Invest Account von 2 Customers
            System.assertNotEquals(null, vbYinvestAcc.get(custA_YinvAcc.Id));
            System.assertNotEquals(null, vbYinvestAcc.get(custB_YinvAcc.Id));
            //Assistants
            assistantXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
            System.assertEquals(1, assistantXinvestAcc.size()); //1 Invest Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXinvestAcc.get(custB_XinvAcc.Id));
            assistantYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
            System.assertEquals(1, assistantYinvestAcc.size()); //1 Invest Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYinvestAcc.get(custB_YinvAcc.Id));
            //Deputies
            deputyXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
            System.assertEquals(1, deputyXinvestAcc.size()); //1 Invest Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXinvestAcc.get(custB_XinvAcc.Id));
            deputyYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
            System.assertEquals(1, deputyYinvestAcc.size()); //1 Invest Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYinvestAcc.get(custB_YinvAcc.Id));
            //Hierarchy
            managerXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
            System.assertEquals(1, managerXinvestAcc.size()); //1 Invest Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXinvestAcc.get(custB_XinvAcc.Id));
            managerYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
            System.assertEquals(1, managerYinvestAcc.size()); //1 Invest Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYinvestAcc.get(custB_YinvAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'InvestmentAccount');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
        System.assertEquals(2,vbXinvestAcc.size()); //je 1 Invest Account von 2 Customers
        System.assertNotEquals(null, vbXinvestAcc.get(custA_XinvAcc.Id));
        System.assertNotEquals(null, vbXinvestAcc.get(custB_XinvAcc.Id));
        vbYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
        System.assertEquals(2,vbYinvestAcc.size()); //je 1 Invest Account von 2 Customers
        System.assertNotEquals(null, vbYinvestAcc.get(custA_YinvAcc.Id));
        System.assertNotEquals(null, vbYinvestAcc.get(custB_YinvAcc.Id));
        //Assistants
        assistantXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
        System.assertEquals(1, assistantXinvestAcc.size()); //1 Invest Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXinvestAcc.get(custA_XinvAcc.Id));
        assistantYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
        System.assertEquals(1, assistantYinvestAcc.size()); //1 Invest Account von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYinvestAcc.get(custA_YinvAcc.Id));
        //Deputies
        deputyXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
        System.assertEquals(1, deputyXinvestAcc.size()); //1 Invest Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXinvestAcc.get(custA_XinvAcc.Id));
        deputyYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
        System.assertEquals(1, deputyYinvestAcc.size()); //1 Invest Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYinvestAcc.get(custA_YinvAcc.Id));
        //Hierarchy
        managerXinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
        System.assertEquals(1, managerXinvestAcc.size()); //1 Invest Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXinvestAcc.get(custA_XinvAcc.Id));
        managerYinvestAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
        System.assertEquals(1, managerYinvestAcc.size()); //1 Invest Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYinvestAcc.get(custA_YinvAcc.Id));
        
    }

    //FSCEC-1918 - Banking Account (MultiOwner: not shared between owners)
    @isTest
    static void bankingAccountUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;
        
        Id bankingAcctRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();                
        List<FinServ__FinancialAccount__c> bankingAccounts = new List<FinServ__FinancialAccount__c>();

        FinServ__FinancialAccount__c custA_XbankAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,bankingAcctRtId,'BankAcc'+TestDataUtility.getRandomNumber(3));
        bankingAccounts.add(custA_XbankAcc);

        FinServ__FinancialAccount__c custA_YbankAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,bankingAcctRtId,'BankAcc'+TestDataUtility.getRandomNumber(3));
        bankingAccounts.add(custA_YbankAcc);

        FinServ__FinancialAccount__c custB_XbankAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,bankingAcctRtId,'BankAcc'+TestDataUtility.getRandomNumber(3));
        bankingAccounts.add(custB_XbankAcc);

        FinServ__FinancialAccount__c custB_YbankAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,bankingAcctRtId,'BankAcc'+TestDataUtility.getRandomNumber(3));
        custB_YbankAcc.OwnerId = vbY.Id;
        bankingAccounts.add(custB_YbankAcc);

        Map<Id,FinServ__FinancialAccount__c> vbXbankAcc;
        Map<Id,FinServ__FinancialAccount__c> vbYbankAcc;
        
        //Assistants
        Map<Id,FinServ__FinancialAccount__c> assistantXbankAcc;
        Map<Id,FinServ__FinancialAccount__c> assistantYbankAcc;
        //Deputies
        Map<Id,FinServ__FinancialAccount__c> deputyXbankAcc;
        Map<Id,FinServ__FinancialAccount__c> deputyYbankAcc;
        //Hierarchy
        Map<Id,FinServ__FinancialAccount__c> managerXbankAcc;
        Map<Id,FinServ__FinancialAccount__c> managerYbankAcc;
        
        Test.startTest();
            insert bankingAccounts;
            
            vbXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
            System.assertEquals(2,vbXbankAcc.size()); //je 1 Banking Account von 2 Customers
            System.assertNotEquals(null, vbXbankAcc.get(custA_XbankAcc.Id));
            System.assertNotEquals(null, vbXbankAcc.get(custB_XbankAcc.Id));
            vbYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
            System.assertEquals(2,vbYbankAcc.size()); //je 1 Banking Account von 2 Customers
            System.assertNotEquals(null, vbYbankAcc.get(custA_YbankAcc.Id));
            System.assertNotEquals(null, vbYbankAcc.get(custB_YbankAcc.Id));
            //Assistants
            assistantXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
            System.assertEquals(1, assistantXbankAcc.size()); //1 Banking Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXbankAcc.get(custB_XbankAcc.Id));
            assistantYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
            System.assertEquals(1, assistantYbankAcc.size()); //1 Banking Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYbankAcc.get(custB_YbankAcc.Id));
            //Deputies
            deputyXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
            System.assertEquals(1, deputyXbankAcc.size()); //1 Banking Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXbankAcc.get(custB_XbankAcc.Id));
            deputyYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
            System.assertEquals(1, deputyYbankAcc.size()); //1 Banking Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYbankAcc.get(custB_YbankAcc.Id));
            //Hierarchy
            managerXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
            System.assertEquals(1, managerXbankAcc.size()); //1 Banking Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXbankAcc.get(custB_XbankAcc.Id));
            managerYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
            System.assertEquals(1, managerYbankAcc.size()); //1 Banking Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYbankAcc.get(custB_YbankAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'BankingAccount');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
        System.assertEquals(2,vbXbankAcc.size()); //je 1 Banking Account von 2 Customers
        System.assertNotEquals(null, vbXbankAcc.get(custA_XbankAcc.Id));
        System.assertNotEquals(null, vbXbankAcc.get(custB_XbankAcc.Id));
        vbYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
        System.assertEquals(2,vbYbankAcc.size()); //je 1 Banking Account von 2 Customers
        System.assertNotEquals(null, vbYbankAcc.get(custA_YbankAcc.Id));
        System.assertNotEquals(null, vbYbankAcc.get(custB_YbankAcc.Id));
        //Assistants
        assistantXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
        System.assertEquals(1, assistantXbankAcc.size()); //1 Banking Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXbankAcc.get(custA_XbankAcc.Id));
        assistantYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
        System.assertEquals(1, assistantYbankAcc.size()); //1 Banking Account von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYbankAcc.get(custA_YbankAcc.Id));
        //Deputies
        deputyXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
        System.assertEquals(1, deputyXbankAcc.size()); //1 Banking Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXbankAcc.get(custA_XbankAcc.Id));
        deputyYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
        System.assertEquals(1, deputyYbankAcc.size()); //1 Banking Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYbankAcc.get(custA_YbankAcc.Id));
        //Hierarchy
        managerXbankAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
        System.assertEquals(1, managerXbankAcc.size()); //1 Banking Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXbankAcc.get(custA_XbankAcc.Id));
        managerYbankAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
        System.assertEquals(1, managerYbankAcc.size()); //1 Banking Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYbankAcc.get(custA_YbankAcc.Id));            
    
    }

    //FSCEC-1918 - General Account (MultiOwner: is shared between owners)
    @isTest
    static void generalAccountUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;
        
        Id generalAcctRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdGeneralAccount();
        List<FinServ__FinancialAccount__c> generalAccounts = new List<FinServ__FinancialAccount__c>();

        FinServ__FinancialAccount__c custA_XgenAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,generalAcctRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        generalAccounts.add(custA_XgenAcc);

        FinServ__FinancialAccount__c custA_YgenAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,generalAcctRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        generalAccounts.add(custA_YgenAcc);

        FinServ__FinancialAccount__c custB_XgenAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,generalAcctRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        generalAccounts.add(custB_XgenAcc);

        FinServ__FinancialAccount__c custB_YgenAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,generalAcctRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        custB_YgenAcc.OwnerId = vbY.Id;
        generalAccounts.add(custB_YgenAcc);

        Map<Id,FinServ__FinancialAccount__c> vbXgenAcc;
        Map<Id,FinServ__FinancialAccount__c> vbYgenAcc;
        
        //Assistants
        Map<Id,FinServ__FinancialAccount__c> assistantXgenAcc;
        Map<Id,FinServ__FinancialAccount__c> assistantYgenAcc;
        //Deputies
        Map<Id,FinServ__FinancialAccount__c> deputyXgenAcc;
        Map<Id,FinServ__FinancialAccount__c> deputyYgenAcc;
        //Hierarchy
        Map<Id,FinServ__FinancialAccount__c> managerXgenAcc;
        Map<Id,FinServ__FinancialAccount__c> managerYgenAcc;
        
        Test.startTest();
            insert generalAccounts;
            
            vbXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
            System.assertEquals(4,vbXgenAcc.size()); //je 2 General Accounts von 2 Customern
            System.assertNotEquals(null, vbXgenAcc.get(custA_XgenAcc.Id));
            System.assertNotEquals(null, vbXgenAcc.get(custA_YgenAcc.Id));
            System.assertNotEquals(null, vbXgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, vbXgenAcc.get(custB_YgenAcc.Id));
            vbYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
            System.assertEquals(4,vbYgenAcc.size()); //je 2 General Accounts von 2 Customern
            System.assertNotEquals(null, vbYgenAcc.get(custA_XgenAcc.Id));
            System.assertNotEquals(null, vbYgenAcc.get(custA_YgenAcc.Id));
            System.assertNotEquals(null, vbYgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, vbYgenAcc.get(custB_YgenAcc.Id));
            //Assistants
            assistantXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
            System.assertEquals(2, assistantXgenAcc.size()); //2 General Accounts von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, assistantXgenAcc.get(custB_YgenAcc.Id));
            assistantYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
            System.assertEquals(2, assistantYgenAcc.size()); //2 General Accounts von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, assistantYgenAcc.get(custB_YgenAcc.Id));
            //Deputies
            deputyXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
            System.assertEquals(2, deputyXgenAcc.size()); //2 General Accounts von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, deputyXgenAcc.get(custB_YgenAcc.Id));
            deputyYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
            System.assertEquals(2, deputyYgenAcc.size()); //2 General Accounts von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, deputyYgenAcc.get(custB_YgenAcc.Id));
            //Hierarchy
            managerXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
            System.assertEquals(2, managerXgenAcc.size()); //2 General Accounts von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, managerXgenAcc.get(custB_YgenAcc.Id));
            managerYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
            System.assertEquals(2, managerYgenAcc.size()); //2 General Accounts von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYgenAcc.get(custB_XgenAcc.Id));
            System.assertNotEquals(null, managerYgenAcc.get(custB_YgenAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'General');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
        System.assertEquals(4,vbXgenAcc.size()); //je 2 General Accounts von 2 Customers
        System.assertNotEquals(null, vbXgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, vbXgenAcc.get(custA_YgenAcc.Id));
        System.assertNotEquals(null, vbXgenAcc.get(custB_XgenAcc.Id));
        System.assertNotEquals(null, vbXgenAcc.get(custB_YgenAcc.Id));
        vbYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
        System.assertEquals(4,vbYgenAcc.size()); //je 2 General Accounts von 2 Customers
        System.assertNotEquals(null, vbYgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, vbYgenAcc.get(custA_YgenAcc.Id));
        System.assertNotEquals(null, vbYgenAcc.get(custB_XgenAcc.Id));
        System.assertNotEquals(null, vbYgenAcc.get(custB_YgenAcc.Id));
        //Assistants
        assistantXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
        System.assertEquals(2, assistantXgenAcc.size()); //2 General Accounts von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, assistantXgenAcc.get(custA_YgenAcc.Id));
        assistantYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
        System.assertEquals(2, assistantYgenAcc.size()); //2 General Accounts von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, assistantYgenAcc.get(custA_YgenAcc.Id));        
        //Deputies
        deputyXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
        System.assertEquals(2, deputyXgenAcc.size()); //2 General Accounts von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, deputyXgenAcc.get(custA_YgenAcc.Id));
        deputyYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
        System.assertEquals(2, deputyYgenAcc.size()); //2 General Accounts von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, deputyYgenAcc.get(custA_YgenAcc.Id));
        //Hierarchy
        managerXgenAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
        System.assertEquals(2, managerXgenAcc.size()); //2 General Accounts von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, managerXgenAcc.get(custA_YgenAcc.Id));
        managerYgenAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
        System.assertEquals(2, managerYgenAcc.size()); //2 General Accounts von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYgenAcc.get(custA_XgenAcc.Id));
        System.assertNotEquals(null, managerYgenAcc.get(custA_YgenAcc.Id));
    
    }

    //FSCEC-1918 - CreditCard (MultiOwner: not shared between owners)
    @isTest
    static void creditCardUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;
        
        Id creditCardRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdCreditCard();
        List<FinServ__FinancialAccount__c> creditCards = new List<FinServ__FinancialAccount__c>();

        FinServ__FinancialAccount__c custA_XcrdCardAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,creditCardRtId,'Credit Card'+TestDataUtility.getRandomNumber(3));
        creditCards.add(custA_XcrdCardAcc);

        FinServ__FinancialAccount__c custA_YcrdCardAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,creditCardRtId,'Credit Card'+TestDataUtility.getRandomNumber(3));
        creditCards.add(custA_YcrdCardAcc);

        FinServ__FinancialAccount__c custB_XcrdCardAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,creditCardRtId,'Credit Card'+TestDataUtility.getRandomNumber(3));
        creditCards.add(custB_XcrdCardAcc);

        FinServ__FinancialAccount__c custB_YcrdCardAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,creditCardRtId,'Credit Card'+TestDataUtility.getRandomNumber(3));
        custB_YcrdCardAcc.OwnerId = vbY.Id;
        creditCards.add(custB_YcrdCardAcc);

        Map<Id,FinServ__FinancialAccount__c> vbXcrdCardAcc;
        Map<Id,FinServ__FinancialAccount__c> vbYcrdCardAcc;
        
        //Assistants
        Map<Id,FinServ__FinancialAccount__c> assistantXcrdCardAcc;
        Map<Id,FinServ__FinancialAccount__c> assistantYcrdCardAcc;
        //Deputies
        Map<Id,FinServ__FinancialAccount__c> deputyXcrdCardAcc;
        Map<Id,FinServ__FinancialAccount__c> deputyYcrdCardAcc;
        //Hierarchy
        Map<Id,FinServ__FinancialAccount__c> managerXcrdCardAcc;
        Map<Id,FinServ__FinancialAccount__c> managerYcrdCardAcc;
        
        Test.startTest();
            insert creditCards;
            
            vbXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
            System.assertEquals(2,vbXcrdCardAcc.size()); //je 1 CreditCard von 2 Customers
            System.assertNotEquals(null, vbXcrdCardAcc.get(custA_XcrdCardAcc.Id));
            System.assertNotEquals(null, vbXcrdCardAcc.get(custB_XcrdCardAcc.Id));
            vbYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
            System.assertEquals(2,vbYcrdCardAcc.size()); //je 1 CreditCard von 2 Customers
            System.assertNotEquals(null, vbYcrdCardAcc.get(custA_YcrdCardAcc.Id));
            System.assertNotEquals(null, vbYcrdCardAcc.get(custB_YcrdCardAcc.Id));
            //Assistants
            assistantXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
            System.assertEquals(1, assistantXcrdCardAcc.size()); //1 CreditCard von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXcrdCardAcc.get(custB_XcrdCardAcc.Id));
            assistantYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
            System.assertEquals(1, assistantYcrdCardAcc.size()); //1 CreditCard von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYcrdCardAcc.get(custB_YcrdCardAcc.Id));
            //Deputies
            deputyXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
            System.assertEquals(1, deputyXcrdCardAcc.size()); //1 CreditCard von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXcrdCardAcc.get(custB_XcrdCardAcc.Id));
            deputyYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
            System.assertEquals(1, deputyYcrdCardAcc.size()); //1 CreditCard von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYcrdCardAcc.get(custB_YcrdCardAcc.Id));
            //Hierarchy
            managerXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
            System.assertEquals(1, managerXcrdCardAcc.size()); //1 CreditCard von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXcrdCardAcc.get(custB_XcrdCardAcc.Id));
            managerYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
            System.assertEquals(1, managerYcrdCardAcc.size()); //1 CreditCard von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYcrdCardAcc.get(custB_YcrdCardAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'CreditCard');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
        System.assertEquals(2,vbXcrdCardAcc.size()); //je 1 CreditCard von 2 Customers
        System.assertNotEquals(null, vbXcrdCardAcc.get(custA_XcrdCardAcc.Id));
        System.assertNotEquals(null, vbXcrdCardAcc.get(custB_XcrdCardAcc.Id));
        vbYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
        System.assertEquals(2,vbYcrdCardAcc.size()); //je 1 CreditCard von 2 Customers
        System.assertNotEquals(null, vbYcrdCardAcc.get(custA_YcrdCardAcc.Id));
        System.assertNotEquals(null, vbYcrdCardAcc.get(custB_YcrdCardAcc.Id));
        //Assistants
        assistantXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
        System.assertEquals(1, assistantXcrdCardAcc.size()); //1 CreditCard von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXcrdCardAcc.get(custA_XcrdCardAcc.Id));
        assistantYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
        System.assertEquals(1, assistantYcrdCardAcc.size()); //1 CreditCard von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYcrdCardAcc.get(custA_YcrdCardAcc.Id));
        //Deputies
        deputyXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
        System.assertEquals(1, deputyXcrdCardAcc.size()); //1 CreditCard von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXcrdCardAcc.get(custA_XcrdCardAcc.Id));
        deputyYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
        System.assertEquals(1, deputyYcrdCardAcc.size()); //1 CreditCard von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYcrdCardAcc.get(custA_YcrdCardAcc.Id));
        //Hierarchy
        managerXcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
        System.assertEquals(1, managerXcrdCardAcc.size()); //1 CreditCard von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXcrdCardAcc.get(custA_XcrdCardAcc.Id));
        managerYcrdCardAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
        System.assertEquals(1, managerYcrdCardAcc.size()); //1 CreditCard von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYcrdCardAcc.get(custA_YcrdCardAcc.Id));        
    
    }

    //FSCEC-1918 - Loan Account (MultiOwner: not shared between owners)
    @isTest
    static void loanAccountUpdateMultiOwner() {
          SharingTestUtil.populateVbStructure();
          
          User vbX = SharingTestUtil.vbAX1user;
          User vbY = SharingTestUtil.vbAY1user;
  
          User managerX = SharingTestUtil.vbAXuser;
          User managerY = SharingTestUtil.vbAYuser;
          
          User deputyX = SharingTestUtil.deputyXtoAx1;        
          User deputyY = SharingTestUtil.deputyYtoAy1;
          
          User assistantX = SharingTestUtil.ass1toAX1;
          User assistantY = SharingTestUtil.ass3toAY1;
          
          Account customerA = SharingTestUtil.multi4CustomerAccount;
          Account customerB = SharingTestUtil.multi1CustomerAccount;
          
          Id loanAccRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdLoanAccount();
          List<FinServ__FinancialAccount__c> loanAccounts = new List<FinServ__FinancialAccount__c>();
  
          FinServ__FinancialAccount__c custA_XloanAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,loanAccRtId,'LoanAcc'+TestDataUtility.getRandomNumber(3));
          loanAccounts.add(custA_XloanAcc);
  
          FinServ__FinancialAccount__c custA_YloanAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,loanAccRtId,'LoanAcc'+TestDataUtility.getRandomNumber(3));
          loanAccounts.add(custA_YloanAcc);
  
          FinServ__FinancialAccount__c custB_XloanAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,loanAccRtId,'LoanAcc'+TestDataUtility.getRandomNumber(3));
          loanAccounts.add(custB_XloanAcc);
  
          FinServ__FinancialAccount__c custB_YloanAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,loanAccRtId,'LoanAcc'+TestDataUtility.getRandomNumber(3));
          custB_YloanAcc.OwnerId = vbY.Id;
          loanAccounts.add(custB_YloanAcc);
  
          Map<Id,FinServ__FinancialAccount__c> vbXloanAcc;
          Map<Id,FinServ__FinancialAccount__c> vbYloanAcc;
          
          //Assistants
          Map<Id,FinServ__FinancialAccount__c> assistantXloanAcc;
          Map<Id,FinServ__FinancialAccount__c> assistantYloanAcc;
          //Deputies
          Map<Id,FinServ__FinancialAccount__c> deputyXloanAcc;
          Map<Id,FinServ__FinancialAccount__c> deputyYloanAcc;
          //Hierarchy
          Map<Id,FinServ__FinancialAccount__c> managerXloanAcc;
          Map<Id,FinServ__FinancialAccount__c> managerYloanAcc;
          
          Test.startTest();
              insert loanAccounts;
              
              vbXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
              System.assertEquals(2,vbXloanAcc.size()); //je 1 Loan Account von 2 Customers
              System.assertNotEquals(null, vbXloanAcc.get(custA_XloanAcc.Id));
              System.assertNotEquals(null, vbXloanAcc.get(custB_XloanAcc.Id));
              vbYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
              System.assertEquals(2,vbYloanAcc.size()); //je 1 Loan Account von 2 Customers
              System.assertNotEquals(null, vbYloanAcc.get(custA_YloanAcc.Id));
              System.assertNotEquals(null, vbYloanAcc.get(custB_YloanAcc.Id));
              //Assistants
              assistantXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
              System.assertEquals(1, assistantXloanAcc.size()); //1 Loan Account von Customer B (A ausgeblendet)
              System.assertNotEquals(null, assistantXloanAcc.get(custB_XloanAcc.Id));
              assistantYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
              System.assertEquals(1, assistantYloanAcc.size()); //1 Loan Account von Customer B (A ausgeblendet)
              System.assertNotEquals(null, assistantYloanAcc.get(custB_YloanAcc.Id));
              //Deputies
              deputyXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
              System.assertEquals(1, deputyXloanAcc.size()); //1 Loan Account von Customer B (A ausgeblendet)
              System.assertNotEquals(null, deputyXloanAcc.get(custB_XloanAcc.Id));
              deputyYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
              System.assertEquals(1, deputyYloanAcc.size()); //1 Loan Account von Customer B (A ausgeblendet)
              System.assertNotEquals(null, deputyYloanAcc.get(custB_YloanAcc.Id));
              //Hierarchy
              managerXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
              System.assertEquals(1, managerXloanAcc.size()); //1 Loan Account von Customer B (A ausgeblendet)
              System.assertNotEquals(null, managerXloanAcc.get(custB_XloanAcc.Id));
              managerYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
              System.assertEquals(1, managerYloanAcc.size()); //1 Loan Account von Customer B (A ausgeblendet)
              System.assertNotEquals(null, managerYloanAcc.get(custB_YloanAcc.Id));
  
              //Now switch the visibility
              customerA.HideForAssistantsAndDeputies__c = false;
              customerA.HideForHierarchy__c = false;
              customerB.HideForAssistantsAndDeputies__c = true;
              customerB.HideForHierarchy__c = true;
              update customerA;
              update customerB;
              
              Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'LoanAccount');
              Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
          
          Test.stopTest();
  
          vbXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
          System.assertEquals(2,vbXloanAcc.size()); //je 1 Loan Account von 2 Customers
          System.assertNotEquals(null, vbXloanAcc.get(custA_XloanAcc.Id));
          System.assertNotEquals(null, vbXloanAcc.get(custB_XloanAcc.Id));
          vbYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
          System.assertEquals(2,vbYloanAcc.size()); //je 1 Loan Account von 2 Customers
          System.assertNotEquals(null, vbYloanAcc.get(custA_YloanAcc.Id));
          System.assertNotEquals(null, vbYloanAcc.get(custB_YloanAcc.Id));
          //Assistants
          assistantXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
          System.assertEquals(1, assistantXloanAcc.size()); //1 Loan Account von Customer A (B ausgeblendet)
          System.assertNotEquals(null, assistantXloanAcc.get(custA_XloanAcc.Id));
          assistantYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
          System.assertEquals(1, assistantYloanAcc.size()); //1 Loan Account von von Customer A (B ausgeblendet)
          System.assertNotEquals(null, assistantYloanAcc.get(custA_YloanAcc.Id));
          //Deputies
          deputyXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
          System.assertEquals(1, deputyXloanAcc.size()); //1 Loan Account von Customer A (B ausgeblendet)
          System.assertNotEquals(null, deputyXloanAcc.get(custA_XloanAcc.Id));
          deputyYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
          System.assertEquals(1, deputyYloanAcc.size()); //1 Loan Account von Customer A (B ausgeblendet)
          System.assertNotEquals(null, deputyYloanAcc.get(custA_YloanAcc.Id));
          //Hierarchy
          managerXloanAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
          System.assertEquals(1, managerXloanAcc.size()); //1 Loan Account von Customer A (B ausgeblendet)
          System.assertNotEquals(null, managerXloanAcc.get(custA_XloanAcc.Id));
          managerYloanAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
          System.assertEquals(1, managerYloanAcc.size()); //1 Loan Account von Customer A (B ausgeblendet)
          System.assertNotEquals(null, managerYloanAcc.get(custA_YloanAcc.Id));        
      
    }

    //FSCEC-1918 - Mortgage (MultiOwner: not shared between owners)
    @isTest
    static void mortgageUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;
        
        Id mortgageRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdMortgage();
        List<FinServ__FinancialAccount__c> mortgages = new List<FinServ__FinancialAccount__c>();

        FinServ__FinancialAccount__c custA_XmortAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,mortgageRtId,'Mortgage'+TestDataUtility.getRandomNumber(3));
        mortgages.add(custA_XmortAcc);

        FinServ__FinancialAccount__c custA_YmortAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,mortgageRtId,'Mortgage'+TestDataUtility.getRandomNumber(3));
        mortgages.add(custA_YmortAcc);

        FinServ__FinancialAccount__c custB_XmortAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,mortgageRtId,'Mortgage'+TestDataUtility.getRandomNumber(3));
        mortgages.add(custB_XmortAcc);

        FinServ__FinancialAccount__c custB_YmortAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,mortgageRtId,'Mortgage'+TestDataUtility.getRandomNumber(3));
        custB_YmortAcc.OwnerId = vbY.Id;
        mortgages.add(custB_YmortAcc);

        Map<Id,FinServ__FinancialAccount__c> vbXmortAcc;
        Map<Id,FinServ__FinancialAccount__c> vbYmortAcc;
        
        //Assistants
        Map<Id,FinServ__FinancialAccount__c> assistantXmortAcc;
        Map<Id,FinServ__FinancialAccount__c> assistantYmortAcc;
        //Deputies
        Map<Id,FinServ__FinancialAccount__c> deputyXmortAcc;
        Map<Id,FinServ__FinancialAccount__c> deputyYmortAcc;
        //Hierarchy
        Map<Id,FinServ__FinancialAccount__c> managerXmortAcc;
        Map<Id,FinServ__FinancialAccount__c> managerYmortAcc;
        
        Test.startTest();
            insert mortgages;
            
            vbXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
            System.assertEquals(2,vbXmortAcc.size()); //je 1 Mortgage Account von 2 Customers
            System.assertNotEquals(null, vbXmortAcc.get(custA_XmortAcc.Id));
            System.assertNotEquals(null, vbXmortAcc.get(custB_XmortAcc.Id));
            vbYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
            System.assertEquals(2,vbYmortAcc.size()); //je 1 Mortgage Account von 2 Customers
            System.assertNotEquals(null, vbYmortAcc.get(custA_YmortAcc.Id));
            System.assertNotEquals(null, vbYmortAcc.get(custB_YmortAcc.Id));
            //Assistants
            assistantXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
            System.assertEquals(1, assistantXmortAcc.size()); //1 Mortgage Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXmortAcc.get(custB_XmortAcc.Id));
            assistantYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
            System.assertEquals(1, assistantYmortAcc.size()); //1 Mortgage Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYmortAcc.get(custB_YmortAcc.Id));
            //Deputies
            deputyXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
            System.assertEquals(1, deputyXmortAcc.size()); //1 Mortgage Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXmortAcc.get(custB_XmortAcc.Id));
            deputyYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
            System.assertEquals(1, deputyYmortAcc.size()); //1 Mortgage Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYmortAcc.get(custB_YmortAcc.Id));
            //Hierarchy
            managerXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
            System.assertEquals(1, managerXmortAcc.size()); //1 Mortgage Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXmortAcc.get(custB_XmortAcc.Id));
            managerYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
            System.assertEquals(1, managerYmortAcc.size()); //1 Mortgage Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYmortAcc.get(custB_YmortAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'Mortgage');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
        System.assertEquals(2,vbXmortAcc.size()); //je 1 Mortgage Account von 2 Customers
        System.assertNotEquals(null, vbXmortAcc.get(custA_XmortAcc.Id));
        System.assertNotEquals(null, vbXmortAcc.get(custB_XmortAcc.Id));
        vbYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
        System.assertEquals(2,vbYmortAcc.size()); //je 1 Mortgage Account von 2 Customers
        System.assertNotEquals(null, vbYmortAcc.get(custA_YmortAcc.Id));
        System.assertNotEquals(null, vbYmortAcc.get(custB_YmortAcc.Id));
        //Assistants
        assistantXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
        System.assertEquals(1, assistantXmortAcc.size()); //1 Mortgage Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXmortAcc.get(custA_XmortAcc.Id));
        assistantYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
        System.assertEquals(1, assistantYmortAcc.size()); //1 Mortgage Account von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYmortAcc.get(custA_YmortAcc.Id));
        //Deputies
        deputyXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
        System.assertEquals(1, deputyXmortAcc.size()); //1 Mortgage Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXmortAcc.get(custA_XmortAcc.Id));
        deputyYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
        System.assertEquals(1, deputyYmortAcc.size()); //1 Mortgage Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYmortAcc.get(custA_YmortAcc.Id));
        //Hierarchy
        managerXmortAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
        System.assertEquals(1, managerXmortAcc.size()); //1 Mortgage Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXmortAcc.get(custA_XmortAcc.Id));
        managerYmortAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
        System.assertEquals(1, managerYmortAcc.size()); //1 Mortgage Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYmortAcc.get(custA_YmortAcc.Id));            
    }

    //FSCEC-1918 - Savings Account (MultiOwner: not shared between owners)
    @isTest
    static void savingsAccountUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;
        
        Id savingsAccountRtId = RecordTypeHelper.getFinancialAccountRecordTypeIdSavingsAccount();
        List<FinServ__FinancialAccount__c> savingsAccounts = new List<FinServ__FinancialAccount__c>();

        FinServ__FinancialAccount__c custA_XsavAcc = SharingTestUtil.createFinancialAccount(customerA,vbX,savingsAccountRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        savingsAccounts.add(custA_XsavAcc);

        FinServ__FinancialAccount__c custA_YsavAcc = SharingTestUtil.createFinancialAccount(customerA,vbY,savingsAccountRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        savingsAccounts.add(custA_YsavAcc);

        FinServ__FinancialAccount__c custB_XsavAcc = SharingTestUtil.createFinancialAccount(customerB,vbX,savingsAccountRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        savingsAccounts.add(custB_XsavAcc);

        FinServ__FinancialAccount__c custB_YsavAcc = SharingTestUtil.createFinancialAccount(customerB,vbY,savingsAccountRtId,'GeneralAcc'+TestDataUtility.getRandomNumber(3));
        custB_YsavAcc.OwnerId = vbY.Id;
        savingsAccounts.add(custB_YsavAcc);

        Map<Id,FinServ__FinancialAccount__c> vbXsavAcc;
        Map<Id,FinServ__FinancialAccount__c> vbYsavAcc;
        
        //Assistants
        Map<Id,FinServ__FinancialAccount__c> assistantXsavAcc;
        Map<Id,FinServ__FinancialAccount__c> assistantYsavAcc;
        //Deputies
        Map<Id,FinServ__FinancialAccount__c> deputyXsavAcc;
        Map<Id,FinServ__FinancialAccount__c> deputyYsavAcc;
        //Hierarchy
        Map<Id,FinServ__FinancialAccount__c> managerXsavAcc;
        Map<Id,FinServ__FinancialAccount__c> managerYsavAcc;
        
        Test.startTest();
            insert savingsAccounts;
            
            vbXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
            System.assertEquals(2,vbXsavAcc.size()); //je 1 Savings Account von 2 Customers
            System.assertNotEquals(null, vbXsavAcc.get(custA_XsavAcc.Id));
            System.assertNotEquals(null, vbXsavAcc.get(custB_XsavAcc.Id));
            vbYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
            System.assertEquals(2,vbYsavAcc.size()); //je 1 Savings Account von 2 Customers
            System.assertNotEquals(null, vbYsavAcc.get(custA_YsavAcc.Id));
            System.assertNotEquals(null, vbYsavAcc.get(custB_YsavAcc.Id));
            //Assistants
            assistantXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
            System.assertEquals(1, assistantXsavAcc.size()); //1 Savings Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXsavAcc.get(custB_XsavAcc.Id));
            assistantYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
            System.assertEquals(1, assistantYsavAcc.size()); //1 Savings Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYsavAcc.get(custB_YsavAcc.Id));
            //Deputies
            deputyXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
            System.assertEquals(1, deputyXsavAcc.size()); //1 Savings Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXsavAcc.get(custB_XsavAcc.Id));
            deputyYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
            System.assertEquals(1, deputyYsavAcc.size()); //1 Savings Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYsavAcc.get(custB_YsavAcc.Id));
            //Hierarchy
            managerXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
            System.assertEquals(1, managerXsavAcc.size()); //1 Savings Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXsavAcc.get(custB_XsavAcc.Id));
            managerYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
            System.assertEquals(1, managerYsavAcc.size()); //1 Savings Account von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYsavAcc.get(custB_YsavAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('FinServ__FinancialAccount__c', 'SavingsAccount');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(vbX);
        System.assertEquals(2,vbXsavAcc.size()); //je 1 Savings Account von 2 Customers
        System.assertNotEquals(null, vbXsavAcc.get(custA_XsavAcc.Id));
        System.assertNotEquals(null, vbXsavAcc.get(custB_XsavAcc.Id));
        vbYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(vbY);
        System.assertEquals(2,vbYsavAcc.size()); //je 1 Savings Account von 2 Customers
        System.assertNotEquals(null, vbYsavAcc.get(custA_YsavAcc.Id));
        System.assertNotEquals(null, vbYsavAcc.get(custB_YsavAcc.Id));
        //Assistants
        assistantXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantX);
        System.assertEquals(1, assistantXsavAcc.size()); //1 Savings Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXsavAcc.get(custA_XsavAcc.Id));
        assistantYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(assistantY);
        System.assertEquals(1, assistantYsavAcc.size()); //1 Savings Account von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYsavAcc.get(custA_YsavAcc.Id));
        //Deputies
        deputyXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyX);
        System.assertEquals(1, deputyXsavAcc.size()); //1 Savings Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXsavAcc.get(custA_XsavAcc.Id));
        deputyYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(deputyY);
        System.assertEquals(1, deputyYsavAcc.size()); //1 Savings Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYsavAcc.get(custA_YsavAcc.Id));
        //Hierarchy
        managerXsavAcc = SharingTestUtil.financialAccountsVisibleForUser(managerX);
        System.assertEquals(1, managerXsavAcc.size()); //1 Savings Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXsavAcc.get(custA_XsavAcc.Id));
        managerYsavAcc = SharingTestUtil.financialAccountsVisibleForUser(managerY);
        System.assertEquals(1, managerYsavAcc.size()); //1 Savings Account von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYsavAcc.get(custA_YsavAcc.Id));        
    
    }
    //FSCEC-1918 - CarInsurance Policy (MultiOwner: not shared between owners)
    @isTest
    static void carInsuranceUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;

        Product2 insProd = new Product2(Name='Car Insurance Test Product',ContractType__c='OwnContract',Family='InsurancePolicy');
        insert insProd;
        
        Id carInsuranceRtId = RecordTypeHelper.getInsurancePolicyRecordTypeIdCarInsurance();
        List<InsurancePolicy> carInsurances = new List<InsurancePolicy>();

        InsurancePolicy custA_XcarInsPol = SharingTestUtil.createInsurancePolicy(customerA,vbX,insProd,true,carInsuranceRtId);
        carInsurances.add(custA_XcarInsPol);

        InsurancePolicy custA_YcarInsPol = SharingTestUtil.createInsurancePolicy(customerA,vbY,insProd,true,carInsuranceRtId);
        carInsurances.add(custA_YcarInsPol);

        InsurancePolicy custB_XcarInsPol = SharingTestUtil.createInsurancePolicy(customerB,vbX,insProd,true,carInsuranceRtId);
        carInsurances.add(custB_XcarInsPol);

        InsurancePolicy custB_YcarInsPol = SharingTestUtil.createInsurancePolicy(customerB,vbY,insProd,true,carInsuranceRtId);
        custB_YcarInsPol.OwnerId = vbY.Id;
        carInsurances.add(custB_YcarInsPol);

        Map<Id,InsurancePolicy> vbXcarInsPol;
        Map<Id,InsurancePolicy> vbYcarInsPol;
        
        //Assistants
        Map<Id,InsurancePolicy> assistantXcarInsPol;
        Map<Id,InsurancePolicy> assistantYcarInsPol;
        //Deputies
        Map<Id,InsurancePolicy> deputyXcarInsPol;
        Map<Id,InsurancePolicy> deputyYcarInsPol;
        //Hierarchy
        Map<Id,InsurancePolicy> managerXcarInsPol;
        Map<Id,InsurancePolicy> managerYcarInsPol;
        
        Test.startTest();
            insert carInsurances;
            
            vbXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
            System.assertEquals(2,vbXcarInsPol.size()); //je 1 Car Insurance Policy von 2 Customers
            System.assertNotEquals(null, vbXcarInsPol.get(custA_XcarInsPol.Id));
            System.assertNotEquals(null, vbXcarInsPol.get(custB_XcarInsPol.Id));
            vbYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
            System.assertEquals(2,vbYcarInsPol.size()); //je 1 Car Insurance Policy von 2 Customers
            System.assertNotEquals(null, vbYcarInsPol.get(custA_YcarInsPol.Id));
            System.assertNotEquals(null, vbYcarInsPol.get(custB_YcarInsPol.Id));
            //Assistants
            assistantXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
            System.assertEquals(1, assistantXcarInsPol.size()); //1 Car Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXcarInsPol.get(custB_XcarInsPol.Id));
            assistantYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
            System.assertEquals(1, assistantYcarInsPol.size()); //1 Car Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYcarInsPol.get(custB_YcarInsPol.Id));
            //Deputies
            deputyXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
            System.assertEquals(1, deputyXcarInsPol.size()); //1 Car Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXcarInsPol.get(custB_XcarInsPol.Id));
            deputyYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
            System.assertEquals(1, deputyYcarInsPol.size()); //1 Car Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYcarInsPol.get(custB_YcarInsPol.Id));
            //Hierarchy
            managerXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
            System.assertEquals(1, managerXcarInsPol.size()); //1 Car Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXcarInsPol.get(custB_XcarInsPol.Id));
            managerYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
            System.assertEquals(1, managerYcarInsPol.size()); //1 Car Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYcarInsPol.get(custB_YcarInsPol.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('InsurancePolicy', 'CarInsurance');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
        System.assertEquals(2,vbXcarInsPol.size()); //je 1 Car Insurance Policy von 2 Customers
        System.assertNotEquals(null, vbXcarInsPol.get(custA_XcarInsPol.Id));
        System.assertNotEquals(null, vbXcarInsPol.get(custB_XcarInsPol.Id));
        vbYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
        System.assertEquals(2,vbYcarInsPol.size()); //je 1 Car Insurance Policy von 2 Customers
        System.assertNotEquals(null, vbYcarInsPol.get(custA_YcarInsPol.Id));
        System.assertNotEquals(null, vbYcarInsPol.get(custB_YcarInsPol.Id));
        //Assistants
        assistantXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
        System.assertEquals(1, assistantXcarInsPol.size()); //1 Car Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXcarInsPol.get(custA_XcarInsPol.Id));
        assistantYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
        System.assertEquals(1, assistantYcarInsPol.size()); //1 Car Insurance Policy von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYcarInsPol.get(custA_YcarInsPol.Id));
        //Deputies
        deputyXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
        System.assertEquals(1, deputyXcarInsPol.size()); //1 Car Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXcarInsPol.get(custA_XcarInsPol.Id));
        deputyYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
        System.assertEquals(1, deputyYcarInsPol.size()); //1 Car Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYcarInsPol.get(custA_YcarInsPol.Id));
        //Hierarchy
        managerXcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
        System.assertEquals(1, managerXcarInsPol.size()); //1 Car Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXcarInsPol.get(custA_XcarInsPol.Id));
        managerYcarInsPol = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
        System.assertEquals(1, managerYcarInsPol.size()); //1 Car Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYcarInsPol.get(custA_YcarInsPol.Id));        
    
    }

    //FSCEC-1918 - HealthInsurance Policy (MultiOwner: not shared between owners)
    @isTest
    static void healthInsuranceUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;

        Product2 insProd = new Product2(Name='Health Insurance Test Product',ContractType__c='OwnContract',Family='InsurancePolicy');
        insert insProd;
        
        Id healthInsRtId = RecordTypeHelper.getInsurancePolicyRecordTypeIdHealthInsurance();
        List<InsurancePolicy> healthInsurances = new List<InsurancePolicy>();

        InsurancePolicy custA_XhealthIns = SharingTestUtil.createInsurancePolicy(customerA,vbX,insProd,true,healthInsRtId);
        healthInsurances.add(custA_XhealthIns);

        InsurancePolicy custA_YhealthIns = SharingTestUtil.createInsurancePolicy(customerA,vbY,insProd,true,healthInsRtId);
        healthInsurances.add(custA_YhealthIns);

        InsurancePolicy custB_XhealthIns = SharingTestUtil.createInsurancePolicy(customerB,vbX,insProd,true,healthInsRtId);
        healthInsurances.add(custB_XhealthIns);

        InsurancePolicy custB_YhealthIns = SharingTestUtil.createInsurancePolicy(customerB,vbY,insProd,true,healthInsRtId);
        custB_YhealthIns.OwnerId = vbY.Id;
        healthInsurances.add(custB_YhealthIns);

        Map<Id,InsurancePolicy> vbXhealthIns;
        Map<Id,InsurancePolicy> vbYhealthIns;
        
        //Assistants
        Map<Id,InsurancePolicy> assistantXhealthIns;
        Map<Id,InsurancePolicy> assistantYhealthIns;
        //Deputies
        Map<Id,InsurancePolicy> deputyXhealthIns;
        Map<Id,InsurancePolicy> deputyYhealthIns;
        //Hierarchy
        Map<Id,InsurancePolicy> managerXhealthIns;
        Map<Id,InsurancePolicy> managerYhealthIns;
        
        Test.startTest();
            insert healthInsurances;
            
            vbXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
            System.assertEquals(2,vbXhealthIns.size()); //je 1 Health Insurance Policy von 2 Customers
            System.assertNotEquals(null, vbXhealthIns.get(custA_XhealthIns.Id));
            System.assertNotEquals(null, vbXhealthIns.get(custB_XhealthIns.Id));
            vbYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
            System.assertEquals(2,vbYhealthIns.size()); //je 1 Health Insurance Policy von 2 Customers
            System.assertNotEquals(null, vbYhealthIns.get(custA_YhealthIns.Id));
            System.assertNotEquals(null, vbYhealthIns.get(custB_YhealthIns.Id));
            //Assistants
            assistantXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
            System.assertEquals(1, assistantXhealthIns.size()); //1 Health Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXhealthIns.get(custB_XhealthIns.Id));
            assistantYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
            System.assertEquals(1, assistantYhealthIns.size()); //1 Health Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYhealthIns.get(custB_YhealthIns.Id));
            //Deputies
            deputyXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
            System.assertEquals(1, deputyXhealthIns.size()); //1 Health Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXhealthIns.get(custB_XhealthIns.Id));
            deputyYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
            System.assertEquals(1, deputyYhealthIns.size()); //1 Health Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYhealthIns.get(custB_YhealthIns.Id));
            //Hierarchy
            managerXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
            System.assertEquals(1, managerXhealthIns.size()); //1 Health Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXhealthIns.get(custB_XhealthIns.Id));
            managerYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
            System.assertEquals(1, managerYhealthIns.size()); //1 Health Insurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYhealthIns.get(custB_YhealthIns.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('InsurancePolicy', 'HealthInsurance');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
        System.assertEquals(2,vbXhealthIns.size()); //je 1 Health Insurance Policy von 2 Customers
        System.assertNotEquals(null, vbXhealthIns.get(custA_XhealthIns.Id));
        System.assertNotEquals(null, vbXhealthIns.get(custB_XhealthIns.Id));
        vbYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
        System.assertEquals(2,vbYhealthIns.size()); //je 1 Health Insurance Policy von 2 Customers
        System.assertNotEquals(null, vbYhealthIns.get(custA_YhealthIns.Id));
        System.assertNotEquals(null, vbYhealthIns.get(custB_YhealthIns.Id));
        //Assistants
        assistantXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
        System.assertEquals(1, assistantXhealthIns.size()); //1 Health Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXhealthIns.get(custA_XhealthIns.Id));
        assistantYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
        System.assertEquals(1, assistantYhealthIns.size()); //1 Health Insurance Policy von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYhealthIns.get(custA_YhealthIns.Id));
        //Deputies
        deputyXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
        System.assertEquals(1, deputyXhealthIns.size()); //1 Health Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXhealthIns.get(custA_XhealthIns.Id));
        deputyYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
        System.assertEquals(1, deputyYhealthIns.size()); //1 Health Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYhealthIns.get(custA_YhealthIns.Id));
        //Hierarchy
        managerXhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
        System.assertEquals(1, managerXhealthIns.size()); //1 Health Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXhealthIns.get(custA_XhealthIns.Id));
        managerYhealthIns = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
        System.assertEquals(1, managerYhealthIns.size()); //1 Health Insurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYhealthIns.get(custA_YhealthIns.Id));        
    
    }

    //FSCEC-1918 - LifeInsurance Policy (MultiOwner: not shared between owners)
    @isTest
    static void lifeInsuranceUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;

        Product2 insProd = new Product2(Name='Life Insurance Test Product',ContractType__c='OwnContract',Family='InsurancePolicy');
        insert insProd;
        
        Id LifeInsRtId = RecordTypeHelper.getInsurancePolicyRecordTypeIdLifeInsurance();
        List<InsurancePolicy> lifeInsurances = new List<InsurancePolicy>();

        InsurancePolicy custA_XlifeInsAcc = SharingTestUtil.createInsurancePolicy(customerA,vbX,insProd,true,LifeInsRtId);
        lifeInsurances.add(custA_XlifeInsAcc);

        InsurancePolicy custA_YlifeInsAcc = SharingTestUtil.createInsurancePolicy(customerA,vbY,insProd,true,LifeInsRtId);
        lifeInsurances.add(custA_YlifeInsAcc);

        InsurancePolicy custB_XlifeInsAcc = SharingTestUtil.createInsurancePolicy(customerB,vbX,insProd,true,LifeInsRtId);
        lifeInsurances.add(custB_XlifeInsAcc);

        InsurancePolicy custB_YlifeInsAcc = SharingTestUtil.createInsurancePolicy(customerB,vbY,insProd,true,LifeInsRtId);
        custB_YlifeInsAcc.OwnerId = vbY.Id;
        lifeInsurances.add(custB_YlifeInsAcc);

        Map<Id,InsurancePolicy> vbXlifeInsAcc;
        Map<Id,InsurancePolicy> vbYlifeInsAcc;
        
        //Assistants
        Map<Id,InsurancePolicy> assistantXlifeInsAcc;
        Map<Id,InsurancePolicy> assistantYlifeInsAcc;
        //Deputies
        Map<Id,InsurancePolicy> deputyXlifeInsAcc;
        Map<Id,InsurancePolicy> deputyYlifeInsAcc;
        //Hierarchy
        Map<Id,InsurancePolicy> managerXlifeInsAcc;
        Map<Id,InsurancePolicy> managerYlifeInsAcc;
        
        Test.startTest();
            insert lifeInsurances;
            
            vbXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
            System.assertEquals(2,vbXlifeInsAcc.size()); //je 1 LifeInsurance Policy von 2 Customers
            System.assertNotEquals(null, vbXlifeInsAcc.get(custA_XlifeInsAcc.Id));
            System.assertNotEquals(null, vbXlifeInsAcc.get(custB_XlifeInsAcc.Id));
            vbYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
            System.assertEquals(2,vbYlifeInsAcc.size()); //je 1 LifeInsurance Policy von 2 Customers
            System.assertNotEquals(null, vbYlifeInsAcc.get(custA_YlifeInsAcc.Id));
            System.assertNotEquals(null, vbYlifeInsAcc.get(custB_YlifeInsAcc.Id));
            //Assistants
            assistantXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
            System.assertEquals(1, assistantXlifeInsAcc.size()); //1 LifeInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXlifeInsAcc.get(custB_XlifeInsAcc.Id));
            assistantYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
            System.assertEquals(1, assistantYlifeInsAcc.size()); //1 LifeInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYlifeInsAcc.get(custB_YlifeInsAcc.Id));
            //Deputies
            deputyXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
            System.assertEquals(1, deputyXlifeInsAcc.size()); //1 LifeInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXlifeInsAcc.get(custB_XlifeInsAcc.Id));
            deputyYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
            System.assertEquals(1, deputyYlifeInsAcc.size()); //1 LifeInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYlifeInsAcc.get(custB_YlifeInsAcc.Id));
            //Hierarchy
            managerXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
            System.assertEquals(1, managerXlifeInsAcc.size()); //1 LifeInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXlifeInsAcc.get(custB_XlifeInsAcc.Id));
            managerYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
            System.assertEquals(1, managerYlifeInsAcc.size()); //1 LifeInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYlifeInsAcc.get(custB_YlifeInsAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('InsurancePolicy', 'LifeInsurance');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
        System.assertEquals(2,vbXlifeInsAcc.size()); //je 1 LifeInsurance Policy von 2 Customers
        System.assertNotEquals(null, vbXlifeInsAcc.get(custA_XlifeInsAcc.Id));
        System.assertNotEquals(null, vbXlifeInsAcc.get(custB_XlifeInsAcc.Id));
        vbYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
        System.assertEquals(2,vbYlifeInsAcc.size()); //je 1 LifeInsurance Policy von 2 Customers
        System.assertNotEquals(null, vbYlifeInsAcc.get(custA_YlifeInsAcc.Id));
        System.assertNotEquals(null, vbYlifeInsAcc.get(custB_YlifeInsAcc.Id));
        //Assistants
        assistantXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
        System.assertEquals(1, assistantXlifeInsAcc.size()); //1 LifeInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXlifeInsAcc.get(custA_XlifeInsAcc.Id));
        assistantYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
        System.assertEquals(1, assistantYlifeInsAcc.size()); //1 LifeInsurance Policy von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYlifeInsAcc.get(custA_YlifeInsAcc.Id));
        //Deputies
        deputyXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
        System.assertEquals(1, deputyXlifeInsAcc.size()); //1 LifeInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXlifeInsAcc.get(custA_XlifeInsAcc.Id));
        deputyYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
        System.assertEquals(1, deputyYlifeInsAcc.size()); //1 LifeInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYlifeInsAcc.get(custA_YlifeInsAcc.Id));
        //Hierarchy
        managerXlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
        System.assertEquals(1, managerXlifeInsAcc.size()); //1 LifeInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXlifeInsAcc.get(custA_XlifeInsAcc.Id));
        managerYlifeInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
        System.assertEquals(1, managerYlifeInsAcc.size()); //1 LifeInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYlifeInsAcc.get(custA_YlifeInsAcc.Id));        
    
    }

    //FSCEC-1918 - LegalInsurance Policy (MultiOwner: not shared between owners)
    @isTest
    static void legalInsuranceUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;

        Product2 insProd = new Product2(Name='Legal Insurance Test Product',ContractType__c='OwnContract',Family='InsurancePolicy');
        insert insProd;
        
        Id legalInsRtId = RecordTypeHelper.getInsurancePolicyRecordTypeIdLegalInsurance();
        List<InsurancePolicy> legalInsurances = new List<InsurancePolicy>();

        InsurancePolicy custA_XlegalInsAcc = SharingTestUtil.createInsurancePolicy(customerA,vbX,insProd,true,legalInsRtId);
        legalInsurances.add(custA_XlegalInsAcc);

        InsurancePolicy custA_YlegalInsAcc = SharingTestUtil.createInsurancePolicy(customerA,vbY,insProd,true,legalInsRtId);
        legalInsurances.add(custA_YlegalInsAcc);

        InsurancePolicy custB_XlegalInsAcc = SharingTestUtil.createInsurancePolicy(customerB,vbX,insProd,true,legalInsRtId);
        legalInsurances.add(custB_XlegalInsAcc);

        InsurancePolicy custB_YlegalInsAcc = SharingTestUtil.createInsurancePolicy(customerB,vbY,insProd,true,legalInsRtId);
        custB_YlegalInsAcc.OwnerId = vbY.Id;
        legalInsurances.add(custB_YlegalInsAcc);

        Map<Id,InsurancePolicy> vbXlegalInsAcc;
        Map<Id,InsurancePolicy> vbYlegalInsAcc;
        
        //Assistants
        Map<Id,InsurancePolicy> assistantXlegalInsAcc;
        Map<Id,InsurancePolicy> assistantYlegalInsAcc;
        //Deputies
        Map<Id,InsurancePolicy> deputyXlegalInsAcc;
        Map<Id,InsurancePolicy> deputyYlegalInsAcc;
        //Hierarchy
        Map<Id,InsurancePolicy> managerXlegalInsAcc;
        Map<Id,InsurancePolicy> managerYlegalInsAcc;
        
        Test.startTest();
            insert legalInsurances;
            
            vbXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
            System.assertEquals(2,vbXlegalInsAcc.size()); //je 1 LegalInsurance Policy von 2 Customers
            System.assertNotEquals(null, vbXlegalInsAcc.get(custA_XlegalInsAcc.Id));
            System.assertNotEquals(null, vbXlegalInsAcc.get(custB_XlegalInsAcc.Id));
            vbYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
            System.assertEquals(2,vbYlegalInsAcc.size()); //je 1 LegalInsurance Policy von 2 Customers
            System.assertNotEquals(null, vbYlegalInsAcc.get(custA_YlegalInsAcc.Id));
            System.assertNotEquals(null, vbYlegalInsAcc.get(custB_YlegalInsAcc.Id));
            //Assistants
            assistantXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
            System.assertEquals(1, assistantXlegalInsAcc.size()); //1 LegalInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXlegalInsAcc.get(custB_XlegalInsAcc.Id));
            assistantYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
            System.assertEquals(1, assistantYlegalInsAcc.size()); //1 LegalInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYlegalInsAcc.get(custB_YlegalInsAcc.Id));
            //Deputies
            deputyXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
            System.assertEquals(1, deputyXlegalInsAcc.size()); //1 LegalInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXlegalInsAcc.get(custB_XlegalInsAcc.Id));
            deputyYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
            System.assertEquals(1, deputyYlegalInsAcc.size()); //1 LegalInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYlegalInsAcc.get(custB_YlegalInsAcc.Id));
            //Hierarchy
            managerXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
            System.assertEquals(1, managerXlegalInsAcc.size()); //1 LegalInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXlegalInsAcc.get(custB_XlegalInsAcc.Id));
            managerYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
            System.assertEquals(1, managerYlegalInsAcc.size()); //1 LegalInsurance Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYlegalInsAcc.get(custB_YlegalInsAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('InsurancePolicy', 'LegalInsurance');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
        System.assertEquals(2,vbXlegalInsAcc.size()); //je 1 LegalInsurance Policy von 2 Customers
        System.assertNotEquals(null, vbXlegalInsAcc.get(custA_XlegalInsAcc.Id));
        System.assertNotEquals(null, vbXlegalInsAcc.get(custB_XlegalInsAcc.Id));
        vbYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
        System.assertEquals(2,vbYlegalInsAcc.size()); //je 1 LegalInsurance Policy von 2 Customers
        System.assertNotEquals(null, vbYlegalInsAcc.get(custA_YlegalInsAcc.Id));
        System.assertNotEquals(null, vbYlegalInsAcc.get(custB_YlegalInsAcc.Id));
        //Assistants
        assistantXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
        System.assertEquals(1, assistantXlegalInsAcc.size()); //1 LegalInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXlegalInsAcc.get(custA_XlegalInsAcc.Id));
        assistantYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
        System.assertEquals(1, assistantYlegalInsAcc.size()); //1 LegalInsurance Policy von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYlegalInsAcc.get(custA_YlegalInsAcc.Id));
        //Deputies
        deputyXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
        System.assertEquals(1, deputyXlegalInsAcc.size()); //1 LegalInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXlegalInsAcc.get(custA_XlegalInsAcc.Id));
        deputyYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
        System.assertEquals(1, deputyYlegalInsAcc.size()); //1 LegalInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYlegalInsAcc.get(custA_YlegalInsAcc.Id));
        //Hierarchy
        managerXlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
        System.assertEquals(1, managerXlegalInsAcc.size()); //1 LegalInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXlegalInsAcc.get(custA_XlegalInsAcc.Id));
        managerYlegalInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
        System.assertEquals(1, managerYlegalInsAcc.size()); //1 LegalInsurance Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYlegalInsAcc.get(custA_YlegalInsAcc.Id));        
    
    }

    //FSCEC-1918 - PropertyInsurance Policy (MultiOwner: not shared between owners)
    @isTest
    static void propertyInsuranceUpdateMultiOwner() {
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User vbY = SharingTestUtil.vbAY1user;

        User managerX = SharingTestUtil.vbAXuser;
        User managerY = SharingTestUtil.vbAYuser;
        
        User deputyX = SharingTestUtil.deputyXtoAx1;        
        User deputyY = SharingTestUtil.deputyYtoAy1;
        
        User assistantX = SharingTestUtil.ass1toAX1;
        User assistantY = SharingTestUtil.ass3toAY1;
        
        Account customerA = SharingTestUtil.multi4CustomerAccount;
        Account customerB = SharingTestUtil.multi1CustomerAccount;

        Product2 insProd = new Product2(Name='Property Insurance Test Product',ContractType__c='OwnContract',Family='InsurancePolicy');
        insert insProd;
        
        Id propInsRtId = RecordTypeHelper.getInsurancePolicyRecordTypeIdPropertyInsurance();
        List<InsurancePolicy> propertyInsurances = new List<InsurancePolicy>();

        InsurancePolicy custA_XpropInsAcc = SharingTestUtil.createInsurancePolicy(customerA,vbX,insProd,true,propInsRtId);
        propertyInsurances.add(custA_XpropInsAcc);

        InsurancePolicy custA_YpropInsAcc = SharingTestUtil.createInsurancePolicy(customerA,vbY,insProd,true,propInsRtId);
        propertyInsurances.add(custA_YpropInsAcc);

        InsurancePolicy custB_XpropInsAcc = SharingTestUtil.createInsurancePolicy(customerB,vbX,insProd,true,propInsRtId);
        propertyInsurances.add(custB_XpropInsAcc);

        InsurancePolicy custB_YpropInsAcc = SharingTestUtil.createInsurancePolicy(customerB,vbY,insProd,true,propInsRtId);
        custB_YpropInsAcc.OwnerId = vbY.Id;
        propertyInsurances.add(custB_YpropInsAcc);

        Map<Id,InsurancePolicy> vbXpropInsAcc;
        Map<Id,InsurancePolicy> vbYpropInsAcc;
        
        //Assistants
        Map<Id,InsurancePolicy> assistantXpropInsAcc;
        Map<Id,InsurancePolicy> assistantYpropInsAcc;
        //Deputies
        Map<Id,InsurancePolicy> deputyXpropInsAcc;
        Map<Id,InsurancePolicy> deputyYpropInsAcc;
        //Hierarchy
        Map<Id,InsurancePolicy> managerXpropInsAcc;
        Map<Id,InsurancePolicy> managerYpropInsAcc;
        
        Test.startTest();
            insert propertyInsurances;
            
            vbXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
            System.assertEquals(2,vbXpropInsAcc.size()); //je 1 BlaBla Policy von 2 Customers
            System.assertNotEquals(null, vbXpropInsAcc.get(custA_XpropInsAcc.Id));
            System.assertNotEquals(null, vbXpropInsAcc.get(custB_XpropInsAcc.Id));
            vbYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
            System.assertEquals(2,vbYpropInsAcc.size()); //je 1 BlaBla Policy von 2 Customers
            System.assertNotEquals(null, vbYpropInsAcc.get(custA_YpropInsAcc.Id));
            System.assertNotEquals(null, vbYpropInsAcc.get(custB_YpropInsAcc.Id));
            //Assistants
            assistantXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
            System.assertEquals(1, assistantXpropInsAcc.size()); //1 BlaBla Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantXpropInsAcc.get(custB_XpropInsAcc.Id));
            assistantYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
            System.assertEquals(1, assistantYpropInsAcc.size()); //1 BlaBla Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, assistantYpropInsAcc.get(custB_YpropInsAcc.Id));
            //Deputies
            deputyXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
            System.assertEquals(1, deputyXpropInsAcc.size()); //1 BlaBla Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyXpropInsAcc.get(custB_XpropInsAcc.Id));
            deputyYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
            System.assertEquals(1, deputyYpropInsAcc.size()); //1 BlaBla Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, deputyYpropInsAcc.get(custB_YpropInsAcc.Id));
            //Hierarchy
            managerXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
            System.assertEquals(1, managerXpropInsAcc.size()); //1 BlaBla Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerXpropInsAcc.get(custB_XpropInsAcc.Id));
            managerYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
            System.assertEquals(1, managerYpropInsAcc.size()); //1 BlaBla Policy von Customer B (A ausgeblendet)
            System.assertNotEquals(null, managerYpropInsAcc.get(custB_YpropInsAcc.Id));

            //Now switch the visibility
            customerA.HideForAssistantsAndDeputies__c = false;
            customerA.HideForHierarchy__c = false;
            customerB.HideForAssistantsAndDeputies__c = true;
            customerB.HideForHierarchy__c = true;
            update customerA;
            update customerB;
            
            Integer index = getRelatedObjectIndex('InsurancePolicy', 'PropertyInsurance');
            Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        
        Test.stopTest();

        vbXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbX);
        System.assertEquals(2,vbXpropInsAcc.size()); //je 1 BlaBla Policy von 2 Customers
        System.assertNotEquals(null, vbXpropInsAcc.get(custA_XpropInsAcc.Id));
        System.assertNotEquals(null, vbXpropInsAcc.get(custB_XpropInsAcc.Id));
        vbYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(vbY);
        System.assertEquals(2,vbYpropInsAcc.size()); //je 1 BlaBla Policy von 2 Customers
        System.assertNotEquals(null, vbYpropInsAcc.get(custA_YpropInsAcc.Id));
        System.assertNotEquals(null, vbYpropInsAcc.get(custB_YpropInsAcc.Id));
        //Assistants
        assistantXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantX);
        System.assertEquals(1, assistantXpropInsAcc.size()); //1 BlaBla Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantXpropInsAcc.get(custA_XpropInsAcc.Id));
        assistantYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(assistantY);
        System.assertEquals(1, assistantYpropInsAcc.size()); //1 BlaBla Policy von von Customer A (B ausgeblendet)
        System.assertNotEquals(null, assistantYpropInsAcc.get(custA_YpropInsAcc.Id));
        //Deputies
        deputyXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyX);
        System.assertEquals(1, deputyXpropInsAcc.size()); //1 BlaBla Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyXpropInsAcc.get(custA_XpropInsAcc.Id));
        deputyYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(deputyY);
        System.assertEquals(1, deputyYpropInsAcc.size()); //1 BlaBla Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, deputyYpropInsAcc.get(custA_YpropInsAcc.Id));
        //Hierarchy
        managerXpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerX);
        System.assertEquals(1, managerXpropInsAcc.size()); //1 BlaBla Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerXpropInsAcc.get(custA_XpropInsAcc.Id));
        managerYpropInsAcc = SharingTestUtil.insurancePoliciesVisibleForUser(managerY);
        System.assertEquals(1, managerYpropInsAcc.size()); //1 BlaBla Policy von Customer A (B ausgeblendet)
        System.assertNotEquals(null, managerYpropInsAcc.get(custA_YpropInsAcc.Id));        
            
    }

      /* 
        FSCEC-1780 Visibility for "Prospect" Customers ("Interessent")

            - "Interessent" is customer with FinServ__Status__c = 'Prospect'
            - Propsects can never have multi-ownership!
            - "EWE" means the customer did consent to marketing communication            
            - "EWE" exists when Account.HasOptedOutProcessing__pc is 'false'
            - For non-propsect customers, EWE is not considered for sharing within hierarchy
            - For prospect customers, only those with EWE are to be shared wiht the hierarchy
            - The Hide For Hierarchy is still considered

        Setup - Users
            - VB X (AX1)
            - Manager X -> AX (manager to AX1)
            - Assistant X ->  AX1    
            - Deputy X (AX2 -> AX1)
        
        Setup - Customers (all owned by VBX, not mulit-owner)
            - prospect A -> prospect customer without EWE, not hidden for hierarchy
            - prospect B -> prospect customer without EWE, hidden for hierarchy
            - prospect C -> prospect customer with EWE, not hidden for hierarchy
            - prospect D -> prospect customer with EWE, hidden for hierarchy

        Tests
            Intial state
            - Prospect A is NOT visible for Manager X
            - Prospect B is NOT visible for Manager X
            - Prospect C is visible for Manager X
            - Prospect D is NOT visible for Manager X

            Update EWE for Prospect A & B to "has EWE"
            Update EWE for Prospect C & D = to "has no EWE"

            Updated state
            - Prospect A is visible for Manager X            
            - Prospect B is NOT visible for Manager X
            - Prospect C is NOT visible for Manager X
            - Prospect D is NOT visible for Manager X
    */

    @IsTest
    static void prospectHierarchyVisibilityEWE() {
        
        SharingTestUtil.populateVbStructure();
        
        User vbX = SharingTestUtil.vbAX1user;
        User managerX = SharingTestUtil.vbAXuser;
        User deputyX = SharingTestUtil.deputyXtoAx1;                
        User assistantX = SharingTestUtil.ass1toAX1;
        
        List<Account> customerAccs = new List<Account>();
        
        //prospect A -> prospect customer without EWE, not hidden for hierarchy
        Account prospectA = SharingTestUtil.createCustomerAccount(vbX,'prospectA');
        prospectA.FinServ__Status__c = 'Prospect';
        prospectA.HasOptedOutProcessing__pc = true;
        prospectA.ConsentToProcessStatus__pc ='NotSeen';
        prospectA.HideForHierarchy__c = false;
        prospectA.HideForAssistantsAndDeputies__c = false;
        prospectA.MultipleOwners__c = false;
        customerAccs.add(prospectA);
        
        //prospect B -> prospect customer without EWE, hidden for hierarchy
        Account prospectB = SharingTestUtil.createCustomerAccount(vbX,'prospectB');
        prospectB.FinServ__Status__c = 'Prospect';
        prospectB.HasOptedOutProcessing__pc = true;
        prospectB.ConsentToProcessStatus__pc ='NotSeen';
        prospectB.HideForHierarchy__c = true;
        prospectB.HideForAssistantsAndDeputies__c = false;
        prospectB.MultipleOwners__c = false;
        customerAccs.add(prospectB);
        
        //prospect C -> prospect customer with EWE, not hidden for hierarchy
        Account prospectC = SharingTestUtil.createCustomerAccount(vbX,'prospectC');
        prospectC.FinServ__Status__c = 'Prospect';
        prospectC.HasOptedOutProcessing__pc = false;
        prospectC.ConsentToProcessStatus__pc ='OptIn';
        prospectC.HideForHierarchy__c = false;
        prospectC.HideForAssistantsAndDeputies__c = false;
        prospectC.MultipleOwners__c = false;
        customerAccs.add(prospectC);

        //prospect D -> prospect customer with EWE, hidden for hierarchy
        Account prospectD = SharingTestUtil.createCustomerAccount(vbX,'prospectD');
        prospectD.FinServ__Status__c = 'Prospect';
        prospectD.HasOptedOutProcessing__pc = false;
        prospectD.ConsentToProcessStatus__pc ='OptIn';
        prospectD.HideForHierarchy__c = true;
        prospectD.HideForAssistantsAndDeputies__c = false;
        prospectD.MultipleOwners__c = false;
        customerAccs.add(prospectD);

        Map<Id,Account> vbXaccs;
        Map<Id,Account> managerXaccs;
        Map<Id,Account> deputyXaccs;
        Map<Id,Account> assistantXaccs;

        Test.startTest();

            System.runAs(TestDataUtility.getIntegrationTestUser()) {
                insert customerAccs;
            }
            
            vbXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbX));
            managerXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(managerX));
            deputyXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyX));
            assistantXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantX));
                    
            // - Prospect A is NOT visible for Manager X
            System.assertEquals(Null, managerXaccs.get(prospectA.Id));
            // Visible for Assistants/Deputies and VB
            System.assertNotEquals(Null, assistantXaccs.get(prospectA.Id));
            System.assertNotEquals(Null, deputyXaccs.get(prospectA.Id));
            System.assertNotEquals(Null, vbXaccs.get(prospectA.Id));            

            // - Prospect B is NOT visible for Manager X
            System.assertEquals(Null, managerXaccs.get(prospectB.Id));
            // Visible for Assistants/Deputies and VB
            System.assertNotEquals(Null, assistantXaccs.get(prospectB.Id));
            System.assertNotEquals(Null, deputyXaccs.get(prospectB.Id));
            System.assertNotEquals(Null, vbXaccs.get(prospectB.Id));
            
            // - Prospect C is visible for Manager X
            System.assertNotEquals(Null, managerXaccs.get(prospectC.Id));
            // Visible for Assistants/Deputies and VB
            System.assertNotEquals(Null, assistantXaccs.get(prospectC.Id));
            System.assertNotEquals(Null, deputyXaccs.get(prospectC.Id));
            System.assertNotEquals(Null, vbXaccs.get(prospectC.Id));
            
            // - Prospect D is NOT visible for Manager X
            System.assertEquals(Null, managerXaccs.get(prospectD.Id));
            // Visible for Assistants/Deputies and VB
            System.assertNotEquals(Null, assistantXaccs.get(prospectD.Id));
            System.assertNotEquals(Null, deputyXaccs.get(prospectD.Id));
            System.assertNotEquals(Null, vbXaccs.get(prospectD.Id));

            customerAccs = new List<Account>();
            // Update EWE for Prospect A & B to "has EWE"
            prospectA.HasOptedOutProcessing__pc = false;
            prospectA.ConsentToProcessStatus__pc ='OptIn';
            customerAccs.add(prospectA);
            prospectB.HasOptedOutProcessing__pc = false;
            prospectB.ConsentToProcessStatus__pc ='OptIn';
            customerAccs.add(prospectB);
            // Update EWE for Prospect C & D = to "has no EWE"
            prospectC.HasOptedOutProcessing__pc = true;
            prospectC.ConsentToProcessStatus__pc ='OptOut';
            customerAccs.add(prospectC);
            prospectD.HasOptedOutProcessing__pc = true;
            prospectD.ConsentToProcessStatus__pc ='OptOut';
            customerAccs.add(prospectD);
            
            System.runAs(TestDataUtility.getIntegrationTestUser()) {
                update customerAccs;
            }
        
        Test.stopTest();
        
        vbXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(vbX));
        managerXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(managerX));
        deputyXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(deputyX));
        assistantXaccs = new Map<Id,Account>(SharingTestUtil.customerAccountsVisibleForUser(assistantX));


        // - Prospect A is visible for Manager X
        System.assertNotEquals(Null, managerXaccs.get(prospectA.Id));
        // Visible for Assistants/Deputies and VB
        System.assertNotEquals(Null, assistantXaccs.get(prospectA.Id));
        System.assertNotEquals(Null, deputyXaccs.get(prospectA.Id));
        System.assertNotEquals(Null, vbXaccs.get(prospectA.Id));            
        
        // - Prospect B is NOT visible for Manager X
        System.assertEquals(Null, managerXaccs.get(prospectB.Id));
        // Visible for Assistants/Deputies and VB
        System.assertNotEquals(Null, assistantXaccs.get(prospectB.Id));
        System.assertNotEquals(Null, deputyXaccs.get(prospectB.Id));
        System.assertNotEquals(Null, vbXaccs.get(prospectB.Id));            
        
        // - Prospect C is NOT visible for Manager X
        System.assertEquals(Null, managerXaccs.get(prospectC.Id));
        // Visible for Assistants/Deputies and VB
        System.assertNotEquals(Null, assistantXaccs.get(prospectC.Id));
        System.assertNotEquals(Null, deputyXaccs.get(prospectC.Id));
        System.assertNotEquals(Null, vbXaccs.get(prospectC.Id));            

        // - Prospect D is NOT visible for Manager X
        System.assertEquals(Null, managerXaccs.get(prospectD.Id));
        // Visible for Assistants/Deputies and VB
        System.assertNotEquals(Null, assistantXaccs.get(prospectD.Id));
        System.assertNotEquals(Null, deputyXaccs.get(prospectD.Id));
        System.assertNotEquals(Null, vbXaccs.get(prospectD.Id));            

                    
    }

}