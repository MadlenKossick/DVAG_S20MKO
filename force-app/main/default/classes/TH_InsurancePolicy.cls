/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Insurance Policy Standard Object
 */

public without sharing class TH_InsurancePolicy extends TriggerHandler {
    
    private Map<Id,SObject> carInsurances;
    private Map<Id,SObject> healthInsurances;
    private Map<Id,SObject> lifeInsurances;
    private Map<Id,SObject> legalInsurances;
    private Map<Id,SObject> propertyInsurances;

    public TH_InsurancePolicy() {
        Id recTypeCarInsurance = RecordTypeHelper.getInsurancePolicyRecordTypeIdCarInsurance();
        Id recTypeHealthInsurance = RecordTypeHelper.getInsurancePolicyRecordTypeIdHealthInsurance();
        Id recTypeLifeInsurance = RecordTypeHelper.getInsurancePolicyRecordTypeIdLifeInsurance();
        Id recTypeLegalInsurance = RecordTypeHelper.getInsurancePolicyRecordTypeIdLegalInsurance();
        Id recTypePropertyInsurance = RecordTypeHelper.getInsurancePolicyRecordTypeIdPropertyInsurance();

        this.carInsurances = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeCarInsurance});
        this.healthInsurances = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeHealthInsurance});
        this.lifeInsurances = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeLifeInsurance});
        this.legalInsurances = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypeLegalInsurance});
        this.propertyInsurances = RecordTypeHelper.getFilteredMap(Trigger.new, new Set<Id>{recTypePropertyInsurance});
    }    

    public override void afterInsert() {
        //TODO: ISnbt this missing?
        //new TH_IntegrationEvent(Trigger.new, 'Insert', 'InsurancePolicy');
        afterInsertCarInsurances();
        afterInsertHealthInsurances();
        afterInsertLifeInsurances();
        afterInsertLegalInsurances();
        afterInsertPropertyInsurances();
    }
    
    public override void afterUpdate() {
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'InsurancePolicy');
        afterUpdateCarInsurances();
        afterUpdateHealthInsurances();        
        afterUpdateLifeInsurances();
        afterUpdateLegalInsurances();
        afterUpdatePropertyInsurances();
    }
    
    public override void beforeDelete() {
        TH_CheckProductBeforeDelete.checkProductIdForInsurancePolicies(Trigger.old);
    }
    
    public override void afterDelete() {
        new TH_IntegrationEvent(Trigger.old, Trigger.oldMap, 'Delete', 'InsurancePolicy');
    }

    /** Car Insurance */
    private void afterInsertCarInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.carInsurances.values());
    }
    private void afterUpdateCarInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.carInsurances);
    }

    /** Health Insurance */
    private void afterInsertHealthInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.healthInsurances.values());
    }
    private void afterUpdateHealthInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.healthInsurances);
    }

    /** Life Insurance */
    private void afterInsertLifeInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.lifeInsurances.values());
    }
    private void afterUpdateLifeInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.lifeInsurances);
    }

    /** Legal Insurance */
    private void afterInsertLegalInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.legalInsurances.values());
    }
    private void afterUpdateLegalInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.legalInsurances);
    }

    /** Property Insurance */
    private void afterInsertPropertyInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(this.propertyInsurances.values());
    }
    private void afterUpdatePropertyInsurances() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, this.propertyInsurances);
    }

  }