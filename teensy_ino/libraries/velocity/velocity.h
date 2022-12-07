#ifndef VELOCITY_H
#define VELOCITY_H

#include "options.h"

/*!
    Deals with velocity transformations from a raw encoder velocity signal.
*/
class Velocity {

    public:
        //! Velocity constructor
        Velocity ();

        //! Sets up buffer for storing incoming velocity values and initialises to 0.
        void setup ();

        /*! Main loop for velocity calculations.
            \param enc_velocity Raw encoder velocity.
            \param min_v Minimum velocity threshold.
            \param offset Applied offset.
            \param gain Applied gain.
        */
        void loop (float enc_velocity, float min_v, float offset, float gain);

        //! Flag for whether velocity has changed / has new value.
        bool update;

        //! Result of ::_velocity_to_volts conversion.
        float current_volts;

    private:
        /*! Convert velocity to volts.
            \param min_v Minimum threshold, if ::current_volts is less than this value it will be set to min_v.
            \param offset Offset applied to ::current_volts.
        */
        void _velocity_to_volts (float min_v, float offset);

        /*! Perform an average over the sample buffer.
            \param enc_velocity Encoder velocity.
        */
        float _average (float enc_velocity);

        /*! Filter method applying _average() according to encoder time steps.
            \param enc_velocity Encoder velocity.
        */
        void _filter (float enc_velocity);
        
        //! Whether to apply velocity filtering.
        const bool _filtering_on = FILTER_ON;

        //! Maximum velocity to output as volts (mm/s).
        const float _max_velocity = MAX_VELOCITY;

        //! Max voltage offset which ::_max_velocity attains (volts).
        const float _max_volts = MAX_VOLTS;

        float _new_velocity = 0;
        float _previous_velocity = 0;

        int _current_idx = 0;

        unsigned long _this_micros;
        unsigned long _last_micros;

        //! Whether to decrease the filtering window with faster speeds.
        const bool _variable_window = VARIABLE_WINDOW;

        //! Time (in ms) to average over at low speeds. this is used as the window, if VARIABLE_WINDOW = 0. At MAX_VELOCITY integration is over 1 bin = UPDATE_US.
        const float _n_millis_low = N_MILLIS_LOW;

        //! Update rate for filtered window (microseconds).
        const float _update_every_us = UPDATE_US;
        int _n_bins;
        int _n_bins_min = 1;
        unsigned long _new_update_us;
        float *_buffer;
};


#endif  /* VELOCITY_H */
