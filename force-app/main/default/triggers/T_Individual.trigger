/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Account Main Trigger
 */

trigger T_Individual on Individual (after insert, after update) {
  new TH_Individual().run();
}