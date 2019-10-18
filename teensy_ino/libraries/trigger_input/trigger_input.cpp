#include "Arduino.h"
#include "trigger_input.h"
#include "options.h"



TriggerInput::TriggerInput() {
}


void
TriggerInput::_get_state() {

    this->_current_state = digitalRead(ZERO_POSITION_PIN);

    this->delta_state = 0;
    if (this->_current_state == HIGH && this->_previous_state == LOW) {
        this->delta_state = 1;
    }
    if (this->_current_state == LOW && this->_previous_state == HIGH) {
        this->delta_state = -1;
    }
    this->_previous_state = this->_current_state;
}


void
TriggerInput::setup() {

    pinMode(ZERO_POSITION_PIN, INPUT);

    this->_current_state = digitalRead(ZERO_POSITION_PIN);
    this->_previous_state = this->_current_state;
    this->delta_state = 0;
}


void TriggerInput::loop() {

    this->_get_state();
}
