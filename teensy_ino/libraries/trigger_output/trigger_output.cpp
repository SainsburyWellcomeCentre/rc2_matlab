#include "Arduino.h"
#include "trigger_output.h"
#include "options.h"


TriggerOutput::TriggerOutput() {
}


void
TriggerOutput::setup(int pin) {

    this._pin = pin;
    pinMode(this._pin, OUTPUT);
    digitalWrite(this._pin, LOW);
}


void
TriggerOutput::start() {

    digitalWrite(this._pin, HIGH);
    this->_on = 1;
    this->_time_started = millis();
}


void
TriggerOutput::_stop() {

    digitalWrite(this._pin, LOW);
    this->_on = 0;
}


void
TriggerOutput::loop() {
    
    if (this->_on) {    
        if ((millis() - this->_time_started) >= this->_duration) {
            this->_stop();
        }
    }
}
