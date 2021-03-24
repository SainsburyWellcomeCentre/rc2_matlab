measure_encoder_delay.ino

Reads the state of the rotary encoders and outputs the same value on TTL0 and TTL1.

This script was designed to be run on the second Teensy for producing a supplementary figure showing the relationship between the encoder ticks and the resulting motion on the stage.

During this, the primary Teensy should be run as normal (forward only).

There is a separate user directory in rc/user which contains config information for this test.
