#ifndef GAIN_CONTROL_H
#define GAIN_CONTROL_H

#include "options.h"

/*!
    Deals with gain control in response to a TriggerInput.
*/
class GainControl {

    public:
		//! GainControl constructor
        GainControl();

		//! Set up the gain up, down and report pins; initialise properties.
        void setup ();

		//! Main loop method. Detects trigger inputs, adjusts gain and writes to gain report pin.
        void loop ();
        
        float value = 1;

    private:
    	
    	void _start();
    	void _stop();
    	
    	float _target;
    	float _initial_value;
    	int _time_started;
    	float _dvalue;
    	float _full_dt;
};


#endif  /* GAIN_CONTROL_H */
