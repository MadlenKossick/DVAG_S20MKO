/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Contact Standard Object
 */

 public without sharing class TH_CustomerAdvisorRelationship extends TriggerHandler {
    public override void afterInsert() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Insert', 'CustomerAdvisorRelationship__c');
    }
      
    public override void afterUpdate() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'CustomerAdvisorRelationship__c');
    }

    public override void afterDelete() {
        new TH_IntegrationEvent(Trigger.old, Trigger.oldMap, 'Delete', 'CustomerAdvisorRelationship__c');
    }
}