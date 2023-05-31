/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description FinServ__AssetsAndLiabilities__c Main Trigger
 * 
 */

 trigger T_AssetsAndLiabilities on FinServ__AssetsAndLiabilities__c(after insert, after update) {
    new TH_AssetsAndLiabilities().run();
}