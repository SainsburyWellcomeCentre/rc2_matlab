#ifndef TRIGGER_INPUT_H
#define TRIGGER_INPUT_H



class TriggerInput {

    public:
        TriggerInput();
        void setup(int pin);
        void loop();

        int current_state;
        int delta_state;
        
    private:
        
        void _get_state();
        
        int _pin;
        int _previous_state;
};


#endif  /* TRIGGER_INPUT_H */
