@echo off
g++ -o "abort.exe" abort.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "home.exe" home.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "reset.exe" reset.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "listen_until.exe" listen_until.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "move_to.exe" move_to.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "calibrate_zero.exe" calibrate_zero.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "calibrate_zero_no_gear.exe" calibrate_zero_no_gear.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "mismatch_ramp_down_at.exe" mismatch_ramp_down_at.cpp rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "mismatch_ramp_up_until.exe" mismatch_ramp_up_until.cpp rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o "communicate.exe" communicate.c rc_shared.c -I"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Include" -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
echo done