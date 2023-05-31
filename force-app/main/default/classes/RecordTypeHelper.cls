public class RecordTypeHelper {
    /* Account */
    public static String getAccRecordTypeIdHousehold() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('IndustriesHousehold')
            .getRecordTypeId();
    }
    
    public static String getAccRecordTypeIdPersonAccount() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
    }
    
    
    public static String getAccRecordTypeIdDirectorate() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Directorate')
            .getRecordTypeId();
    }
    
    /* Contact */
    public static String getConRecordTypeIdFinancialAdvisor() {
        return Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('FinancialAdvisor')
            .getRecordTypeId();
    }

    /* Lead */
    public static String getLeadRecordTypeIdReferral() {
        return Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get('Referral')
            .getRecordTypeId();
    }
    
    /* Campaign */
    public static String getCampRecordTypeIdDistributed() {
        return Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
            .get('DistributedMarketingCampaign')
            .getRecordTypeId();
    }

    /* FinServ__AssetsAndLiabilities__c */
    public static String getAssetsLiabilitiesRecordTypeIdNonfinancialAsset() {
        return Schema.SObjectType.FinServ__AssetsAndLiabilities__c.getRecordTypeInfosByDeveloperName()
            .get('NonfinancialAsset')
            .getRecordTypeId();
    }
    
    /* FinServ__FinancialAccount__c */
    public static String getFinancialAccountRecordTypeIdBankingAccount() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
            .get('BankingAccount')
            .getRecordTypeId();
    }

    public static String getFinancialAccountRecordTypeIdInvestmentAccount() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
                .get('InvestmentAccount')
                .getRecordTypeId();
    }

    public static String getFinancialAccountRecordTypeIdGeneralAccount() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
                .get('General')
                .getRecordTypeId();
    }
    
    public static String getFinancialAccountRecordTypeIdCreditCard() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
                .get('CreditCard')
                .getRecordTypeId();
    }
    
    public static String getFinancialAccountRecordTypeIdLoanAccount() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
                .get('LoanAccount')
                .getRecordTypeId();
    }

    public static String getFinancialAccountRecordTypeIdMortgage() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
                .get('Mortgage')
                .getRecordTypeId();
    }

    public static String getFinancialAccountRecordTypeIdSavingsAccount() {
        return Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
                .get('SavingsAccount')
                .getRecordTypeId();
    }

    public static String getCustomerProperyRecordTypeIdVehicle() {        
        return Schema.SObjectType.CustomerProperty.getRecordTypeInfosByDeveloperName()
                .get('Vehicle')
                .getRecordTypeId();
    }

    public static String getCustomerProperyRecordTypeIdRealEstate() {        
        return Schema.SObjectType.CustomerProperty.getRecordTypeInfosByDeveloperName()
                .get('RealEstate')
                .getRecordTypeId();
    }

    public static String getIncomeExpenseRecordTypeIdExpense() {        
        return Schema.SObjectType.IncomeAndExpenses__c.getRecordTypeInfosByDeveloperName()
                .get('Expense')
                .getRecordTypeId();
    }
    
    public static String getIncomeExpenseRecordTypeIdNetGrossIncome() {        
        return Schema.SObjectType.IncomeAndExpenses__c.getRecordTypeInfosByDeveloperName()
                .get('NetGrossIncome')
                .getRecordTypeId();
    }

    public static String getIncomeExpenseRecordTypeIdNetIncome() {        
        return Schema.SObjectType.IncomeAndExpenses__c.getRecordTypeInfosByDeveloperName()
                .get('NetIncome')
                .getRecordTypeId();
    }

    public static String getAssetLiabilityRecordTypeIdAsset() {        
        return Schema.SObjectType.FinServ__AssetsAndLiabilities__c.getRecordTypeInfosByDeveloperName()
                .get('NonfinancialAsset')
                .getRecordTypeId();
    }

    public static String getAssetLiabilityRecordTypeIdLiability() {        
        return Schema.SObjectType.FinServ__AssetsAndLiabilities__c.getRecordTypeInfosByDeveloperName()
                .get('Liability')
                .getRecordTypeId();
    }

    public static String getEventRecordTypeIdAdvisorEvent() {        
        return Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName()
                .get('AdvisorEvent')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyParticipantRecordTypeIdCar() {        
        return Schema.SObjectType.InsurancePolicyParticipant.getRecordTypeInfosByDeveloperName()
                .get('CarInsurance')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyAssetRecordTypeIdCar() {        
        return Schema.SObjectType.InsurancePolicyAsset.getRecordTypeInfosByDeveloperName()
                .get('CarInsurance')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyRecordTypeIdCarInsurance() {        
        return Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('CarInsurance')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyRecordTypeIdHealthInsurance() {        
        return Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('HealthInsurance')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyRecordTypeIdLifeInsurance() {        
        return Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('LifeInsurance')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyRecordTypeIdLegalInsurance() {        
        return Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('LegalInsurance')
                .getRecordTypeId();
    }

    public static String getInsurancePolicyRecordTypeIdPropertyInsurance() {        
        return Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('PropertyInsurance')
                .getRecordTypeId();
    }
    
    /* Helper */
    public static List<SObject> getFilteredList(List<SObject> unfilteredList, Set<Id> recordTypeIds) {
        List<SObject> mapFiltered = new List<SObject>();
        if (unfilteredList == null || recordTypeIds == null ||
            unfilteredList.isEmpty() || recordTypeIds.isEmpty()) {

            return mapFiltered;
        }

        for (SObject obj: unfilteredList) {
            if (recordTypeIds.contains((String)obj.get('RecordTypeId'))) {
                mapFiltered.add(obj);
            }
        }

        return mapFiltered;
    }

    public static Map<Id, SObject> getFilteredMap(List<SObject> unfilteredList, Set<Id> recordTypeIds) {
        List<SObject> lstObjects = getFilteredList(unfilteredList, recordTypeIds);
        Map<Id, SObject> retMap;

        if (lstObjects.size() > 0) {
            retMap = new Map<Id, SObject>(lstObjects);
        }
        else {
            retMap = new Map<Id, SObject>();
        }

        return retMap; 
    }

    public static String getUserProfileIdFieldSalesUser() {
        return [Select ID from Profile where Name = 'DVAG Field Sales User'].get(0).Id;
    }

    public static String getUserProfileIdIntegrationUser() {
        return [Select ID from Profile where Name = 'DVAG Integration API Only'].get(0).Id;
    }

    public static String getUserProfileIdBackOfficeUser() {
        return [Select ID from Profile where Name = 'DVAG Backoffice User'].get(0).Id;
    }    
    
}