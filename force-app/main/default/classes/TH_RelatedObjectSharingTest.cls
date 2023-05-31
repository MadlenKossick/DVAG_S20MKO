/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Testclass
 * 
 *  TODO: Needs Refactoring
 *
 * @description Tests for sharing the related objects of person accounts
 */

@IsTest
public class TH_RelatedObjectSharingTest {
    @TestSetup
    static void testSetup() {
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            SharingTestUtil.createTestVbStructure();
        }
    }

    @isTest
    static void testRelatedObjectLeadInsert() {
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;
            customerAcc = [Select Id,OwnerId, PersonContactId, ExtCustomerNumber__c FROM Account WHERE Id = :customerAcc.Id];
            Lead record = SharingTestUtil.createLead(customerAcc);
            insert record;

            List<LeadShare> apexShares = [SELECT Id, UserOrGroupId
                                          FROM   LeadShare 
                                          WHERE  LeadId = :record.Id
                                          AND    RowCause = 'Manual'];
    
            system.assert(apexShares.size() > 0);
        }
    }

    @isTest
    static void testRelatedObjectLeadUpdate(){
        Test.startTest();
        SharingTestUtil.populateVbStructure();
        Test.stopTest();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);
        System.assertNotEquals(null, SharingTestUtil.vbAX1user);

        
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;            
            customerAcc = [Select Id,OwnerId, PersonContactId, ExtCustomerNumber__c FROM Account WHERE Id = :customerAcc.Id];
            Lead record = SharingTestUtil.createLead(customerAcc);            
            insert record;            
            record.OwnerId = SharingTestUtil.vbBX1user.Id;
            Database.update(record);

            List<LeadShare> apexShareAfter = [SELECT Id, UserOrGroupId
                                            FROM   LeadShare 
                                            WHERE  LeadId = :record.Id
                                            AND    RowCause = 'Manual'];

            Set<Id> allGroups = new Set<Id>();
            for (LeadShare share : apexShareAfter) {
                allGroups.add(share.UserOrGroupId);
            }

            String groupNameLike = '%_' + SharingTestUtil.vbBX1user.ExtFinancialAdvisorId__c; 
            List<Group> groups = [SELECT Id
                                FROM Group
                                WHERE Id IN :allGroups
                                AND   Group.DeveloperName LIKE :groupNameLike];
            system.assert(groups.size() == apexShareAfter.size());
        }
    }

    @isTest
    static void testRelatedObjectFinancialGoalInsert(){
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;
            FinServ__FinancialGoal__c record = SharingTestUtil.createFinancialGoal(customerAcc);
            insert record;         

            List<FinServ__FinancialGoal__Share> apexShares = [SELECT Id, UserOrGroupId
                                                            FROM   FinServ__FinancialGoal__Share 
                                                            WHERE  ParentId = :record.Id
                                                            AND    RowCause = 'Manual'];

            system.assert(apexShares.size() > 0);
        }
    }

    @isTest
    static void testRelatedObjectFinancialGoalUpdate(){
        Test.startTest();
        SharingTestUtil.populateVbStructure();
        Test.stopTest();

        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            List<FinServ__FinancialGoal__c> records = TestDataUtility.createFinancialGoals(2, null);
            for(FinServ__FinancialGoal__c record : records) {
                record.OwnerId = SharingTestUtil.vbBX1user.Id;
            }
            Database.update(records);

            List<FinServ__FinancialGoal__Share> apexShareAfter = [SELECT Id, UserOrGroupId
                                                                FROM   FinServ__FinancialGoal__Share 
                                                                WHERE  ParentId = :records[0].Id
                                                                AND    RowCause = 'Manual'];

            Set<Id> allGroups = new Set<Id>();
            for (FinServ__FinancialGoal__Share share : apexShareAfter) {
                allGroups.add(share.UserOrGroupId);
            }

            String groupNameLike = '%_' + SharingTestUtil.vbBX1user.ExtFinancialAdvisorId__c; 
            List<Group> groups = [SELECT Id
                                FROM Group
                                WHERE Id IN :allGroups
                                AND   Group.DeveloperName LIKE :groupNameLike];
            system.assert(groups.size() == apexShareAfter.size());
        }
    }

    @isTest
    static void testRelatedObjectAssetsAndLiabilitiesInsert(){
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;

            List<FinServ__AssetsAndLiabilities__c> assetRecords = new List<FinServ__AssetsAndLiabilities__c>();
            assetRecords.add(SharingTestUtil.createAssetLiability(customerAcc, RecordTypeHelper.getAssetsLiabilitiesRecordTypeIdNonfinancialAsset()));
            assetRecords.add(SharingTestUtil.createAssetLiability(customerAcc, RecordTypeHelper.getAssetLiabilityRecordTypeIdLiability()));
            insert assetRecords;
            
            List<FinServ__AssetsAndLiabilities__Share> apexShares = [SELECT Id, UserOrGroupId
                                                                     FROM   FinServ__AssetsAndLiabilities__Share 
                                                                     WHERE  ParentId IN (:assetRecords[0].Id, :assetRecords[1].Id)
                                                                     AND    RowCause = 'Manual'];

            system.assertNotEquals(0, apexShares.size());
        }
    }

    //@isTest
    static void testRelatedObjectAssetsAndLiabilitiesUpdate(){
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            List<FinServ__AssetsAndLiabilities__c> records = TestDataUtility.createAssetsAndLiabilities(2, null);
            for(FinServ__AssetsAndLiabilities__c record : records){
                record.OwnerId = SharingTestUtil.vbBX1user.Id;
            }

            Database.update(records);

            List<FinServ__AssetsAndLiabilities__Share> apexShareAfter = [SELECT Id, UserOrGroupId
                                                                        FROM   FinServ__AssetsAndLiabilities__Share 
                                                                        WHERE  ParentId = :records[0].Id
                                                                        AND    RowCause = 'Manual'];

            Set<Id> allGroups = new Set<Id>();
            for (FinServ__AssetsAndLiabilities__Share share : apexShareAfter) {
                allGroups.add(share.UserOrGroupId);
            }

            String groupNameLike = '%_' + SharingTestUtil.vbBX1user.ExtFinancialAdvisorId__c; 
            List<Group> groups = [SELECT Id
                                FROM Group
                                WHERE Id IN :allGroups
                                AND   Group.DeveloperName LIKE :groupNameLike];
            system.assert(groups.size() == apexShareAfter.size());
        }
    }

    
    @isTest
    static void testRelatedObjectFinancialAccountInsert(){
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;

            List<FinServ__FinancialAccount__c> records = new List<FinServ__FinancialAccount__c>();
            records.add(SharingTestUtil.createBankingAccount(customerAcc, SharingTestUtil.vbAXuser));
            records.add(SharingTestUtil.createBankingAccount(customerAcc, SharingTestUtil.vbAXuser));
            insert records;

            List<FinServ__FinancialAccount__Share> apexShares = [SELECT Id, UserOrGroupId
                                                                 FROM   FinServ__FinancialAccount__Share 
                                                                 WHERE  ParentId in (:records[0].Id, :records[1].Id)
                                                                 AND    RowCause = 'Manual'];

            system.assert(apexShares.size() > 0);
        }
    }

    @isTest
    static void testRelatedObjectFinancialAccountUpdate(){
        SharingTestUtil.populateVbStructure();

        System.assertNotEquals(null, SharingTestUtil.vbAXuser);
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            List<FinServ__FinancialAccount__c> records = TestDataUtility.createFinancialAccounts(2, false);
                for(FinServ__FinancialAccount__c record : records){
                record.OwnerId = SharingTestUtil.vbBX1user.Id;
            }

            Database.update(records);

            List<FinServ__FinancialAccount__Share> apexShareAfter = [SELECT Id, UserOrGroupId
                                                                    FROM   FinServ__FinancialAccount__Share 
                                                                    WHERE  ParentId = :records[0].Id
                                                                    AND    RowCause = 'Manual'];

            Set<Id> allGroups = new Set<Id>();
            for (FinServ__FinancialAccount__Share share : apexShareAfter) {
                allGroups.add(share.UserOrGroupId);
            }

            String groupNameLike = '%_' + SharingTestUtil.vbBX1user.ExtFinancialAdvisorId__c; 
            List<Group> groups = [SELECT Id
                                FROM Group
                                WHERE Id IN :allGroups
                                AND   Group.DeveloperName LIKE :groupNameLike];
            system.assert(groups.size() == apexShareAfter.size());
        }
    }

    @isTest
    static void testRelatedObjectInsurancePolicyInsert(){
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);
        System.assertNotEquals(null, SharingTestUtil.vbAXcustomerAccount);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;                        
            Id policyRtId = RecordTypeHelper.getInsurancePolicyRecordTypeIdCarInsurance();
            Product2 insProd = TestDataUtility.createOwnInsuranceProduct('TST12');
            InsurancePolicy record = SharingTestUtil.createInsurancePolicy(customerAcc,SharingTestUtil.vbAXuser,insProd,true,policyRtId);
            insert record;

            List<InsurancePolicyShare> apexShares = [SELECT Id, UserOrGroupId
                                                     FROM   InsurancePolicyShare 
                                                     WHERE  ParentId = :record.Id
                                                     AND    RowCause = 'Manual'];

            system.assert(apexShares.size() > 0);
        }
    }

    @isTest
    static void testRelatedObjectInsurancePolicyUpdate(){
        SharingTestUtil.populateVbStructure();

        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            List<InsurancePolicy> records = TestDataUtility.createInsurancePolicies(2, false);
            for(InsurancePolicy record : records){
                record.OwnerId = SharingTestUtil.vbBX1user.Id;
            }

            Database.update(records);

            List<InsurancePolicyShare> apexShareAfter = [SELECT Id, UserOrGroupId
                                                         FROM   InsurancePolicyShare 
                                                         WHERE  ParentId = :records[0].Id
                                                         AND    RowCause = 'Manual'];

            Set<Id> allGroups = new Set<Id>();
            for (InsurancePolicyShare share : apexShareAfter) {
                allGroups.add(share.UserOrGroupId);
            }

            String groupNameLike = '%_' + SharingTestUtil.vbBX1user.ExtFinancialAdvisorId__c; 
            List<Group> groups = [SELECT Id
                                FROM Group
                                WHERE Id IN :allGroups
                                AND   Group.DeveloperName LIKE :groupNameLike];
            system.assert(groups.size() == apexShareAfter.size());
        }
    }

    @isTest
    static void testRelatedObjectIncomeAndExpensesInsert(){
        SharingTestUtil.populateVbStructure();
        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;
            IncomeAndExpenses__c record = SharingTestUtil.createIncomeAndExpenseNetGrossIncome(customerAcc);            
            insert record;         

            List<IncomeAndExpenses__Share> apexShares = [SELECT Id, UserOrGroupId
                                                              FROM   IncomeAndExpenses__Share 
                                                              WHERE  ParentId = :record.Id
                                                              AND    RowCause = 'Manual'];

            system.assert(apexShares.size() > 0);
        }
    }

    @isTest
    static void testRelatedObjectIncomeAndExpensesUpdate(){
        Test.startTest();
        SharingTestUtil.populateVbStructure();
        Test.stopTest();

        System.assertNotEquals(null, SharingTestUtil.vbAXuser);

        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            Account customerAcc = SharingTestUtil.createCustomerAccount(SharingTestUtil.vbAXuser);
            insert customerAcc;
            
            IncomeAndExpenses__c iaeRecord = SharingTestUtil.createIncomeAndExpenseNetGrossIncome(customerAcc);
            insert iaeRecord;
            
            List<IncomeAndExpenses__Share> apexShareBefore = [SELECT Id, UserOrGroupId
                                                                FROM   IncomeAndExpenses__Share 
                                                                WHERE  ParentId = :iaeRecord.Id
                                                                AND    RowCause = 'Manual'];
            System.assertNotEquals(0, apexShareBefore.size());
            iaeRecord.OwnerId = SharingTestUtil.vbBX1user.Id;
            Database.update(iaeRecord);

            List<IncomeAndExpenses__Share> apexShareAfter = [SELECT Id, UserOrGroupId
                                                                FROM   IncomeAndExpenses__Share 
                                                                WHERE  ParentId = :iaeRecord.Id
                                                                AND    RowCause = 'Manual'];

            Set<Id> allGroups = new Set<Id>();
            for (IncomeAndExpenses__Share share : apexShareAfter) {
                allGroups.add(share.UserOrGroupId);
            }

            String groupNameLike = '%_' + SharingTestUtil.vbBX1user.ExtFinancialAdvisorId__c; 
            List<Group> groups = [SELECT Id
                                FROM Group
                                WHERE Id IN :allGroups
                                AND   Group.DeveloperName LIKE :groupNameLike];
            system.assert(groups.size() == apexShareAfter.size());
            System.assertEquals(apexShareBefore.size(), apexShareAfter.size());
        }
    }
}