/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger Handler
 *
 * @description shared the document with portal user
 */
public without sharing class TH_ContentDocumentLinkSharing {
    
    public static void setSharingPortalUser(List<ContentDocumentLink> newRecords){
        for(ContentDocumentLink cdl : newRecords) {
            // only ContentDocument linked with EmailMessage
            if (((String) cdl.LinkedEntityId).startsWith('701')) {
                cdl.Visibility = 'AllUsers';
            }
        }
    }    
}