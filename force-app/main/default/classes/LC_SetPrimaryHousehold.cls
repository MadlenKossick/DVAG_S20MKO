/**
 * @author Jochen Litzinger, Cloud Consulting Group
 * @date 2023
 *
 * @group LWCs
 *
 * @description controller for the LWC SetPrimaryHousehold
 *
 */

 public with sharing class LC_SetPrimaryHousehold {
     // wrapper class for Account Contact Relations
     public class ACRWrapper {
        @AuraEnabled 
        public String recordIdPG {get;set;}
        @AuraEnabled
        public List<ACRS> records {get;set;}
        @AuraEnabled
        public List<FinServ__FinancialAccount__c> financialAccounts {get;set;}
        @AuraEnabled
        public List<InsurancePolicy> insurancePolicies {get;set;}
        
        public ACRWrapper() {}
    }

    public class ACRS {
        @AuraEnabled 
        public Id id {get;set;}
        @AuraEnabled 
        public String name {get;set;}
        @AuraEnabled 
        public List<String> contacts {get;set;}
                             
        public ACRS() {}
    }

    @AuraEnabled (cacheable=false)
    public static ACRWrapper getHouseholdAccounts(String recordId) {
        Map<ID, ACRS> acrsByAccId = new Map<ID, ACRS>();
        ACRWrapper acrwr = new ACRWrapper();

        String recTypeIdHousehold = RecordTypeHelper.getAccRecordTypeIdHousehold();

        System.debug('recordId ' +  recordId);
        if (String.isBlank(recordId)) throw new AuraHandledException('Invalid record id!');
        
        // get contact id for person account
        List<Contact> paContacts = [SELECT Id, AccountId FROM Contact WHERE AccountId = :recordId];
        if (paContacts.size() != 1) throw new AuraHandledException('Invalid contact for person account');
        Contact paContact = paContacts[0];
        
        // get the household accounts
        Set<ID> householdAccs = new Set<ID>();
        Map<ID,ID> householdByContact = new Map<ID,ID>();
        for (AccountContactRelation acr :  [SELECT Id, AccountId FROM AccountContactRelation 
                                            WHERE Account.RecordTypeId = : recTypeIdHousehold 
                                            AND ContactId = :paContact.Id]) {
            householdAccs.add(acr.AccountId);
            householdByContact.put(acr.AccountId, acr.Id);
        }
        
        // get all relations for the household accounts
        List<AccountContactRelation> acrs = [SELECT Id, AccountId, Account.Name, ContactId, Contact.FirstName, Contact.Lastname, FinServ__PrimaryGroup__c 
            FROM AccountContactRelation WHERE AccountId in :householdAccs ORDER BY AccountId];
        
        // get current primary group record
        List<AccountContactRelation> acrspg = [SELECT Id, ContactId FROM AccountContactRelation 
        WHERE ContactId = :paContact.Id AND FinServ__PrimaryGroup__c = true];
        
        acrwr.recordIdPG =  (acrspg.isEmpty()) ? '' : acrspg[0].Id;
                
        // get all relations for the household accounts
        for (AccountContactRelation acr : acrs)  {

            if (!acrsByAccId.containsKey(acr.AccountId)) {
                ACRS ac = new ACRS();
                ac.id = householdByContact.get(acr.AccountId);
                ac.name = acr.Account.Name;
                ac.contacts = new List<String>();           

                acrsByAccId.put(acr.AccountId, ac);
            }

            acrsByAccId.get(acr.AccountId).contacts.add(acr.Contact.FirstName + ' ' + acr.Contact.LastName);
        }
        acrwr.records = acrsByAccId.values();

        acrwr.financialAccounts = [SELECT Id, FinServ__PrimaryOwner__c, PrimaryHouseholdHelper__c 
            FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :recordId];

        acrwr.insurancePolicies = [SELECT Id, NameInsuredId, PrimaryHouseholdHelper__c 
            FROM InsurancePolicy WHERE NameInsuredId = :recordId];

        return acrwr;
    }

    @AuraEnabled
    public static void manageRecords(String data, String objType, String op) {
        System.debug('LC_SetPrimaryHousehold.manageRecords: ' + op + '/' + objType + '/' + data);
        List<SObject> lstObjects = new List<SObject>();
        Boolean isList = objType.left(4).equalsIgnoreCase('list') ? true : false;
        
        if (isList) {
            lstObjects = (List<SObject>) JSON.deserialize(data, Type.forName(objType));
        } 
        else {
            SObject obj = (SObject) JSON.deserialize(data, Type.forName(objType));
            lstObjects.add(obj);
        }
              
        try {
            if (op.equalsIgnoreCase('insert')) {
                insert lstObjects;
            }
            else if (op.equalsIgnoreCase('delete')) {
                delete lstObjects;
            }
            else if (op.equalsIgnoreCase('update')) {
                update lstObjects;
            }
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
}