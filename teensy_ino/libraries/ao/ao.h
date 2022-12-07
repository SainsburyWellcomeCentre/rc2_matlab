#ifndef ANALOG_OUTPUT_H
#define ANALOG_OUTPUT_H

#include "options.h"

/*!
    Analog output class for writing output voltage values from the Teensy.
*/
class AnalogOut {

    public:
        //! AnalogOut constructor
        AnalogOut();

        /*! Setup the analog write resolution and write the offset voltage to the output.
            \param dac_offset_volts Offset value to write in volts.
        */
        void setup (float dac_offset_volts);

        /*! Writes the given voltage value to the output, dependent on the `update` bool.
            \param update Update bool
            \param voltage Voltage float
        */
        void loop(bool update, float voltage);

    private:
        /*! Converts a voltage value to a uint16_t value suitable for writing to the output.
            \param volts Voltage float
            \return uint16_t value scaled according to ::_max_dac_volts and ::_max_dac_bits
        */
        uint16_t _volts_to_bits (float volts);

        /*! Writes a uint16_t bits value to the analog output pin.
            \param bits Write bits
        */
        void _write (uint16_t bits);
        
        //! Max DAC volts - TODO how to reference #define MAX_DAC_VOLTS in options.h
        float _max_dac_volts = MAX_DAC_VOLTS;

        //! Max DAC bits - TODO how to reference #define MAX_DAC_BITS in options.h
        uint16_t _max_dac_bits = MAX_DAC_BITS;
};


#endif  /* ANALOG_OUTPUT_H */
