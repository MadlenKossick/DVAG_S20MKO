/**
 * @author Cloud Consulting Group - Madlen Kossick
 * @date 2023
 *
 * @group Test
 *
 * @description Trigger for platform events: TH_ToastEvent
 */
trigger T_ToastEventTestHelper on ToastEvent__e (after insert) {
    TH_ToastEventTestService.events = Trigger.new;
}