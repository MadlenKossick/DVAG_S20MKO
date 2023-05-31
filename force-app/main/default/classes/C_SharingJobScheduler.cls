/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Controller
 *
 * @description Methods for Lightning Web Component sharingJobScheduler & sharingJobExecutor
 */
public class C_SharingJobScheduler{
  private static String PROCESS = 'Sharing Job Scheduler';

  @AuraEnabled
  public static void startBatch(String batchName){
    if (batchName == 'Agent'){
      Database.executeBatch(new B_CalculateGroupHierarchy(), SharingUtil.getGroupHierarchyCalculationBatchSize());
    } else if (batchName == '360Objects'){
      List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
      Database.executeBatch(new B_ShareRelatedObjects(configs, 0), SharingUtil.getShareRelatedObjectsBatchSize());
    }
  }

  @AuraEnabled
  public static List<BatchJobHistory> getJobHistory(){
    List<String> classNames = new List<String>{ 'B_CalculateGroupHierarchy', 'B_ShareRelatedObjects', 'B_InsertSharingCalculations' };
    List<AsyncApexJob> jobs = [SELECT Status, NumberOfErrors, CreatedDate, CompletedDate, ApexClass.Name
                           FROM AsyncApexJob
                           WHERE ApexClass.Name IN:classNames
                           WITH SECURITY_ENFORCED
                           ORDER BY CompletedDate DESC
                           LIMIT 10];

    List<BatchJobHistory> jobsConverted = new List<BatchJobHistory>();
    for (AsyncApexJob job : jobs){
      jobsConverted.add(new BatchJobHistory(job));
    }

    return jobsConverted;
  }

  @AuraEnabled
  public static List<CronTrigger> getCurrentlyScheduledCrons(String cronJobName){
    return [SELECT Id, PreviousFireTime, EndTime, NextFireTime, State, CronJobDetail.Name
        FROM CronTrigger
        WHERE CronJobDetail.Name LIKE:cronJobName
        WITH SECURITY_ENFORCED];
  }

  @AuraEnabled
  public static void scheduleJob(String frequency, String jobType){
    try{
      if (jobType == 'agent'){
        switch  on frequency{
          when 'every5minutes'{
            System.schedule('GROUP Sharing #1', '0 0 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #2', '0 5 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #3', '0 10 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #4', '0 15 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #5', '0 20 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #6', '0 25 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #7', '0 30 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #8', '0 35 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #9', '0 40 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #10', '0 45 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #11', '0 50 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #12', '0 55 * * * ?', new B_CalculateGroupHierarchy());
          }
          when 'every15minutes'{
            System.schedule('GROUP Sharing #1', '0 0 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #2', '0 15 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #3', '0 30 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #4', '0 45 * * * ?', new B_CalculateGroupHierarchy());
          }
          when 'every30minutes'{
            System.schedule('GROUP Sharing #1', '0 0 * * * ?', new B_CalculateGroupHierarchy());
            System.schedule('GROUP Sharing #2', '0 30 * * * ?', new B_CalculateGroupHierarchy());
          }
        }
      } else if (jobType == '360Objects'){
        List<RelatedSharingObjects__mdt> configs = SharingUtil.getRelatedSharingObjects();
        switch  on frequency{
          when 'every5minutes'{
            System.schedule('Related Objects Sharing #1', '0 0 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #2', '0 5 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #3', '0 10 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #4', '0 15 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #5', '0 20 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #6', '0 25 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #7', '0 30 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #8', '0 35 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #9', '0 40 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #10', '0 45 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #11', '0 50 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #12', '0 55 * * * ?', new B_ShareRelatedObjects(configs,0));
          }
          when 'every15minutes'{
            System.schedule('Related Objects Sharing #1', '0 0 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #2', '0 15 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #3', '0 30 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #4', '0 45 * * * ?', new B_ShareRelatedObjects(configs,0));
          }
          when 'every30minutes'{
            System.schedule('Related Objects Sharing #1', '0 0 * * * ?', new B_ShareRelatedObjects(configs,0));
            System.schedule('Related Objects Sharing #2', '0 30 * * * ?', new B_ShareRelatedObjects(configs,0));
          }
        }
      }
    } catch (Exception e) {
      ErrorUtil.logExceptionError(PROCESS, 'Schedule Job', e);
    }
  }

  @AuraEnabled
  public static void deleteScheduledJob(List<String> cronJobIds) {
    try {
        for (String cronJobId : cronJobIds) {
            System.abortJob(cronJobId);
        }
    }   catch (Exception e){
            ErrorUtil.logExceptionError(PROCESS, 'Delete Scheduled Job', e);
    }
  }

  public class BatchJobHistory{
    @AuraEnabled
    public String ApexClassName;
    @AuraEnabled
    public String Status;
    @AuraEnabled
    public Integer NumberOfErrors;
    @AuraEnabled
    public Datetime CreatedDate;
    @AuraEnabled
    public Datetime CompletedDate;
    public BatchJobHistory(AsyncApexJob sfobj){
      this.ApexClassName = sfobj.ApexClass.Name;
      this.Status = sfobj.Status;
      this.NumberOfErrors = sfobj.NumberOfErrors;
      this.CreatedDate = sfobj.CreatedDate;
      this.CompletedDate = sfobj.CompletedDate;
    }

  }

  // sharingJobExecutor
  @AuraEnabled
  public static void addAgentSharingCalculations(String userIds){
    String userIdsCleaned = userIds.replaceAll(' ', '');

    if (String.isBlank(userIdsCleaned)){
      Database.executeBatch(new B_InsertSharingCalculations('AgentSharingCalculation__c'), 2000);
    } else{
      List<String> userIdsSeparated = userIdsCleaned.split(',');
      List<AgentSharingCalculation__c> agentSharingsToInsert = new List<AgentSharingCalculation__c>();
      List<User> addedUsers = [SELECT Id, ExtFinancialAdvisorId__c
                         FROM User
                         WHERE Id IN:userIdsSeparated];
      for (User usr : addedUsers){
        agentSharingsToInsert.add(new AgentSharingCalculation__c(Agent__r = usr, UniqueKey__c = usr.ExtFinancialAdvisorId__c));
      }

      Database.upsert (agentSharingsToInsert, AgentSharingCalculation__c.Fields.UniqueKey__c, false);
    }
  }

  @AuraEnabled
  public static void addAccountSharingCalculations(String accountIds){
    String accountIdsCleaned = accountIds.replaceAll(' ', '');

    if (String.isBlank(accountIdsCleaned)){
      Database.executeBatch(new B_InsertSharingCalculations('AccountSharingCalculation__c'), 2000);
    } else{
      List<String> accountIdsSeparated = accountIdsCleaned.split(',');
      List<AccountSharingCalculation__c> accountSharingsToInsert = new List<AccountSharingCalculation__c>();

      for (String accId : accountIdsSeparated){
        accountSharingsToInsert.add(new AccountSharingCalculation__c(Account__c = accId, UniqueKey__c = accId));
      }

      Database.upsert (accountSharingsToInsert, AccountSharingCalculation__c.Fields.UniqueKey__c, false);
    }
  }

}