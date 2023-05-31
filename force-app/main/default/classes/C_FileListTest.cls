/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group TestClass
 *
 * @description Test class for C_FileList
 */
@IsTest
public class C_FileListTest {
   
    @TestSetup
    static void setupTestData(){ 
        List<Campaign> l_camp = TestDataUtility.createCampaign(1);

        insert l_camp;

        List<ContentVersion> l_conVersions = new List<ContentVersion>();
        l_conVersions.add(new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test pic Content'),
            IsMajorVersion = true)
        );
        l_conVersions.add(new ContentVersion(
            Title          = 'a pdf',
            PathOnClient   = 'Pic.pdf',
            VersionData    = Blob.valueOf('Test pdf Content'),
            IsMajorVersion = true)
        );

        insert l_conVersions;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record
        List<ContentDocumentLink> l_conDocs = new List<ContentDocumentLink>();
        ContentDocumentLink cdl1 = new ContentDocumentLink();
        cdl1.LinkedEntityId = l_camp[0].Id;
        cdl1.ContentDocumentId = documents[0].Id;
        cdl1.ShareType = 'V';
        cdl1.Visibility = 'InternalUsers';
        l_conDocs.add(cdl1);

        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.LinkedEntityId = l_camp[0].Id;
        cdl2.ContentDocumentId = documents[1].Id;
        cdl2.ShareType = 'V';
        cdl2.Visibility = 'InternalUsers';
        l_conDocs.add(cdl2);

        insert l_conDocs;
    }

    @isTest
    static void handleShowFiles(){
        List<ContentDocument> l_docs = [SELECT Id FROM ContentDocument];
        System.assertEquals(2, l_docs.size());

        List<Campaign> l_camp = [SELECT Id FROM Campaign];
        Test.startTest();

        Map<Id, String> files = C_FileList.getRelatedFilesByRecordId(l_camp[0].Id);
        Test.stopTest();

        System.assertEquals(1, files.size());
    }

    @isTest
    static void handleSharingFiles(){
        
        List<Campaign> l_camp = [SELECT Id FROM Campaign];
        Test.startTest();
        Test.stopTest();

        List<ContentDocumentLink> l_docLinks = [SELECT Id 
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId = :l_camp[0].Id
                                                    AND Visibility = 'AllUsers'];
        System.assertEquals(2, l_docLinks.size());
    }
}