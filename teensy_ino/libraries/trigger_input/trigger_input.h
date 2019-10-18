#ifndef TRIGGER_INPUT_H
#define TRIGGER_INPUT_H



class TriggerInput {

    public:
        TriggerInput();
        void setup();
        void loop();

        int delta_state;
        
    private:
        
        int _current_state;
        int _previous_state;
};


#endif  /* TRIGGER_INPUT_H */
