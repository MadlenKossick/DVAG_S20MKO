/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Account Standard Object
 */

public without sharing class TH_Account extends TriggerHandler {
    public override void beforeInsert() {
        TH_AccountManageConsent.initializeConsentFields(Trigger.new);
        TH_MarketingSynchronisation.setSynMcOnInsert(Trigger.new);
    }
    
    public override void beforeUpdate() {
        TH_AccountManageConsent.updateConsentFields(Trigger.new, Trigger.oldMap);
        TH_CommunicationChannels.deleteOkiFieldsValues(Trigger.new, Trigger.oldMap);
        TH_MarketingSynchronisation.setSynMcOnUpdate((List<Account>)Trigger.new, (Map<Id, Account>)Trigger.oldMap);
        TH_AccountManageHiding.manageHiddenAccounts((List<Account>)Trigger.new, (Map<Id, Account>)Trigger.oldMap);
    }
    
    public override void afterInsert() {
        TH_AccountManageSharing.calcSharingNewAccount(Trigger.newMap);
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Insert', 'Account');
    }
    
    public override void afterUpdate() {
        TH_AccountManageSharing.calcSharingUpdatedAccount(Trigger.newMap, Trigger.oldMap);        
        TH_CommunicationChannels.deleteOkiFieldsValuesAfterUpdate(Trigger.new, Trigger.oldMap);
        TH_MarketingSynchronisation.updateSyncMConCampainMember((List<Account>)Trigger.new, (Map<Id, Account>)Trigger.oldMap);
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'Account');
        new TH_ToastEvent(Trigger.new, Trigger.oldMap, 'Account');
    }

    public override void beforeDelete() {
        TH_AccountManageDeletion.deleteAccount(Trigger.oldMap);
        TH_AccountContactRelationManageHH.accountsBeforeDelete((List<Account>) Trigger.old);        
    }
    
    public override void afterDelete() {
        TH_AccountManageDeletion.deleteIndividual(Trigger.oldMap);
        new TH_IntegrationEvent(Trigger.old, Trigger.oldMap, 'Delete', 'Account');
        TH_AccountContactRelationManageHH.accountsAfterDelete();
    }
}