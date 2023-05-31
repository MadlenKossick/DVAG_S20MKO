/**
 * @author DVAG / Marc Habjanic, Gökcan Kirci
 * @date 2022
 *
 * @group Test
 *
 * @description Trigger for platform events: TH_IntegrationEvent
 */
trigger T_IntegrationEventTestHelper on IntegrationEvent__e (after insert) {
    TH_IntegrationEventTest.testEvents = Trigger.new;
 }