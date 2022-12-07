#ifndef ENCODER_H
#define ENCODER_H

#include "options.h"

#define FORWARDS 1
#define BACKWARDS -1

/*!
    Deals with data received by a rotary encoder.
*/
class Encoder {

    public:
        //! Encoder constructor
        Encoder();

        /*! Setup the encoder pins, attach interrupt signals to respective functions.
            \param protocol Protocol being run.
        */
        void setup (int protocol);

        //! Main loop method. Handles setting zero-velocity after timeout.
        void loop ();

        //! Current recorded velocity.
        volatile float current_velocity = 0;

        //! Total distance recorded.
        volatile float total_distance = 0;

    private:
        //! Read the current state of pins A and B. Required to determine if encoder is moving forward or backward.
        void _read ();

        //! Calculate time since previous interrupt.
        void _delta_t ();

        //! Calculate the direction in which the encoder is travelling.
        void _direction ();

        //! Calculate the ::_delta_distance and ::current_velocity. Increment ::total_distance.
        void _velocity();

        //! Increments the ::total_distance with the current ::_delta_distance.
        void _increment_distance();

        //! Run on pin interrupts. Performs _read(), _delta_t(), _direction(), _velocity().
        void _main ();

        //! Attached to interrupt for ENC_A_PIN. Sets the ::_current_pin and runs main()
        static void _interrupt_a();  // static

        //! Attached to interrupt for ENC_B_PIN. Sets the ::_current_pin and runs main()
        static void _interrupt_b();

        //! The protocol being run.
        int _protocol;

        volatile uint32_t _previous_usecs;
        uint32_t _current_usecs;
        uint32_t _delta_usecs;

        //! If encoder doesn't move, time to take before setting velocity to 0.
        const uint32_t _timeout = TIMEOUT;

        //! Distance in nm traveled by treadmill on each tick.
        const float _nm_per_count = NM_PER_COUNT;

        //! 0-1, phase of distance from A to B relative to distance from A to A encoder tick - empirically determined.
        const float _phase_factor = PHASE_FACTOR;

        //! 0-1, phase of distance from B to A relative to distance from A to A encoder tick - empirically determined
        const float _phase_factor_back = PHASE_FACTOR_BACK;

        const float _b_to_a_rising_nm = (1 - _phase_factor) * _nm_per_count;
        const float _a_to_b_rising_nm = _phase_factor * _nm_per_count;
        const float _b_to_a_rising_nm_back = _phase_factor_back * _nm_per_count;
        const float _a_to_b_rising_nm_back = (1 - _phase_factor_back) * _nm_per_count;

        //! Whether or not to use encoder ticks A and B to calculate velocity.
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
