/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Contact Financial Account Trigger
 * 
 */

trigger T_FinancialAccount on FinServ__FinancialAccount__c(before delete, after insert, after update, after delete) {
    new TH_FinancialAccount().run();
}