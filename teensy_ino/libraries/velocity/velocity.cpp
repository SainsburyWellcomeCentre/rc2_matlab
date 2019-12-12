#include <math.h>
#include "Arduino.h"
#include "velocity.h"



Velocity::Velocity() {
}



void
Velocity::_velocity_to_volts(float min_v, float offset) {

    this->current_volts = (this->_new_velocity / this->_max_velocity) * this->_max_volts;
    if( this->current_volts < min_v ) this->current_volts = min_v;
    if( this->current_volts > this->_max_volts ) this->current_volts = this->_max_volts;
    this->current_volts = offset + this->current_volts;
}



float
Velocity::_average(float enc_velocity) {

    float alpha = 0;
    float r = 0;
    int weights_idx;
    int n_bins = 0;
    float vel_from_max = 0;
    
    // Linear simple sliding window.
    if (this->_variable_window) {
        
        vel_from_max = (this->_max_velocity - fabs(enc_velocity));
        if ( vel_from_max < 0 ) vel_from_max = 0;
        n_bins = this->_n_bins_min + (this->_n_bins - this->_n_bins_min) * vel_from_max/this->_max_velocity;
    } 
    else {
        n_bins = this->_n_bins;
    }
    
    alpha = 1.0 / n_bins;
    
    // Could be simplified
    for (int i = 0; i < this->_n_bins; i++) {
        
        weights_idx = (i - this->_current_idx + this->_n_bins - 1) % this->_n_bins;
        
        if (weights_idx > this->_n_bins - n_bins - 1) {
            r += alpha * this->_buffer[i];
        }
    }
    
    return r;
}



void
Velocity::_filter(float enc_velocity) {
    
    // get the current time
    this->_this_micros = micros();
    
    // every _new_update_us microseconds
    if ( this->_this_micros > this->_last_micros + this->_new_update_us ) {
        
        // store the time this has happened
        this->_last_micros = this->_this_micros;
        // iterate the current index of the buffer to store
        this->_current_idx = ((this->_current_idx + 1) % this->_n_bins);
        // store the current velocity in that location in buffer
        this->_buffer[this->_current_idx] = enc_velocity;
        // perform the averaging of the velocity
        this->_new_velocity = this->_average(enc_velocity);
    }
    
    // if micros this time is smaller than the previous time, we've overflowed...
    if ( this->_this_micros < this -> _last_micros ) {
        this->_last_micros = 0;
    }
}



void
Velocity::setup() {

    if (this->_filtering_on) {
        
        // the number of bins we require to store old velocities is the duration to filter
        //  divided by the specified filter update rate (i.e. how often to store values)
        this->_n_bins = this->_n_millis_low / (1e-3 * this->_update_every_us);
        
        // create the buffer to store velocity values to
        this->_buffer = new float[this->_n_bins];
        
        // set all the values in the buffer to zero initially
        for (int i = 0; i < this->_n_bins; i++) {
            this->_buffer[i] = 0.0;
        }
        
        // this is the actual update rate (i.e. if the specified update
        //   rate doesn't divide the filter duration perfectly)
        float dt = this->_n_millis_low / (float) this->_n_bins;
        this->_new_update_us = (unsigned long) 1e3 * dt;
    }
}



void
Velocity::loop(float enc_velocity, float min_v, float offset) {

    // by default we do not need to update (only if velocity has changed)
    //   this public variable tells other parts whether we need to update...
    this->update = 0;
    
    if (this->_filtering_on ) {
        // send the velocity to the filter
         this->_filter(enc_velocity);
    }
    else {
        // otherwise just take this velocity
        this->_new_velocity = enc_velocity;
    }
    
    // if the new velocity is not equal to the velocity on the last loop
    if (this->_new_velocity != this->_previous_velocity) {
        // tell other modules we need to update
        this->update = 1;
        // convert the velocity to volts...
        this->_velocity_to_volts(min_v, offset);
        // store the new velocity value for future use
        this->_previous_velocity = this->_new_velocity;
    }
}
