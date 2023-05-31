/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Lead Main Trigger
 * 
 */

 trigger T_Lead on Lead(after insert, after update) {
    new TH_Lead().run();
}