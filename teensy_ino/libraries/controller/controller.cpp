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


// Setup all objects.
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

    // Check state of the trigger input
    trig_in.loop();

    
    // Disable interrupts so that value is not changed in middle of operation.
    noInterrupts();

    // Check to make sure encoder has moved in last Xms
    enc.loop();

    // If trigger input received, reset the distance to zero.
    if (trig_in.delta_state) {
        enc.total_distance = 0;
    }

    // Fix the encoder velocity and distance for each loop.
    encoder_velocity = enc.current_velocity;
    encoder_distance = enc.total_distance;

    // Reenable interrupts
    interrupts();

    // Compute the velocity as a voltage
    vel.loop(encoder_velocity, this->min_volts, this->dac_offset_volts);

    // Do we need to update the voltage?
    update = vel.update;
    volts = vel.current_volts;

    // If the treadmill has move beyond forward distance or backward distance issue a trigger
    //  and reset distance to zero.
    if (encoder_distance > FORWARD_DISTANCE || encoder_distance < BACKWARD_DISTANCE) {
        trig_out.start();
        noInterrupts();
        enc.total_distance = 0;
        interrupts();
    }

    // Check status of trigger output.
    trig_out.loop();
    
    // Determine whether to update the voltage.
    ao.loop(update, volts);
}
