/**
 * @author iwerstler@salesforce.com
 * @date 18-April-2023
 *
 * @group Trigger Handler
 *
 * @description manage special cases for households with only 1 PA or PersonAccounts without housholds or PersonAccounts with only 1 relevant household
 */


 public without sharing class TH_AccountContactRelationManageHH {

    private static Set<Id> setContactIdsToCheck     = new Set<Id>(); //the Contact ids of PersonAccounts that need to be checked in the after trigger if changes need to be applied
    private static Set<Id> setHouseholdIdsToCheck   = new Set<Id>(); //the Account ids of households that need to be checked in the after trigger if changes need to be applied

    public static Id idProfileIntegrationUser {
        get {
            if (idProfileIntegrationUser == null) { // lazy loading - we don't need the user always 
                idProfileIntegrationUser = RecordTypeHelper.getUserProfileIdIntegrationUser();     
            }
            return idProfileIntegrationUser;
        }
        set;
    } 
    
    public static Id idUserIntegration {
        get {
            if (idUserIntegration == null) { // lazy loading - we don't need the user always 
                Id profileId = RecordTypeHelper.getUserProfileIdIntegrationUser();
                idUserIntegration = [select id from User where ProfileId = :profileId and isActive=true limit 1].Id;
                //no fallback as there always needs to be an active integration user          
            }
            return idUserIntegration;
        }
        set;
    } 
    
    public static Id idHouseholdRecordTypeId {
        get {
            if (idHouseholdRecordTypeId == null) { // lazy loading - we don't need the record type always 
                idHouseholdRecordTypeId = RecordTypeHelper.getAccRecordTypeIdHousehold();
            }
            return idHouseholdRecordTypeId;
        }
        set;
    }



    /**
     * 
     * if an Household or PersonAccount is deleted, we need to check if the business rules for affected related PersonAccounts require to apply some changes
     * this method called "before delete" to being able to identify the PersonAccounts - ids stored in static variable.
     * next method called "after delete" to actually perform operations with ids from static variable
     */
    public static void accountsBeforeDelete(List<Account> lstAccounts){

        Set<Id> setHouseholdAccountIds  = new Set<Id>();
        Set<Id> setPersonContactIds     = new Set<Id>();

        for(Account acc : lstAccounts) {
            if (acc.isPersonAccount) {
                setPersonContactIds.add(acc.PersonContactId);
            } else if (acc.RecordTypeId == idHouseholdRecordTypeId ){
                setHouseholdAccountIds.add(acc.Id);
            }
        }

        if (!setPersonContactIds.isEmpty()) {
            //check which Households might be affected by the deletion of a PA
            List<AccountContactRelation> lstAccountContactRelations = [select 
                                                                            id,AccountId,Account.RecordTypeId, ContactId 
                                                                        from 
                                                                            AccountContactRelation 
                                                                        where 
                                                                            ContactId in :setPersonContactIds
                                                                            and 
                                                                            Account.RecordTypeId = :idHouseholdRecordTypeId];
            for(AccountContactRelation acr : lstAccountContactRelations){
                setHouseholdIdsToCheck.add(acr.AccountId);
            }
            //if a PersonAccount is deleted, this could affect PersonAccounts that are related to the same Households, as they could then need to switch the PrimaryGroup field
            //therefore we need to identify those PersonAccounts and check them. Story 1777
            lstAccountContactRelations =                                [select 
                                                                            id,AccountId,Account.RecordTypeId, ContactId 
                                                                        from 
                                                                            AccountContactRelation 
                                                                        where 
                                                                            FinServ__PrimaryGroup__c = false
                                                                            and
                                                                            AccountId in :setHouseholdIdsToCheck
                                                                            and
                                                                            ContactId not in :setPersonContactIds
                                                                        ];
                                                                        // primarygroup = false => we only need to check if the other relation is not already primary group
                                                                        // accountId in set => we check ACR related to affected Accounts to identify there PersonAccounts
                                                                        // contactId not in set => of course we do not look into deleted PersonAccounts
            for(AccountContactRelation acr : lstAccountContactRelations){
                setContactIdsToCheck.add(acr.ContactId);
            }                                                                        

        }

        if (!setHouseholdAccountIds.isEmpty()) {
            //check which PA might be affected by the deletion of a HH
            List<AccountContactRelation> lstAccountContactRelations = [select 
                                                                            id,AccountId,ContactId 
                                                                        from 
                                                                            AccountContactRelation 
                                                                        where 
                                                                            AccountId in :setHouseholdAccountIds
                                                                            and 
                                                                            Contact.isPersonAccount = true];
            for(AccountContactRelation acr : lstAccountContactRelations){
                setContactIdsToCheck.add(acr.ContactId);
            }
        }

    }

    public static void accountsAfterDelete(){

        //if households have been deleted, we we need to check if the previously related PersonAccounts are abandoned
        if (!setContactIdsToCheck.isempty())    checkPersonAccounts(setContactIdsToCheck);
        //if PersonAccounts have been deleted, we we need to check if for the previously related Households changes need to be applied
        if (!setHouseholdIdsToCheck.isempty())  checkHouseholdAccounts(setHouseholdIdsToCheck);        
    }

    /**
     * 
     * if a AccountContactRelation is created, we need to check if the business rules require to apply some changes
     * 
     */
    public static void accountContactRelationsAfterInsert(Map<Id,AccountContactRelation> mapId2AccountContactRelations){
        
        Set<Id> setAccountContactRelationIds = mapId2AccountContactRelations.keySet();
        //from all AccountContactRelations in trigger, only those are relevant, which are related to households
        //as we can't see that on the AccountContactRelations directly, we have to filter on related Account and Contact
        List<AccountContactRelation> lstAccountContactRelations = [select 
                                                                        id,AccountId,ContactId 
                                                                    from 
                                                                        AccountContactRelation 
                                                                    where 
                                                                   		id in :setAccountContactRelationIds
                                                                   		and
                                                                        Account.RecordTypeId = :idHouseholdRecordTypeId
                                                                        and 
                                                                        Contact.isPersonAccount = true];

        if (lstAccountContactRelations.isEmpty()) return; //nothing to do

        Set<Id> setContactIds  = new Set<Id>();

        for (AccountContactRelation acr : lstAccountContactRelations) {
            setContactIds.add(acr.ContactId);
        }

        checkPersonAccounts(setContactIds);

    }


    /**
     * 
     * if a AccountContactRelation is deleted, we need to check if the business rules for the related Household or PersonAccount require to apply some changes
     * 
     */
    public static void accountContactRelationsAfterDelete(List<AccountContactRelation> lstAccountContactRelationsOld){

        Set<Id> setAccountIds  = new Set<Id>();
        Set<Id> setContactIds  = new Set<Id>();

        //first we need to check if these have been actual household relations
        for(AccountContactRelation acr : lstAccountContactRelationsOld) {
            if (acr.Roles == null || acr.Roles == '' || acr.Roles.contains('HouseholdMember')){
                //unfortunately roles content is not reliable at the moment, so we will check also those cases, where roles is empty
                //once other roles will be established, the previous line needs to ensure we only work on HouseholdMember records
                if (acr.AccountId != null) setAccountIds.add(acr.AccountId);
                if (acr.ContactId != null) setContactIds.add(acr.ContactId);
            }
        }
        
        if (!setAccountIds.isEmpty())  checkHouseholdAccounts(setAccountIds);
        if (!setContactIds.isEmpty())  checkPersonAccounts(setContactIds);

    }

    /**
     * checks business rules for person accounts
     * 
     * 1) there must be at least 1 HH (story 1772)
     * 2) if there is exactly 1 HH with more than a single PA, this HH will be the primary group
     * 
     */
    private static void checkPersonAccounts( Set<Id> setContactIds) {

        if (setContactIds == null || setContactIds.isEmpty()) return;

        List<Account> lstPersonAccounts = [select 
                                                ID, FirstName, LastName, PersonContactId, 
                                                (select 
                                                    id,AccountId
                                                from 
                                                    PersonAccountContactRelations 
                                                where 
                                                    Account.RecordTypeId = :idHouseholdRecordTypeId)
                                            from
                                                Account
                                            WHERE
                                                isPersonAccount = true
                                                and
                                                PersonContactId in :setContactIds];

        if (lstPersonAccounts.isEmpty()) return;

        Set<Id> setPersonAccountIdsWithHouseholds = new Set<Id>();

        //CASE 1: there must be at least 1 HH, if not:create one
        Map<Id,Account> mapPersonContactId2AccountHouseholds = new Map<Id,Account>();

        for (Account acc : lstPersonAccounts) {
            if (acc.PersonAccountContactRelations.isEmpty()){
                Account accHH = createHouseholdForPersonAccount(acc);
                mapPersonContactId2AccountHouseholds.put(acc.PersonContactId,accHH);
            } else {
                setPersonAccountIdsWithHouseholds.add(acc.Id); //Case 2 does only need to look into personaccounts that already have households
            }
        }
        if (!mapPersonContactId2AccountHouseholds.isEmpty()) {
            createNewSingleHouseholds(mapPersonContactId2AccountHouseholds);
        }
        //END CASE 1

        //CASE 2: check if there is exactly 1 visible(!) household. if yes, set the primary group flag for this HH

        if (setPersonAccountIdsWithHouseholds.isEmpty()) return; // nothing to do anymore

        lstPersonAccounts = [select 
                                    ID, 
                                    (select 
                                        id,AccountId,FinServ__PrimaryGroup__c
                                    from 
                                        PersonAccountContactRelations 
                                    where 
                                        Account.RecordTypeId = :idHouseholdRecordTypeId
                                        and
                                        Account.Owner.ProfileId != :idProfileIntegrationUser)
                                from
                                    Account
                                WHERE
                                    Id in :setPersonAccountIdsWithHouseholds];
        //Account.Owner.ProfileId != :idProfileIntegrationUser => ignore invisible HH

        List<AccountContactRelation> lstAccountContactRelationsToUpdate = new List<AccountContactRelation>();

        for(Account acc : lstPersonAccounts){
            if (acc.PersonAccountContactRelations.size()==1) {
                AccountContactRelation acr = acc.PersonAccountContactRelations[0];
                if (acr.FinServ__PrimaryGroup__c == false ){
                    acr.FinServ__PrimaryGroup__c = true;
                    lstAccountContactRelationsToUpdate.add(acr);
                }
            }
        }

        if (!lstAccountContactRelationsToUpdate.isEmpty()) {
            update lstAccountContactRelationsToUpdate;
        } 
        //END CASE 2

    }  

    private static void createNewSingleHouseholds(Map<Id,Account> mapPersonContactId2AccountHouseholds){

        insert mapPersonContactId2AccountHouseholds.values(); //inserting new households

        List<AccountContactRelation> lstAccountContactRelations = new List<AccountContactRelation>();

        for(Id idPersonContact : mapPersonContactId2AccountHouseholds.keySet()) {
            
            Account accHousehold = mapPersonContactId2AccountHouseholds.get(idPersonContact);
            
            AccountContactRelation acr = new AccountContactRelation();
            acr.AccountId = accHousehold.Id;
            acr.ContactId = idPersonContact;
            //acr.FinServ__PrimaryGroup__c    = true;
            acr.FinServ__Primary__c         = true;
            acr.Roles = 'HouseholdMember';

            lstAccountContactRelations.add(acr);

        }

        insert lstAccountContactRelations; //inserting new AccountContactRelations

    }


    /**
     * helper method to create a default household for a person account
     */
    private static Account createHouseholdForPersonAccount(Account accPerson) {
        
        Account accHH = new Account();
        accHH.name          = 'Haushalt ' + accPerson.FirstName + ' ' + accPerson.LastName;
        accHH.OwnerId       = idUserIntegration;
        accHH.recordTypeId  = idHouseholdRecordTypeId;
        return accHH;

    }



    private static void checkHouseholdAccounts(Set<Id> setHouseholdAccountIds) {

        List<Account> lstAccounts = [select 
                                            ID, OwnerId,
                                            (select 
                                                id,AccountId,ContactId,FinServ__Primary__c,FinServ__PrimaryGroup__c
                                            from 
                                                AccountContactRelations
                                            where 
                                                Contact.IsPersonAccount = true)
                                        from
                                            Account
                                        WHERE
                                            RecordTypeId = :idHouseholdRecordTypeId
                                            and
                                            Id in :setHouseholdAccountIds];


        if (lstAccounts.isEmpty()) return; //can happen as roles on ACR is not always properly filled

        List<Account>                   lstAccountsToChangeOwner              = new List<Account>();
        List<AccountContactRelation>    lstAccountContactRelationsToChange    = new List<AccountContactRelation>();

        for (Account acc : lstAccounts){
            //household has only one remaining PersonAccount
            if(acc.AccountContactRelations.size() == 1){
                //check if we have to change the ownership to integration user (story 1783)
                if (acc.OwnerId != idUserIntegration) {
                    acc.OwnerId = idUserIntegration;
                    lstAccountsToChangeOwner.add(acc);
                } 
                //check if we need to set primary member flag and delete primarygroup flag (story 1774)
                AccountContactRelation acr = acc.AccountContactRelations[0];
                if (acr.FinServ__Primary__c == false || acr.FinServ__PrimaryGroup__c == true ) {
                    acr.FinServ__Primary__c      = true;
                    acr.FinServ__PrimaryGroup__c = false;
                    lstAccountContactRelationsToChange.add(acr);
                }
            }
        }


        if (!lstAccountsToChangeOwner.isEmpty())            update lstAccountsToChangeOwner;
        if (!lstAccountContactRelationsToChange.isEmpty())  update lstAccountContactRelationsToChange;

    }

    //create reliable data for manual testing 
    public static void createFamilyTestData(){
        createFamilyTestData(UserInfo.getUserId());
    }

    public static void createFamilyTestData(Id idOwner){


        /* for anonymous Apex
        1)
        TH_AccountContactRelationManageHH.createFamilyTestData();
        
        2)
        Account acc = new Account(id = '0017Z00002BeGFkQAN');
        delete acc;
        
        3)
        List<Account> lstAccounts = [select id from Account where createddate >= YESTERDAY and (name like '%Simpson%' or name like '%Houten%')];
        if (!lstAccounts.isEmpty()) delete lstAccounts;
        
        4)
        AccountContactRelation acr = new AccountContactRelation(id = '07k7Z00000a8p4GQAQ');
        delete acr;
        */
        
        List<Account> lstAccounts;

        Id recTypeId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();

        if (!Test.isRunningTest()) {
            //purge old manual test data
            lstAccounts = [select id from Account where ExtCustomerNumber__c like 'IwTest%'];
            if (!lstAccounts.isEmpty()) delete lstAccounts;
            lstAccounts = [select id from Account where createddate >= TODAY and (name like '%Simpson%' or name like '%Houten%')];
            if (!lstAccounts.isEmpty()) delete lstAccounts;
        }

        Integer i=1;

        lstAccounts = new List<Account>();
        lstAccounts.add(new Account(name='Haushalt Simpson sen.',           OwnerId = idOwner, recordTypeId= TH_AccountContactRelationManageHH.idHouseholdRecordTypeId,ExtCustomerNumber__c = 'IwTest ' + i++));
        lstAccounts.add(new Account(name='Haushalt Familie Simpson',        OwnerId = idOwner, recordTypeId= TH_AccountContactRelationManageHH.idHouseholdRecordTypeId,ExtCustomerNumber__c = 'IwTest ' + i++));
        lstAccounts.add(new Account(name='Haushalt Lisa Simpson',           OwnerId = TH_AccountContactRelationManageHH.idUserIntegration,recordTypeId= TH_AccountContactRelationManageHH.idHouseholdRecordTypeId,ExtCustomerNumber__c = 'IwTest ' + i++)); 
        lstAccounts.add(new Account(name='Haushalt Familie Simpson-Van Houten',OwnerId = idOwner, recordTypeId= TH_AccountContactRelationManageHH.idHouseholdRecordTypeId,ExtCustomerNumber__c = 'IwTest ' + i++)); 

        lstAccounts.add(
            new Account(
                LastName = 'Simpson',
                FirstName = 'Grampa',
                OwnerId = idOwner, 
                PreferredPostalAddress__pc = 'HouseholdAddress',
                PersonBirthdate = system.today(),
                ExtCustomerNumber__c = 'IwTestPA1',
                RecordTypeId = recTypeId
            )
        );
        lstAccounts.add(
            new Account(
                LastName = 'Simpson',
                FirstName = 'Homer',
                OwnerId = idOwner, 
                PreferredPostalAddress__pc = 'HouseholdAddress',
                PersonBirthdate = system.today(),
                ExtCustomerNumber__c = 'IwTestPA2',
                RecordTypeId = recTypeId
            )
        );
        lstAccounts.add(
            new Account(
                LastName = 'Simpson',
                FirstName = 'Marge',
                OwnerId = idOwner, 
                PreferredPostalAddress__pc = 'HouseholdAddress',
                PersonBirthdate = system.today(),
                ExtCustomerNumber__c = 'IwTestPA3',
                RecordTypeId = recTypeId
            )
        );  
        lstAccounts.add(
            new Account(
                LastName = 'Simpson',
                FirstName = 'Lisa',
                OwnerId = idOwner, 
                PreferredPostalAddress__pc = 'HouseholdAddress',
                PersonBirthdate = system.today(),
                ExtCustomerNumber__c = 'IwTestPA4',
                RecordTypeId = recTypeId
            )
        );          
        lstAccounts.add(
            new Account(
                LastName = 'Van Houten',
                FirstName = 'Milhouse',
                OwnerId = idOwner, 
                PreferredPostalAddress__pc = 'HouseholdAddress',
                PersonBirthdate = system.today(),
                ExtCustomerNumber__c = 'IwTestPA5',
                RecordTypeId = recTypeId
            )
        );   

        insert lstAccounts;

        List<Account> lstPersonAccounts = [select PersonContactId from Account where ExtCustomerNumber__c like 'IwTestPA%' order by ExtCustomerNumber__c asc];

        List<AccountContactRelation> lstAccountContactRelations = new List<AccountContactRelation>();
        
        //Grampa in Grampas Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[0].Id,
                                                                    ContactId   = lstPersonAccounts[0].PersonContactId,
                                                                    Roles       = 'HouseholdMember',
                                                                    FinServ__PrimaryGroup__c    = true,
                                                                    FinServ__Primary__c         = true));
        //Homer in Grampas Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[0].Id,
                                                                    ContactId   = lstPersonAccounts[1].PersonContactId,
                                                                    Roles       = 'HouseholdMember',
                                                                    FinServ__PrimaryGroup__c    = false,
                                                                    FinServ__Primary__c         = false));


        //Homer in Fam Simpsons Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[1].Id,
                                                            ContactId   = lstPersonAccounts[1].PersonContactId,
                                                            Roles       = 'HouseholdMember',
                                                            FinServ__PrimaryGroup__c    = false,
                                                            FinServ__Primary__c         = false));

        //Marge in Fam Simpsons Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[1].Id,
                                                            ContactId   = lstPersonAccounts[2].PersonContactId,
                                                            Roles       = 'HouseholdMember',
                                                            FinServ__PrimaryGroup__c    = true,
                                                            FinServ__Primary__c         = true));

        //Lisa in Fam Simpsons Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[1].Id,
                                                            ContactId   = lstPersonAccounts[3].PersonContactId,
                                                            Roles       = 'HouseholdMember',
                                                            FinServ__PrimaryGroup__c    = true,
                                                            FinServ__Primary__c         = false));

        //Lisa in Lisa Simpsons Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[2].Id,
                                                            ContactId   = lstPersonAccounts[3].PersonContactId,
                                                            Roles       = 'HouseholdMember',
                                                            FinServ__PrimaryGroup__c    = false,
                                                            FinServ__Primary__c         = true));   
                                                            
            //Lisa in Simpson-VanHouten Haushalt
            lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[3].Id,
                                                            ContactId   = lstPersonAccounts[3].PersonContactId,
                                                            Roles       = 'HouseholdMember',
                                                            FinServ__PrimaryGroup__c    = false,
                                                            FinServ__Primary__c         = true));                                                            

        //Milhouse in Simpson-VanHouten Haushalt
        lstAccountContactRelations.add(new AccountContactRelation(AccountId   = lstAccounts[3].Id,
                                                            ContactId   = lstPersonAccounts[4].PersonContactId,
                                                            Roles       = 'HouseholdMember',
                                                            FinServ__PrimaryGroup__c    = true,
                                                            FinServ__Primary__c         = false));                                                               

        insert lstAccountContactRelations;


    }
    



}