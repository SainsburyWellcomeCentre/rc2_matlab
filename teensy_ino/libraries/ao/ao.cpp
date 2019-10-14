#include "Arduino.h"
#include "ao.h"


AnalogOut::AnalogOut() {
}



uint16_t
AnalogOut::_volts_to_bits(float volts) {

    float temp = volts * (float) this->_max_dac_bits / this->_max_dac_volts;
    uint16_t bits = (uint16_t) temp;
    return bits;
}



void
AnalogOut::_write(uint16_t value) {

    if ( value > this->_max_dac_bits ) value = this->_max_dac_bits;
    if ( value < 0 ) value = 0;
    analogWrite(DAC_PIN, value);
}



void
AnalogOut::setup(float offset) {

    analogWriteResolution(12);
    this->_write(this->_volts_to_bits(offset));
}



void
AnalogOut::loop(bool update, float voltage) {

    if (update) {
        this->_write(this->_volts_to_bits(voltage));
    }
}
