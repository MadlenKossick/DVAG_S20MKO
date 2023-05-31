public with sharing class C_FileList {
    
    @AuraEnabled
    public static Map<ID, String> getRelatedFilesByRecordId(String recordId) {
        // Get record file IDs        
        List<ContentDocumentLink> files = [SELECT ContentDocumentId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId = :recordId];
        List<ID> fileIDs = new List<ID>();
        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }
 
        List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title 
                                        FROM ContentVersion 
                                        WHERE ContentDocumentId IN :fileIDs 
                                            AND FileExtension = 'pdf'];
        Map<Id, String> mapIdTitle = new Map<Id, String>();
        for (ContentVersion docLink : docs) {
            mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
        }
        return mapIdTitle;
    }

    public static void setSharingPortalUser(List<ContentDocumentLink> newRecords){
        for(ContentDocumentLink cdl : newRecords) {
            // only ContentDocument linked with EmailMessage
            if (((String) cdl.LinkedEntityId).startsWith('701')) {
                cdl.Visibility = 'AllUsers';
            }
        }
    }    
}