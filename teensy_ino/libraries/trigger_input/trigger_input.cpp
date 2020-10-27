#include "Arduino.h"
#include "trigger_input.h"
#include "options.h"



TriggerInput::TriggerInput() {
}


void
TriggerInput::_get_state() {

    this->current_state = digitalRead(this->_pin);

    this->delta_state = 0;
    if (this->current_state == HIGH && this->_previous_state == LOW) {
        this->delta_state = 1;
    }
    if (this->current_state == LOW && this->_previous_state == HIGH) {
        this->delta_state = -1;
    }
    this->_previous_state = this->current_state;
}


void
TriggerInput::setup(int pin) {

    this->_pin = pin;
    pinMode(this->_pin, INPUT);

    this->current_state = digitalRead(this->_pin);
    this->_previous_state = this->current_state;
    this->delta_state = 0;
}


void TriggerInput::loop() {

    this->_get_state();
}
