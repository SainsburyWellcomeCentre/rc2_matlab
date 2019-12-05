/* CALIBRATE_SOLOIST.INO
 * 
 * script for 
 * 1. wait for trigger input
 * 2. play a single velocity profile
 */


#include "velocity.h"
#include "ao.h"
#include "trigger_input.h"

#define DAC_OFFSET 		0.5
#define MIN_VOLTS 		-0.5

#define TARGET_VELOCITY 	400  // mm/s 

#define DWELL_MS  		2000  // 2 s
#define RAMP_DUR_MS 	200   // 200 ms
#define MAX_DUR_MS 		1000  // 1 s


// Controller defined in Arduino/Libraries: controller.cpp/h
Velocity vel = Velocity();
AnalogOut ao = AnalogOut();
TriggerInput trig_in = TriggerInput();


bool wait_for_trigger = 1;
unsigned long initial_time = millis();
unsigned long now;
unsigned long dt;
float velocity = 0;


void
setup() {
    // Protocol specific variables
    //    see class definition for details.
    ao.setup(DAC_OFFSET);
    vel.setup();
    vel.loop(0, MIN_VOLTS, DAC_OFFSET);
    trig_in.setup();
}


void
loop() {
	
	// Check state of the trigger input
    trig_in.loop();

    // If trigger input received, reset the time to to current time.
    if (trig_in.delta_state) {
    	wait_for_trigger = 0;
        initial_time = millis();
    }

    if (wait_for_trigger) {
    	return;
    }
	
	// Get current time
	now = millis();
	
	dt = now - initial_time;
	
	if (dt < DWELL_MS) {
		return;
	}
	
	if ((dt >= DWELL_MS) && (dt < (DWELL_MS + RAMP_DUR_MS))) {
		velocity = TARGET_VELOCITY*(dt - DWELL_MS)/RAMP_DUR_MS;
        vel.loop(velocity, MIN_VOLTS, DAC_OFFSET);
	} else if ((dt >= (DWELL_MS + RAMP_DUR_MS)) && (dt < (DWELL_MS + RAMP_DUR_MS + MAX_DUR_MS))) {
		velocity = TARGET_VELOCITY;
        vel.loop(velocity, MIN_VOLTS, DAC_OFFSET);
	} else if ((dt >= (DWELL_MS + RAMP_DUR_MS + MAX_DUR_MS)) && (dt < (DWELL_MS + 2*RAMP_DUR_MS + MAX_DUR_MS))) {
		velocity = TARGET_VELOCITY*((DWELL_MS + 2*RAMP_DUR_MS + MAX_DUR_MS) - dt)/RAMP_DUR_MS;
        vel.loop(velocity, MIN_VOLTS, DAC_OFFSET);
	} else if (dt > (DWELL_MS + 2*RAMP_DUR_MS + MAX_DUR_MS)) { 
        vel.current_volts = 0.5;
		wait_for_trigger = 1;
	}
	
	// Compute the velocity as a voltage
    
	
    //if (vel.current_volts < 0.4) vel.current_volts = 0.5;
    
	// output the voltage
	ao.loop(1, vel.current_volts);
}
