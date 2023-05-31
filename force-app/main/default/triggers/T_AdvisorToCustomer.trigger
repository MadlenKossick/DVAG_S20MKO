/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description AdvisorToCustomer__c Main Trigger
 */

 trigger T_AdvisorToCustomer on AdvisorToCustomer__c(after insert, after delete) {
    new TH_AdvisorToCustomer().run();
  }