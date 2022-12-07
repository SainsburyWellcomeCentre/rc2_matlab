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

/*!
    Controls the overall behaviour of each protocol. For many Teensy protocol .ino files, their setup() and loop() methods redirect here.
*/
class Controller {

    public:
        //! Controller constructor
        Controller();

        /*! Sets up the Controller class and any other associated classes as well as pin IDs and modes. */
        void setup ();

        /*! Main loop. Monitors triggers and velocity. */
        void loop ();

        //! The protocol being run.
        int protocol;

        //! Voltage output corresponding to 0m/s. If set to non-zero value, negative voltage output indicates backwards, positive indicates forwards.
        float dac_offset_volts;

        //! How far below the ::dac_offset_volts is allowed. Should be a non-positive float with abs() < ::dac_offset_volts.
        float min_volts;
};


#endif  /* CONTROLLER_H */
