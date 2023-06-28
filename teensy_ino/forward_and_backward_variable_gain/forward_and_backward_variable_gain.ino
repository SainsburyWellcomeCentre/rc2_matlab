/* FORWARD_AND_BACKWARD_VARIABLE_GAIN.INO
 * 
 * script for 
 * 1. monitoring the motion of a rotary encoder
 * 2. filtering the encoder signal
 * 3. outputing voltage signal of encoder velocity DEPENDENDING ON DIGITAL INPUTS WHICH CHANGES THE GAIN
 * 
 */


#include "Arduino.h"
#include "options.h"

#include "encoder.h"
#include "velocity.h"
#include "ao.h"
#include "gain_control_levels.h"


class Encoder;
Velocity vel = Velocity();
AnalogOut ao = AnalogOut();
GainControlLevels gain = GainControlLevels();
int protocol = FORWARD_AND_BACKWARD;
float dac_offset_volts = 0.5;
float min_volts = 0;

void
setup() {
	
	enc.setup(protocol);
	ao.setup(dac_offset_volts);
	vel.setup();
	gain.setup();
	pinMode(DISABLE_PIN, INPUT);
}


void
loop() {

	// Determine whether to update the voltage.
	if (digitalRead(DISABLE_PIN) == HIGH) {
		ao.loop(true, dac_offset_volts);
		return;
	}

	bool update = 0;
	float volts = 0;
	
	// Check to make sure encoder has moved in last Xms
	enc.loop();
	
	// Fix the encoder velocity and distance for each loop.
	noInterrupts();
	float encoder_velocity = enc.current_velocity;
	float encoder_distance = enc.total_distance;
	interrupts();

	// Check state of the gain
	gain.loop();

	// Compute the velocity as a voltage
	vel.loop(encoder_velocity, min_volts, dac_offset_volts, gain.value);

	// Do we need to update the voltage?
	update = vel.update;
	volts = vel.current_volts;

	// If the treadmill has move beyond forward distance or backward distance reset distance to zero.
	if (encoder_distance > FORWARD_DISTANCE || encoder_distance < BACKWARD_DISTANCE) {
		noInterrupts();
		enc.total_distance = 0;
		interrupts();
	}
	
	ao.loop(update, volts);
}
