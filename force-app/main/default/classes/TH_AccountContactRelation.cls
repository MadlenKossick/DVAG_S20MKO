/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Account Contact Relationship Object
 */

 public with sharing class TH_AccountContactRelation extends TriggerHandler {
    public override void afterInsert() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Insert', 'AccountContactRelation');
        TH_AccountContactRelationManageHH.accountContactRelationsAfterInsert((Map<Id,AccountContactRelation>) Trigger.newMap);
    }
       
    public override void afterUpdate() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'AccountContactRelation');
    }

    public override void afterDelete() {
        new TH_IntegrationEvent(Trigger.old, Trigger.oldMap, 'Delete', 'AccountContactRelation');
        TH_AccountContactRelationManageHH.accountContactRelationsAfterDelete((List<AccountContactRelation>) Trigger.old);
    }    
}