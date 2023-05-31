/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Updates the campaign sharing for VBs
 */

 public with sharing class TH_CampaignDataSharing {
    private static String PROCESS = 'CampaignSharing Calculation';

    public static void calculateSharingOnCampaignInsert(Map<Id, SObject> newCampaigns) {
        Map<Id, Set<Id>> mapCamWithUser = new Map<Id, Set<Id>>();        

        Id recordIdVB = RecordTypeHelper.getConRecordTypeIdFinancialAdvisor();
        
        // get all VB contacts
        List<Contact> l_VBs = [SELECT Id
                                    FROM Contact 
                                    WHERE RecordTypeId = :recordIdVB];

        List<User> l_User   = [SELECT Id, ContactId 
                                    FROM User 
                                    WHERE ContactId IN :l_VBs 
                                        AND IsActive = TRUE];
        Map<Id, Id> mapConUser = new Map<Id, Id>();
        for (User user : l_User) {
            mapConUser.put(user.ContactId, user.Id);
        }

        // get all active VB contacts
        List<Contact> l_VBcon = [SELECT Id, DistributionCompany__c, 
                                    (SELECT Id, LicenseClass, Status FROM BusinessLicenses WHERE Status = 'Verified' /*AND LicenseClass IN :businessLicense*/ ORDER BY LicenseClass) 
                                    FROM Contact 
                                    WHERE Id IN :mapConUser.keySet()];

        for (Id newCampaignId : newCampaigns.keySet()) {
            Campaign newCampaign = (Campaign) newCampaigns.get(newCampaignId);
            Set<Id> vbUserIds = new Set<Id>();

            if (newCampaign.AvailabilityForDistributionCompany__c == null) {
                return;
            }

            List<String> distributionCompany = newCampaign.AvailabilityForDistributionCompany__c.split(';');
               
            if (newCampaign.RequiredBusinessLicenses__c == null) {
                // if the Business License null -> share for all Users
                for (Contact con : l_VBcon) {
                    if (distributionCompany.contains(con.DistributionCompany__c)) {
                        vbUserIds.add(mapConUser.get(con.Id));
                    }
                }
            } else if (newCampaign.RequiredBusinessLicenses__c != null) { 
                List<String> l_businessLicense = newCampaign.RequiredBusinessLicenses__c.split(';');
                for (Contact vbContact : l_VBcon) {
                    if (distributionCompany.contains(vbContact.DistributionCompany__c)) {
                        // VB must have at least all business licenses selected on the campaign
                        Integer counter = l_businessLicense.size();
                        for (String license : l_businessLicense) {
                            for (BusinessLicense busLicItem : vbContact.BusinessLicenses) {
                                if (busLicItem.LicenseClass == license) {
                                    counter--;
                                }
                            }
                        }

                        if (counter == 0) {
                            vbUserIds.add(mapConUser.get(vbContact.Id));
                        }
                    }
                }
            }
            
            mapCamWithUser.put(newCampaignId, vbUserIds);
        }     

        try {  
            createCampaignShareForCampaign(mapCamWithUser);
        } catch (Exception e) {
            ErrorUtil.logExceptionError(process, 'Insert Campaign', e);
        }    
    }

    public static void calculateSharingOnCampaignUpdate(Map<Id, SObject> newCampaigns, Map<Id, SObject> oldCampaigns) {
        Set<Id> campIdsDelete = new Set<Id>();

        Map<Id, Set<Id>> mapCamWithUser = new Map<Id, Set<Id>>();        

        Id recordIdVB = RecordTypeHelper.getConRecordTypeIdFinancialAdvisor();

        // get all VB contacts
        List<Contact> l_VBs = [SELECT Id
                                    FROM Contact 
                                    WHERE RecordTypeId = :recordIdVB];

        List<User> l_User   = [SELECT Id, ContactId 
                                    FROM User 
                                    WHERE ContactId IN :l_VBs 
                                        AND IsActive = TRUE];
        Map<Id, Id> mapConUser = new Map<Id, Id>();
        for (User user : l_User) {
            mapConUser.put(user.ContactId, user.Id);
        }

        // get all active VB contacts
        List<Contact> l_VBcon = [SELECT Id, DistributionCompany__c, 
                                    (SELECT Id, LicenseClass, Status FROM BusinessLicenses WHERE Status = 'Verified' /*AND LicenseClass IN :businessLicense*/ ORDER BY LicenseClass) 
                                    FROM Contact 
                                    WHERE Id IN :mapConUser.keySet()];

        for (Id newCampaignId : newCampaigns.keySet()) {
            Campaign newCampaign = (Campaign) newCampaigns.get(newCampaignId);
            Campaign oldCampaign = (Campaign) oldCampaigns.get(newCampaignId);

            if (newCampaign.AvailabilityForDistributionCompany__c == null) {
                // if the distribution Company null -> delete all sharings
                campIdsDelete.add(newCampaignId);
            } else {
                Set<Id> vbUserIds = new Set<Id>();

                List<String> distributionCompany = newCampaign.AvailabilityForDistributionCompany__c.split(';');
                
                if (newCampaign.RequiredBusinessLicenses__c == null ) {
                    campIdsDelete.add(newCampaignId);
                    // if the Business License null -> share for all Users
                    for (Contact con : l_VBcon) {
                        if (distributionCompany.contains(con.DistributionCompany__c)) {
                            vbUserIds.add(mapConUser.get(con.Id));
                        }
                    }
                } else {
                    if (newCampaign.RequiredBusinessLicenses__c != oldCampaign.RequiredBusinessLicenses__c || 
                                newCampaign.AvailabilityForDistributionCompany__c != oldCampaign.AvailabilityForDistributionCompany__c) {
                        campIdsDelete.add(newCampaignId);
                        List<String> l_businessLicense = newCampaign.RequiredBusinessLicenses__c.split(';');
                        for (Contact vbContact : l_VBcon) {
                            if (distributionCompany.contains(vbContact.DistributionCompany__c)) {
                                // VB must have at least all business licenses selected on the campaign
                                if (vbContact.BusinessLicenses != null) {
                                    // VB must have at least all business licenses selected on the campaign
                                    Integer counter = l_businessLicense.size();
                                    for (String license : l_businessLicense) {
                                        for (BusinessLicense busLicItem : vbContact.BusinessLicenses) {
                                            if (busLicItem.LicenseClass == license) {
                                                counter--;
                                            }
                                        }
                                    }

                                    if (counter == 0) {
                                        vbUserIds.add(mapConUser.get(vbContact.Id));
                                    }
                                }
                            }
                        }
                    }
                }   
                
                mapCamWithUser.put(newCampaignId, vbUserIds); 
            }
            
            
        }

        // delete all Campaign Share values for this campaign
        List<CampaignShare> l_camShare  = [SELECT Id 
                                            FROM CampaignShare 
                                            WHERE CampaignId IN :campIdsDelete
                                                AND RowCause = 'Manual'];
        
        Database.deleteResult[] results = Database.delete(l_camShare, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Deletion all campaign shares failed', dmlHelper, true);

        try {  
            createCampaignShareForCampaign(mapCamWithUser);
        } catch (Exception e) {
            ErrorUtil.logExceptionError(process, 'Update Campaign', e);
        } 
    }

    /* 
    is currently not used
    
    public static void calculateSharingOnContactInsert(Map<Id, SObject> newContacts) {
        Set<Id> updateConIds = new Set<Id>();
        for (Id newContactId : newContacts.keySet()) {
            Contact newContact = (Contact) newContacts.get(newContactId);
            // fields must be filled
            if (newContact.DistributionCompany__c != null) {
                if (updateConIds.isEmpty() || !updateConIds.contains(newContactId)) {
                    updateConIds.add(newContactId);
                }
            }     
        }

        calculateSharingOnBusinessLicense('Error - Insert Contact', updateConIds); 
    }*/

    public static void calculateSharingOnContactUpdate(Map<Id, SObject> newContacts, Map<Id, SObject> oldContacts) {
        
        Set<Id> updateConIds = new Set<Id>();

        for (Id newContactId : newContacts.keySet()) {
            Contact newContact = (Contact) newContacts.get(newContactId);
            Contact oldContact = (Contact) oldContacts.get(newContactId);

            if (newContact.DistributionCompany__c == null && oldContact.DistributionCompany__c != null) {
                if (updateConIds.isEmpty() || !updateConIds.contains(newContactId)) {
                    updateConIds.add(newContactId);
                }
            } else if (newContact.DistributionCompany__c != oldContact.DistributionCompany__c) {
                if (updateConIds.isEmpty() || !updateConIds.contains(newContactId)) {
                    updateConIds.add(newContactId);
                }
            }    
        }
        calculateSharingOnBusinessLicense('Error - Update Contact', updateConIds); 
    }
    
    public static void calculateSharingOnBusinessLicenseIns(Map<Id, SObject> newLicenses) {
        Set<Id> updateConIds = new Set<Id>();
        for (Id newLicenseId : newLicenses.keySet()) {
            BusinessLicense newLicense = (BusinessLicense) newLicenses.get(newLicenseId);
            if (updateConIds.isEmpty() || !updateConIds.contains(newLicense.ContactId)) {
                updateConIds.add(newLicense.ContactId);
            }
        }    
        
        calculateSharingOnBusinessLicense('Error - Insert BusinessLicense', updateConIds); 
    }

    public static void calculateSharingOnBusinessLicenseUpd(Map<Id, SObject> newLicenses, Map<Id, SObject> oldLicenses) {
        Set<Id> updateConIds = new Set<Id>();

        for (Id newLicenseId : newLicenses.keySet()) {
            BusinessLicense newLicense = (BusinessLicense) newLicenses.get(newLicenseId);
            BusinessLicense oldLicense = (BusinessLicense) oldLicenses.get(newLicenseId);

            if (newLicense.Status != oldLicense.Status || newLicense.LicenseClass != oldLicense.LicenseClass) {
                if (updateConIds.isEmpty() || !updateConIds.contains(newLicense.ContactId)) {
                    updateConIds.add(newLicense.ContactId);
                }                  
            }    
        }

        calculateSharingOnBusinessLicense('Error - Update BusinessLicense', updateConIds);        
    }

    public static void calculateSharingOnBusinessLicenseDel(Map<Id, SObject> oldLicenses) {
        Set<Id> updateConIds = new Set<Id>();
        
        for (Id oldLicenseId : oldLicenses.keySet()) {
            BusinessLicense oldLicense = (BusinessLicense) oldLicenses.get(oldLicenseId);
            
            if (updateConIds.isEmpty() || !updateConIds.contains(oldLicense.ContactId)) {
                updateConIds.add(oldLicense.ContactId);
            }                   
        }

        calculateSharingOnBusinessLicense('Error - Delete BusinessLicense', updateConIds); 
    }

    public static void calculateSharingOnBusinessLicense(String errorMsg, Set<Id> conIds){
        Map<Id, Contact> mapCon = new Map<Id, Contact>([SELECT Id, 
                                        (SELECT Id, LicenseClass, Status FROM BusinessLicenses WHERE Status = 'Verified' ORDER BY LicenseClass), 
                                        DistributionCompany__c 
                                    FROM Contact 
                                    WHERE Id IN :conIds
        ]);
        List<User> l_User = [SELECT Id, ContactId 
                                FROM User 
                                WHERE ContactId IN :mapCon.keySet()];

        Map<Id, Id> mapConUser = new Map<Id, Id>();
        for (User user : l_User) {
            mapConUser.put(user.ContactId, user.Id);
        }

        List<Campaign> l_campaign = [SELECT Id, RequiredBusinessLicenses__c, AvailabilityForDistributionCompany__c 
                                        FROM Campaign 
                                        WHERE IsActive = TRUE];
        if (Test.isRunningTest()){
            l_campaign = [SELECT Id, RequiredBusinessLicenses__c, AvailabilityForDistributionCompany__c 
                            FROM Campaign];
        }

        // delete all Campaign Share values for this user, contact
        List<CampaignShare> l_camShare = [SELECT Id 
                                            FROM CampaignShare 
                                            WHERE UserOrGroupId IN :mapConUser.values() 
                                                AND RowCause = 'Manual'];
        
        Database.deleteResult[] results = Database.delete(l_camShare, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Deletion all campaign shares failed', dmlHelper, true);

        try {  
            List<CampaignShare> l_camShareIns = new List<CampaignShare>();

            for (Id conId : conIds) {
                l_camShareIns.addAll(createCampaignShareForUser(mapConUser.get(conId), mapCon.get(conId), l_campaign));
            }

            if (!l_camShareIns.isEmpty()) {
                Database.saveResult[] resultsIns = Database.insert(l_camShareIns, false);
                DMLHelper dmlHelperIns = new DMLHelper(resultsIns);
                ErrorUtil.processDMLErrors(PROCESS, 'Insert CampaignShare failed', dmlHelperIns, true); 
            }            
        } catch (Exception e) {
            ErrorUtil.logExceptionError(process, 'Update BusinessLicense', e);
        } 
    }

    public static void createCampaignShareForCampaign(Map<Id, Set<Id>> mapCamWithUser) {
        
        List<CampaignShare> l_camShare = new List<CampaignShare>();

        for (Id camId : mapCamWithUser.keySet()) {
            Set<Id> userIds = mapCamWithUser.get(camId);
            
            for (Id vbId : userIds) {
                l_camShare.add(
                    new CampaignShare(
                        CampaignId = camId,
                        UserOrGroupId = vbId,
                        CampaignAccessLevel = 'Edit',
                        RowCause = 'Manual'
                    )
                );
            }
        }
        
        Database.saveResult[] results = Database.insert(l_camShare, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert CampaignShare failed', dmlHelper, true);
    }

    // VBUser(Contact) was inserted or updated -> set the Campaign Share
    public static List<CampaignShare> createCampaignShareForUser(Id userId, Contact vbContact, List<Campaign> l_campaign) {
        List<CampaignShare> l_camShare = new List<CampaignShare>();

        if (vbContact.DistributionCompany__c == null) {
            return null;
        } else {
            Map<Id, Campaign> m_campaign = new Map<Id, Campaign>();
            for (Campaign camItem : l_campaign) {
                if(!m_campaign.containsKey(camItem.Id)) {
                    if(camItem.AvailabilityForDistributionCompany__c.contains(vbContact.DistributionCompany__c)) {
                        if (camItem.RequiredBusinessLicenses__c == null) {
                            m_campaign.put(camItem.Id, camItem);
                        } else {
                            if (vbContact.BusinessLicenses != null) {
                                List<String> l_businessLicense = camItem.RequiredBusinessLicenses__c.split(';');

                                Integer counter = l_businessLicense.size();
                                for (String license : l_businessLicense) {
                                    for (BusinessLicense busLicItem : vbContact.BusinessLicenses) {
                                        if (busLicItem.LicenseClass == license) {
                                            counter--;
                                        }
                                    }
                                }

                                if (counter == 0) {
                                    m_campaign.put(camItem.Id, camItem);
                                }
                            }
                        }                                          
                    }                        
                }
            }         

            if (m_campaign != null && !m_campaign.isEmpty()) {                
                for (Campaign camItem : m_campaign.values()) {
                    l_camShare.add(
                        new CampaignShare(
                            CampaignId = camItem.Id,
                            UserOrGroupId = userId,
                            CampaignAccessLevel = 'Edit',
                            RowCause = 'Manual'
                        )
                    );
                }
            }
        }
        return l_camShare;
    }
}