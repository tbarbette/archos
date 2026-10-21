#!/bin/sh
# Speaker + mic loopback test on the RT5640 (run as user, sound server stopped)
c() { amixer -q -c 0 cset "name=$1" "$2" || echo "failed: $1"; }
# rt5640 EnableSeq (alsa-ucm-conf codecs/rt5640/EnableSeq.conf)
for s in 'DAC MIXL INF1 Switch' 'DAC MIXR INF1 Switch' 'Stereo DAC MIXL DAC L1 Switch' 'Stereo DAC MIXR DAC R1 Switch' \
	'OUT MIXL DAC L1 Switch' 'OUT MIXR DAC R1 Switch' 'SPK MIXL DAC L1 Switch' 'SPK MIXR DAC R1 Switch' \
	'ADC Capture Switch' 'SPOL MIX SPKVOL L Switch' 'SPOR MIX SPKVOL R Switch' 'Speaker Channel Switch' \
	'Speaker L Playback Switch' 'Speaker R Playback Switch'; do c "$s" on; done
c 'SPOL MIX SPKVOL R Switch' off
c 'Stereo ADC1 Mux' ADC
c 'ADC Capture Volume' 71
c 'Speaker Playback Volume' 30
c 'DAC1 Playback Volume' 160
for b in 1 2 3; do c "IN$b Boost" 0; done
c 'Stereo ADC MIXL ADC1 Switch' on
c 'Stereo ADC MIXR ADC1 Switch' on
python3 -c '
import math, struct, wave
w = wave.open("/tmp/tone.wav", "wb"); w.setnchannels(2); w.setsampwidth(2); w.setframerate(48000)
w.writeframes(b"".join(struct.pack("<hh", v, v) for v in (int(8000 * math.sin(2 * math.pi * 1000 * i / 48000)) for i in range(96000))))'
for b in 1 2 3; do
	for x in 1 2 3; do s=off; [ $x = $b ] && s=on; c "RECMIXL BST$x Switch" $s; c "RECMIXR BST$x Switch" $s; done
	arecord -q -D hw:0,0 -f S16_LE -r 48000 -c 2 -d 3 /tmp/in$b.wav & sleep 0.3
	aplay -q -D hw:0,0 /tmp/tone.wav; wait
	python3 -c '
import math, struct, sys, wave
w = wave.open(sys.argv[1]); n = w.getnframes(); d = struct.unpack("<%dh" % (2 * n), w.readframes(n))
l = d[0::2][24000:120000]
def g(f):  # Goertzel power at f
    k = 2 * math.cos(2 * math.pi * f / 48000); s1 = s2 = 0
    for x in l: s1, s2 = x + k * s1 - s2, s1
    return math.sqrt(max(s1 * s1 + s2 * s2 - k * s1 * s2, 0)) / len(l)
rms = math.sqrt(sum(x * x for x in l) / len(l))
print("IN%s rms=%.0f 1kHz=%.1f 1.3kHz=%.1f" % (sys.argv[2], rms, g(1000), g(1300)))' /tmp/in$b.wav $b
done
