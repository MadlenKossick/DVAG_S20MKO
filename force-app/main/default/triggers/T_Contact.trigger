/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Contact Main Trigger
 * 
 */

trigger T_Contact on Contact(before insert, after insert, before update, after update) {
  new TH_Contact().run();
}