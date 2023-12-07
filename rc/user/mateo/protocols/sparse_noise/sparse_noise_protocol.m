function seq = sparse_noise_protocol(ctl)
%%seq = SPARSE_NOISE_PROTOCOL(ctl)
%
%   Just wrapper around VisStimSequence() class, so that the GUI can run
%   this function and have access to the class.

seq = VisStimSequence(ctl);
