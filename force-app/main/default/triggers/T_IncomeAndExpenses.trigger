/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description IncomeAndExpenses__c Main Trigger
 * 
 */

trigger T_IncomeAndExpenses on IncomeAndExpenses__c (after insert, after update) {
    new TH_IncomeAndExpenses().run();
}