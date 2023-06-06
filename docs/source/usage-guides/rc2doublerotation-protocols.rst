Trials and Protocols
====================

The ``rc\prot`` directory contains classes which run trials on the setup. 
A *trial* on the setup involves the concept of motion with a start and end point. 
This could involve movement of the stage from the back to the front, running on the treadmill a certain distance 
(from unblocking the treadmill to blocking of the treadmill a certain distance later), 
or viewing a corridor which moves a certain distance (or combination of these).

These include:

- `Coupled`
- `EncoderOnly`
- `ReplayOnly`
- `StageOnly`
- `CoupledMismatch`
- `EncoderOnlyMismatch`

.. note::
    These names are not particularly descriptive, and ideally should be changed, but remain for historical reasons.

In order to create a sequence of trials, the :class:`rc.prot.ProtocolSequence` class can be used.
This stores a sequence of trial objects in a cell array and executes them one after the other.

Trial Classes
-------------

Coupled
^^^^^^^

The :class:`rc.prot.Coupled` class is used to couple the velocity of the treadmill with the velocity of the linear stage.
The multiplexer outputs the analog voltage of the Teensy (treadmill velocity), 
which is passed to the controller of the linear stage and (if selected) the motion of a virtual corridor.

EncoderOnly
^^^^^^^^^^^

The :class:`rc.prot.EncoderOnly` class is used to run a trial in which the stage is stationary but the treadmill is allowed to move a certain distance.
The multiplexer outputs the analog voltage of the Teensy (treadmill velocity), which is passed to (if selected) the motion of a virtual corridor.

ReplayOnly
^^^^^^^^^^
The :class:`rc.prot.ReplayOnly` class is used to run a trial in which the stage is stationary but an external command is sent from the analog output of the NIDAQ.
The multiplexer outputs the analog voltage from the NIDAQ AO, which is passed to (if selected) the motion of a virtual corridor.

StageOnly
^^^^^^^^^

The :class:`rc.prot.StageOnly` class is used to run a trial in which the linear stage is moved by an external command provided by the analog output of the NIDAQ.
The multiplexer outputs the analog voltage from the NIDAQ AO, which is passed to the controller of the linear stage and (if selected) the motion of a virtual corridor.

.. note::
    StageOnly is not a good name. During the trial, a visual stimulus such as a moving corridor may still be presented. It is called StageOnly because historically there was no visual stimulus and it was distinguished from Coupled and EncoderOnly. 

CoupledMismatch
^^^^^^^^^^^^^^^

The :class:`rc.prot.CoupledMismatch` class is similar to the :class:`rc.prot.Coupled` class, but at some point along the trial there is a mismatch between the velocity of the treadmill and the command to the linear stage and (if selected) virtual corridor. 
Note that although this controls the duration of the gain, the magnitude of the gain is controlled on the Teensy itself. (See `teensy_ino` README).

EncoderOnlyMismatch
^^^^^^^^^^^^^^^^^^^

The :class:`rc.prot.EncoderOnlyMismatch` class is similar to the :class:`rc.prot.EncoderOnly`` class, but at some point along the trial there is a mismatch between the velocity of the treadmill and the virtual corridor.
Note that although this controls the duration of the gain, the magnitude of the gain is controlled on the Teensy itself. (See `teensy_ino` README).

Sequence of Trials
------------------

In order to run a sequence of trials we add objects of the above trial classes to a :class:`rc.prot.ProtocolSequence` class.

So we can do::

    seq = ProtocolSequence();

    trial1 = Coupled(ctl, config);
    trial2 = EncoderOnly(ctl, config);

    seq.add(trial1);
    seq.add(trial2);

    seq.run();

And this would run two trials, the first where the stage velocity is matched to the velocity of the treadmill and the second in which the treadmill moves but the stage doesn't.

Alternatively, you can run the trials separately::

    trial1 = Coupled(ctl, config);
    trial2 = EncoderOnly(ctl, config);

    trial1.run();
    trial2.run();

However, this has the disadvantage that the data for each trial is saved separately. 
Whereas, using the `run()` method of the :class:`rc.prot.ProtocolSequence` class starts acquiring data at the beginning and continues saving until all trials are finished.  

If you want to set the properties of the trial (e.g. stage start position, distance of travel, turning on of visual stimulus).

.. rc/dev
.. automodule:: rc.prot
.. autoclass:: ProtocolSequence
    :show-inheritance:
    :members:
.. autoclass:: Coupled
    :show-inheritance:
    :members:
.. autoclass:: EncoderOnly
    :show-inheritance:
    :members:
.. autoclass:: ReplayOnly
    :show-inheritance:
    :members:
.. autoclass:: StageOnly
    :show-inheritance:
    :members:
.. autoclass:: CoupledMismatch
    :show-inheritance:
    :members:
.. autoclass:: EncoderOnlyMismatch
    :show-inheritance:
    :members: