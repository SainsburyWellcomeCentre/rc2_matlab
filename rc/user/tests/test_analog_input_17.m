s = daq.createSession('ni');
chan = addAnalogInputChannel(s, 'Dev2', 17, 'Voltage');
s.Rate = 10000;
s.IsContinuous = 1;
s.NotifyWhenDataAvailableExceeds = 20000;
addlistener(s, 'DataAvailable', @(x, y)test_callback(x, y));
s.startBackground();
