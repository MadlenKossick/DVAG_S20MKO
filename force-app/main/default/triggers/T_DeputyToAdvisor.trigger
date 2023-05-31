/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description DeputyToAdvisor__c Main Trigger
 */

trigger T_DeputyToAdvisor on DeputyToAdvisor__c (before delete, after insert) {
   new TH_DeputyToAdvisor().run();
}