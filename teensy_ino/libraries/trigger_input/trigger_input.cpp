#include "Arduino.h"
#include "trigger_input.h"
#include "options.h"



Trigger::Trigger() {
}



void
Trigger::setup() {

    pinMode(REWARD_PIN, INPUT);

    this->_current_state = digitalRead(REWARD_PIN);
    this->_previous_state = this->_current_state;
    this->delta_state = 0;
}



void Trigger::loop() {
}
