/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Testclass
 *
 * @description Tests for sharing the related objects of person accounts
 */
@IsTest
public class B_ShareRelatedObjectsTest{
    public static User oldOwner;
    public static User newOwner;
    @TestSetup
    static void testSetup(){
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account directoratePartnerAccount = new Account(
                name = 'Root PartnerAccount',
                RecordTypeId = RecordTypeHelper.getAccRecordTypeIdDirectorate()
            );
            insert directoratePartnerAccount;
            oldOwner = SharingTestUtil.createFieldSalesContactUser('Test', 'VB1', 'vb1.dvag@dvag.txt', '185', directoratePartnerAccount.Id, null);
            newOwner = SharingTestUtil.createFieldSalesContactUser('Test', 'VB2', 'vb2.dvag@dvag.txt', '815', directoratePartnerAccount.Id, null);
        }
    }

    @IsTest
    static void testRelatedObjectBatch(){
        Test.startTest();

        List<Account> accs = TestDataUtility.createPersonAccount(1);

        FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
        finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
        finAcc.FinServ__PrimaryOwner__c = accs[0].Id;
        finAcc.FinServ__HeldAway__c = false;
        insert finAcc;

        insert new AccountSharingCalculation__c(Account__c = accs[0].Id, UniqueKey__c = accs[0].Id);

        List<FinServ__FinancialAccount__Share> shares = [SELECT Id, UserOrGroupId, ParentId, AccessLevel
                                                         FROM FinServ__FinancialAccount__Share
                                                         WHERE RowCause = 'Manual'];

        if (shares.isEmpty()){
            ID groupId = [Select Id
                          from group
                          where developername like '%_%'
                          limit 1].Id;
            System.debug('Missing Shares testRelatedObjectBatch.groupId: ' + groupId);
            FinServ__FinancialAccount__Share share = new FinServ__FinancialAccount__Share();
            share.ParentId = finAcc.Id;
            share.UserOrGroupId = groupId;
            share.AccessLevel = 'Read';
            share.RowCause = 'Manual';
            insert share;
            System.debug('testRelatedObjectBatch.share created Id: ' + share.Id);
        }

        Integer index = 0;
        List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
        for (Integer i = 0; i < configs.size(); i++){
            if (configs[i].ObjectName__c == 'FinServ__FinancialAccount__c' && configs[i].RecordTypeName__c == 'BankingAccount'){
                index = i;
            }
        }

        // System.debug('testRelatedObjectBatch.configs: ' + configs[index]);
        Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        Test.stopTest();

        List<AccountSharingCalculation__c> accShaCals = [SELECT Id
                                                         FROM AccountSharingCalculation__c];
        system.assert(accShaCals.size() == 0);
    }

    @IsTest
    static void testRelatedObjectBatchMultiOwner(){
        List<Account> accs = TestDataUtility.createPersonAccount(1);
        accs[0].MultipleOwners__c = true;
        accs[0].HideForHierarchy__c = true;
        accs[0].HideForAssistantsAndDeputies__c = true;
        update accs;

        FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
        finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
        finAcc.FinServ__PrimaryOwner__c = accs[0].Id;
        finAcc.FinServ__HeldAway__c = false;
        insert finAcc;

        Test.startTest();

        List<FinServ__FinancialAccount__Share> shares = [SELECT Id, UserOrGroupId, ParentId, AccessLevel
                                                         FROM FinServ__FinancialAccount__Share
                                                         WHERE RowCause = 'Manual'];

        if (shares.isEmpty()){
            ID groupId = [Select Id
                          from group
                          where developername like '%_%'
                          limit 1].Id;
            System.debug('Missing Shares testRelatedObjectBatch.groupId: ' + groupId);
            FinServ__FinancialAccount__Share share = new FinServ__FinancialAccount__Share();
            share.ParentId = finAcc.Id;
            share.UserOrGroupId = groupId;
            share.AccessLevel = 'Read';
            share.RowCause = 'Manual';
            insert share;
            System.debug('testRelatedObjectBatch.share created Id: ' + share.Id);
        }

        Integer index = 0;
        List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
        for (Integer i = 0; i < configs.size(); i++){
            if (configs[i].ObjectName__c == 'FinServ__FinancialAccount__c' && configs[i].RecordTypeName__c == 'BankingAccount'){
                index = i;
            }
        }
        Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        Test.stopTest();

        List<AccountSharingCalculation__c> accShaCals = [SELECT Id
                                                         FROM AccountSharingCalculation__c];
        system.assert(accShaCals.size() == 0);
    }

    @IsTest
    static void testRelatedObjectBatchOwnerChange(){
        oldOwner = [SELECT Id, FirstName, LastName, username, ExtFinancialAdvisorId__c
                    from USER
                    where username = 'vb1.dvag@dvag.txt'];
        newOwner = [SELECT Id, FirstName, LastName, username, ExtFinancialAdvisorId__c
                    from USER
                    where username = 'vb2.dvag@dvag.txt'];

        List<FinServ__FinancialAccount__c> records = TestDataUtility.createFinancialBankingAccounts(2, oldOwner, false);

        Test.startTest();

        List<FinServ__FinancialAccount__Share> shares = [SELECT Id, UserOrGroupId, ParentId, AccessLevel
                                                         FROM FinServ__FinancialAccount__Share
                                                         WHERE RowCause = 'Manual'];

        if (shares.isEmpty()){
            ID groupId = [Select Id
                          from group
                          where developername like '%_%'
                          limit 1].Id;
            System.debug('Missing Shares testRelatedObjectBatch.groupId: ' + groupId);
            FinServ__FinancialAccount__Share share = new FinServ__FinancialAccount__Share();
            share.ParentId = records[0].Id;
            share.UserOrGroupId = groupId;
            share.AccessLevel = 'Read';
            share.RowCause = 'Manual';
            insert share;
            System.debug('testRelatedObjectBatch.share created Id: ' + share.Id);
        }
        update new Account(Id = records[0].FinServ__PrimaryOwner__c, OwnerId = newOwner.Id);

        Integer index = 0;
        List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
        for (Integer i = 0; i < configs.size(); i++){
            if (configs[i].ObjectName__c == 'FinServ__FinancialAccount__c' && configs[i].RecordTypeName__c == 'BankingAccount'){
                index = i;
            }
        }

        Database.executeBatch(new B_ShareRelatedObjects(configs, index), SharingUtil.getShareRelatedObjectsBatchSize());
        Test.stopTest();

        List<AccountSharingCalculation__c> accShaCals = [SELECT Id
                                                         FROM AccountSharingCalculation__c];
        system.assert(accShaCals.size() == 0);
    }
}