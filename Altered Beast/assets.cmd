path %path%;c:\Program Files\sox
for %%f in ("original samples\*.wav") do sox "%%f" "%%~nxf" channels 1 silence 1 0.1 1%% reverse silence 1 0.1 1%% reverse rate 8000
for %%f in (*.wav) do ..\..\..\c\pcmenc\encoder\x64\Release\pcmenc.exe -rto 1 -p 4 -dt1 12 -dt2 12 -dt3 423 -a 100 "%%f"