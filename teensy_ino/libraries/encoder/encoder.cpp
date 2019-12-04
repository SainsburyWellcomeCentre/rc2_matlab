#include "Arduino.h"
#include "encoder.h"
#include "options.h"



Encoder::Encoder() {
}



void
Encoder::_read() {

    // Read the current state of pins A and B.
    // Need to do this to determine whether encoder is moving forward or backward.
    this->_a_state = digitalReadFast(ENC_A_PIN);
    this->_b_state = digitalReadFast(ENC_B_PIN);
}



void
Encoder::_delta_t() {

    // Calculate how long has it been since the previous interrupt.
    this->_current_usecs = micros();
    this->_delta_usecs = this->_current_usecs - this->_previous_usecs;
    this->_previous_usecs = this->_current_usecs;
}



void
Encoder::_direction() {

    // Calculate the direction in which the encoder is travelling.
    if ( this->_a_state == this->_b_state ) {
        if ( this->_current_pin == ENC_A_PIN ) {
            this->_current_direction = BACKWARDS;
        }
        if ( this->_current_pin == ENC_B_PIN ) {
            this->_current_direction = FORWARDS;
        }
    } else {
        if ( this->_current_pin == ENC_A_PIN ) {
            this->_current_direction = FORWARDS;
        }
        if ( this->_current_pin == ENC_B_PIN ) {
            this->_current_direction = BACKWARDS;
        }
    }
    this->_direction_change = ( this->_current_direction != this->_previous_direction );
    this->_previous_direction = this->_current_direction;
}



void
Encoder::_velocity() {

    // Determine the distance the encoder has travelled.
    if ( this->_current_pin == ENC_A_PIN && !this->_direction_change ) {
        if ( this->_current_direction == FORWARDS ) {
            this->_delta_distance = this->_a_to_b_rising_nm;
        }
        else if ( this->_current_direction == BACKWARDS ) {
            this->_delta_distance = -this->_b_to_a_rising_nm_back; //-
        }
    }
    else if ( this->_current_pin == ENC_B_PIN && !this->_direction_change ) {
        if ( this->_current_direction == FORWARDS ) {
            this->_delta_distance = this->_b_to_a_rising_nm;
        }
        else if ( this->_current_direction == BACKWARDS ) {
            this->_delta_distance = -this->_a_to_b_rising_nm_back; //-
        }
    }
    
    // If we're not using both encoder ticks to calculate velocity
    //     the distance travelled is just the distance between ticks on A
    if ( !this->_dual_trigger ) {
        float dir = this->_current_direction;
        this->_delta_distance = dir * this->_nm_per_count;
    }
    
    // If the direction has just changed, we say we haven't moved anywhere.
    if ( this->_direction_change ) {
        this->_delta_distance = 0;
    }
    
    // Do the velocity calculation.
    float t = (float) this->_delta_usecs;
    this->current_velocity = (float) this->_delta_distance / t; // this->delta_usecs;
    
    // Increment the distance depending on the protocol.
    if (this->_protocol == FORWARD_AND_BACKWARD) {
        this->_increment_distance();
    } else if (this->current_velocity > 0) {
        this->_increment_distance();
    }
}


void
Encoder::_increment_distance() {
    this->total_distance += this->_delta_distance*1E-6;
}


void
Encoder::_main() {

    // Every interrupt runs these steps.
    this->_read();
    this->_delta_t();
    this->_direction();
    this->_velocity();
}



void
Encoder::_interrupt_a() {

    // We have received signal on A.
    enc._current_pin = 0;
    enc._main();
}



void
Encoder::_interrupt_b() {

    // We have received signal on B.
    enc._current_pin = 1;
    enc._main();
}



void
Encoder::setup(int protocol) {

    // Setup encoder pins on fast reading pins.
    pinMode(ENC_A_PIN, INPUT_PULLUP);
    pinMode(ENC_B_PIN, INPUT_PULLUP);
    
    // Attach interrupt signals to respective functions.
    attachInterrupt(ENC_A_PIN, this->_interrupt_a, RISING);
    if ( this->_dual_trigger ) {
        attachInterrupt(ENC_B_PIN, this->_interrupt_b, RISING);
    }
    
    // Set some vars.
    this->_previous_usecs = micros();
    this->_protocol = protocol;
}



void
Encoder::loop() {

    noInterrupts();
    uint32_t now = micros();
    uint32_t last_u = this->_previous_usecs;
    if ((now > last_u) && ((now - last_u) > this->_timeout)) {
        this->current_velocity = 0;
    }
    interrupts();
}

Encoder enc = Encoder();