/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Controller
 *
 * @description helper for the duplicates view
 */
 public without sharing class C_Duplicates {
    
    @AuraEnabled(cacheable=true)
    public static string getDuplicatesAccounts(){
        try {
          
            List<Account> accsToDuplicateSets = [SELECT Name, PersonMailingAddress, PersonBirthdate, AccountNumber, toLabel(FinServ__Status__c), 
                                                        RecordTypeId, toLabel(RecordType.Name), 
                                                        (SELECT DuplicateRecordSet.Name FROM DuplicateRecordItems ORDER BY DuplicateRecordSet.Name ASC) 
                                                FROM Account 
                                                WHERE Id IN (SELECT RecordId FROM DuplicateRecordItem) 
                                                    AND OwnerId = :UserInfo.getUserId()];

            List<DuplicatesWrapper> duplicateList = new List<DuplicatesWrapper>();
            for(Account acc : accsToDuplicateSets){
                for(DuplicateRecordItem item : acc.DuplicateRecordItems){
                    DuplicatesWrapper dw = new DuplicatesWrapper();
                    Address addr = acc.PersonMailingAddress;
                    dw.groupName = item.DuplicateRecordSet.Name;
                    dw.accountId = acc.Id;
                    dw.name = acc.Name;
                    dw.type = acc.RecordType.Name;
                    dw.status = acc.FinServ__Status__c;
                    dw.hauptwohnsitz = acc.PersonMailingAddress != null ? addr.street + ', ' + addr.postalCode + ' ' + addr.city : '';
                    if (acc.PersonBirthdate != null) {                        
                        dw.geburtstag = acc.PersonBirthdate.format();
                    }
                    dw.kundennummer = acc.AccountNumber;
                    duplicateList.add(dw);
                }                
            }
            System.debug(JSON.serialize(duplicateList));

            return JSON.serialize(duplicateList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static  String getRecordDuplicates(String recordId) {
        try {
            List<Account> accounts = [SELECT Name, (SELECT DuplicateRecordSetId, RecordId, DuplicateRecordSet.Name FROM DuplicateRecordItems) 
                                        FROM Account 
                                        WHERE Id = :recordId 
                                            AND OwnerId = :UserInfo.getUserId()];

            Id drsId = accounts[0].DuplicateRecordItems[0].DuplicateRecordSetId;
            List<DuplicateRecordItem> items = [SELECT RecordId 
                                                FROM DuplicateRecordItem 
                                                WHERE DuplicateRecordSetId = :drsId];

            List<Id> recId = new List<Id>();
            for(duplicateRecordItem item: items){
                recId.add(item.recordId);
            }

            //System.debug([SELECT Id, Name from account where id in :recId]);
            List<Account> resultAccounts = [SELECT Id, Name 
                                            FROM Account 
                                            WHERE Id IN :recId 
                                                AND OwnerId = :UserInfo.getUserId()];
            System.debug('result account :' + JSON.serialize(resultAccounts));

            return JSON.serialize(resultAccounts);        
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    

    public class DuplicatesWrapper {
        public String groupName { get; set; }
        public Id accountId { get; set; }
        public String name { get; set; }
        public String type { get; set; }
        public String status { get; set; }
        public String hauptwohnsitz { get; set; }
        public String geburtstag { get; set; }
        public String kundennummer { get; set; }
      }
}