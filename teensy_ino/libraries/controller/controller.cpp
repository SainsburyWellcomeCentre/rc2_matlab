#include "Arduino.h"
#include "controller.h"
#include "options.h"

#include "encoder.h"
#include "velocity.h"
#include "ao.h"
#include "trigger_input.h"
#include "trigger_output.h"



class Encoder;
Velocity vel = Velocity();
AnalogOut ao = AnalogOut();
TriggerInput trig_in = TriggerInput();
TriggerOutput trig_out = TriggerOutput();



Controller::Controller() {
}



void
Controller::setup() {

    enc.setup(this->protocol);
    ao.setup(this->dac_offset_volts);
    vel.setup();
    trig_in.setup();
    trig_out.setup();
}



void
Controller::loop() {
    
    bool update;
    float volts;
    float encoder_velocity, encoder_distance;
    
    // Check to make sure encoder has moved in last Xms
    enc.loop();
    
    // Check state of the trigger input
    trig_in.loop();
    
    // Fix the encoder velocity for each loop (otherwise it may
    // change between calls).
    // Disable interrupts so that value is not changed in middle of operation.
    noInterrupts();
    if (trig_in.delta_state) {
        enc.total_distance = 0;
    }
    encoder_velocity = enc.current_velocity;
    encoder_distance = enc.total_distance;
    interrupts();

    // Compute the velocity as a voltage
    vel.loop(encoder_velocity, this->min_volts, this->dac_offset_volts);

    update = vel.update;
    volts = vel.current_volts;

    if (encoder_distance > FORWARD_DISTANCE || encoder_distance < BACKWARD_DISTANCE) {
        
        trig_out.start();
        noInterrupts();
        enc.total_distance = 0;
        interrupts();
    }
    
    trig_out.loop();
    ao.loop(update, volts);
}
