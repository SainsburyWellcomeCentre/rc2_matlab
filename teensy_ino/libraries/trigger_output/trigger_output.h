#ifndef TRIGGER_OUTPUT_H
#define TRIGGER_OUTPUT_H


class TriggerOutput {

    public:
        TriggerOutput();
        
        void setup(int pin);
        void loop();
        void start();
        
        
	private:
		
		void _stop();
		
		bool _on = 0;
		unsigned int _duration = 50;
		int _time_started;
		int _pin;
};


#endif  /* TRIGGER_INPUT_H */
