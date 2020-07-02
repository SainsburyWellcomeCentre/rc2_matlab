#ifndef DISABLE_H
#define DISABLE_H



class Disable {

    public:
        Disable();
        void setup();
        void loop();

        int delta_state;
        
    private:
        
        void _get_state();
        
        int _current_state;
        int _previous_state;
};


#endif  /* DISABLE_H */
