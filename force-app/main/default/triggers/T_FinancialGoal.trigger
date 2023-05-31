/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description FinServ__FinancialGoal__c Main Trigger
 * 
 */

 trigger T_FinancialGoal on FinServ__FinancialGoal__c(after insert, after update) {
    new TH_FinancialGoal().run();
}