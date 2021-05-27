function nonblocking_pause(duration)

t = tic();
while toc(t) < duration
    pause(0.001);
end
