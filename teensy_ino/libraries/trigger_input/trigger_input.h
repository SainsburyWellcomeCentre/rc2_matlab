#ifndef TRIGGER_INPUT_H
#define TRIGGER_INPUT_H

/*!
    Deals with monitoring pins used as trigger inputs.
*/
class TriggerInput {

    public:
        //! TriggerInput constructor
        TriggerInput();

        /*! Setup the pin to listen to for the trigger and initialise state.
            \param pin Pin to listen for trigger on.
        */
        void setup(int pin);

        //! Main loop method. Monitors status of ::_pin to update ::current_state and ::delta_state.
        void loop();

        //! Current trigger state.
        int current_state;

        //! -1, 0, 1 - Indicates change in state from previous ::current_state.
        int delta_state;
        
    private:
        
        //! Reads the current pin state and updates ::current_state, ::delta_state, ::_previous_state.
        void _get_state();
        
        //! Pin to listen for trigger on.
        int _pin;

        //! The previous pin state.
        int _previous_state;
};


#endif  /* TRIGGER_INPUT_H */
