public without sharing class TH_CustomerProperty extends TriggerHandler {
    public override void afterInsert() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Insert', 'CustomerProperty');
    }
    public override void afterUpdate() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'CustomerProperty');
    }
    public override void afterDelete() {
        new TH_IntegrationEvent(Trigger.old, Trigger.oldMap, 'Delete', 'CustomerProperty');
    }
}