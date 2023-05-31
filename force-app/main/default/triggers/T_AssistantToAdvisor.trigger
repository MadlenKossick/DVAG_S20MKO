/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description AssistantToAdvisor__c Main Trigger
 */

trigger T_AssistantToAdvisor on AssistantToAdvisor__c (before delete, after insert) {
   new TH_AssistantToAdvisor().run();
}