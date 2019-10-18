#ifndef TRIGGER_OUTPUT_H
#define TRIGGER_OUTPUT_H


class TriggerOutput {

    public:
        TriggerOutput();
        
        void setup();
        void loop();
        void start();
        
        
	private:
		
		void _stop();
		
		bool _on = 0;
		unsigned int _duration = 50;
		int _time_started;
};


#endif  /* TRIGGER_INPUT_H */
