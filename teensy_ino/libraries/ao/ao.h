#ifndef ANALOG_OUTPUT_H
#define ANALOG_OUTPUT_H

#include "options.h"


class AnalogOut {

    public:
        AnalogOut();
        void setup (float dac_offset_volts);
        void loop(bool update, float voltage);

    private:
        uint16_t _volts_to_bits (float volts);
        void _write (uint16_t bits);

        float _max_dac_volts = MAX_DAC_VOLTS;
        uint16_t _max_dac_bits = MAX_DAC_BITS;
};


#endif  /* ANALOG_OUTPUT_H */
