#ifndef CONTROLLER_H
#define CONTROLLER_H


/*
*    Controller class
*    - controls the overall behaviour of each protocol.
*
*    setup() and loop() in .ino files just direct here
*
*      protocol:           which protocol are we running
*      dac_offset_volts:   voltage output corresponding to 0m/s
*                           if set to non-zero value, negative voltage 
*                           output indicates backwards, positive indicates forwards
*      min_volts:          how far below the dac_offset_volts should we allow
*                           should be a non-positive float and abs() < dac_offset_volts
*                               NO CHECKS ARE MADE TO ENSURE THIS IS THE CASE
*/


class Controller {

    public:
        Controller();
        void setup ();
        void loop ();

        int protocol;
        float dac_offset_volts;
        float min_volts;
};


#endif  /* CONTROLLER_H */
