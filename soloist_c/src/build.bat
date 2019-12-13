@echo off
g++ -o ..\exe\abort.exe abort.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o ..\exe\home.exe home.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o ..\exe\reset.exe reset.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o ..\exe\listen_until.exe listen_until.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o ..\exe\move_to.exe move_to.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o ..\exe\calibrate_zero.exe calibrate_zero.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
g++ -o ..\exe\ramp_down_gain.exe ramp_down_gain.c rc_shared.c -L"C:/Program Files (x86)/Aerotech/Soloist/CLibrary/Lib64" -lSoloistC64
echo done