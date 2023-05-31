/**
 * @author rbrezina@salesforce.com
 * @date 28-Februar-2023
 *
 * @group Trigger Handler
 *
 * @description Original Version to manage changes on Contact, also if part of PersonAccount by copying data from an related Individual sObject
 */

public without sharing class TH_AccountManageConsent {
        
    public static void initializeConsentFields(list<Account> newPersonAccounts) {
        // Init aggregated consent fields on contact record level
        
        for (Account cont : newPersonAccounts) {
            // Skip record for Accounts only
            if (cont.IsPersonAccount == false) {
                continue;
            }
            
            // Set Defaults on Insert, if no different value was provided initially, e. g. BULK API with insert
            if (cont.ConsentToProcessStatus__pc == null) {
                cont.HasOptedOutProcessing__pc = true;
            }
            if (cont.ConsentToCallStatus__pc == null) {
                cont.PersonDoNotCall = true;
            }
            if (cont.ConsentToEmailStatus__pc == null) {
                cont.PersonHasOptedOutOfEmail = true;
            }
            if (cont.ConsentToCallStatus__pc == null) {
                cont.FinServ__MarketingOptOut__pc = true;
            }
        }
    }
    
    public static void updateConsentFields(List<Account> updPersonAccounts, Map<Id, SObject> oldMap) 
    {
        for (Account cont : updPersonAccounts) {
            
            // Skip record for Accounts only
            if (cont.IsPersonAccount == false) {
                continue;
            }
            
            Account oldCont = (Account)oldMap.get(cont.Id);

            // For death contacts, death must be recorgnized accordingly
            if (cont.IsDeceased__pc == true) {                    
                cont.HasOptedOutProcessing__pc = true;
                cont.ConsentToProcessStatus__pc = 'Fulfilled';
                    
                cont.PersonHasOptedOutOfEmail = true;
                cont.ConsentToEmailStatus__pc = 'OptOut';
                    
                cont.PersonDoNotCall = true;
                cont.ConsentToCallStatus__pc = 'OptOut';
                    
                cont.FinServ__MarketingOptOut__pc = true;
                cont.ConsentToMarketingStatus__pc = 'OptOut';
            } else {
                // Treat each consent if different values flag vs. status were provided on any kind of update,
                // e. g. SOQL, BULK API upsert and/or especially Salesforce Consent API
                // 
                // If value of each consent flag has been changed outside and the new consent status of each type
                // is different from consent flag, set consent status accordingly

                // changed HasOptedOutProcessing__pc    --> new.cont.ConsentToProcessStatus__pc = 'OptIn' || 'OptOut'
                if (cont.HasOptedOutProcessing__pc != oldCont.HasOptedOutProcessing__pc && cont.ConsentToProcessStatus__pc != null) {
                    if (cont.HasOptedOutProcessing__pc) {
                        cont.ConsentToProcessStatus__pc = 'OptOut';
                    } else {
                        cont.ConsentToProcessStatus__pc = 'OptIn';
                    }
                }

                // changed PersonHasOptedOutOfEmail     --> new.cont.ConsentToEmailStatus__pc = 'OptIn' || 'OptOut'
                if (cont.PersonHasOptedOutOfEmail != oldCont.PersonHasOptedOutOfEmail && cont.ConsentToEmailStatus__pc != null) {
                    if (cont.PersonHasOptedOutOfEmail) {
                        cont.ConsentToEmailStatus__pc = 'OptOut';
                    } else {
                        cont.ConsentToEmailStatus__pc = 'OptIn';
                    }
                }

                // changed PersonDoNotCall              --> new.cont.ConsentToCallStatus__pc = 'OptIn' || 'OptOut'
                if (cont.PersonDoNotCall != oldCont.PersonDoNotCall && cont.ConsentToCallStatus__pc != null) {
                    if (cont.PersonDoNotCall) {
                        cont.ConsentToCallStatus__pc = 'OptOut';
                    } else {
                        cont.ConsentToCallStatus__pc = 'OptIn';
                    }
                }

                // changed FinServ__MarketingOptOut__pc --> new.cont.ConsentToMarketingStatus__pc = 'OptIn' || 'OptOut' 
                if (cont.FinServ__MarketingOptOut__pc != oldCont.FinServ__MarketingOptOut__pc && cont.ConsentToMarketingStatus__pc != null) {
                    if (cont.FinServ__MarketingOptOut__pc) {
                        cont.ConsentToMarketingStatus__pc = 'OptOut';
                    } else {
                        cont.ConsentToMarketingStatus__pc = 'OptIn';
                    }
                }
            }
        }
    }
}