/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Testklassen
 *
 * @description Testklassen Utility - Grundlage für alle anderen Testklassen
 */
public class TestDataUtility {
    
    public static final String testIntegrationUserName = 'i.am.mr.integration@dvag.apextest';
    public static final String testDataSecurityOfficereUserName = 'datenschutzbeauftragter@dvag.apextest';

    public static List<Account> createHouseholdAccount(Integer accountsToCreate) {
        List<Account> accountList = new List<Account>();

        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdHousehold();

        for (Integer i = 0; i < accountsToCreate; i++) {
            accountList.add(
                new Account(
                    Name = 'Household TestAccount' + i,
                    RecordTypeId = recTypeId
                )
            );
        }

        if (accountList.size() > 0) {
            insert accountList;
        }
        return accountList;
    }

    //Return the VB user with advisorId "vb"+<number>
    public static User getTestVbUser(String vbNumber) {
        ID vbProfileId = RecordTypeHelper.getUserProfileIdFieldSalesUser();
        String advisorId = 'vb' + vbNumber;
        return [SELECT Id, ExtFinancialAdvisorId__c
                FROM USER
                WHERE ProfileId = :vbProfileId
                AND ExtFinancialAdvisorId__c = :advisorId LIMIT 1];
    }

    public static List<Account> createHouseholdAccount(Integer accountsToCreate, User ownerVB) {
        List<Account> accountList = new List<Account>();

        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdHousehold();

        for (Integer i = 0; i < accountsToCreate; i++) {
            accountList.add(
                new Account(
                    Name = 'Household TestAccount' + i,
                    RecordTypeId = recTypeId,
                    OwnerId = ownerVB.Id
                )
            );
        }

        if (accountList.size() > 0) {
            insert accountList;
        }
        return accountList;
    }

    public static List<Account> createPersonAccount(Integer accountsToCreate) {
        List<Account> accountList = new List<Account>();

        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();

        for (Integer i = 0; i < accountsToCreate; i++) {
            accountList.add(
                new Account(
                    LastName = 'Test FirstName ' + i,
                    FirstName = 'Test LastName ' + i,
                    PreferredPostalAddress__pc = 'HouseholdAddress',
                    PersonBirthdate = system.today(),
                    ExtCustomerIdHost__c = 'HostId' + i,
                    ExtCustomerIdOki__c = 'OkiId' + i,
                    ExtCustomerNumber__c = 'CustomerNr' + i,
                    RecordTypeId = recTypeId
                )
            );
        }

        if (accountList.size() > 0) {
            insert accountList;
        }
        return accountList;
    }

    public static List<CustomerAdvisorRelationship__c> createCustomerAdvisorRelationship(List<Account> accountList, User ownerVb) {
        List<CustomerAdvisorRelationship__c> relList = new List<CustomerAdvisorRelationship__c>();

        Integer i = 0;
        for (Account acc : accountList) {
          i++;
            relList.add(
                new CustomerAdvisorRelationship__c(
                    Account__c = acc.Id,
                    OwnerId = ownerVb.Id,
                    DoNotCare__c = false,
                    InformalSalutation__c = false,
                    UniqueKey__c = acc.ExtCustomerIdOki__c + '-' + ownerVb.ExtFinancialAdvisorId__c
                )
            );
        }        

        if (relList.size() > 0) {
            insert relList;
        }
        return relList;
    }

    public static List<AccountContactRelation> createAccountContactRelation(Integer relationsToCreate, User ownerVB) {
        List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();
        List<Account> householdAcc = createHouseholdAccount(relationsToCreate, ownerVB);        
        List<Account> personAccs = createPersonAccount(relationsToCreate);
        
        Set<Id> personAccIds = new Set<Id>();
        for (Account acc : personAccs) {
            personAccIds.add(acc.Id);
        }

        List<Contact> contactIds = [SELECT Id FROM Contact WHERE AccountId IN :personAccIds];

        for (Integer i = 0; i < relationsToCreate; i++) {
            accConRelList.add(
                new AccountContactRelation(
                    AccountId = householdAcc.get(i).Id, 
                    ContactId = contactIds.get(i).Id
                )
            );
        }

        if (accConRelList.size() > 0) {
            insert accConRelList;
        }
        return accConRelList;
    }

    public static List<Campaign> createCampaign(Integer campaignsToCreate) {
        List<Campaign> listOfCampaign = new List<Campaign>();

        Id recTypeId = RecordTypeHelper.getCampRecordTypeIdDistributed();

        for (Integer i = 0; i < campaignsToCreate; i++) {
            listOfCampaign.add(
                new Campaign(Name = 'TestCon' + i, RecordTypeId = recTypeId)
            );
        }
        return listOfCampaign;
    }

    public static List<Individual> createIndividual(Integer individualsToCreate) {
        List<Individual> listOfIndividual = new List<Individual>();

        for (Integer i = 0; i < individualsToCreate; i++) {
            listOfIndividual.add(
                new Individual(
                    firstname = 'Firstname' + i,
                    lastname = 'Lastname' + i,
                    salutation = 'Mr.'
                )
            );
        }
        if (listOfIndividual.size() > 0) {
            insert listOfIndividual;
        }
        return listOfIndividual;
    }

    public static FinServ__FinancialAccount__c createFinancialAccount(Boolean isOwnContract, List<Account> personAccs)  {
        List<Account> accs = new List<Account>();
        if (personAccs != null) {
            accs.addAll(personAccs);
        } else {
            accs = createPersonAccount(1);
        }

        FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
        finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
        finAcc.FinServ__PrimaryOwner__c = accs[0].Id;
        finAcc.FinServ__HeldAway__c = !isOwnContract;
        insert finAcc;
        return finAcc;
    }

    //DELETE?!
    public static InsurancePolicy createInsurancePolicy(Boolean isOwnContract) {
        List<Account> accs = createPersonAccount(1);

        InsurancePolicy insPol = new InsurancePolicy();
        insPol.Name = 'Test Insurance Policy';
        insPol.NameInsuredId = accs[0].Id;
        insPol.Heldaway__c = !isOwnContract;
        insert insPol;
        return insPol;
    }

    public static InsurancePolicy createInsurancePolicy(Account insuredAcc, String productCode, Boolean isOwnContract) {
        Product2 polProd;
        if (isOwnContract) {
            polProd = createOwnInsuranceProduct(productCode);
        } else {
            polProd = createForeignInsuranceProduct(productCode);
        }
        InsurancePolicy insPol = new InsurancePolicy(Name = 'Test Insurance Policy',
                                                    NameInsuredId = insuredAcc.Id,
                                                    Heldaway__c = !isOwnContract,
                                                    ProductId = polProd.Id);
        insert insPol;
        return insPol;
    }

    public static List<CustomerProperty> createCustomerProperty(Integer customerPropertiesToCreate) {
        Account acc = createPersonAccount(1).get(0);    

        Id recTypeId = RecordTypeHelper.getCustomerProperyRecordTypeIdRealEstate();

        List<CustomerProperty> cstPropList = new List<CustomerProperty>();
        for (Integer i=0; i < customerPropertiesToCreate; i++){
            cstPropList.add(
                new CustomerProperty(
                    PrimaryOwnerId = acc.Id,
                    RecordTypeId = recTypeId,
                    Description = 'Test Customer Property ' + i)
            );
        }    

        insert cstPropList;
        return cstPropList;
    }

    public static User getIntegrationTestUser(){
        User integrationUser;
        List<User> testUsers = [SELECT UserName, Email, FirstName, LastName, ProfileId, UserRoleId, Alias
                                FROM User
                                WHERE UserName = :testIntegrationUserName];
        
        if (testUsers.size() > 0) {
            integrationUser = testUsers.get(0);
        } else {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                integrationUser = createIntegrationUser();
            }
        }
        return integrationUser; 
    }

    private static User createIntegrationUser(){
        
        Id intUserProfileId = RecordTypeHelper.getUserProfileIdIntegrationUser();
        
        Id userRoleId = [SELECT Id, DeveloperName 
                        FROM UserRole 
                        WHERE DeveloperName = 'CEO' 
                        Limit 1].Id;
    
        User newUser = new User();        
        newUser.UserName = testIntegrationUserName;
        newUser.Email = testIntegrationUserName;
        newUser.IsActive = true;
        newUser.FirstName = 'Mr';
        newUser.LastName = 'Integration';
        newUser.ProfileId = intUserProfileId;
        newUser.Alias = 'MRDIL';
        newUser.Emailencodingkey = 'UTF-8';
        newUser.Languagelocalekey = 'en_US';
        newUser.Localesidkey = 'en_US';
        newUser.Timezonesidkey = 'Europe/Berlin';
        newUser.UserRoleId = userRoleId;
        insert newUser;

        List<PermissionSetGroup> lst_psg = [SELECT Id, MasterLabel, Status 
                                                FROM PermissionSetGroup 
                                                WHERE MasterLabel IN ('All FSC Services (Internal User)')];
        
        if(lst_psg[0].Status != 'Updated') {
            Test.calculatePermissionSetGroup(lst_psg[0].Id);
        }
        
        List<PermissionSet> lst_ps = [SELECT Id, Label 
                                          FROM PermissionSet 
                                          WHERE Label IN ('DVAG Dataloader Bulk Import Settings', 'DVAG Integration Settings')];

        List<PermissionSetAssignment> lst_psAssign = new List<PermissionSetAssignment>();
        lst_psAssign.add(new PermissionSetAssignment(PermissionSetGroupId = lst_psg[0].Id, AssigneeId = newUser.Id));   
        lst_psAssign.add(new PermissionSetAssignment(PermissionSetId = lst_ps[0].Id, AssigneeId = newUser.Id));   
        lst_psAssign.add(new PermissionSetAssignment(PermissionSetId = lst_ps[1].Id, AssigneeId = newUser.Id));   
        insert lst_psAssign;
        
        return newUser;
    }

    public static User createCommunityAccountContact(Integer vbNumber) {
        Id recordTypeIdDirectorate = RecordTypeHelper.getAccRecordTypeIdDirectorate();
        Account communityAccount = new Account(Name ='Test Directorate ' + vbNumber, RecordTypeId = recordTypeIdDirectorate);
        insert communityAccount; 

        Id recordTypeIdVb = RecordTypeHelper.getConRecordTypeIdFinancialAdvisor();
    
        Contact communityContact = new Contact(LastName ='Mustermann' + vbNumber, 
                                                AccountId = communityAccount.Id,
                                                DistributionCompany__c = '4400001',
                                                RecordTypeId = recordTypeIdVb);
        insert communityContact;  
        
        User communityUser = createCommunityUser(communityContact.Id, 'test.vb.extern' + vbNumber + '@dvag.apex', vbNumber);
        
        BusinessLicense busLicense = new BusinessLicense(LicenseClass = '34i', 
                                                            Status = 'Verified',
                                                            ContactId = communityContact.Id,
                                                            Name = '34i'
        );
        insert busLicense;
        return communityUser;
    }

    public static User createCommunityUser(Id communityContactId, String email, Integer advisorNumber) {
        Id vbProfileId =  RecordTypeHelper.getUserProfileIdFieldSalesUser();
        String tmpAlias = 'mumax' + advisorNumber;
        User testUser = new User();
        testUser.UserName = email + advisorNumber + '.apextest';
        testUser.Email = email;
        testUser.IsActive = true;
        testUser.ContactId = communityContactId;
        testUser.FirstName = 'Max';
        testUser.LastName = 'Mustermann' + advisorNumber;
        testUser.ProfileId = vbProfileId;
        testUser.FederationIdentifier = 'vb' + advisorNumber;
        testUser.ExtFinancialAdvisorId__c = 'vb' + advisorNumber;
        testUser.Alias = tmpAlias.abbreviate(8);
        testUser.Emailencodingkey = 'UTF-8';
        testUser.Languagelocalekey = 'en_US';
        testUser.Localesidkey = 'en_US';
        testUser.Timezonesidkey = 'Europe/Berlin';
        insert testUser;
        return testUser;
    }

    public static Product2 createOwnInsuranceProduct(String ProductCode) {
        Product2 testProduct = new Product2(Name = 'Own Product'+ProductCode,
                                            ContractType__c = 'OwnContract',                                            
                                            Family = 'InsurancePolicy');
        insert testProduct;
        return testProduct;
    }

    public static Product2 createForeignInsuranceProduct(String ProductCode) {
        Product2 testProduct = new Product2(Name = 'Foreign Product'+ProductCode,
                                            ContractType__c = 'ForeignContract',
                                            Family = 'InsurancePolicy');
        insert testProduct;
        return testProduct;
    }

    public static List<InsurancePolicy> createInsurancePolicies(Integer InsurancePolicieToCreate, Boolean isOwnContract) {
        List<InsurancePolicy> insPols = new List<InsurancePolicy>();
        List<Account> accs = createPersonAccount(1);
    
        for (Integer i = 0; i < InsurancePolicieToCreate; i++) {
            insPols.add(
                new InsurancePolicy(
                    Name = 'Test Insurance Policy'+i,
                    NameInsuredId = accs[0].Id,
                    HeldAway__c = !isOwnContract
                )
            );
        }
        System.debug('insPols: ' + insPols);
        if(insPols.size() > 0){
            insert insPols;
        }        
        return insPols;
    }

    public static List<FinServ__FinancialAccount__c> createFinancialAccounts(Integer finAccountsToCreate, Boolean isOwnContract) {

        List<FinServ__FinancialAccount__c> finAccs = new List<FinServ__FinancialAccount__c>();
        Account ownerAcc = createPersonAccount(1).get(0);
    
        for (Integer i = 0; i < finAccountsToCreate; i++) {
            FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
            finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
            finAcc.FinServ__PrimaryOwner__c = ownerAcc.Id;
            finAcc.FinServ__HeldAway__c = !isOwnContract;
            finAccs.add(finAcc);
        }
    
        if(finAccs.size() > 0){
            insert finAccs;
        }          
        return finAccs;
    }

    public static List<FinServ__FinancialAccount__c> createFinancialBankingAccounts(Integer finAccountsToCreate, User owner, Boolean isOwnContract) {

        List<FinServ__FinancialAccount__c> finAccs = new List<FinServ__FinancialAccount__c>();
        Account ownerAcc = createPersonAccount(1).get(0);
        ownerAcc.OwnerId = owner.Id;
    
        for (Integer i = 0; i < finAccountsToCreate; i++) {
          FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
          finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
          finAcc.FinServ__PrimaryOwner__c = ownerAcc.Id;
          finAcc.FinServ__HeldAway__c = !isOwnContract;
          finAcc.OwnerId = owner.Id;
          finAccs.add(finAcc);
        }
    
        if(finAccs.size() > 0){
            insert finAccs;
        }          
        return finAccs;
    }
  
    public static List<Lead> createLeads(Integer leadsToCreate, Id conId, List<Account> personAccs) {
        List<Lead> leads = new List<Lead>();
        List<Account> accs = new List<Account>();
        if (personAccs != null) {
            accs.addAll(personAccs);
        } else {
            accs = createPersonAccount(1);
        }
        
        Id recType = RecordTypeHelper.getLeadRecordTypeIdReferral();
    
        for (Integer i = 0; i < leadsToCreate; i++) {
            leads.add(new Lead(LastName = 'Test Lead ' + i,
                               Company = 'Test Lead ' + i,
                               FinServ__RelatedAccount__c = accs[0].Id,
                               RecordTypeId = recType,
                               FinServ__ReferredByContact__c = conId));
        }

        if(leads.size() > 0){
            insert leads;
        }        
        return leads;
    }

    public static List<IncomeAndExpenses__c> createIncomeAndExpense(Integer recordsToCreate, List<Account> personAccs) {
        List<IncomeAndExpenses__c> records = new List<IncomeAndExpenses__c>();
        
        List<Account> accs = new List<Account>();
        if (personAccs != null) {
            accs.addAll(personAccs);
        } else {
            accs = createPersonAccount(1);
        }

        Id recType = RecordTypeHelper.getIncomeExpenseRecordTypeIdNetIncome();

        for (Integer i = 0; i < recordsToCreate; i++) {
            records.add(
                new IncomeAndExpenses__c(
                    Name = 'Test Record ' + i,
                    RecordTypeId = recType,
                    PrimaryOwner__c = accs[0].Id));
        }

        if(records.size() > 0){
            insert records;
        }        
        return records;
    }

    public static List<FinServ__FinancialGoal__c> createFinancialGoals(Integer recordsToCreate, List<Account> personAccs) {
        List<FinServ__FinancialGoal__c> records = new List<FinServ__FinancialGoal__c>();
        
        List<Account> accs = new List<Account>();
        if (personAccs != null) {
            accs.addAll(personAccs);
        } else {
            accs = createPersonAccount(1);
        }

        for (Integer i = 0; i < recordsToCreate; i++) {
            records.add(new FinServ__FinancialGoal__c(Name = 'Test Record ' + i,
                                                      Custom_Description__c = 'Others',
                                                      FinServ__PrimaryOwner__c = accs[0].Id));
        }

        if(records.size() > 0){
            insert records;
        }        
        return records;
    }

    public static List<FinServ__AssetsAndLiabilities__c> createAssetsAndLiabilities(Integer recordsToCreate, List<Account> personAccs) {
        List<FinServ__AssetsAndLiabilities__c> records = new List<FinServ__AssetsAndLiabilities__c>();
        
        List<Account> accs = new List<Account>();
        if (personAccs != null) {
            accs.addAll(personAccs);
        } else {
            accs = createPersonAccount(1);
        }
        
        Id recType = RecordTypeHelper.getAssetsLiabilitiesRecordTypeIdNonfinancialAsset();
    
        for (Integer i = 0; i < recordsToCreate; i++) {
            records.add(new FinServ__AssetsAndLiabilities__c(Name = 'Test Record ' + i,
                                                             FinServ__PrimaryOwner__c = accs[0].Id,
                                                             RecordTypeId = recType));
        }

        if(records.size() > 0){
            insert records;
        }        
        return records;
    }

    public static String getRandomNumber(Integer length) {
        return  String.valueof(Math.abs(Crypto.getRandomLong())).substring(0, length);
    }    

    public Static List<User> createUsers(String ProfileName, Integer recordsToCreate){
        List<User> records = new List<User>();
        Id profile = [SELECT Id FROM Profile WHERE Name = :ProfileName LIMIT 1].Id;
        for (Integer i = 0; i < recordsToCreate; i++) {
            records.add(
                new User(
                    ProfileId = profile,
                    LastName = 'Test User ' + i,
                    Email = 'testuser'+i+'@example.com',
                    Username = 'testuser'+i+'@example.com.testUser',
                    Alias = 'tu'+i,
                    TimeZoneSidKey = 'Europe/Berlin',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US'
                )
            );
        }

        if(records.size() > 0){
            insert records;
        }        
        return records;
    }

    public static User getDataSecurityOfficerTestUser(){
        User dataSecurityUser;
        List<User> testUsers = [SELECT UserName, Email, FirstName, LastName, ProfileId, UserRoleId, Alias
                                FROM User
                                WHERE UserName = :testDataSecurityOfficereUserName];
        
        if (testUsers.size() > 0) {
            dataSecurityUser = testUsers.get(0);
        } else {
            System.runAs(getIntegrationTestUser()) {
                dataSecurityUser = createDataSecurityOfficerUser();
            }
        }
        return dataSecurityUser;
    }

    private static User createDataSecurityOfficerUser() {
        User integrationUser = getIntegrationTestUser();                
        Id userRoleId = [SELECT Id, DeveloperName 
                        FROM UserRole 
                        WHERE DeveloperName = 'CEO'
                        Limit 1].Id;
    
        User newUser = new User();        
        newUser.UserName = testDataSecurityOfficereUserName;
        newUser.Email = testDataSecurityOfficereUserName;
        newUser.IsActive = true;
        newUser.FirstName = 'Mr';
        newUser.LastName = 'DataSecurity';
        newUser.ProfileId = RecordTypeHelper.getUserProfileIdBackofficeUser();
        newUser.Alias = 'MRDSB';
        newUser.Emailencodingkey = 'UTF-8';
        newUser.Languagelocalekey = 'en_US';
        newUser.Localesidkey = 'en_US';
        newUser.Timezonesidkey = 'Europe/Berlin';
        newUser.UserRoleId = userRoleId;        
        insert newUser;

        List<PermissionSetGroup> lst_psg = [SELECT Id, MasterLabel 
                                                FROM PermissionSetGroup 
                                                WHERE MasterLabel IN ('All FSC Services (Internal User)')];    
        
        List<PermissionSet> lst_ps = [SELECT Id, Label 
                                          FROM PermissionSet 
                                          WHERE Label IN ('DVAG Hide Accounts')];

        List<PermissionSetAssignment> lst_psAssign = new List<PermissionSetAssignment>();
        lst_psAssign.add(new PermissionSetAssignment(PermissionSetGroupId = lst_psg[0].Id, AssigneeId = newUser.Id));   
        lst_psAssign.add(new PermissionSetAssignment(PermissionSetId = lst_ps[0].Id, AssigneeId = newUser.Id));                   
        insert lst_psAssign;

        return newUser;
    }

    public static List<OrgParameter__mdt> getOrgParameters(){
        if (Test.isRunningTest()) {
            return getOrgParametersTest();
        } else {
            return OrgParameter__mdt.getAll().values();
        }
    }

    private static List<OrgParameter__mdt> getOrgParametersTest(){
        List<OrgParameter__mdt> params = new List<OrgParameter__mdt>();
        params.add(new OrgParameter__mdt(DeveloperName = 'SecurityOfficerUsername', StringValue__c = testDataSecurityOfficereUserName));

        return params;
    }
}