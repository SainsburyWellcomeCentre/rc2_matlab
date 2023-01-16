#ifndef TRIGGER_OUTPUT_H
#define TRIGGER_OUTPUT_H

/*!
    Deals with writing on pins used as trigger outputs.
*/
class TriggerOutput {

    public:
		//! TriggerInput constructor
        TriggerOutput();
        
		/*! Setup the pin to use as an output. Set the pin mode as output and reset the state to low.
            \param pin Pin to write triggers on.
        */
        void setup(int pin);

		//! Main loop method. Monitors status of ::_on and implements time delay to ::_stop().
        void loop();

		//! Initiates a trigger output event by writing a digital output on ::_pin and updating the ::_time_started of the trigger event.
        void start();
        
        
	private:
		//! Resets the output on ::_pin to low.
		void _stop();
		
		//! Whether the trigger output should be initiated.
		bool _on = 0;

		//! Duration of trigger output event in ms.
		unsigned int _duration = 50;

		//! The time that the last trigger output event was initiated in ms.
		int _time_started;

		//! The pin to write trigger output events to.
		int _pin;
};


#endif  /* TRIGGER_INPUT_H */
