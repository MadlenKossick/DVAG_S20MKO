@isTest
public class TH_AccountContactRelationManageHHTest {
    
    @isTest
    public static void removePersonFromHouseholdSwitchesPrimaryGroupToOtherHousehold() {

        //1777
        //remove Lisa from Fam Simpson household

        Account accFamSimpson = [select id,ownerId from Account where name='Haushalt Familie Simpson'];

        Id hh1Id = accFamSimpson.Id;
        Id hh2Id = [select id from Account where name='Haushalt Familie Simpson-Van Houten'].Id;
        
        AccountContactRelation acr1 = [select id,FinServ__PrimaryGroup__c from AccountContactRelation where AccountId = :hh1Id and Contact.Firstname = 'Lisa'];
        AccountContactRelation acr2 = [select id,FinServ__PrimaryGroup__c from AccountContactRelation where Account.name='Haushalt Familie Simpson-Van Houten' and Contact.Firstname = 'Lisa'];

        Assert.isTrue(acr1.FinServ__PrimaryGroup__c,'PG should be set');
        Assert.isFalse(acr2.FinServ__PrimaryGroup__c,'PG should not be set');

        Test.startTest();

        delete acr1;
        Test.stopTest();
        
        acr2     = [select id,FinServ__PrimaryGroup__c from AccountContactRelation where Account.name='Haushalt Familie Simpson-Van Houten' and Contact.Firstname = 'Lisa'];
        Assert.isTrue(acr2.FinServ__PrimaryGroup__c,'PG should be set');

        //test: ensure other account did not change
        Account accFamSimpson2 = [select id,ownerId from Account where name='Haushalt Familie Simpson'];
        Assert.areEqual(accFamSimpson.ownerId,accFamSimpson2.ownerId,'owner of fam simpson should not change');

    }

    @isTest
    public static void removePersonFromHouseholdSwitchesOtherPersonsAttributes() {
        //1774 +1783
        //remove Lisa from Van Houten household
        //=> household van Houten = Single Person Household
        //Ownership = Integration User
        //Milhouse = primary member 
        //Milhouse ACR no longer primary group

        Id hh1Id = [select id from Account where name='Haushalt Familie Simpson-Van Houten'].Id;
        
        AccountContactRelation acr1 = [select id,FinServ__Primary__c                            from AccountContactRelation where AccountId = :hh1Id and Contact.Firstname = 'Lisa'];
        AccountContactRelation acr2 = [select id,FinServ__Primary__c,FinServ__PrimaryGroup__c   from AccountContactRelation where AccountId = :hh1Id and Contact.Firstname = 'Milhouse'];

        Assert.isFalse(acr2.FinServ__Primary__c,'Primary__c should not be set');
        Assert.isTrue(acr2.FinServ__PrimaryGroup__c,'PrimaryGroup__c should be set');

        Test.startTest();

        delete acr1;
        Test.stopTest();
        
        acr2     = [select id,FinServ__Primary__c,FinServ__PrimaryGroup__c,Account.Owner.ProfileId,Account.Owner.name from AccountContactRelation where AccountId = :hh1Id and Contact.Firstname = 'Milhouse'];
       
        Assert.isTrue(acr2.FinServ__Primary__c,'primary should be set');
        Assert.isFalse(acr2.FinServ__PrimaryGroup__c,'PrimaryGroup__c should not be set');
        Assert.areEqual(RecordTypeHelper.getUserProfileIdIntegrationUser(),acr2.Account.Owner.ProfileId,'owner is not an integration user');

    }    

    @isTest
    public static void newHouseholdsBeingCreatedForAbandonedPersonAccounts() {
        //1772
        //1) Delete Household of Simpson sen
        //=> new Household for Grampa Simpson created
        //2) remove Homer from Simpson Family Household
        //=> new Household for Homer Simpson created 
        
        Account                 hhGrampa = [select id from Account where name ='Haushalt Simpson sen.'];
        AccountContactRelation  acr      = [select id,FinServ__Primary__c from AccountContactRelation where Account.name='Haushalt Familie Simpson' and Contact.Firstname = 'Homer'];

        List<Account> lstSingleAccounts = [select owner.profileId from Account where name = 'Haushalt Grampa Simpson' or name ='Haushalt Homer Simpson'];
        Assert.isTrue(lstSingleAccounts.isEmpty());

        Test.startTest();
        delete hhGrampa;
        delete acr;
        Test.stopTest();
        
        List<AccountContactRelation> lstSingleAccountContactRelations = [select FinServ__Primary__c,Account.owner.profileId,Account.owner.name,Account.name from AccountContactRelation where Account.name = 'Haushalt Grampa Simpson' or Account.name ='Haushalt Homer Simpson'];
        Assert.areEqual(2,lstSingleAccountContactRelations.size(),'there should be 2 single person households');
        Assert.isTrue(lstSingleAccountContactRelations[0].FinServ__Primary__c,'primary should be set for FinServ__Primary__c ' + lstSingleAccountContactRelations[0].Account.name);
        Assert.isTrue(lstSingleAccountContactRelations[1].FinServ__Primary__c,'primary should be set for FinServ__Primary__c ' + lstSingleAccountContactRelations[1].Account.name);
        Assert.areEqual(RecordTypeHelper.getUserProfileIdIntegrationUser(),lstSingleAccountContactRelations[0].Account.owner.profileId,'owner should be integration user ' + lstSingleAccountContactRelations[0].Account.owner.name);
        Assert.areEqual(RecordTypeHelper.getUserProfileIdIntegrationUser(),lstSingleAccountContactRelations[1].Account.owner.profileId,'owner should be integration user ' + lstSingleAccountContactRelations[1].Account.owner.name);

    }    


    @isTest
    public static void massDeleteAcr() {
    
        Id idIntegrationUserProfile = RecordTypeHelper.getUserProfileIdIntegrationUser();

        List<Account> lstAccounts =  [select id,Owner.ProfileId,name from Account where ExtCustomerNumber__c like 'HH%'];
        for(Account acc : lstAccounts){
            Assert.areNotEqual(idIntegrationUserProfile,acc.Owner.ProfileId,'owner should not be integration user on Account ' + acc.name);
        }
        
        List<AccountContactRelation> lstAcr = [select id from AccountContactRelation where Account.ExtCustomerNumber__c like 'HH%' and FinServ__Primary__c=true];
        Assert.areEqual(50,lstAcr.size(),'prep failed - there should be 50 AccountContactRelations with FinServ__Primary__c=true');
        
        Test.startTest();
        delete lstAcr;
        Test.stopTest();

        lstAccounts = [select id,Owner.ProfileId,name from Account where ExtCustomerNumber__c like 'HH%'];
        for(Account acc : lstAccounts){
            Assert.areEqual(idIntegrationUserProfile,acc.Owner.ProfileId,'owner should be integration user on Account ' + acc.name);
        }

    }


    @isTest
    public static void massDeleteHouseholds() {
    
        List<Account> lstAccounts =  [select id from Account where ExtCustomerNumber__c like 'Haushalt PA Contact%'];
        
        Assert.areEqual(0,lstAccounts.size(),'prep failed - there should be no single person households');
        lstAccounts = [select id from Account where ExtCustomerNumber__c like 'HH%'];
        Assert.areEqual(50,lstAccounts.size(),'prep failed - there should be 50 multi person households');
        
        Test.startTest();
        delete lstAccounts;
        Test.stopTest();

        lstAccounts = [select id from Account where name like 'Haushalt Contact PA%'];
        Assert.areEqual(50,lstAccounts.size(),'there should be 50 new single person households');

    }



    
    private static void makeMassData(){

        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();

        List<Account> lstHHAccounts = new List<Account>();
        List<Account> lstPAAccounts = new List<Account>();
        for(Integer i = 0; i< 50; i++) {
            String strCnt = ((i<10) ? '0' : '') + i;
            lstHHAccounts.add(new Account(name='HH'+i,recordTypeId= TH_AccountContactRelationManageHH.idHouseholdRecordTypeId,ExtCustomerNumber__c = 'HH' + strCnt));
            lstPAAccounts.add(
                new Account(
                    LastName = 'PA'+i,
                    FirstName = 'Contact',
                    PreferredPostalAddress__pc = 'HouseholdAddress',
                    PersonBirthdate = system.today(),
                    ExtCustomerNumber__c = 'PA' + strCnt,
                    RecordTypeId = recTypeId
                )
            );
        }
        insert lstHHAccounts;
        insert lstPAAccounts;

        lstPAAccounts = [select PersonContactId from Account where ExtCustomerNumber__c like 'PA%' order by ExtCustomerNumber__c asc];
        
        List<AccountContactRelation> lstAccountContactRelations = new List<AccountContactRelation>();
        for(Integer i = 0;i<50; i++ ) {
            lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstHHAccounts[i].Id,
                                                                    ContactId   = lstPAAccounts[i].PersonContactId,
                                                                    Roles       = 'HouseholdMember',
                                                                    FinServ__PrimaryGroup__c    = true,
                                                                    FinServ__Primary__c         = true));
            lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstHHAccounts[i].Id,
                                                                    ContactId   = lstPAAccounts[Math.mod(i+1,50)].PersonContactId,
                                                                    Roles       = 'HouseholdMember',
                                                                    FinServ__PrimaryGroup__c    = false,
                                                                    FinServ__Primary__c         = false));                                                                    
        }
        insert lstAccountContactRelations;
        
    }

    @TestSetup 
    //can create reliable data for manual testing too
    public static void createTestData(){
        // if (Test.isRunningTest()) TestDataUtility.getIntegrationTestUser(); //make sure integration user exists in test context
        makeMassData();
        TH_AccountContactRelationManageHH.createFamilyTestData();
    }
    

}