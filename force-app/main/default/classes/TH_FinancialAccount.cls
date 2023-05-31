/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Financial Account  Object
 */

public without sharing class TH_FinancialAccount extends TriggerHandler {
    private Map<Id, SObject> bankingAccounts;
    private Map<Id, SObject> investmentAccounts;
    private Map<Id, SObject> generalAccounts;
    private Map<Id, SObject> creditCards;
    private Map<Id, SObject> loanAccounts;
    private Map<Id, SObject> mortgages;
    private Map<Id, SObject> savingsAccounts;

    public TH_FinancialAccount() {
        Id recTypeBankingAccount = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
        Id recTypeInvestmentAccount = RecordTypeHelper.getFinancialAccountRecordTypeIdInvestmentAccount();
        Id recTypeGeneralAccount = RecordTypeHelper.getFinancialAccountRecordTypeIdGeneralAccount();
        Id recTypeCreditCard = RecordTypeHelper.getFinancialAccountRecordTypeIdCreditCard();
        Id recTypeLoanAccount = RecordTypeHelper.getFinancialAccountRecordTypeIdLoanAccount();
        Id recTypeMortgage = RecordTypeHelper.getFinancialAccountRecordTypeIdMortgage();
        Id recTypeSavingsAccount = RecordTypeHelper.getFinancialAccountRecordTypeIdSavingsAccount();

        this.bankingAccounts = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeBankingAccount});
        this.investmentAccounts = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeInvestmentAccount});
        this.generalAccounts = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeGeneralAccount});
        this.creditCards = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeCreditCard});
        this.loanAccounts = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeLoanAccount});
        this.mortgages = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeMortgage});
        this.savingsAccounts = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeSavingsAccount});
    }
    
    public override void afterInsert() {
        afterInsertInvestmentAccounts();
        afterInsertBankingAccounts();
        afterInsertGeneralAccounts();
        afterInsertCreditCards();
        afterInsertLoanAccounts();
        afterInsertMortgages();
        afterInsertSavingsAccounts();
    }

    public override void beforeUpdate() {
        TH_AccountManageHiding.preventOwnerChangeForHiddenRecords(Trigger.newMap,Trigger.old,FinServ__FinancialAccount__c.FinServ__PrimaryOwner__c.getDescribe().getName());
    }

    public override void afterUpdate() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'FinServ__FinancialAccount__c');
        afterUpdateInvestmentAccounts();
        afterUpdateBankingAccounts();
        afterUpdateGeneralAccounts();
        afterUpdateCreditCards();
        afterUpdateLoanAccounts();
        afterUpdateMortgages();
        afterUpdateSavingsAccounts();
    }
        
    public override void afterDelete() {
        new TH_IntegrationEvent(Trigger.old, Trigger.oldMap, 'Delete', 'FinServ__FinancialAccount__c');
    }

    /** Banking Accounts */
    private void afterInsertBankingAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.bankingAccounts.values());
    }
    private void afterUpdateBankingAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.bankingAccounts);
    }

    /** Investment Accounts */    
    private void afterInsertInvestmentAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.investmentAccounts.values());
    }
    private void afterUpdateInvestmentAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.investmentAccounts);
    }

     /** General Accounts */    
    private void afterInsertGeneralAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.generalAccounts.values());
    }
    private void afterUpdateGeneralAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.generalAccounts);
    }
    
    /** Credit Cards */    
    private void afterInsertCreditCards() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.creditCards.values());
    }
    private void afterUpdateCreditCards() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.creditCards);
    }
    
    /** Loan Accounts */    
    private void afterInsertLoanAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.loanAccounts.values());
    }
    private void afterUpdateLoanAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.loanAccounts);
    }
    
    /** Mortgages */    
    private void afterInsertMortgages() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.mortgages.values());
    }
    private void afterUpdateMortgages() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.mortgages);
    }
    
    /** Savings Accounts */    
    private void afterInsertSavingsAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.savingsAccounts.values());
    }

    private void afterUpdateSavingsAccounts() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.savingsAccounts);
    }
  }