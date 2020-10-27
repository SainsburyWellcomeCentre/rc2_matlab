#ifndef GAIN_CONTROL_H
#define GAIN_CONTROL_H

#include "options.h"

class GainControl {

    public:
        GainControl();
        void setup ();
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
