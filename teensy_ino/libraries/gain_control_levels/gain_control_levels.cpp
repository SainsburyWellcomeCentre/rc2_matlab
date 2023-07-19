#include <math.h>
#include "Arduino.h"
#include "gain_control_levels.h"
#include "trigger_input.h"
#include "options.h"


TriggerInput gain_up = TriggerInput();
TriggerInput gain_down = TriggerInput();


GainControlLevels::GainControlLevels() {
}


void
GainControlLevels::setup() {
	
	gain_up.setup(GAIN_UP_PIN);
	gain_down.setup(GAIN_DOWN_PIN);
	pinMode(GAIN_REPORT_PIN, OUTPUT);
	
	this->_target = 0;
	this->value = this->_target;
	this->_time_started = 0;
	this->_initial_value = this->value;
}



void
GainControlLevels::loop() {
	
	float dt = 0;
	
	gain_up.loop();
	gain_down.loop();
	
	if ( (gain_up.delta_state != 0) | (gain_down.delta_state != 0) ) {
		
		this->_time_started = millis();
		this->_initial_value = this->value;
		
		if ( (gain_up.current_state == HIGH) & (gain_down.current_state == HIGH) ) {
			this->_target = GAIN_DEFAULT_VAL;
			digitalWrite(GAIN_REPORT_PIN, HIGH);
		}
		else if ( (gain_up.current_state == HIGH) & (gain_down.current_state == LOW) ) {
			this->_target = GAIN_UP_VAL;
			digitalWrite(GAIN_REPORT_PIN, HIGH);
		}
		else if ( (gain_up.current_state == LOW) & (gain_down.current_state == HIGH) ) {
			this->_target = GAIN_DOWN_VAL;
			digitalWrite(GAIN_REPORT_PIN, HIGH);
		}
		else if ( (gain_up.current_state == LOW) & (gain_down.current_state == LOW) ) {	
			this->_target = GAIN_ZERO_VAL;
			digitalWrite(GAIN_REPORT_PIN, HIGH);
		}
		
		this->_dvalue = this->_target - this->_initial_value;
		this->_full_dt = fabs(this->_dvalue) * MS_PER_UNIT_GAIN;
	}
	
	
	if ((millis() - this->_time_started) < this->_full_dt) {
		dt = (float) (millis() - this->_time_started);
		this->value = this->_initial_value + dt * (this->_dvalue/this->_full_dt);
	} else {
		this->value = this->_target;
	}
    
}
