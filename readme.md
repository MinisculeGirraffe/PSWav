

ffmpeg remove meta from file
```
ffmpeg -y -i ./money_machine.wav -map_metadata -1 -codec copy -fflags +bitexact -flags:v +bitexact -flags:a +bitexact  money_machine_nometa.wav
```