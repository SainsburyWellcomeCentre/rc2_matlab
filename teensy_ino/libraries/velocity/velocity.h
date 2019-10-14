#ifndef VELOCITY_H
#define VELOCITY_H

#include "options.h"


class Velocity {

    public:
        Velocity ();
        void setup ();
        void loop (float enc_velocity, float min_v, float offset);

        bool update;
        float current_volts;

    private:
        void _velocity_to_volts (float min_v, float offset);
        float _average (float enc_velocity);
        void _filter (float enc_velocity);

        const bool _filtering_on = FILTER_ON;
        const float _max_velocity = MAX_VELOCITY;
        const float _max_volts = MAX_VOLTS;

        float _new_velocity = 0;
        float _previous_velocity = 0;

        int _current_idx = 0;

        unsigned long _this_micros;
        unsigned long _last_micros;

        const bool _variable_window = VARIABLE_WINDOW;
        const float _n_millis_low = N_MILLIS_LOW;
        const float _update_every_us = UPDATE_US;
        int _n_bins;
        int _n_bins_min = 1;
        unsigned long _new_update_us;
        float *_buffer;
};


#endif  /* VELOCITY_H */
