/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger
 *
 * @description CustomerAdvisorRelationship__c Main Trigger
 */

trigger T_CustomerAdvisorRelationship on CustomerAdvisorRelationship__c (after insert, after update, after delete) {
    new TH_CustomerAdvisorRelationship().run();
}