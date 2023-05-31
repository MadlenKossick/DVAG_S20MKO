/**
 * @author DVAG / LPF
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Creates Integration Event Platform Events to be consumed by MuleSoft
 */

public without sharing class TH_IntegrationEvent {
    private List<SObject> newRecordsFiltered;
    private Map<Id,SObject> oldRecordsFiltered;
    private Set<String> extIdFields;

    public TH_IntegrationEvent(List<SObject> newRecords, Map<Id,SObject> oldRecords, String context, String sObjectType) {
        
        if(checkGlobalFilter('DVAG Integration API Only')) {
            List<IntegrationEventFilter__mdt> recordFilter = getRecordFilter(sObjectType);
            initExtIdFields(sObjectType);            
            filterEvents(recordFilter, newRecords, oldRecords);
            execute(newRecordsFiltered, oldRecordsFiltered, context, sObjectType);
        }
    }
    
    private List<Database.SaveResult> execute(List<SObject> newRecords, Map<Id,SObject> oldRecords, String context, String sObjectType) {
        Map<Id, IntegrationEvent__e> eventsToPublish;

            if(context == 'Insert') {
                eventsToPublish = createEventMap(newRecords, context, sObjectType);
            } else if(context == 'Update') {
                eventsToPublish = createChangeEventMap(new Map<Id,SObject>(newRecords), oldRecords, context, sObjectType);                
            } else if(context == 'Delete') {
                eventsToPublish = createEventMap(oldRecords.values(), context, sObjectType);
            }
            return Eventbus.publish(eventsToPublish.values());
    }

    //PRIVATE METHODS
    private List<IntegrationEventFilter__mdt> getRecordFilter(String sObjectType) {
        return [SELECT FieldApiName__c, FieldValue__c FROM IntegrationEventFilter__mdt WHERE SObject__c = :sObjectType];
    }


    private void filterEvents(List<IntegrationEventFilter__mdt> recordFilter, List<SObject> newRecords, Map<Id,SObject> oldRecords) {
        newRecordsFiltered = new List<SObject>();
        oldRecordsFiltered = new Map<Id, SObject>();
        
        for(SObject record : newRecords) {
            if(checkRecordFilter(record, recordFilter)) {
                newRecordsFiltered.add(record);
                if(oldRecords != null) {  
                    oldRecordsFiltered.put(record.Id, oldRecords.get(record.Id));
                }
            }
        }
    }

    private void initExtIdFields(String sObjectType) {
        extIdFields = new Set<String>();
        if(sObjectType=='Account') {
            for (SObjectField sObjectField : Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().values()) {
                if (sObjectField.getDescribe().isExternalId()) {
                    String name = sObjectField.getDescribe().getName();
                    Integer suffix = name.length()-3;
                    String adaptedPersonAccountField = (name.right(3)=='__c')? (name.left(suffix) + '__pc') : ('Person' + name);
                    extIdFields.add(adaptedPersonAccountField);
                }
            }
        }
        for (SObjectField sObjectField : Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap().values()) {
            if (sObjectField.getDescribe().isExternalId()) {
                extIdFields.add(sObjectField.getDescribe().getName());
            }
        }
    }

    private Boolean checkRecordFilter(SObject record, List<IntegrationEventFilter__mdt> recordFilter) {
        
        //the object has no filters 
        if (recordFilter.isEmpty()) {
            return true;
        }

        //value for the current record ist accepted
        for(IntegrationEventFilter__mdt filter : recordFilter) {
            if(filter.FieldValue__c == record.get(filter.FieldApiName__c)) {
                return true;
            }
        }
        return false;
    }

    private Boolean checkGlobalFilter(String profileName) {
        try {
            String integrationProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].get(0).Id;
            return UserInfo.getProfileId() != integrationProfileId;
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Could not find profile ' + profileName);
            return false;
        }
    }
    
    private Map<Id, IntegrationEvent__e> createEventMap(List<SObject> objectRecords, String context, String sObjectType) {
        Map<Id, IntegrationEvent__e> eventMap  = new Map<Id, IntegrationEvent__e>();
        for(SObject record : objectRecords) {            
            eventMap.put(record.Id, createEvent(record, context, sObjectType));
        }
        return eventMap;
    }

    private Map<Id, IntegrationEvent__e> createChangeEventMap(Map<ID,SObject> newObjectRecords, Map<ID,SObject> oldObjectRecords, String context, String sObjectType) {
        Map<Id, IntegrationEvent__e> eventMap  = new Map<Id, IntegrationEvent__e>();        
        
        for(SObject record : newObjectRecords.values()) {
            String changedFields = getChangedFields(record, oldObjectRecords.get(record.Id));
            if (changedFields == null) {
                continue; //don´t send events without changed fields
            }
            IntegrationEvent__e event = createEvent(record, context, sObjectType);
            event.ChangedFields__c = changedFields;
            eventMap.put(record.Id, event);
        }
        return eventMap;
    }
    

    private IntegrationEvent__e createEvent(SObject record, String context, String sObjectType) {
        IntegrationEvent__e newEvent = new IntegrationEvent__e();        
        newEvent.RecordId__c = record.Id;
        newEvent.Context__c = context;
        newEvent.SObject__c = sObjectType;
        newEvent.ExternalIds__c = getExtIdsForRecord(record);

        // check if the RecordTypeId field exists
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();

        if (fieldMap.containsKey('RecordTypeId')) {
            newEvent.RecordTypeId__c = (String) record.get('RecordTypeId');
        }
        
        return newEvent;
    }

    private String getExtIdsForRecord(SObject record) {
        Map<String, Object> fields = new Map<String, Object>();
        for (String extIds : extIdFields) {
            fields.put(extIds, record.get(extIds));
        }
        return printFields(fields);
    }

    @TestVisible
    private String getChangedFields(SObject newRecord, SObject oldRecord) {
        Map<String, Object> changedFields = new Map<String, Object>();
        Set<String> systemFields = new Set<String>{'CreatedDate','LastModifiedById','LastModifiedDate','SystemModstamp'};

        for (String key : newRecord.getPopulatedFieldsAsMap().keySet()) {
            if (systemFields.contains(key)) { 
                continue;
            }
            if (oldRecord.get(key) != newRecord.get(key)) {
                changedFields.put(key, newRecord.get(key));
            }
        }

        for (String key : oldRecord.getPopulatedFieldsAsMap().keySet()) {
            if(newRecord.get(key) == null) {
                changedFields.put(key, newRecord.get(key));
            }
        }
        if (changedFields.isEmpty()) {
            return null;
        } else {
            return printFields(changedFields);
        }
    }


    private String printFields(Map<String,Object> changedFields) {
        if (changedFields.isEmpty()) {
            return '{ }';
        }

        String result;        
        for(String key : changedFields.keySet()) {
            if (String.isEmpty(result)) {
                result = '{ \'' + key + '\'' + ':' + ' \'' + changedFields.get(key) + '\''; 
            }
            else {
                result = result + ', \'' + key + '\'' + ':' + ' \'' + changedFields.get(key) + '\'';
            }
        }

        return result + ' }';
    }
}