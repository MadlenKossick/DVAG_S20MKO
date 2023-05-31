@isTest
public class TH_AccountManageHidingTest {

    private static User vbUser;
    private static User dsoUser;
    private static final Integer VBNUMBER = 4711;
    
    @TestSetup
    static void makeData(){
        TestDataUtility.getIntegrationTestUser();

        System.runAs(TestDataUtility.getIntegrationTestUser()) {         
            dsoUser = TestDataUtility.getDataSecurityOfficerTestUser();
        }
        
        System.runAs(TestDataUtility.getIntegrationTestUser())  {
            vbUser = TestDataUtility.createCommunityAccountContact(VBNUMBER);
        }        

        List<Account>   lstAccounts     = TestDataUtility.createPersonAccount(7);
        List<Account>   lstAccountPeers = new List<Account>();
        lstAccountPeers.add(lstAccounts.remove(6));
        lstAccountPeers.add(lstAccounts.remove(5));
        lstAccountPeers[0].LastName='Peer0';
        lstAccountPeers[0].LastName='Peer1';
        update lstAccountPeers;

        List<FinServ__FinancialAccount__c>          lstFinAccs  = new List<FinServ__FinancialAccount__c>();
        List<IncomeAndExpenses__c>                  lstIncome   = new List<IncomeAndExpenses__c>();
        List<FinServ__AssetsAndLiabilities__c>      lstAssets   = new List<FinServ__AssetsAndLiabilities__c>();
        List<FinServ__FinancialGoal__c>             lstGoals    = new List<FinServ__FinancialGoal__c>();
        List<FinServ__AccountAccountRelation__c>    lstAccAccRel = new List<FinServ__AccountAccountRelation__c>();

        Id idRecTypeFinancialAccount    = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
        Id idRecTypeIncome              = RecordTypeHelper.getIncomeExpenseRecordTypeIdNetIncome();
        Id idRecTypeAssets              = RecordTypeHelper.getAssetsLiabilitiesRecordTypeIdNonfinancialAsset();
        
        FinServ__ReciprocalRole__c recRole = new FinServ__ReciprocalRole__c(name='dummy',FinServ__InverseRole__c='dummy',FinServ__RelationshipType__c='All');
        insert recRole;

        Integer i=0;
        
        for(Account acc : lstAccounts){
            acc.OwnerId = vbUser.Id;
            lstIncome.add( new IncomeAndExpenses__c(Name = 'Test Record ' + i++,RecordTypeId = idRecTypeIncome, PrimaryOwner__c = acc.Id,OwnerId=vbUser.Id));
            lstIncome.add( new IncomeAndExpenses__c(Name = 'Test Record ' + i++,RecordTypeId = idRecTypeIncome, PrimaryOwner__c = acc.Id,OwnerId=vbUser.Id));
            lstIncome.add( new IncomeAndExpenses__c(Name = 'Test Record ' + i++,RecordTypeId = idRecTypeIncome, PrimaryOwner__c = acc.Id,OwnerId=vbUser.Id));
            lstAssets.add( new FinServ__AssetsAndLiabilities__c(Name = 'Test Record ' + i++, FinServ__PrimaryOwner__c = acc.Id,RecordTypeId = idRecTypeAssets,OwnerId=vbUser.Id));
            lstFinAccs.add(new FinServ__FinancialAccount__c(RecordTypeId=idRecTypeFinancialAccount,FinServ__PrimaryOwner__c=acc.Id,FinServ__HeldAway__c=true ,OwnerId=vbUser.Id));
            //lstFinAccs.add(new FinServ__FinancialAccount__c(RecordTypeId=idRecTypeFinancialAccount,FinServ__PrimaryOwner__c=acc.Id,FinServ__HeldAway__c=false,OwnerId=vbUser.Id));
            lstGoals.add(  new FinServ__FinancialGoal__c(Name = 'Test Record ' + i++, Custom_Description__c = 'Others',FinServ__PrimaryOwner__c = acc.Id,OwnerId=vbUser.Id));
            lstGoals.add(  new FinServ__FinancialGoal__c(Name = 'Test Record ' + i++, Custom_Description__c = 'Others',FinServ__PrimaryOwner__c = acc.Id,OwnerId=vbUser.Id));
            lstGoals.add(  new FinServ__FinancialGoal__c(Name = 'Test Record ' + i++, Custom_Description__c = 'Others',FinServ__PrimaryOwner__c = acc.Id,OwnerId=vbUser.Id));
            lstAccAccRel.add(new FinServ__AccountAccountRelation__c(FinServ__AssociationType__c='Peer',FinServ__Role__c=recRole.Id,FinServ__Account__c=acc.Id,FinServ__RelatedAccount__c=lstAccountPeers[0].Id,OwnerId=vbUser.Id));
            lstAccAccRel.add(new FinServ__AccountAccountRelation__c(FinServ__AssociationType__c='Peer',FinServ__Role__c=recRole.Id,FinServ__RelatedAccount__c=acc.Id,FinServ__Account__c=lstAccountPeers[1].Id,OwnerId=vbUser.Id));
        }
        
        update lstAccounts;
        insert lstIncome;
        insert lstAssets;
        insert lstFinAccs;
        insert lstGoals;
        insert lstAccAccRel;
    }

    private static void initUsers() {
        dsoUser = TestDataUtility.getDataSecurityOfficerTestUser();
        vbUser = TestDataUtility.getTestVbUser(String.valueOf(VBNUMBER));
    }

    @isTest
    static void hideAllRecords(){
        initUsers();
        
        List<Account>   lstAccountsToHide   = [select id from Account where LastName like 'Test%'];
        Set<Id>         setAccountIds       = new Set<Id>();
        for(Account acc : lstAccountsToHide) {
            acc.HideGlobally__c = true;
            setAccountIds.add(acc.Id);
        }
        Test.startTest();
            update lstAccountsToHide;
        Test.stopTest();

        List<Sobject> lstSobjects = new List<Sobject>();
        lstSobjects.addAll([select OwnerId from IncomeAndExpenses__c where PrimaryOwner__c in :setAccountIds]); 
        lstSobjects.addAll([select OwnerId from FinServ__AssetsAndLiabilities__c where FinServ__PrimaryOwner__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__FinancialAccount__c where FinServ__PrimaryOwner__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__FinancialGoal__c where FinServ__PrimaryOwner__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__AccountAccountRelation__c where FinServ__Account__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__AccountAccountRelation__c where FinServ__RelatedAccount__c in :setAccountIds]);

        for(Sobject sobj : lstSobjects){
            Assert.areEqual(dsoUser.Id,(Id) sobj.get('OwnerId'),'Owner is not Security Officer');
        }
    }

    @isTest
    static void unhideAllRecords(){
        initUsers();

        List<Account>   lstAccountsToHide   = [select id from Account where LastName like 'Test%'];
        Set<Id>         setAccountIds       = new Set<Id>();
        for(Account acc : lstAccountsToHide) {
            acc.HideGlobally__c = true;
            acc.OwnerId = dsoUser.Id;
            setAccountIds.add(acc.Id);
        }
        update lstAccountsToHide;

        List<Sobject> lstSobjects;
        lstSobjects = [select OwnerId from FinServ__AssetsAndLiabilities__c where FinServ__PrimaryOwner__c in :setAccountIds];
        setOwnerId(lstSobjects, dsoUser.Id);
        lstSobjects = [select OwnerId from FinServ__FinancialAccount__c where FinServ__PrimaryOwner__c in :setAccountIds];
        setOwnerId(lstSobjects,dsoUser.Id);
        lstSobjects = [select OwnerId from FinServ__AccountAccountRelation__c where FinServ__Account__c in :setAccountIds];
        setOwnerId(lstSobjects, dsoUser.Id);
        lstSobjects = [select OwnerId from FinServ__AccountAccountRelation__c where FinServ__RelatedAccount__c in :setAccountIds];
        setOwnerId(lstSobjects, dsoUser.Id);

        lstAccountsToHide   = [select id from Account where LastName like 'Test%'];
        setAccountIds       = new Set<Id>();
        for(Account acc : lstAccountsToHide) {
            acc.HideGlobally__c = false;
            acc.OwnerId =   vbUser.Id;
            setAccountIds.add(acc.Id);
        }

        Test.startTest();
            update lstAccountsToHide;
        Test.stopTest();

        lstSobjects = new List<Sobject>();
        lstSobjects.addAll([select OwnerId from FinServ__AssetsAndLiabilities__c where FinServ__PrimaryOwner__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__FinancialAccount__c where FinServ__PrimaryOwner__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__AccountAccountRelation__c where FinServ__Account__c in :setAccountIds]);
        lstSobjects.addAll([select OwnerId from FinServ__AccountAccountRelation__c where FinServ__RelatedAccount__c in :setAccountIds]);

        for(Sobject sobj : lstSobjects){
            Assert.areEqual(vbUser.Id,(Id) sobj.get('OwnerId'),'Owner is not VB');
        }

    }

    private static void setOwnerId(List<Sobject> lstSobjects,Id ownerId) {
        for (Sobject sobj : lstSobjects) {
            sobj.put('OwnerId',ownerId);
        }
        update lstSobjects;
    }

}