/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Account Main Trigger
 */

trigger T_Account on Account(before insert, after insert, before update, after update, before delete, after delete) {
  new TH_Account().run();
}