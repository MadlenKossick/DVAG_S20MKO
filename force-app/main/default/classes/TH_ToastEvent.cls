/**
* @author Cloud Consulting Group - Madlen Kossick
* @date 2023
*
* @group TriggerHandler
*
* @description Methods for check changings to push a toast message
*/
public without sharing class TH_ToastEvent {
    
    private enum Variant {INFO, SUCCESS, WARNING, ERROR}
    private enum Mode {DISMISSIBLE, PESTER, STICKY}

    public TH_ToastEvent(List<SObject> newRecords, Map<Id,SObject> oldRecords, String sObjectType) {
        
        // run only for VBs
        if(checkGlobalFilter('DVAG Field Sales User')) {
            Map<Id, ToastEvent__e> allEvents = new Map<Id, ToastEvent__e>();

            allEvents = checkAccoutAddress(newRecords, oldRecords);

            System.debug(allEvents);
            Eventbus.publish(allEvents.values());
        }
    }

    private Boolean checkGlobalFilter(String profileName) {
        try {
            String integrationProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].get(0).Id;
            return UserInfo.getProfileId() == integrationProfileId;
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Could not find profile ' + profileName);
            return false;
        }
    }
    
    public static Map<Id, ToastEvent__e> checkAccoutAddress(List<SObject> newAccounts, Map<Id,SObject> oldAccounts) {
        
        String title = System.Label.ToastEvent_Acc_AddressChanged_Title;
        String message = System.Label.ToastEvent_Acc_AddressChanged_Message;
        String key = 'Acc_AddressChanged';
        
        Id personAccountRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
    
        Map<Id, ToastEvent__e> allEvents = new Map<Id, ToastEvent__e>();

        for (Account newAccount : (List<Account>) newAccounts) {
            Account oldAccount = (Account)oldAccounts.get(newAccount.Id);
                        
            if (newAccount.RecordTypeId != personAccountRtId) { //Extend for HouseholdAccounts
                continue;
            }

            // check which preferred address
            Boolean streetChanged = newAccount.PersonMailingStreet != oldAccount.PersonMailingStreet;
            Boolean cityChanged = newAccount.PersonMailingCity != oldAccount.PersonMailingCity;
            Boolean postalcodeChanged = newAccount.PersonMailingPostalCode != oldAccount.PersonMailingPostalCode;
            Boolean countryChanged = newAccount.PersonMailingCountry != oldAccount.PersonMailingCountry;

            if (streetChanged || cityChanged || postalcodeChanged || countryChanged) {
                ToastEvent__e event = createEvent(newAccount.Id, key, message, getMode(Mode.STICKY), title, getVariant(Variant.INFO));
                allEvents.put(newAccount.Id, event);
            }
        }

        return allEvents;
    }

    private static ToastEvent__e createEvent(String recordId, String key, String message, String mode, String title, String variant) {
        ToastEvent__e newEvent = new ToastEvent__e();
        
        newEvent.RecordId__c = recordId;
        newEvent.Key__c = key;
        newEvent.Message__c = message;
        newEvent.Mode__c = mode;
        newEvent.Title__c = title;
        newEvent.Variant__c = variant;
        
        return newEvent;
    }

    // Variant  
    private static String getVariant(Variant variant) {
        switch on variant {
            when INFO {
                return 'info';
            }
            when SUCCESS {
                return 'success';
            }
            when WARNING {
                return 'warning';
            }
            when ERROR {
                return 'error';
            }
            when else {
                throw new AuraHandledException('Toast variant ' + variant + ' not defined');
            }
        }
    }

    // Mode 
    private static String getMode(Mode mode) {
        switch on mode {
            when DISMISSIBLE {
                return 'dismissible';
            }
            when PESTER {
                return 'pester';
            }
            when STICKY {
                return 'sticky';
            }
            when else {
                throw new AuraHandledException('Toast mode ' + mode + ' not defined');
            }
        }
    }
}