#ifndef ENCODER_H
#define ENCODER_H

#include "options.h"

#define FORWARDS 1
#define BACKWARDS -1


class Encoder {

    public:
        Encoder();

        void setup (int protocol);
        void loop ();

        volatile float current_velocity = 0;
        volatile float total_distance = 0;

    private:
        void _read ();
        void _delta_t ();
        void _direction ();
        void _velocity();
        void _increment_distance();
        void _main ();
        static void _interrupt_a();  // static
        static void _interrupt_b();

        int _protocol;

        volatile uint32_t _previous_usecs;
        uint32_t _current_usecs;
        uint32_t _delta_usecs;

        const uint32_t _timeout = TIMEOUT;
        const float _nm_per_count = NM_PER_COUNT;
        const float _phase_factor = PHASE_FACTOR;
        const float _phase_factor_back = PHASE_FACTOR_BACK;
        const float _a_to_b_rising_nm = _phase_factor * _nm_per_count;
        const float _b_to_a_rising_nm = (1 - _phase_factor) * _nm_per_count;
        const float _b_to_a_rising_nm_back = _phase_factor_back * _nm_per_count;
        const float _a_to_b_rising_nm_back = (1 - _phase_factor_back) * _nm_per_count;
        const bool _dual_trigger = DUAL_TRIGGER;

        int _a_state;
        int _b_state;
        int _current_pin;

        int _current_direction = FORWARDS;
        int _previous_direction = FORWARDS;
        bool _direction_change = 0;
        float _delta_distance;
};

extern Encoder enc;

#endif  /* ENCODER_H */
