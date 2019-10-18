#include "Arduino.h"
#include "trigger_output.h"
#include "options.h"


TriggerOutput::TriggerOutput() {
}


void
TriggerOutput::setup() {

    pinMode(REWARD_PIN, OUTPUT);
    digitalWrite(REWARD_PIN, LOW);
}


void
TriggerOutput::start() {

    digitalWrite(REWARD_PIN, HIGH);
    this->_on = 1;
    this->_time_started = millis();
}


void
TriggerOutput::_stop() {

    digitalWrite(REWARD_PIN, LOW);
    this->_on = 0;
}


void
TriggerOutput::loop() {
    
    if (this->_on) {    
        if ((millis() - this->_time_started) >= this->_duration) {
            this._stop();
        }
    }
}
