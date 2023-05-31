/**
 * @author rbrezina@salesforce.com
 * @date 14-March-2023
 *
 * @group Trigger Handler
 *
 * @description Sync consent data to PersonAccount/Contact e. g. if Salesforce Consent API actions used which are not automatically update those records
 * 
 * Related Salesforce Consent API-Action to synchronize upwards to PersonAccount, Contact.
 *    process: Write update to Contact.HasOptedOutProcessing__c
 *    solicit: Write update to Contact.FinServ__MarketingOptOut__c
 *
 */

public without sharing class TH_IndividualSyncConsentToAccount {
    
    public static void UpdateAccountForIndividual(list<Individual> updIndividuals, Map<Id, SObject> oldMap){
        
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Individual indvl : updIndividuals) {
            Individual oldindvl = (Individual)oldMap.get(indvl.Id);
            
            if ((oldindvl.HasOptedOutProcessing != indvl.HasOptedOutProcessing ) || (oldindvl.HasOptedOutSolicit != indvl.HasOptedOutSolicit)) 
                // Update all custom consent fields on Contacts related to the Individual if there are changes
                for (Contact cont : [SELECT Id, IndividualId, 
                                            HasOptedOutProcessing__c, 
                                            FinServ__MarketingOptOut__c
                                       FROM Contact
                                     WHERE IndividualId = :indvl.Id]) {

                     cont.HasOptedOutProcessing__c = indvl.HasOptedOutProcessing;
                     cont.FinServ__MarketingOptOut__c = indvl.HasOptedOutSolicit;
                                         
                     contactsToUpdate.add(cont);
				}
        }
        
        if (contactsToUpdate.size() > 0)
        	update contactsToUpdate;
    }
}