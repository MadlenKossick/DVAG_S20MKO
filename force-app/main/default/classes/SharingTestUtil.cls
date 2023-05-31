/**
* @author Salesforce.com - Stefan Talkenberg
* @date 2023
*
* @description Utility Class with helper methods to test sharing (e.g. create VB structure, check visibility etc.)
*  
*  ToDo: 
*  - Add Assistants (account/relations)
*  - Add Deputies   (relations)
*  - Add 360 degree  Objects
*  - Add Multiple Ownership
*/

public class SharingTestUtil {

    public static final Id fieldSalesUserProfileId = RecordTypeHelper.getUserProfileIdFieldSalesUser();
    public static final Integer MAX_HIERARCHY_DEPTH = 17;
    //public static final User integrationUser = TestDataUtility.getIntegrationTestUser();
    
    private static final Id personAccountRecordType = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
    private static final Id householdAccountRecordType = RecordTypeHelper.getAccRecordTypeIdHousehold();
    private static final Id directorateAccountRecordType = RecordTypeHelper.getAccRecordTypeIdDirectorate();

    public class ExperienceCloudUserDetails {
        public Id accountID;
        public String firstName;
        public String lastName;
        public String userName;
        public String reportsToUsername;
        public String advisorNumber;
    }
    
    /*partnerAccounts*/
    public static Account directoratePartnerAccount;
    public static Account assistantPartnerAccount; 
    
    /*VB User hierarchy*/
    /*Top Level 0*/
    public static User rootUser;
    public static Account rootCustomerAccount;
    
    /*Middle Level 1*/
    public static User vbAuser;
    public static Account vbAcustomerAccount;
    public static User vbBuser;
    public static Account vbBcustomerAccount;
    
    /*Middle Level 2*/
    public static User vbAXuser;
    public static Account vbAXcustomerAccount;
    public static User vbAYuser;
    public static Account vbAYcustomerAccount;
    public static User vbBXuser;
    public static Account vbBXcustomerAccount;
    public static User vbBYuser;
    public static Account vbBYcustomerAccount;
    
    /*Lowest Level 3*/
    public static User vbAX1user;
    public static Account vbAX1customerAccount;
    public static User vbAX2user;
    public static Account vbAX2customerAccount;
    public static User vbAY1user;
    public static Account vbAY1customerAccount;
    public static User vbAY2user;
    public static Account vbAY2customerAccount;
    public static User vbBX1user;
    public static Account vbBX1customerAccount;
    public static User vbBX2user;
    public static Account vbBX2customerAccount;
    public static User vbBY1user;
    public static Account vbBY1customerAccount;
    public static User vbBY2user;
    public static Account vbBY2customerAccount;

    /* Assistant Users */
    public static User ass1toAX1; 
    public static User ass2toAX;
    public static User ass3toAY1;
    
    /* Multi Ownership Accounts - owned by AX1 and AY1 */
    public static Account multi1CustomerAccount; 
    public static Account multi2CustomerAccount; //Hidden for Assistants/Deputies
    public static Account multi3CustomerAccount; //Hidden for Hierarchy
    public static Account multi4CustomerAccount; //Hidden for Hierarchy & Assistants/Deputies

    /* Additional, deputy-only Users */
    public static User deputyXtoAx1;
    public static User deputyYtoAy1;
    
    /*
    --== VB Test Structure ==--
        This is a VB hierarchy with 15 users

        |User| (Number of subordinates)

        |Root| (16)
        |
        \-- |Deputy X| (0)  (<- defined as deputy to AX1)
        \-- |Deputy Y| (0)  (<- defined as deputy to AY1)
        |
        \-- |VB A| (6)
        |     |
        |      \-- |VB AX| (2)    (<- "assistant2ToAX" defined as assistant)
        |       |   \---- VB AX1  (<- "assistant1ToAX1" defined as assistant)
        |       |   \---- VB AX2
        |       |
        |       \-- |VB AY| (2)
        |            \---- VB AY1  (<- "assistant3ToAY1" defined as assistant)
        |            \---- VB AY2
        |
        \-- |VB B| (6)
                |
                \-- |VB BX| (2) (<- defined as deputy to AX)
                |    \---- VB BX1
                |    \---- VB BX2
                |
                \-- |VB BY| (2) (<- defined as deputy to BX)
                    \---- VB BY1
                    \---- VB BY2

    --== Deputies ==--
    Deputies are VB Users with an additional role, defined as relation
        - VB BX is deputy to VB AX
        - VB BY is deputy to VB BX

    --== Assistants ==--
        Assistants are extra Users that done´t have own customers. They are defined as assistants by a relation
        - Assistant 1: Assistant to VB AX1
        - Assistant 2: Assistant to VB AX
        - Assistant 3: Assistant to VB AY1

    --== Customers ==--
        Each VB has 1 dedicated customer Account 
        Additionally, there are 3 Multi-Ownership customers

        - Multi1
            - Owned by AX1 (RecordOwner) and AY1
            - not hidden
        - Multi2
            - Owned by AX1 and AY1 (RecordOwner) 
            - Hidden for Assistants/Deputies
        - Multi3
            - Owned by AX1 (RecordOwner) and AY1
            - Hidden for Hierarchy
        - Multi4
            - Owned by AY1 and AY1 (RecordOwner)
            - Hidden for Hierarchy
            - Hidden for Assistants/Deputies
    

**********************************************/
            
    /******** Create VB strucutre including Assistants and deputies *************/
    public static void createTestVbAssistantDeputyStructure() {
        System.debug(
            '====== SOQL Limit START createTestVbAssistantDeputyStrucutre: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );

        List<ExperienceCloudUserDetails> userList = createVBdata();
        userList.addAll(createAssistantDeputyData());
        createExperienceCloudUsers(userList);
        
        List<User> createdUsers = [SELECT
                                    ID,
                                    username,
                                    FirstName,
                                    LastName,
                                    ExtFinancialAdvisorId__c,
                                    AccountID,
                                    ContactID,
                                    Contact.ReportsToID
                                    FROM User
                                    ];

        Map<String, User> createdUserMap = new Map<String, User>();
        for (User loopUser : createdUsers) {
        createdUserMap.put(loopUser.ExtFinancialAdvisorId__c, loopUser);
        }

        //Assign the created users
        rootUser = createdUserMap.get('root');
        vbAuser = createdUserMap.get('a');
        vbBuser = createdUserMap.get('b');
        vbAXuser = createduserMap.get('ax');
        vbAYuser = createduserMap.get('ay');
        vbBXuser = createduserMap.get('bx');
        vbBYuser = createduserMap.get('by');
        vbAX1user = createduserMap.get('ax1');
        vbAX2user = createduserMap.get('ax2');
        vbAY1user = createduserMap.get('ay1');
        vbAY2user = createduserMap.get('ay2');
        vbBX1user = createduserMap.get('bx1');
        vbBX2user = createduserMap.get('bx2');
        vbBY1user = createduserMap.get('by1');
        vbBY2user = createduserMap.get('by2');
        ass1toAX1 = createdUserMap.get('ass1');
        ass2toAX = createduserMap.get('ass2');
        ass3toAY1 = createduserMap.get('ass3');
        deputyXtoAx1 = createduserMap.get('depX');
        deputyYtoAy1 = createduserMap.get('depY');
    
        /*Create customers for users*/
        List<Account> customers = new List<Account>();        
        customers.add(createCustomerAccount(rootUser));        
        customers.add(createCustomerAccount(vbAuser));            
        customers.add(createCustomerAccount(vbBuser));
        customers.add(createCustomerAccount(vbAXuser));
        customers.add(createCustomerAccount(vbAYuser));            
        customers.add(createCustomerAccount(vbBXuser));            
        customers.add(createCustomerAccount(vbBYuser));
        customers.add(createCustomerAccount(vbAX1user));            
        customers.add(createCustomerAccount(vbAX2user));
        customers.add(createCustomerAccount(vbAY1user));            
        customers.add(createCustomerAccount(vbAY2user));
        customers.add(createCustomerAccount(vbBX1user));
        customers.add(createCustomerAccount(vbBX2user));
        customers.add(createCustomerAccount(vbBY1user));
        customers.add(createCustomerAccount(vbBY2user));
        

        //Multi Ownership Accounts
        //Multi1        
        //  - not hidden        
        multi1CustomerAccount = createCustomerAccount(vbAX1user,'MultiAcc1');
        multi1CustomerAccount.MultipleOwners__c = true;
        customers.add(multi1CustomerAccount);
        //Multi2
        //  - Hidden for Assistants/Deputies        
        multi2CustomerAccount = createCustomerAccount(vbAY1user,'MultiAcc2');
        multi2CustomerAccount.MultipleOwners__c = true;
        multi2CustomerAccount.HideForAssistantsAndDeputies__c = true;
        customers.add(multi2CustomerAccount);
        // Multi3
        //  - Hidden for Hierarchy
        multi3CustomerAccount = createCustomerAccount(vbAX1user,'MultiAcc3');
        multi3CustomerAccount.MultipleOwners__c = true;
        multi3CustomerAccount.HideForHierarchy__c = true;
        customers.add(multi3CustomerAccount);
        // Multi4
        //  Hidden for Assistants/Deputies & Hierarchy        
        multi4CustomerAccount = createCustomerAccount(vbAY1user,'MultiAcc4');
        multi4CustomerAccount.MultipleOwners__c = true;
        multi4CustomerAccount.HideForHierarchy__c = true;
        multi4CustomerAccount.HideForAssistantsAndDeputies__c = true;
        customers.add(multi4CustomerAccount);        
        insert customers;
        
        // Acc Accounts hidden by AX1 and AY1
        List<AdvisorToCustomer__c> adv2Cust = new List<AdvisorToCustomer__c>();
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi1CustomerAccount,vbAX1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi1CustomerAccount,vbAY1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi2CustomerAccount,vbAX1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi2CustomerAccount,vbAY1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi3CustomerAccount,vbAX1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi3CustomerAccount,vbAY1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi4CustomerAccount,vbAX1user));
        adv2Cust.add(SharingUtil.createAdvisorToCustomer(multi4CustomerAccount,vbAY1user));        
        insert adv2Cust;
    
        /* Create Assistant Relations */ 
        List<AssistantToAdvisor__c> assistants = new List<AssistantToAdvisor__c>();
        assistants.add(SharingUtil.createAssistantToAdvisor(vbAX1user,ass1toAX1));
        assistants.add(SharingUtil.createAssistantToAdvisor(vbAXuser,ass2toAX));
        assistants.add(SharingUtil.createAssistantToAdvisor(vbAY1user,ass3toAY1));
        insert assistants;
    
        /* Create Deputy Relations */
        List<DeputyToAdvisor__c> deputies = new List<DeputyToAdvisor__c>();
        deputies.add(SharingUtil.createDeputyToAdvisor(vbAXuser,vbBXuser));
        deputies.add(SharingUtil.createDeputyToAdvisor(vbBXUser,vbBYuser));
        deputies.add(SharingUtil.createDeputyToAdvisor(vbAX1user,deputyXtoAx1));
        deputies.add(SharingUtil.createDeputyToAdvisor(vbAY1User,deputyYtoAy1));
        insert deputies;

        Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
        
        System.debug(
        '====== SOQL Limit END createTestVbAssistantDeputyStrucutre: ' +
        Limits.getQueries() +
        ' of ' +
        Limits.getLimitQueries() +
        ' used'
        );
    }


    /******** Create VB strucutre without Assistants and deputies (legacy) *************/
    public static void createTestVbStructure() {
        System.debug(
            '====== SOQL Limit START createTestVbStructure: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );

        createExperienceCloudUsers(createVBdata());    

        List<User> createdUsers = [SELECT
                                    ID,
                                    username,
                                    FirstName,
                                    LastName,
                                    ExtFinancialAdvisorId__c,
                                    AccountID,
                                    ContactID,
                                    Contact.ReportsToID
                                    FROM User
                                    ];
        
                                    Map<String, User> createdUserMap = new Map<String, User>();
        for (User loopUser : createdUsers) {
            createdUserMap.put(loopUser.ExtFinancialAdvisorId__c, loopUser);
        }

        //Assign the created users
        rootUser = createdUserMap.get('root');
        vbAuser = createdUserMap.get('a');
        vbBuser = createdUserMap.get('b');
        vbAXuser = createduserMap.get('ax');
        vbAYuser = createduserMap.get('ay');
        vbBXuser = createduserMap.get('bx');
        vbBYuser = createduserMap.get('by');
        vbAX1user = createduserMap.get('ax1');
        vbAX2user = createduserMap.get('ax2');
        vbAY1user = createduserMap.get('ay1');
        vbAY2user = createduserMap.get('ay2');
        vbBX1user = createduserMap.get('bx1');
        vbBX2user = createduserMap.get('bx2');
        vbBY1user = createduserMap.get('by1');
        vbBY2user = createduserMap.get('by2');

        /*Create customers for users*/
        List<Account> customers = new List<Account>();        
        customers.add(createCustomerAccount(rootUser));        
        customers.add(createCustomerAccount(vbAuser));            
        customers.add(createCustomerAccount(vbBuser));
        customers.add(createCustomerAccount(vbAXuser));
        customers.add(createCustomerAccount(vbAYuser));            
        customers.add(createCustomerAccount(vbBXuser));            
        customers.add(createCustomerAccount(vbBYuser));
        customers.add(createCustomerAccount(vbAX1user));            
        customers.add(createCustomerAccount(vbAX2user));
        customers.add(createCustomerAccount(vbAY1user));            
        customers.add(createCustomerAccount(vbAY2user));
        customers.add(createCustomerAccount(vbBX1user));
        customers.add(createCustomerAccount(vbBX2user));
        customers.add(createCustomerAccount(vbBY1user));
        customers.add(createCustomerAccount(vbBY2user));
        insert customers;

        Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());

        System.debug(
        '====== SOQL Limit END createTestVbStructure: ' +
        Limits.getQueries() +
        ' of ' +
        Limits.getLimitQueries() +
        ' used'
        );
    }
    
    /******** Helper function creating the Experience Cloud Users *************/
    private static List<ExperienceCloudUserDetails> createVBdata() {
        /*Create Partner Accounts*/
        directoratePartnerAccount = new Account(
            name = 'Root PartnerAccount',
            RecordTypeId = directorateAccountRecordType
        );
        insert directoratePartnerAccount;
        
        assistantPartnerAccount = new Account(
            name = 'Sammelaccount Assistenten',
            RecordTypeId = directorateAccountRecordType,
            FinServ__SourceSystemId__c = SharingUtil.ASSITANT_ACCOUNT_IDENTIFIER
        );
        insert assistantPartnerAccount;     
        
        List<ExperienceCloudUserDetails> returnUserList = new List<ExperienceCloudUserDetails>();
        
        //Top - Level 0
        ExperienceCloudUserDetails rootExpUser = new ExperienceCloudUserDetails();
        rootExpUser.firstName = 'Root';
        rootExpUser.lastName = 'Root';
        rootExpUser.userName = 'root@dvag.com.tst';
        rootExpUser.accountId = directoratePartnerAccount.Id;
        rootExpUser.reportsToUsername = null;
        rootExpUser.advisorNumber = 'root';
        returnUserList.add(rootExpUser);
        
        //Level 1
        ExperienceCloudUserDetails vbA_ExpUser = new ExperienceCloudUserDetails();
        vbA_ExpUser.firstName = 'VB';
        vbA_ExpUser.lastName = 'A';
        vbA_ExpUser.userName = 'vb.a@dvag.com.tst';
        vbA_ExpUser.accountId = directoratePartnerAccount.Id;
        vbA_ExpUser.reportsToUsername = 'root@dvag.com.tst';
        vbA_ExpUser.advisorNumber = 'a';
        returnUserList.add(vbA_ExpUser);
        
        ExperienceCloudUserDetails vbB_ExpUser = new ExperienceCloudUserDetails();
        vbB_ExpUser.firstName = 'VB';
        vbB_ExpUser.lastName = 'B';
        vbB_ExpUser.userName = 'vb.b@dvag.com.tst';
        vbB_ExpUser.accountId = directoratePartnerAccount.Id;
        vbB_ExpUser.reportsToUsername = 'root@dvag.com.tst';
        vbB_ExpUser.advisorNumber = 'b';
        returnUserList.add(vbB_ExpUser);
        
        //Level 2
        ExperienceCloudUserDetails vbAX_ExpUser = new ExperienceCloudUserDetails();
        vbAX_ExpUser.firstName = 'VB';
        vbAX_ExpUser.lastName = 'AX';
        vbAX_ExpUser.userName = 'vb.ax@dvag.com.tst';
        vbAX_ExpUser.accountId = directoratePartnerAccount.Id;
        vbAX_ExpUser.reportsToUsername = 'vb.a@dvag.com.tst';
        vbAX_ExpUser.advisorNumber = 'ax';
        returnUserList.add(vbAX_ExpUser);
        
        ExperienceCloudUserDetails vbAY_ExpUser = new ExperienceCloudUserDetails();
        vbAY_ExpUser.firstName = 'VB';
        vbAY_ExpUser.lastName = 'AY';
        vbAY_ExpUser.userName = 'vb.ay@dvag.com.tst';
        vbAY_ExpUser.accountId = directoratePartnerAccount.Id;
        vbAY_ExpUser.reportsToUsername = 'vb.a@dvag.com.tst';
        vbAY_ExpUser.advisorNumber = 'ay';
        returnUserList.add(vbAY_ExpUser);
        
        ExperienceCloudUserDetails vbBX_ExpUser = new ExperienceCloudUserDetails();
        vbBX_ExpUser.firstName = 'VB';
        vbBX_ExpUser.lastName = 'BX';
        vbBX_ExpUser.userName = 'vb.bx@dvag.com.tst';
        vbBX_ExpUser.accountId = directoratePartnerAccount.Id;
        vbBX_ExpUser.reportsToUsername = 'vb.b@dvag.com.tst';
        vbBX_ExpUser.advisorNumber = 'bx';
        returnUserList.add(vbBX_ExpUser);
        
        ExperienceCloudUserDetails vbBY_ExpUser = new ExperienceCloudUserDetails();
        vbBY_ExpUser.firstName = 'VB';
        vbBY_ExpUser.lastName = 'BY';
        vbBY_ExpUser.userName = 'vb.by@dvag.com.tst';
        vbBY_ExpUser.accountId = directoratePartnerAccount.Id;
        vbBY_ExpUser.reportsToUsername = 'vb.b@dvag.com.tst';
        vbBY_ExpUser.advisorNumber = 'by';
        returnUserList.add(vbBY_ExpUser);
        
        //Level 3
        ExperienceCloudUserDetails vbAX1_ExpUser = new ExperienceCloudUserDetails();
        vbAX1_ExpUser.firstName = 'VB';
        vbAX1_ExpUser.lastName = 'AX1';
        vbAX1_ExpUser.userName = 'vb.ax1@dvag.com.tst';
        vbAX1_ExpUser.accountId = directoratePartnerAccount.Id;
        vbAX1_ExpUser.reportsToUsername = 'vb.ax@dvag.com.tst';
        vbAX1_ExpUser.advisorNumber = 'ax1';
        returnUserList.add(vbAX1_ExpUser);
        
        ExperienceCloudUserDetails vbAX2_ExpUser = new ExperienceCloudUserDetails();
        vbAX2_ExpUser.firstName = 'VB';
        vbAX2_ExpUser.lastName = 'AX2';
        vbAX2_ExpUser.userName = 'vb.ax2@dvag.com.tst';
        vbAX2_ExpUser.accountId = directoratePartnerAccount.Id;
        vbAX2_ExpUser.reportsToUsername = 'vb.ax@dvag.com.tst';
        vbAX2_ExpUser.advisorNumber = 'ax2';
        returnUserList.add(vbAX2_ExpUser);
        
        ExperienceCloudUserDetails vbAY1_ExpUser = new ExperienceCloudUserDetails();
        vbAY1_ExpUser.firstName = 'VB';
        vbAY1_ExpUser.lastName = 'AY1';
        vbAY1_ExpUser.userName = 'vb.ay1@dvag.com.tst';
        vbAY1_ExpUser.accountId = directoratePartnerAccount.Id;
        vbAY1_ExpUser.reportsToUsername = 'vb.ay@dvag.com.tst';
        vbAY1_ExpUser.advisorNumber = 'ay1';
        returnUserList.add(vbAY1_ExpUser);
        
        ExperienceCloudUserDetails vbAY2_ExpUser = new ExperienceCloudUserDetails();
        vbAY2_ExpUser.firstName = 'VB';
        vbAY2_ExpUser.lastName = 'AY2';
        vbAY2_ExpUser.userName = 'vb.ay2@dvag.com.tst';
        vbAY2_ExpUser.accountId = directoratePartnerAccount.Id;
        vbAY2_ExpUser.reportsToUsername = 'vb.ay@dvag.com.tst';
        vbAY2_ExpUser.advisorNumber = 'ay2';
        returnUserList.add(vbAY2_ExpUser);
        
        ExperienceCloudUserDetails vbBX1_ExpUser = new ExperienceCloudUserDetails();
        vbBX1_ExpUser.firstName = 'VB';
        vbBX1_ExpUser.lastName = 'BX1';
        vbBX1_ExpUser.userName = 'vb.bx1@dvag.com.tst';
        vbBX1_ExpUser.accountId = directoratePartnerAccount.Id;
        vbBX1_ExpUser.reportsToUsername = 'vb.bx@dvag.com.tst';
        vbBX1_ExpUser.advisorNumber = 'bx1';
        returnUserList.add(vbBX1_ExpUser);
        
        ExperienceCloudUserDetails vbBX2_ExpUser = new ExperienceCloudUserDetails();
        vbBX2_ExpUser.firstName = 'VB';
        vbBX2_ExpUser.lastName = 'BX2';
        vbBX2_ExpUser.userName = 'vb.bx2@dvag.com.tst';
        vbBX2_ExpUser.accountId = directoratePartnerAccount.Id;
        vbBX2_ExpUser.reportsToUsername = 'vb.bx@dvag.com.tst';
        vbBX2_ExpUser.advisorNumber = 'bx2';
        returnUserList.add(vbBX2_ExpUser);
        
        ExperienceCloudUserDetails vbBY1_ExpUser = new ExperienceCloudUserDetails();
        vbBY1_ExpUser.firstName = 'VB';
        vbBY1_ExpUser.lastName = 'BY1';
        vbBY1_ExpUser.userName = 'vb.by1@dvag.com.tst';
        vbBY1_ExpUser.accountId = directoratePartnerAccount.Id;
        vbBY1_ExpUser.reportsToUsername = 'vb.by@dvag.com.tst';
        vbBY1_ExpUser.advisorNumber = 'by1';
        returnUserList.add(vbBY1_ExpUser);
        
        ExperienceCloudUserDetails vbBY2_ExpUser = new ExperienceCloudUserDetails();
        vbBY2_ExpUser.firstName = 'VB';
        vbBY2_ExpUser.lastName = 'BY2';
        vbBY2_ExpUser.userName = 'vb.by2@dvag.com.tst';
        vbBY2_ExpUser.accountId = directoratePartnerAccount.Id;
        vbBY2_ExpUser.reportsToUsername = 'vb.by@dvag.com.tst';
        vbBY2_ExpUser.advisorNumber = 'by2';
        returnUserList.add(vbBY2_ExpUser);
        return returnUserList;
    }
    
    private static List<ExperienceCloudUserDetails> createAssistantDeputyData() {
        
        List<ExperienceCloudUserDetails> userReturnList = new List<ExperienceCloudUserDetails>();

        ExperienceCloudUserDetails assistant1_ExpUser = new ExperienceCloudUserDetails();
        assistant1_ExpUser.firstName = 'Assistant';
        assistant1_ExpUser.lastName = 'Assist1';
        assistant1_ExpUser.userName = 'assistant.one@dvag.com.tst';
        assistant1_ExpUser.accountId = assistantPartnerAccount.Id;
        assistant1_ExpUser.advisorNumber = 'ass1';
        userReturnList.add(assistant1_ExpUser);

        ExperienceCloudUserDetails assistant2_ExpUser = new ExperienceCloudUserDetails();
        assistant2_ExpUser.firstName = 'Assistant';
        assistant2_ExpUser.lastName = 'Assist2';
        assistant2_ExpUser.userName = 'assistant.two@dvag.com.tst';
        assistant2_ExpUser.accountId = assistantPartnerAccount.Id;
        assistant2_ExpUser.advisorNumber = 'ass2';
        userReturnList.add(assistant2_ExpUser);   
        
        ExperienceCloudUserDetails assistant3_ExpUser = new ExperienceCloudUserDetails();
        assistant3_ExpUser.firstName = 'Assistant';
        assistant3_ExpUser.lastName = 'Assist3';
        assistant3_ExpUser.userName = 'assistant.three@dvag.com.tst';
        assistant3_ExpUser.accountId = assistantPartnerAccount.Id;
        assistant3_ExpUser.advisorNumber = 'ass3';
        userReturnList.add(assistant3_ExpUser);   

        ExperienceCloudUserDetails deputyX_ExpUser = new ExperienceCloudUserDetails();
        deputyX_ExpUser.firstName = 'DeputyX';
        deputyX_ExpUser.lastName = 'To AX1';
        deputyX_ExpUser.userName = 'deputy.X@dvag.com.tst';
        deputyX_ExpUser.accountId = assistantPartnerAccount.Id;
        deputyX_ExpUser.advisorNumber = 'depX';
        userReturnList.add(deputyX_ExpUser);

        ExperienceCloudUserDetails deputyY_ExpUser = new ExperienceCloudUserDetails();
        deputyY_ExpUser.firstName = 'DeputyY';
        deputyY_ExpUser.lastName = 'To AY1';
        deputyY_ExpUser.userName = 'deputy.Y@dvag.com.tst';
        deputyY_ExpUser.accountId = assistantPartnerAccount.Id;
        deputyY_ExpUser.advisorNumber = 'depY';
        userReturnList.add(deputyY_ExpUser);   

        return userReturnList;
    }

    
    /*Populate the class static variables for easy access*/
    public static void populateVbStructure(){
        System.debug(
            '====== SOQL Limit START  populateVBUsers, SOQL Limit: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );
        
        List<User> userList = [SELECT
                                ID,
                                username,
                                FirstName,
                                LastName,
                                ExtFinancialAdvisorId__c,
                                AccountID,
                                ContactId,
                                Contact.ExtFinancialAdvisorId__c,
                                Contact.ReportsToID
                                FROM User];
        
        Map<String, User> userMap = new Map<String, User>();
        for (User loopUser : userList) {
            userMap.put(loopUser.ExtFinancialAdvisorId__c, loopUser);
        }
        
        List<Account> accountList = [SELECT id,
                                            FirstName,
                                            LastName,                                            
                                            RecordTypeId,
                                            OwnerId,
                                            Owner.ExtFinancialAdvisorId__c,
                                            Owner.FirstName,
                                            Owner.LastName,
                                            PersonContactId,
                                            ExtCustomerNumber__c,
                                            ExtCustomerIdOki__c,
                                            ExtCustomerIdHost__c,
                                            HideForHierarchy__c,
                                            HideForAssistantsAndDeputies__c,
                                            MultipleOwners__c
                                            FROM Account
                                            WHERE RecordTypeId = :personAccountRecordType];
        
        Map<ID, Account> accByOwner = new Map<ID, Account>();
        Map<String, Account> multiAccByOwner = new Map<String, Account>();
        
        for (Account loopAccount : accountList) {
            if (loopAccount.MultipleOwners__c) {
                multiAccByOwner.put(loopAccount.ExtCustomerNumber__c, loopAccount);
            } else {
                accByOwner.put(loopAccount.OwnerId, loopAccount);
            }
        }
        
        //Assign the created users
        rootUser = userMap.get('root');
        rootCustomerAccount = accByOwner.get(rootUser.Id);
        
        vbAuser = userMap.get('a');
        vbAcustomerAccount = accByOwner.get(vbAuser.Id);
        
        vbBuser = userMap.get('b');
        vbBcustomerAccount = accByOwner.get(vbBuser.Id);
        
        vbAXuser = userMap.get('ax');
        vbAXcustomerAccount = accByOwner.get(vbAXuser.Id);
        
        vbAYuser = userMap.get('ay');
        vbAYcustomerAccount = accByOwner.get(vbAYuser.Id);
        
        vbBXuser = userMap.get('bx');
        vbBXcustomerAccount = accByOwner.get(vbBXuser.Id);
        
        vbBYuser = userMap.get('by');
        vbBYcustomerAccount = accByOwner.get(vbBYuser.Id);
        
        vbAX1user = userMap.get('ax1');
        vbAX1customerAccount = accByOwner.get(vbAX1user.Id);
        
        vbAX2user = userMap.get('ax2');
        vbAX2customerAccount = accByOwner.get(vbAX2user.Id);
        
        vbAY1user = userMap.get('ay1');
        vbAY1customerAccount = accByOwner.get(vbAY1user.Id);
        
        vbAY2user = userMap.get('ay2');
        vbAY2customerAccount = accByOwner.get(vbAY2user.Id);
        
        vbBX1user = userMap.get('bx1');
        vbBX1customerAccount = accByOwner.get(vbBX1user.Id);
        
        vbBX2user = userMap.get('bx2');
        vbBX2customerAccount = accByOwner.get(vbBX2user.Id);
        
        vbBY1user = userMap.get('by1');
        vbBY1customerAccount = accByOwner.get(vbBY1user.Id);
        
        vbBY2user = userMap.get('by2');
        vbBY2customerAccount = accByOwner.get(vbBY2user.Id);
        
        multi1CustomerAccount = multiAccByOwner.get('MultiAcc1');
        multi2CustomerAccount = multiAccByOwner.get('MultiAcc2');
        multi3CustomerAccount = multiAccByOwner.get('MultiAcc3');
        multi4CustomerAccount = multiAccByOwner.get('MultiAcc4');

        ass1toAX1 = userMap.get('ass1');
        ass2toAX = userMap.get('ass2');
        ass3toAY1 = userMap.get('ass3');
        
        deputyXtoAx1 = userMap.get('depX');
        deputyYtoAy1 = userMap.get('depY');
        
        directoratePartnerAccount = [
            SELECT name, OwnerId
            FROM account
            WHERE name = 'Root PartnerAccount'
        ];

        assistantPartnerAccount = SharingUtil.getAssistantDirectorateAccount();
        
        System.debug(
            '====== SOQL Limit END populateVBUsers, SOQL Limit: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );
    }
    
    /* Utility - Check if a given user has access to an Account */
    public static Boolean accountVisibleForUser(Account checkAccount, User checkUser) {
        Boolean retVal;
        System.runAs(checkUser) {
            List<Account> resultList = [
                SELECT Id, name
                FROM account
                WHERE ID = :checkAccount.id
            ];
            retVal = resultList.size() > 0;
        }
        return retVal;
    }
    
    /* Utility - Check if a given user has access to a List of accounts */
    public static Boolean accountsVisibleForUser(List<Account> checkAccountList, User checkUser) {
        Boolean retVal;
        System.runAs(checkUser) {
            List<Account> resultList = [
                SELECT Id, name
                FROM account
                WHERE ID = :checkAccountList
            ];
            retVal = (resultList.size() == checkAccountList.size());
        }
        return retVal;
    }

    /* Utility - Return a list of customers (Person Accounts) visible for a given user */
    public static List<Account> customerAccountsVisibleForUser(User checkUser) {        
        List<Account> retList;
        System.runAs(checkUser) {
            retList = [SELECT Id, name, FirstName, LastName, OwnerId, 
                              ExtCustomerNumber__c, ExtCustomerIdHost__c, ExtCustomerIdOki__c,
                              HideForAssistantsAndDeputies__c, HideForHierarchy__c, MultipleOwners__c
                        FROM account
                WHERE RecordTypeId = :personAccountRecordType
            ];
        }
        return retList;
    }
    
    /* Utility - Check if a given user does NOT have access to ANY Account in the list */
    public static Boolean accountsNotVisibleForUser(List<Account> checkAccountList, User checkUser) {
        List<Account> resultList;
        System.runAs(checkUser) {
            resultList = [SELECT Id, name FROM account WHERE ID IN :checkAccountList];
        }
        if (resultList.size() == 0) {
            return true;
        } else {
            System.debug(
                resultlist.size() +
                'accounts visible for User ' +
                checkUser.username
            );
            System.debug(resultList);
            return false;
        }
    }
    
    /* Utility - Create a single Community User & Contact */
    public static User createFieldSalesContactUser(String inputFirstName, String inputLastName, String inputUserName, String advisorNumber, ID partnerAccountID, ID reportsToContactId) {
        System.debug(
            '====== SOQL Limit Start createFieldSalesContactUser: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );
        
        Contact objContact = new Contact(
            FirstName = inputFirstName,
            LastName = inputLastName,
            AccountId = partnerAccountID,
            email = inputUserName,
            ExtFinancialAdvisorId__c = advisorNumber,
            ReportsToId = reportsToContactId
        );    
        insert objContact;
        
        User newUser = new User(
            alias = inputUserName.abbreviate(6),
            email = inputUserName,
            emailencodingkey = 'UTF-8',
            firstname = inputFirstName,
            lastname = inputLastName,
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            ProfileId = fieldSalesUserProfileId,
            country = 'Germany',
            IsActive = true,
            ContactId = objContact.Id,
            timezonesidkey = 'Europe/Berlin',
            username = inputUserName,
            ExtFinancialAdvisorId__c = advisorNumber,
            FederationIdentifier = advisorNumber
        );
        system.System.debug(
            'Created Contact <' +
            objContact.id +
            '> ' +
            objContact.FirstName +
            ' ' +
            objContact.LastName +
            ', ReportsTo <' +
            objContact.ReportsToId +
            '>'
        );
        insert newUser;
        system.System.debug('User <' + newUser.Id + '> ' + newUser.Username);
        System.debug(
            '====== SOQL Limit END createFieldSalesContactUser: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );
        return newUser;
    }
    
    /* Utility - Create Community Users & Contacts with hierarchy from input List*/
    public static void createExperienceCloudUsers(List<ExperienceCloudUserDetails> inputDetails) {
        System.debug(
            '====== SOQL Limit Start createExperienceCloudUsers: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );
        
        //First insert the contacts without reportsTo, as we do not know the id of the contacts yet
        List<Contact> newContactList = new List<Contact>();
        for (ExperienceCloudUserDetails loopDetail : inputDetails) {
            newContactList.add(
                new Contact(
                    FirstName = loopDetail.firstName,
                    LastName = loopDetail.lastName,
                    AccountId = loopDetail.accountID,
                    ExtFinancialAdvisorId__c = loopDetail.advisorNumber,
                    email = loopDetail.userName
                )
            );
        }
        insert newContactList;
        
        //Get the created contacts and put them in a map
        newContactList = [
            SELECT ID, FirstName, LastName, Email, ReportsToId, ExtFinancialAdvisorId__c
            FROM Contact
        ];
        Map<String, Contact> contactMap = new Map<String, Contact>();
        for (Contact loopContact : newContactList) {
            contactMap.put(loopContact.email, loopContact);
        }
        
        List<User> newUserList = new List<User>();
        for (ExperienceCloudUserDetails loopDetail : inputDetails) {
            //create the user
            User loopUser = new User(
                alias = loopDetail.userName.abbreviate(6),
                email = loopDetail.userName,
                emailencodingkey = 'UTF-8',
                firstname = loopDetail.firstName,
                lastname = loopDetail.lastName,
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                ProfileId = fieldSalesUserProfileId,
                country = 'Germany',
                IsActive = true,
                ContactId = contactMap.get(loopDetail.userName.toLowerCase()).Id,
                timezonesidkey = 'Europe/Berlin',
                username = loopDetail.userName,
                FederationIdentifier = loopDetail.advisorNumber,
                ExtFinancialAdvisorId__c = loopDetail.advisorNumber
            );
            newUserList.add(loopUser);
        }
        insert newUserList;
        
        //Update the ReportsTo ID
        List<Contact> updateContactList = new List<Contact>();
        for (ExperienceCloudUserDetails loopDetail : inputDetails) {
            Contact loopContact = contactMap.get(loopDetail.userName.toLowerCase()); //get a contact from the map
            if (null != loopDetail.reportsToUsername) {
                loopContact.ReportsToId = contactMap.get(
                    loopDetail.reportsToUsername.toLowerCase()
                )
                    .Id; //get the reportsTo ID
                updateContactList.add(loopContact);
            }
        }
        update updateContactList;
        System.debug(
            '====== SOQL Limit END createExperienceCloudUsers: ' +
            Limits.getQueries() +
            ' of ' +
            Limits.getLimitQueries() +
            ' used'
        );
    }

    public static List<SharingGroup__mdt> getAllSharingGroupTypesTest(){
        List<SharingGroup__mdt> testGroups = new List<SharingGroup__mdt>();
        testGroups.add(new SharingGroup__mdt(DeveloperName = 'Manager', Prefix__c = 'M_'));
        testGroups.add(new SharingGroup__mdt(DeveloperName = 'Assistants', Prefix__c = 'A_'));
        testGroups.add(new SharingGroup__mdt(DeveloperName = 'Deputies', Prefix__c = 'D_'));
        return testGroups;
    }
    

    /*Show the groups an account is shared with*/
    public static void printAccountGroupSharesWithMembers(Set<ID> accIds) {        
        
        List<AccountShare> accShares = [SELECT id, AccountId, Account.Name, UserOrGroupId, RowCause FROM AccountShare WHERE AccountId in :accIds AND RowCause = 'Manual' order by AccountId];
        Set<Id> sharedWithIds = new Set<id>();
        for (AccountShare accShare : accShares) {
            sharedWithIds.add(accShare.UserOrGroupId);
        }
                
        Map<Id, User> userMap = new Map<Id,User>([SELECT Id, name, username, ExtFinancialAdvisorId__c FROM User WHERE ProfileId = :fieldSalesUserProfileId]);        
        //get all groups directly shared
        Map<Id, Group> groupMap = new Map<Id,Group>([SELECT Id, name, DeveloperName, Type FROM Group WHERE Type = 'Regular' AND Id in :sharedWithIds]); 
        //get their members
        List<GroupMember> groupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :groupMap.keySet()];
        //add all members that are groups themselves
        Set<Id> memberGroupIds = new Set<Id>();
        for (GroupMember mbr : groupMembers) {
            if (null == userMap.get(mbr.UserOrGroupId)) {
                memberGroupIds.add(mbr.UserOrGroupId);
            }
        }
        //get these groups as well
        Map<Id, Group> memberGroupMap = new Map<Id,Group>([SELECT Id, name, DeveloperName, Type FROM Group WHERE Type = 'Regular' AND Id in :memberGroupIds]); 
        //And now get the members for those and add the the overall member list
        groupMembers.addAll([SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :memberGroupMap.keySet()]);        
        
        Map<Id, List<GroupMember>> grpMbrsByGrpId  = new Map<Id, List<GroupMember>>();        
        for (GroupMember mbr : groupMembers) {
            if (null == grpMbrsByGrpId.get(mbr.GroupId)) {
                grpMbrsByGrpId.put(mbr.GroupId, new List<GroupMember>{mbr});
            } else {
                grpMbrsByGrpId.get(mbr.GroupId).add(mbr);
            }
        }
        
        System.debug('------ Accounts currently shared with groups ------');
        Map<Id, List<AccountShare>> accSharesByAccId = new Map<Id, List<AccountShare>>();
        for (AccountShare loopShare : accShares) {
            if (null == accSharesByAccId.get(loopShare.AccountId)) {
                accSharesByAccId.put(loopShare.AccountId, new List<AccountShare>{loopShare});
            } else {
                accSharesByAccId.get(loopShare.AccountId).add(loopShare);
            }
        }

        for (ID accId : accIds) {            
            
            System.debug('Account <' + accSharesByAccId.get(accId).get(0).Account.Name + '> shared with');
            for (AccountShare accShare : accSharesByAccId.get(accId)) {
                Boolean isGroup = false;
                if (null != userMap.get(accShare.UserOrGroupId)) {
                    System.debug('--> User <'+ userMap.get(accShare.UserOrGroupId).Name + '>');
                } else if (null != groupMap.get(accShare.UserOrGroupId)) {
                    System.debug('-- Group <'+ groupMap.get(accShare.UserOrGroupId).DeveloperName + '>');
                    isGroup = true;
                } else {
                    System.debug('-- Unknown <' + accShare.UserOrGroupId + '>');
                }

                if (isGroup) {
                    System.debug('-- --Members-- ');
                    if (null == grpMbrsByGrpId.get(accShare.UserOrGroupId)) {
                        System.debug('Warning: No group Members to  ' + accShare.UserOrGroupId);
                        continue;
                    }
                    for (GroupMember loopMember : grpMbrsByGrpId.get(accShare.UserOrGroupId)) {
                        if (null != userMap.get(loopMember.UserOrGroupId)) {
                            System.debug('-- --> User: ' + userMap.get(loopMember.UserOrGroupId).name);
                        } else if (null != memberGroupMap.get(loopMember.UserOrGroupId)) {
                            System.debug('-- -- Group: ' + memberGroupMap.get(loopMember.UserOrGroupId).DeveloperName);
                            if (null == grpMbrsByGrpId.get(loopMember.UserOrGroupId)) {
                                System.debug('-- -- <no members>');
                            } else {
                                for (GroupMember indirectMember : grpMbrsByGrpId.get(loopMember.UserOrGroupId)) {
                                    System.debug('-- -- --> User: ' + userMap.get(indirectMember.UserOrGroupId).Name);
                                }
                            }
                        } else {
                            System.debug('-- -- Unknown <'+ loopMember.UserOrGroupId +'>');
                        }                        
                    }
                }
            }
        }
    }

    public static void printInsurancePolicyGroupSharesWithMembers(List<InsurancePolicy> policyList) {        
        Set<Id> policyIds = new Set<Id>();
        for (InsurancePolicy pol:policyList) {
            policyIds.add(pol.Id);
        }        
        List<InsurancePolicyShare> policyShares = [SELECT id, ParentId, Parent.Name, UserOrGroupId, RowCause FROM InsurancePolicyShare WHERE ParentId in :policyIds ];//AND RowCause = 'Manual'
        Map<Id, Group> groupMap = new Map<Id,Group>([SELECT Id, DeveloperName, Type FROM Group ]); //WHERE Type = 'Regular'
        Map<Id, User> userMap = new Map<Id,User>([SELECT Id, name, username, ExtFinancialAdvisorId__c FROM User WHERE ProfileId = :fieldSalesUserProfileId]);        
        List<GroupMember> groupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :groupMap.keySet()];
        
        System.debug('------ InsurancePolcies currently shared with groups ------');
        for (InsurancePolicyShare policyShare : policyShares) {            
            String grpString = 'InsurancePolicy <' + policyShare.Parent.Name + '> shared with Group ';
            if (null != groupMap.get(policyShare.UserOrGroupId)) {
                grpString += '<'+ groupMap.get(policyShare.UserOrGroupId).DeveloperName + '> Type ' + groupMap.get(policyShare.UserOrGroupId).Type;
            }
            grpString += 'UserOrGroup <' + policyShare.UserOrGroupId + '>';
            grpString += ' RowCause <' + policyShare.RowCause + '>';
            System.debug(grpString);

            //Now print all group members for the group groupMap.get(accShare.UserOrGroupId)
            List<String> memberNames = new List<String>();
            for (GroupMember loopMember : groupMembers) {            
                if (loopMember.GroupId == policyShare.UserOrGroupId) {
                    String memberString;
                    if (null != usermap.get(loopMember.UserOrGroupId)) {
                        memberString = '-> User: ' + usermap.get(loopMember.UserOrGroupId).name;
                    } else if (null != groupMap.get(loopMember.UserOrGroupId)) {
                        memberString = '-> Group: '+ groupMap.get(loopMember.UserOrGroupId).DeveloperName;
                    } else {
                      memberString = '-> Unknown: '+ loopMember.UserOrGroupId;
                    }
                    memberNames.add(memberString);
                }
            }
            if (memberNames.size()>0)
            {
                for (String tmp : memberNames) {
                    System.debug(tmp);
                }
            }  else {
                System.debug('-> No Members');
            }
        }        
    }
    
    public static FinServ__FinancialGoal__c createFinancialGoal(Account ownerAcc) {        
        FinServ__FinancialGoal__c finGoal = new FinServ__FinancialGoal__c();
        finGoal.OwnerId = ownerAcc.OwnerId;
        finGoal.FinServ__PrimaryOwner__c = ownerAcc.Id;
        finGoal.FinServ__SourceSystemId__c = ownerAcc.ExtCustomerNumber__c+'_' + TestDataUtility.getRandomNumber(5);
        finGoal.name = ownerAcc.FirstName + ' ' + ownerAcc.LastName + ' Goal';
        finGoal.Custom_Description__c = 'Others';
        return finGoal;
    }

    /* Get all Financial Goals visible for a User */
    public static Map<Id,FinServ__FinancialGoal__c> financialGoalsVisibleForUser(User checkUser) {        
        Map<Id,FinServ__FinancialGoal__c> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,FinServ__FinancialGoal__c>([SELECT Id,
                                                            FinServ__SourceSystemId__c,
                                                             FinServ__PrimaryOwner__c,
                                                             FinServ__PrimaryOwner__r.FirstName,
                                                             FinServ__PrimaryOwner__r.LastName,
                                                             FinServ__PrimaryOwner__r.ExtCustomerNumber__c 
                                                        FROM FinServ__FinancialGoal__c]);
        }
        return resultMap;
    }

    public static Account createCustomerAccount(User accountOwner) {        
        String rnd = TestDataUtility.getRandomNumber(4);
        Account newAcc = new Account();
        newAcc.RecordTypeId =  personAccountRecordType;
        newAcc.FirstName = accountOwner.LastName;
        newAcc.LastName = 'Customer'+ rnd;
        newAcc.OwnerId = accountOwner.Id;
        newAcc.ExtCustomerIdHost__c = 'HST_' + accountOwner.LastName + rnd;
        newAcc.ExtCustomerIdOki__c = 'OKI_' + accountOwner.LastName + rnd;
        newAcc.ExtCustomerNumber__c = 'CST_' + accountOwner.LastName + rnd;
        return newAcc;
    }    

    public static Account createCustomerAccount(User accountOwner, String identifier) {        
        Account newAcc = new Account();
        newAcc.RecordTypeId =  personAccountRecordType;
        newAcc.FirstName = identifier;
        newAcc.LastName = 'Customer';
        newAcc.OwnerId = accountOwner.Id;
        newAcc.ExtCustomerIdHost__c = identifier;
        newAcc.ExtCustomerIdOki__c = identifier;
        newAcc.ExtCustomerNumber__c = identifier;
        return newAcc;
    }    

    public static CustomerProperty createCustomerProperty(Account ownerAccount, ID recordType) {
        CustomerProperty prop = new CustomerProperty();
        prop.PrimaryOwnerId = ownerAccount.Id;
        prop.OwnerId = ownerAccount.OwnerId;
        prop.RecordTypeId = recordType;
        prop.SourceSystemIdentifier = ownerAccount.Owner.ExtFinancialAdvisorId__c + TestDataUtility.getRandomNumber(5);
        return prop;
    }

    public static InsurancePolicy createInsurancePolicy(Account insuredAcc, User policyOwner, Product2 insuranceProd, Boolean isOwnContract, Id policyRecordType) {
        InsurancePolicy insPol = new InsurancePolicy(Name = 'Test Insurance Policy '+TestDataUtility.getRandomNumber(5),
                                                    NameInsuredId = insuredAcc.Id,
                                                    OwnerId = policyOwner.Id,
                                                    Heldaway__c = !isOwnContract,
                                                    ProductId = insuranceProd.Id,
                                                    RecordTypeId = policyRecordType);
        return insPol;
      }

    public static Map<Id,InsurancePolicy> insurancePoliciesVisibleForUser(User checkUser) {        
        Map<Id,InsurancePolicy> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,InsurancePolicy>([SELECT Id,
                                                             OwnerId,                                                    
                                                             NameInsuredId,
                                                             NameInsured.FirstName,
                                                             NameInsured.LastName,
                                                             NameInsured.ExtCustomerNumber__c
                                                        FROM InsurancePolicy]);
        }
        return resultMap;
    } 

    /* Get all Customer Properties visible for a User */
    public static Map<Id,CustomerProperty> customerPropertiesVisibleForUser(User checkUser) {        
        Map<Id,CustomerProperty> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,CustomerProperty>([SELECT Id,
                                                             SourceSystemIdentifier,
                                                             OwnerId,                                                             
                                                             RecordTypeId,
                                                             RecordType.DeveloperName,
                                                             PrimaryOwnerId,
                                                             PrimaryOwner.FirstName,
                                                             PrimaryOwner.LastName,                                                    
                                                             PrimaryOwner.ExtCustomerNumber__c 
                                                        FROM CustomerProperty]);
        }
        return resultMap;
    } 
    
    /* Get all Person Life Events visible for a User */
    public static Map<Id,PersonLifeEvent> personLifeEventsVisibleForUser(User checkUser) {        
        Map<Id,PersonLifeEvent> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,PersonLifeEvent>([SELECT Id, 
                                                            Name,
                                                            EventDate,
                                                            EventType,
                                                            PrimaryPersonId,
                                                            PrimaryPerson.Name,                                                
                                                            OwnerId
                                                        FROM PersonLifeEvent]);
        }
        return resultMap;
    }

    public static FinServ__FinancialAccount__c createBankingAccount(Account ownerAccount, User accountOwner) {        
        FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
        finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdBankingAccount();
        finAcc.OwnerId = accountOwner.Id;
        finAcc.FinServ__PrimaryOwner__c = ownerAccount.Id;
        finAcc.Name = ownerAccount.ExtCustomerNumber__c + ' BankAcc ' + TestDataUtility.getRandomNumber(5);
        return finAcc;
    }  

    public static FinServ__FinancialAccount__c createInvestmentAccount(Account ownerAccount, User accountOwner) {        
        FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
        finAcc.RecordTypeId = RecordTypeHelper.getFinancialAccountRecordTypeIdInvestmentAccount();
        finAcc.OwnerId = accountOwner.Id;
        finAcc.FinServ__PrimaryOwner__c = ownerAccount.Id;
        finAcc.Name = ownerAccount.ExtCustomerNumber__c + ' InvestAcc ' + TestDataUtility.getRandomNumber(5);
        return finAcc;
    }

    public static FinServ__FinancialAccount__c createFinancialAccount(Account ownerAccount, User accountOwner, Id recordTypeId, String name) {
        FinServ__FinancialAccount__c finAcc = new FinServ__FinancialAccount__c();
        finAcc.RecordTypeId = recordTypeId;
        finAcc.OwnerId = accountOwner.Id;
        finAcc.FinServ__PrimaryOwner__c = ownerAccount.Id;
        finAcc.Name = ownerAccount.ExtCustomerNumber__c + ' ' + name;
        return finAcc;
    }


    public static Map<Id,FinServ__FinancialAccount__c> financialAccountsVisibleForUser(User checkUser) {        
        Map<Id,FinServ__FinancialAccount__c> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,FinServ__FinancialAccount__c>([SELECT Id, 
                                                                        Name,
                                                                        OwnerId,                                                                    
                                                                        FinServ__PrimaryOwner__c,
                                                                        FinServ__PrimaryOwner__r.Name,
                                                                        FinServ__PrimaryOwner__r.ExtCustomerNumber__c,
                                                                        RecordTypeId,
                                                                        RecordType.DeveloperName
                                                                    FROM FinServ__FinancialAccount__c]);
        }
        return resultMap;
    }

    public static IncomeAndExpenses__c createIncomeAndExpenseNetIncome(Account ownerAccount) {                      
        IncomeAndExpenses__c incomeExpense = new IncomeAndExpenses__c();
        incomeExpense.RecordTypeId = RecordTypeHelper.getIncomeExpenseRecordTypeIdNetIncome();
        incomeExpense.Amount__c = 200;
        incomeExpense.TotalAmount__c = 200;
        incomeExpense.IncomeAndExpensesType__c = 'CapitalGains';
        incomeExpense.OwnerId = ownerAccount.OwnerId;
        incomeExpense.PrimaryOwner__c = ownerAccount.Id;
        incomeExpense.Name = 'Net Income ' + TestDataUtility.getRandomNumber(3);
        return incomeExpense;
    }

    public static IncomeAndExpenses__c createIncomeAndExpenseNetGrossIncome(Account ownerAccount) {        
        IncomeAndExpenses__c incomeExpense = new IncomeAndExpenses__c();
        incomeExpense.RecordTypeId = RecordTypeHelper.getIncomeExpenseRecordTypeIdNetGrossIncome();
        incomeExpense.Amount__c = 200;
        incomeExpense.TotalAmount__c = 200;
        incomeExpense.IncomeAndExpensesType__c = 'Other';
        incomeExpense.OwnerId = ownerAccount.OwnerId;
        incomeExpense.PrimaryOwner__c = ownerAccount.Id;
        incomeExpense.Name = 'Net & Gross Income ' + TestDataUtility.getRandomNumber(3);
        return incomeExpense;
    }

    public static Map<Id,IncomeAndExpenses__c> incomeAndExpensesVisibleForUser(User checkUser) {        
        Map<Id,IncomeAndExpenses__c> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,IncomeAndExpenses__c>([SELECT Id, 
                                                                Name,
                                                                OwnerId,                                                                    
                                                                PrimaryOwner__c,
                                                                PrimaryOwner__r.Name,
                                                                PrimaryOwner__r.ExtCustomerNumber__c,
                                                                RecordTypeId,
                                                                RecordType.DeveloperName
                                                            FROM IncomeAndExpenses__c]);
        }
        return resultMap;
    }


    public static FinServ__AssetsAndLiabilities__c createAssetLiability(Account ownerAccount, ID recordType) {        
        FinServ__AssetsAndLiabilities__c assetLiability = new FinServ__AssetsAndLiabilities__c();
        assetLiability.OwnerId = ownerAccount.OwnerId;
        assetLiability.RecordTypeId = recordType;
        assetLiability.FinServ__PrimaryOwner__c = ownerAccount.Id;
        assetLiability.Name = 'Asset/Liability ' + TestDataUtility.getRandomNumber(3);
        return assetLiability;
    }

    public static Map<Id,FinServ__AssetsAndLiabilities__c> assetLiabilitiesVisibleForUser(User checkUser) {        
        Map<Id,FinServ__AssetsAndLiabilities__c> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,FinServ__AssetsAndLiabilities__c>([SELECT Id, 
                                                                Name,
                                                                OwnerId,                                                                    
                                                                FinServ__PrimaryOwner__c,
                                                                FinServ__PrimaryOwner__r.Name,
                                                                FinServ__PrimaryOwner__r.ExtCustomerNumber__c,
                                                                RecordTypeId,
                                                                RecordType.DeveloperName
                                                            FROM FinServ__AssetsAndLiabilities__c]);
        }
        return resultMap;
    }

    public static Lead createLead(Account referralAccount) {        
        String rnd = TestDataUtility.getRandomNumber(4);        
        Lead lead = new Lead(FirstName = 'Test',
                            LastName = 'Company ' + rnd,
                            Company = 'Test Company ' + rnd,
                            FinServ__RelatedAccount__c = referralAccount.Id,
                            OwnerId  = referralAccount.OwnerId,
                            FinServ__ReferredByContact__c = referralAccount.PersonContactId,
                            RecordTypeId = RecordTypeHelper.getLeadRecordTypeIdReferral());
        return lead;
    }

    public static Map<Id,Lead> leadsVisibleForUser(User checkUser) {        
        Map<Id,Lead> resultMap;
        System.runAs(checkUser) {
            resultMap = new Map<Id,Lead>([SELECT Id, 
                                                FirstName,
                                                LastName,
                                                OwnerId,                                                
                                                FinServ__ReferredByContact__c,
                                                RecordTypeId,
                                                RecordType.DeveloperName
                                            FROM Lead]);
        }
        return resultMap;
    }

    public static List<RelatedSharingObjects__mdt> getRelatedSharingObjectsTest(){
        List<RelatedSharingObjects__mdt> settings = new List<RelatedSharingObjects__mdt>();
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'Lead',
                                                    ObjectName__c = 'Lead',
                                                    ApexShareObject__c = 'LeadShare',
                                                    ReferenceFieldAccount__c = 'FinServ__RelatedAccount__c',
                                                    RecordTypeName__c = '',
                                                    UseMultipleOwnership__c = false,
                                                    UseHierarchy__c = false,
                                                    AccessLevel__c = 'Read'
                                                   ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialGoal',
                                                    ObjectName__c = 'FinServ__FinancialGoal__c',
                                                    ApexShareObject__c = 'FinServ__FinancialGoal__Share',
                                                    ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                    RecordTypeName__c = '',
                                                    UseMultipleOwnership__c = true,
                                                    UseHierarchy__c = true,
                                                    AccessLevel__c = 'Read'
                                                   ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'AssetsAndLiabilities',
                                                    ObjectName__c = 'FinServ__AssetsAndLiabilities__c',
                                                    ApexShareObject__c = 'FinServ__AssetsAndLiabilities__Share',
                                                    ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                    RecordTypeName__c = '',
                                                    UseMultipleOwnership__c = true,
                                                    UseHierarchy__c = true,
                                                    AccessLevel__c = 'Read'
                                                   ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountBankingAccount',
                                                    ObjectName__c = 'FinServ__FinancialAccount__c',
                                                    ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                    ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                    RecordTypeName__c = 'BankingAccount',
                                                    UseMultipleOwnership__c = false,
                                                    UseHierarchy__c = true,
                                                    AccessLevel__c = 'Read'
                                                   ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountInvestmentAccount',
                                                    ObjectName__c = 'FinServ__FinancialAccount__c',
                                                    ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                    ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                    RecordTypeName__c = 'InvestmentAccount',
                                                    UseMultipleOwnership__c = false,
                                                    UseHierarchy__c = true,
                                                    AccessLevel__c = 'Read'
                                                   ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountGeneralAccount',
                                                   ObjectName__c = 'FinServ__FinancialAccount__c',
                                                   ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                   ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                   RecordTypeName__c = 'General',
                                                   UseMultipleOwnership__c = true,
                                                   UseHierarchy__c = true,
                                                   AccessLevel__c = 'Read'
                                                  ));

        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountCreditCard',
                                                   ObjectName__c = 'FinServ__FinancialAccount__c',
                                                   ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                   ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                   RecordTypeName__c = 'CreditCard',
                                                   UseMultipleOwnership__c = false,
                                                   UseHierarchy__c = true,
                                                   AccessLevel__c = 'Read'
                                                  ));

        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountLoanAccount',
                                                  ObjectName__c = 'FinServ__FinancialAccount__c',
                                                  ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                  ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                  RecordTypeName__c = 'LoanAccount',
                                                  UseMultipleOwnership__c = false,
                                                  UseHierarchy__c = true,
                                                  AccessLevel__c = 'Read'
                                                 ));

        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountMortgage',
                                                 ObjectName__c = 'FinServ__FinancialAccount__c',
                                                 ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                 ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                 RecordTypeName__c = 'Mortgage',
                                                 UseMultipleOwnership__c = false,
                                                 UseHierarchy__c = true,
                                                 AccessLevel__c = 'Read'
                                                ));
                                                
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'FinancialAccountSavingsAccount',
                                                  ObjectName__c = 'FinServ__FinancialAccount__c',
                                                  ApexShareObject__c = 'FinServ__FinancialAccount__Share',
                                                  ReferenceFieldAccount__c = 'FinServ__PrimaryOwner__c',
                                                  RecordTypeName__c = 'SavingsAccount',
                                                  UseMultipleOwnership__c = false,
                                                  UseHierarchy__c = true,
                                                  AccessLevel__c = 'Read'
                                                 ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'InsurancePolicyCarInsurance',
                                                    ObjectName__c = 'InsurancePolicy',
                                                    ApexShareObject__c = 'InsurancePolicyShare',
                                                    ReferenceFieldAccount__c = 'NameInsuredId',
                                                    RecordTypeName__c = 'CarInsurance',
                                                    UseMultipleOwnership__c = false,
                                                    UseHierarchy__c = true,
                                                    AccessLevel__c = 'Read'
                                                   ));

        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'InsurancePolicyHealthInsurance',
                                                   ObjectName__c = 'InsurancePolicy',
                                                   ApexShareObject__c = 'InsurancePolicyShare',
                                                   ReferenceFieldAccount__c = 'NameInsuredId',
                                                   RecordTypeName__c = 'HealthInsurance',
                                                   UseMultipleOwnership__c = false,
                                                   UseHierarchy__c = true,
                                                   AccessLevel__c = 'Read'
                                                  ));

        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'InsurancePolicyLifeInsurance',
                                                  ObjectName__c = 'InsurancePolicy',
                                                  ApexShareObject__c = 'InsurancePolicyShare',
                                                  ReferenceFieldAccount__c = 'NameInsuredId',
                                                  RecordTypeName__c = 'LifeInsurance',
                                                  UseMultipleOwnership__c = false,
                                                  UseHierarchy__c = true,
                                                  AccessLevel__c = 'Read'
                                                 ));

        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'InsurancePolicyLegalInsurance',
                                                 ObjectName__c = 'InsurancePolicy',
                                                 ApexShareObject__c = 'InsurancePolicyShare',
                                                 ReferenceFieldAccount__c = 'NameInsuredId',
                                                 RecordTypeName__c = 'LegalInsurance',
                                                 UseMultipleOwnership__c = false,
                                                 UseHierarchy__c = true,
                                                 AccessLevel__c = 'Read'
                                                ));
                                                
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'InsurancePolicyPropertyInsurance',
                                                 ObjectName__c = 'InsurancePolicy',
                                                 ApexShareObject__c = 'InsurancePolicyShare',
                                                 ReferenceFieldAccount__c = 'NameInsuredId',
                                                 RecordTypeName__c = 'PropertyInsurance',
                                                 UseMultipleOwnership__c = false,
                                                 UseHierarchy__c = true,
                                                 AccessLevel__c = 'Read'
                                                ));
        
        settings.add(new RelatedSharingObjects__mdt(DeveloperName = 'IncomeAndExpenses',
                                                    ObjectName__c = 'IncomeAndExpenses__c',
                                                    ApexShareObject__c = 'IncomeAndExpenses__Share',
                                                    ReferenceFieldAccount__c = 'PrimaryOwner__c',
                                                    RecordTypeName__c = '',
                                                    UseMultipleOwnership__c = true,
                                                    UseHierarchy__c = true,
                                                    AccessLevel__c = 'Read'
                                                   ));        
        return settings;
    }
}