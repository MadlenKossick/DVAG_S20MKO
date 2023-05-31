public without sharing class TH_CommunicationChannels {
    
    private static final Set<String> CONTACT_FIELD_LIST = new Set<String>{ 
            'OtherAddress','MailingAddress','Email','MobilePhone', 'Phone', 'Fax', 'OtherMobile__c',
            'OtherPhone', 'FinServ__Facebook__c', 'FinServ__LinkedIn__c', 'Xing__c' };
    private static final Set<String> ACCOUNT_FIELD_LIST = new Set<String>{ 
            'PersonEmail', 'PersonMobilePhone', 'Phone', 'Fax', 
            'OtherMobile__pc', 'PersonHomePhone', 'PersonOtherPhone', 
            'FinServ__Facebook__pc', 'FinServ__LinkedIn__pc', 'Xing__pc','Website' };
    private static final Set<String> ACCOUNT_FIELD_LIST_AFTER = new Set<String>{ 
            'FinServ__OtherAddress__pc'}; // , 'FinServ__MailingAddress__pc' - ExtMailingAddressIdOki__pc should not delete now

    public static Boolean isFirstTime = true;
      
    public static void deleteOkiFieldsValues(List<SObject> newList, Map<Id, SObject> oldMap) {
        
        Boolean IsAccount = false;
        String extField ;
        Set<String> fieldList = new Set<String>();

        // Loop through the new list
        for (SObject obj : newList) {
            Boolean updateRecord = false;

            switch on obj.getSObjectType().getDescribe().getName() {
                when 'Account' {	// when block 1                    
                    fieldList = ACCOUNT_FIELD_LIST;
                    IsAccount = true;
                }	
                when 'Contact' {	                    
                    fieldList  = CONTACT_FIELD_LIST;
                }
            }  
                   
            // Check if the old version of the record is in the oldMap
            SObject oldObj = oldMap.get(obj.Id);

            if (oldObj != null) {
                
                // Loop through the field list
                for (String fieldName : fieldList) {
                    // Check if the field is becoming empty
                    if (obj.get(fieldName) == null && oldObj.get(fieldName) != null) {
                        updateRecord = true;

                        if(fieldName == 'PersonMobilePhone' || fieldName == 'MobilePhone') fieldName = 'Mobile';
                        if (fieldName.endswith('__c')) fieldName = fieldName.removeEnd('__c');
                        if (fieldName.endswith('__pc')) fieldName = fieldName.removeEnd('__pc');
                        
                        // Construct the name of the "ext" field
                   
                        if(fieldName.startswith('Person')) fieldName = fieldName.removeStart('Person');
                        if(fieldName.startswith('FinServ__')) fieldName = fieldName.removeStart('FinServ__');                     
                    
                        // Delete the value of the "ext" field
                        if(!IsAccount){
                            extField = 'Ext' + fieldName + 'IdOki__c';                          
                        } else {
                            if (fieldName == 'Website') {
                                extField = 'Ext' + fieldName + 'IdOki__c';
                            } else if (fieldName == 'HomePhone') {
                                extField = 'ExtPhoneIdOki__pc';
                            } else {
                                extField = 'Ext' + fieldName + 'IdOki__pc';
                            }                                                       
                        }
                        obj.put(extField, null);                                        
                    }
                }        
            }
        }
    }

    // we can not used 'FinServ__OtherAddress__pc', 'FinServ__MailingAddress__pc' in before Trigger
    // value for Country is still set
    // we used after methode
    public static void deleteOkiFieldsValuesAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<SObject> objsToUpdate = new List<SObject>();
        String extField ;
        Set<String> fieldList = new Set<String>();
        // Loop through the new list
        for (SObject obj : newList) {
            Boolean updateRecord = false;

            // Check if the old version of the record is in the oldMap
            SObject oldObj = oldMap.get(obj.Id);            

            if (oldObj != null) {
                Account acc = new Account(Id=obj.Id);                  
                fieldList = ACCOUNT_FIELD_LIST_AFTER;

                // Loop through the field list
                for (String fieldName : fieldList) {
                    // Check if the field is becoming empty
                    if (obj.get(fieldName) == null && oldObj.get(fieldName) != null) {
                        updateRecord = true;

                        if (fieldName.endswith('__pc')) fieldName = fieldName.removeEnd('__pc');
                        
                        // Construct the name of the "ext" field

                        if(fieldName.startswith('FinServ__')) fieldName = fieldName.removeStart('FinServ__');   
                        
                        // Delete the value of the "ext" field
                        extField = 'Ext' + fieldName + 'IdOki__pc';
                        acc.put(extField, null); 
                    }
                }
                
                if (updateRecord) {
                    objsToUpdate.add(acc);  
                }     
            }
        }

        if(objsToUpdate.size() > 0 && isFirstTime) {
            isFirstTime = false;
            update objsToUpdate;
            System.debug(objsToUpdate);
        }
    }
}