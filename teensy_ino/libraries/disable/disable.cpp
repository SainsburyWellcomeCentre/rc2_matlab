#include "Arduino.h"
#include "disable.h"
#include "options.h"



Disable::Disable() {
}


void
Disable::_get_state() {

    this->_current_state = digitalRead(DISABLE_PIN);

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
Disable::setup() {

    pinMode(DISABLE_PIN, INPUT);

    this->_current_state = digitalRead(DISABLE_PIN);
    this->_previous_state = this->_current_state;
    this->delta_state = 0;
}


void Disable::loop() {

    this->_get_state();
}
