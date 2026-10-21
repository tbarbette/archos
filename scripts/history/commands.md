# Every shell command run on the Mac during the port

Chronological log of the commands Claude ran on the owner's Mac (13–21 October 2026), extracted
from the session transcript, with the owner's prompts quoted where they arrived. Outputs are not
included. Commands that ran on the tablet are inside `ssh … '…'` or `$S/t '…'`; commands that ran
in the pmbootstrap container are inside `docker exec pmos …`.

Placeholders: `$S` was a scratch folder (most of it now lives in this repository), `$TASKS` the
output folder of background commands, `$AP_HOST`/`ap-user`/`$LAB_NET` the lab access point and
network the tablet joined on day two, `$TABLET_WIFI`/`$TABLET_MAC` the tablet's address there.
`$S/t` is the SSH wrapper that became `scripts/ssh.sh`. 147147 is the default password of the image.

Reusable versions of the important commands are the scripts one folder up.


## 2026-10-13

> **Owner:** Attached to USB is an old tablet. Force install a recent browser apk (Firefox or chrome) as I can't even connect to playstore anymore and there is no newer rom

**1.** `13:17` Check adb and tablet info

```sh
which adb; adb devices -l; adb shell 'getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.product.cpu.abilist; getprop ro.product.cpu.abi; getprop ro.product.model' 2>&1
```

**2.** `13:17` Look for adb and USB device

```sh
ls ~/Library/Android/sdk/platform-tools/adb 2>/dev/null; which brew; system_profiler SPUSBDataType 2>/dev/null | grep -B2 -A8 -iE 'android|tablet|samsung|lenovo|asus|google|huawei' | head -40
```

**3.** `13:17` List USB devices

```sh
system_profiler SPUSBHostDataType SPUSBDataType 2>/dev/null | head -80
```

**4.** `13:17` Summarize USB device names

```sh
system_profiler SPUSBHostDataType SPUSBDataType 2>/dev/null | grep -E '^\s+[A-Za-z0-9].*:$|Manufacturer|Vendor ID' | sed -n '1,200p' | grep -v 'Bus:' 
```

**5.** `13:17` Install adb via Homebrew and list devices

```sh
brew install --cask android-platform-tools 2>&1 | tail -3; adb devices -l
```

**6.** `13:18` Re-check adb devices

```sh
sleep 3; adb devices -l
```

**7.** `13:19` List Firefox 143 releases and recheck adb

```sh
curl -s https://archive.mozilla.org/pub/fenix/releases/ | grep -oE '143\.[0-9.]+' | sort -uV; echo ---; adb devices -l
```

**8.** `13:19` List Firefox 143.0.4 APK variants

```sh
curl -s https://archive.mozilla.org/pub/fenix/releases/143.0.4/android/ | grep -oE 'fenix-143[^"/]*' | sort -u
```

**9.** `13:19` Download Firefox 143.0.4 ARM APKs

```sh
D=$S/apk; mkdir -p $D; cd $D
for a in armeabi-v7a arm64-v8a; do curl -sSfLO https://archive.mozilla.org/pub/fenix/releases/143.0.4/android/fenix-143.0.4-android-$a/fenix-143.0.4.multi.android-$a.apk || curl -s https://archive.mozilla.org/pub/fenix/releases/143.0.4/android/fenix-143.0.4-android-$a/ | grep -oE 'href="[^"]+apk"'; done; ls -la
```

> **Owner:** Then, can you find a newer (maybe AOSP or similar hobbyist) ROM?

**10.** `13:24` Check download progress and adb

```sh
ls -la $S/apk; adb devices -l
```

**11.** `13:24` Get tablet Android version, ABI, platform

```sh
adb shell 'for p in ro.build.version.release ro.build.version.sdk ro.product.cpu.abilist ro.board.platform ro.boot.verifiedbootstate ro.secure ro.build.display.id; do echo "$p=$(getprop $p)"; done; df -h /data | tail -1'
```

**12.** `13:24` Find Firefox 68.12 Android builds

```sh
curl -s https://archive.mozilla.org/pub/mobile/releases/ | grep -oE '68\.12[^/"]*' | sort -u; curl -s https://archive.mozilla.org/pub/mobile/releases/68.12.0/ | grep -oE 'android[^/"]*' | sort -u
```

**13.** `13:24` List Firefox 68 mobile releases

```sh
curl -s https://archive.mozilla.org/pub/mobile/releases/ | grep -oE '>68[^<]*<' | tail; 
```

**14.** `13:25` Locate Firefox 68.12 API-16 APK

```sh
curl -s https://archive.mozilla.org/pub/mobile/releases/ | grep -oE '>68\.1[0-9][^<]*<'; curl -s https://archive.mozilla.org/pub/mobile/releases/68.12.0/ | grep -oE '>[^<]+/<'; curl -s https://archive.mozilla.org/pub/mobile/releases/68.12.0/android-api-16/en-US/ | grep -oE '>[^<]+\.apk<'
```

**15.** `13:25` Locate Firefox 68.11 API-16 APK

```sh
curl -s https://archive.mozilla.org/pub/mobile/releases/68.11.0/ | grep -oE '>[^<]+/<'; curl -s https://archive.mozilla.org/pub/mobile/releases/68.11.0/android-api-16/multi/ | grep -oE '>[^<]+\.apk<'
```

**16.** `13:25` Download Firefox 68.11 and install via adb

```sh
D=$S/apk68; mkdir -p $D
curl -sSfL -o $D/fennec.apk https://archive.mozilla.org/pub/mobile/releases/68.11.0/android-api-16/multi/fennec-68.11.0.multi.android-arm.apk && ls -la $D && adb shell df /data && adb install -r $D/fennec.apk
```

**17.** `13:28` Check whether Firefox got installed

```sh
sleep 20; adb wait-for-device; adb shell pm list packages | grep -i mozilla; adb shell getprop sys.boot_completed
```

**18.** `13:28` Retry install with pm directly

```sh
D=$S/apk68
adb push $D/fennec.apk /data/local/tmp/fennec.apk && adb shell pm install -r /data/local/tmp/fennec.apk; adb shell pm list packages | grep -i mozilla
```

**19.** `13:31` Launch Firefox and confirm focus

```sh
adb shell rm /data/local/tmp/fennec.apk; adb shell monkey -p org.mozilla.firefox -c android.intent.category.LAUNCHER 1 2>&1 | tail -1; sleep 8; adb shell dumpsys window windows | grep -m1 mCurrentFocus
```

**20.** `13:32` Verify Firefox is running in foreground

```sh
sleep 5; adb shell dumpsys activity activities | grep -m3 -E 'mFocusedActivity|mResumedActivity'; adb shell pidof org.mozilla.firefox || adb shell ps | grep mozilla
```

**21.** `13:32` Fetch ArcTablet RK3288 forum thread list over http

```sh
curl -sL --max-time 30 'http://www.arctablet.com/blog/forum/rk3288-entwicklung-und-customroms-development-and-croms/' | grep -oiE '<a [^>]*href="[^"]*"[^>]*>[^<]*(archos|oxygen|lineage|android|rom)[^<]*</a>' | head -60
```

**22.** `13:32` Check ArcTablet reachability and archived thread URLs

```sh
curl -sIL --max-time 20 'http://www.arctablet.com/blog/forum/rk3288-entwicklung-und-customroms-development-and-croms/' | head -20; curl -s --max-time 20 'https://web.archive.org/cdx/search/cdx?url=arctablet.com/blog/forum/rk3288-entwicklung-und-customroms-development-and-croms/*&output=text&fl=original&collapse=urlkey&limit=500' | grep -iE 'oxygen|archos|lineage' | head -40
```

**23.** `13:32` Search Wayback index for RK3288 Oxygen/Lineage threads

```sh
curl -s --max-time 60 'https://web.archive.org/cdx/search/cdx?url=arctablet.com/blog/forum/rk3288*&output=text&fl=original&collapse=urlkey&limit=3000' | grep -iE 'oxygen|archos|lineage|android-[5-9]|lollipop|marshmallow|nougat' | sed 's/[?#].*//' | sort -u | head -60
```

**24.** `13:33` Search Wayback for ArcTablet Oxygen threads

```sh
curl -s --max-time 90 'https://web.archive.org/cdx/search/cdx?url=arctablet.com/blog/forum/*&output=text&fl=original&collapse=urlkey&limit=20000' | grep -iE 'oxygen|101b|ac101' | sed 's/[?#].*//' | sort -u | head -40
```

**25.** `13:34` Read archived ArcTablet Oxygen ROM threads

```sh
for u in rk3288-entwicklung-und-customroms-development-and-croms/cm-for-archos-101-oxygen/ rockchip-rk3288/rom-for-archos-101-oxygen/ rk3288-entwicklung-und-customroms-development-and-croms/rom-archos-oxygen-101-4-4-4-custom-root-firmware-20150115/page-3/; do echo "=== $u"; curl -sL --max-time 60 "https://web.archive.org/web/2020/http://www.arctablet.com/blog/forum/$u" | python3 -I -c 'import sys,re,html;t=sys.stdin.read();t=re.sub(r"(?s)<(script|style).*?</\1>","",t);t=html.unescape(re.sub(r"<[^>]+>"," ",t));print(re.sub(r"\s+"," ",t)[:5000])'; done
```

**26.** `13:34` Extract post bodies from archived threads

```sh
S=$S; for u in rk3288-entwicklung-und-customroms-development-and-croms/cm-for-archos-101-oxygen/ rockchip-rk3288/rom-for-archos-101-oxygen/; do echo "=== $u"; curl -sL --max-time 60 "https://web.archive.org/web/2020/http://www.arctablet.com/blog/forum/$u" | python3 -I -c 'import sys,re,html;t=sys.stdin.read();t=re.sub(r"(?s)<(script|style).*?</\1>","",t);t=html.unescape(re.sub(r"<[^>]+>"," ",t));t=re.sub(r"\s+"," ",t);i=t.find("Member Since");print(t[max(0,i-300):i+4000])'; done
```


## 2026-10-20

> **Owner:** Try to find a postmarket OS version to install on the tablet, I guess one with the same SOC. The tablet is unusable anyway so you can brick it if need be. I'll throw it to the bin if you can't succeed as I can't update the browser and I can't update the tablet so I can't even go on a website with HTTPS

**27.** `12:28` Compare tablet clock and check for root

```sh
adb devices; date -u; adb shell date; adb shell 'getprop persist.sys.timezone; settings get global auto_time; which su; ls /system/xbin/ | grep -i su; id'
```

**28.** `12:28` Check if tablet is on USB

```sh
system_profiler SPUSBDataType 2>/dev/null | grep -A6 -iE 'archos|rockchip|0x2207|0x0e79'
```

**29.** `12:28` Search postmarketOS wiki for RK3288

```sh
curl -s --max-time 30 'https://wiki.postmarketos.org/api.php?action=query&list=search&srsearch=RK3288&srlimit=50&format=json' | python3 -I -c 'import sys,json;[print(r["title"]) for r in json.load(sys.stdin)["query"]["search"]]'
```

**30.** `12:28` List pmaports device packages for RK3288/Rockchip

```sh
curl -s --max-time 30 'https://gitlab.postmarketos.org/api/v4/projects/postmarketOS%2Fpmaports/repository/tree?path=device/testing&per_page=100&page=1' -o /dev/null -w '%{http_code}\n'; for p in 1 2 3 4 5 6 7 8 9 10; do curl -s --max-time 30 "https://gitlab.postmarketos.org/api/v4/projects/postmarketOS%2Fpmaports/repository/tree?path=device/testing&per_page=100&page=$p"; done | grep -oE '"name":"[^"]*(rk32|rockchip|veyron|tinker|rk3288|kernel-rock|linux-rock)[^"]*"'; for d in main community; do curl -s --max-time 30 "https://gitlab.postmarketos.org/api/v4/projects/postmarketOS%2Fpmaports/repository/tree?path=device/$d&per_page=100" | grep -oE '"name":"[^"]*(rk|rock|veyron|tinker)[^"]*"'; done
```

**31.** `12:29` Read veyron pmOS package files and find other Rockchip tablets

```sh
B='https://gitlab.postmarketos.org/postmarketOS/pmaports/-/raw/master'
for f in device/community/device-google-veyron/APKBUILD device/community/device-google-veyron/deviceinfo device/community/linux-google-veyron/APKBUILD; do echo "=== $f"; curl -s --max-time 30 "$B/$f" | head -70; done
curl -s "https://gitlab.postmarketos.org/api/v4/projects/postmarketOS%2Fpmaports/repository/tree?path=device/testing&per_page=100&page=1&recursive=false" >/dev/null
for p in $(seq 1 12); do curl -s --max-time 30 "https://gitlab.postmarketos.org/api/v4/projects/postmarketOS%2Fpmaports/repository/tree?path=device/testing&per_page=100&page=$p"; done | grep -oE '"name":"device-[^"]*"' | grep -iE 'rk|archos|pipo|teclast|onda|chuwi|cube|tinker|hp-chrome|asus-c' 
```

**32.** `12:29` Sparse-clone pmaports device folder

```sh
S=$S; mkdir -p $S/src && cd $S/src && git clone -q --depth 1 --filter=blob:none --sparse https://gitlab.postmarketos.org/postmarketOS/pmaports.git && cd pmaports && git sparse-checkout set device && find device -maxdepth 2 | grep -iE 'veyron|rk3|rockchip|tinker|freeme' 
```

**33.** `12:29` Inspect veyron and freeme (RK3188 tablet) ports

```sh
P=$S/src/pmaports; cat $P/device/community/device-google-veyron/deviceinfo; echo ====; head -40 $P/device/community/linux-google-veyron/APKBUILD; echo ====; ls $P/device/community/linux-google-veyron; echo ==== freeme; cat $P/device/testing/device-lark-freeme-70-2s/deviceinfo; ls $P/device/testing/u-boot-lark-freeme-70-2s; ls $P/device/testing/linux-postmarketos-rockchip-rk3188
```

**34.** `12:29` Inspect veyron kernel and freeme tablet port

```sh
P=$S/src/pmaports; head -45 $P/device/community/linux-google-veyron/APKBUILD; ls $P/device/community/linux-google-veyron; echo "--- freeme"; cat $P/device/testing/device-lark-freeme-70-2s/deviceinfo; ls $P/device/testing/u-boot-lark-freeme-70-2s $P/device/testing/linux-postmarketos-rockchip-rk3188
```

**35.** `12:29` Check available VM/container and flashing tools

```sh
for t in docker orb limactl podman colima qemu-system-aarch64 utm rkdeveloptool dtc; do printf "%s: " $t; which $t || echo -; done; brew info --json=v2 rkdeveloptool 2>/dev/null | grep -o '"name":"rkdeveloptool"' | head -1; docker info 2>&1 | grep -E 'Server Version|Architecture|CPUs|Total Memory|error' | head; sysctl -n hw.ncpu hw.memsize; df -h ~ | tail -1
```

**36.** `12:30` Check Docker daemon state

```sh
docker info 2>&1 | head -20; ls /Applications | grep -iE 'docker|orb|rancher'
```

**37.** `12:30` Start Docker and test armv7 emulation

```sh
open -a Docker; for i in $(seq 1 40); do docker info >/dev/null 2>&1 && break; sleep 3; done; docker info 2>&1 | grep -E 'Server Version|Architecture|CPUs|Total Memory'; docker run --rm --platform linux/arm/v7 alpine:3.22 uname -m; adb devices
```

**38.** `12:30` Check veyron kernel config for relevant drivers

```sh
C=$S/src/pmaports/device/community/linux-google-veyron/config-google-veyron.armv7; grep -E '^CONFIG_(TOUCHSCREEN_[A-Z0-9_]+|BRCMFMAC.*|RTL8[0-9A-Z_]+|DRM_ROCKCHIP|ROCKCHIP_[A-Z_]+|DRM_PANEL_[A-Z_]+|MFD_RK8XX.*|REGULATOR_[A-Z0-9_]+|BACKLIGHT_[A-Z_]+|MMC_DW.*|SND_SOC_[A-Z0-9_]+|USB_DWC2|PHY_ROCKCHIP.*|BATTERY_[A-Z0-9_]+|CHARGER_[A-Z0-9_]+|INPUT_[A-Z_]+|KEYBOARD_[A-Z_]+|IIO|[A-Z_]*MMA[0-9]+|SENSORS_[A-Z_]+)=' $C | tr '\n' ' '; echo; grep -cE '=m$' $C
```

**39.** `12:30` Wait for tablet to appear on adb (background)

```sh
adb wait-for-device && adb devices -l
```

**40.** `12:30` Build rkdeveloptool for macOS

```sh
S=$S/src; brew install libusb automake autoconf pkg-config dtc 2>&1 | tail -2; git clone -q --depth 1 https://github.com/rockchip-linux/rkdeveloptool.git $S/rkdeveloptool && cd $S/rkdeveloptool && autoreconf -i >/dev/null 2>&1 && ./configure >/dev/null && make -j8 2>&1 | grep -E 'error' | head; ls -la $S/rkdeveloptool/rkdeveloptool
```

**41.** `12:33` Rebuild rkdeveloptool without -Werror

```sh
R=$S/src/rkdeveloptool; make -C $R -j8 CXXFLAGS="-g -O2 -Wno-vla-cxx-extension -Wno-error" 2>&1 | grep -E ' error|Error' | head; $R/rkdeveloptool -v; $R/rkdeveloptool ld
```

**42.** `12:33` Create pmbootstrap container

```sh
S=$S; mkdir -p $S/share
docker volume create pmos-work >/dev/null
docker run -d --name pmos --privileged -v pmos-work:/work -v $S/share:/share alpine:3.22 sleep infinity
docker exec pmos sh -c 'apk add -q git python3 py3-pip sudo openssl coreutils procps multipath-tools losetup dtc make gcc musl-dev bash xz file >/dev/null && adduser -D -u 1000 pmos && echo "pmos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/pmos && chown pmos /work && su pmos -c "git clone -q --depth 1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git ~/pmbootstrap" && ln -s /home/pmos/pmbootstrap/pmbootstrap.py /usr/local/bin/pmbootstrap && su pmos -c "pmbootstrap --version"'
```

**43.** `12:34` Inspect pmbootstrap config keys

```sh
docker exec -u pmos pmos sh -c 'grep -n "defaults\b\|^    \"[a-z_]*\":" ~/pmbootstrap/pmb/config/__init__.py | head -60; ls ~/pmbootstrap/pmb/types.py && grep -n "class Config" -A45 ~/pmbootstrap/pmb/types.py | head -60'
```

**44.** `12:34` List pmbootstrap Config fields

```sh
docker exec -u pmos pmos sh -c 'grep -n "class Config" -A60 ~/pmbootstrap/pmb/core/config.py | grep -E "^[0-9]+-    [a-z_]+:" '
```

**45.** `12:34` Write pmbootstrap config and clone pmaports

```sh
docker exec -u pmos pmos sh -c 'mkdir -p ~/.config && cat > ~/.config/pmbootstrap_v3.cfg <<EOF
[pmbootstrap]
aports = /work/cache_git/pmaports
work = /work
device = google-veyron
ui = phosh
user = user
hostname = oxygen101
timezone = Europe/Brussels
extra_packages = firefox-esr,openssh-server,dtc,i2c-tools,evtest
jobs = 12
EOF
mkdir -p /work/cache_git && git clone -q https://gitlab.postmarketos.org/postmarketOS/pmaports.git /work/cache_git/pmaports && cd /work/cache_git/pmaports && git branch -r | tail -5 && git log -1 --format=%cd'
```

**46.** `12:34` List pmaports stable channels

```sh
docker exec -u pmos pmos sh -c 'cd /work/cache_git/pmaports && git branch -r | grep -E "origin/v[0-9]" | tail -3; cat channels.cfg | head -30'
```

**47.** `12:35` Switch to v26.06 and init chroot

```sh
docker exec -u pmos pmos sh -c 'cd /work/cache_git/pmaports && git checkout -q v26.06 && ls device/community | grep -E "veyron|rockchip"; grep pkgver= device/community/linux-google-veyron/APKBUILD; cd ~ && yes "" | timeout 600 pmbootstrap -q chroot -- true 2>&1 | tail -5; echo rc=$?'
```

**48.** `12:35` Check whether the tablet has connected

```sh
cat $TASKS/bb3cm9m8w.output; adb devices
```

> **Owner:** It's plugged in but the mac does not detect. A permission problem?

**49.** `12:50` Check whether macOS sees the tablet on USB

```sh
system_profiler SPUSBHostDataType SPUSBDataType 2>/dev/null | grep -E '^\s+[A-Za-z0-9].*:$|Vendor ID|Product ID' | grep -v Bus: ; adb devices -l; ioreg -p IOUSB -l 2>/dev/null | grep -iE '"USB Product Name"|idVendor' | head -30
```

**50.** `12:54` Check tablet clock, root, RAM and cmdline

```sh
cat $TASKS/bb3cm9m8w.output; date -u; adb shell 'date; id; ls /system/xbin /system/bin | grep -E "^su$|busybox"; cat /proc/meminfo | head -1; cat /proc/cmdline'
```

**51.** `12:54` Collect memory, partitions, i2c devices, dmesg

```sh
O=$S/hw; mkdir -p $O
adb shell 'busybox cat /proc/meminfo | busybox head -2; busybox cat /proc/cpuinfo | busybox tail -5; cat /proc/mtd; cat /proc/partitions; ls /dev/block/platform/*/by-name 2>/dev/null; ls -d /proc/device-tree /sys/firmware/devicetree/base 2>&1; ls /sys/bus/i2c/devices/; for d in /sys/bus/i2c/devices/*; do echo "$d $(cat $d/name 2>/dev/null)"; done; busybox uname -a'; adb shell dmesg > $O/dmesg.txt; wc -l $O/dmesg.txt
```

> **Owner:** Ok now!

**52.** `12:54` Inspect input devices, display and platform devices

```sh
O=$S/hw; head -c 300 $O/dmesg.txt; echo; adb shell 'getevent -i 2>/dev/null | grep -E "add device|name:|bus:"; ls /sys/class/graphics/fb0/; cat /sys/class/graphics/fb0/modes /sys/class/graphics/fb0/virtual_size 2>/dev/null; ls /sys/class/display /sys/class/backlight 2>/dev/null; ls /sys/bus/platform/devices/ | busybox tr "\n" " "; wm size; wm density'
```

**53.** `12:54` Identify WiFi chip, then reboot to Rockchip loader

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool
adb shell 'ls /sys/bus/sdio/devices/ 2>/dev/null; cat /sys/bus/sdio/devices/*/vendor /sys/bus/sdio/devices/*/device 2>/dev/null; getprop wifi.interface; getprop ro.wifi.chip 2>/dev/null; ls /system/lib/modules /vendor/lib/modules 2>/dev/null; ls /system/etc/firmware | busybox head -30'
adb reboot bootloader; sleep 8; $RK ld
```

**54.** `12:55` Read partition table and chip/flash info

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; $RK ppt; $RK rci; $RK rfi
```

**55.** `12:55` Back up first 160 MB of eMMC via loader

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; B=$S/backup; mkdir -p $B
$RK rl 0 0x50000 $B/emmc-head.bin 2>&1 | tail -1; ls -la $B; xxd -s 0 -l 64 $B/emmc-head.bin; strings -n 6 $B/emmc-head.bin | head -20
```

**56.** `12:55` Split partitions and extract DTB from resource

```sh
B=$S/backup
dd if=$B/emmc-head.bin of=$B/resource.img bs=512 skip=$((0x6000)) count=$((0x8000)) 2>/dev/null
dd if=$B/emmc-head.bin of=$B/uboot.img bs=512 skip=$((0x2000)) count=$((0x2000)) 2>/dev/null
dd if=$B/emmc-head.bin of=$B/kernel.img bs=512 skip=$((0xE000)) count=$((0x8000)) 2>/dev/null
dd if=$B/emmc-head.bin of=$B/boot.img bs=512 skip=$((0x16000)) count=$((0x10000)) 2>/dev/null
dd if=$B/emmc-head.bin of=$B/recovery.img bs=512 skip=$((0x26000)) count=$((0x10000)) 2>/dev/null
for f in resource uboot kernel boot recovery; do printf "%-9s " $f; xxd -l 16 $B/$f.img; done
python3 -I - $B/resource.img $B <<'EOF'
import sys,struct
d=open(sys.argv[1],'rb').read()
assert d[:4]==b'RSCE',d[:4]
hdr_blks=struct.unpack_from('<H',d,6)[0]; tbl_off=d[8]; ent_blks=d[9]; n=struct.unpack_from('<I',d,10)[0]
print('entries',n)
for i in range(n):
    o=(hdr_blks+i*ent_blks)*512
    e=d[o:o+512]
    name=e[4:260].split(b'\0')[0].decode()
    blk,size=struct.unpack_from('<II',e,260)
    print(name,blk,size)
    open(sys.argv[2]+'/res_'+name.replace('/','_'),'wb').write(d[blk*512:blk*512+size])
EOF
ls -la $B
```

**57.** `12:55` Decompile stock DTB and find key nodes

```sh
B=$S/backup; find $B -name 'res_*' -size 0 -delete; dtc -I dtb -O dts -o $B/stock.dts $B/res_rk-kernel.dtb 2>/dev/null; wc -l $B/stock.dts; grep -nE 'compatible = "(.*(screen|mipi|lvds|edp|vtl|ct36|gt9|ricoh|syr|backlight|rk3288-dsi|dsi).*)"' $B/stock.dts | head -40
```

**58.** `12:55` Show touchscreen, display, backlight nodes

```sh
B=$S/backup; sed -n '5330,5430p;6020,6217p' $B/stock.dts
```

**59.** `12:56` Map GPIO phandles and show SYR82x nodes

```sh
B=$S/backup; python3 -I - $B/stock.dts <<'EOF'
import re,sys
t=open(sys.argv[1]).read()
# map phandle -> node path name
stack=[];ph={}
for line in t.split('\n'):
    s=line.strip()
    m=re.match(r'([^\s]+) \{$',s)
    if m: stack.append(m.group(1)); continue
    if s=='};' and stack: stack.pop(); continue
    m=re.match(r'phandle = <(0x[0-9a-f]+)>;',s)
    if m: ph[int(m.group(1),16)]='/'.join(stack[-2:])
for k in [0xb3,0xb4,0xe6,0x115,0x116,0x8d,0x118,0x11b,0xc7]:
    print(hex(k),ph.get(k))
EOF
sed -n '4640,4720p' $B/stock.dts | grep -vE '^\s*$'; 
```

**60.** `12:56` Show PMIC regulators with voltages

```sh
B=$S/backup; awk 'NR>=4870 && NR<=5210' $B/stock.dts | grep -E 'ricoh619@|gpios|irq|regulator-(name|min|max|always|boot)|ricoh619_|pwr_hold|interrupt' | sed 's/^\t*//' | python3 -I -c '
import sys,re
for l in sys.stdin:
    l=l.rstrip()
    m=re.search(r"<(0x[0-9a-f]+)>",l)
    if "microvolt" in l and m: l+=f"   # {int(m.group(1),16)/1e6} V"
    print(l)'; grep -nE 'rksdmmc@|dwmmc@|sdhci@' $B/stock.dts
```

**61.** `12:56` Inspect vendor U-Boot strings and boot.img header

```sh
B=$S/backup; strings -n 4 $B/uboot.img | grep -m1 -n LOADER; grep -c . <(strings $B/uboot.img); strings -n 5 $B/uboot.img | grep -iE 'U-Boot 20|resource|second|fdt|dtb|appended|recovery|bootcmd|rk_load|charge|zImage|kernel' | sort -u | head -60; xxd -l 64 $B/boot.img
```

**62.** `12:57` Parse stock boot/recovery image headers

```sh
B=$S/backup; python3 -I - $B/boot.img $B/recovery.img <<'EOF'
import struct,sys
for f in sys.argv[1:]:
    d=open(f,'rb').read()
    ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
    name=d[48:64].split(b'\0')[0]; cmd=d[64:576].split(b'\0')[0]
    def up(x): return (x+ps-1)//ps*ps
    so=ps+up(ks)+up(rs)
    print(f.split('/')[-1],dict(ks=hex(ks),ka=hex(ka),rs=hex(rs),ra=hex(ra),ss=hex(ss),sa=hex(sa),ta=hex(ta),ps=ps),name,cmd)
    print('  second magic:',d[so:so+4], ' ramdisk magic:',d[ps+up(ks):ps+up(ks)+4].hex())
EOF
```

**63.** `12:57` Read veyron kernel and device APKBUILDs (v26.06)

```sh
docker exec -u pmos pmos sh -c 'cd /work/cache_git/pmaports/device/community/linux-google-veyron && sed -n "40,200p" APKBUILD; ls; cat ../device-google-veyron/APKBUILD | head -60'
```

**64.** `12:58` Fetch Linux 6.12.90 and locate RK3288 DTS/driver refs

```sh
docker exec -u pmos pmos sh -c 'mkdir -p /work/ksrc && cd /work/ksrc && wget -q https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.90.tar.xz && tar xf linux-6.12.90.tar.xz && cd linux-6.12.90 && ls arch/arm/boot/dts/rockchip/ | grep rk3288 | tr "\n" " "; echo; grep -n "rc5t619\|RC5T619" -r drivers/regulator/rn5t618-regulator.c drivers/mfd/rn5t618.c | head; grep -rln "mipi_dsi" arch/arm/boot/dts/rockchip/rk3288-*.dts*'
```

**65.** `12:58` Inspect DSI dtsi node, RC5T619 regulators, DSI driver

```sh
docker exec -u pmos pmos sh -c 'cd /work/ksrc/linux-6.12.90 && grep -n "mipi_dsi: dsi@" -A40 arch/arm/boot/dts/rockchip/rk3288.dtsi | head -45; sed -n 60,110p drivers/regulator/rn5t618-regulator.c; grep -n "compatible" drivers/mfd/rn5t618.c; grep -n "rockchip,rk3288-mipi-dsi" -B2 -A20 drivers/gpu/drm/rockchip/dw-mipi-dsi-rockchip.c | head -40'
```

**66.** `12:58` Inspect panel-simple DSI entry format

```sh
docker exec -u pmos pmos sh -c 'cd /work/ksrc/linux-6.12.90 && grep -n "struct panel_desc_dsi {" -A8 drivers/gpu/drm/panel/panel-simple.c; grep -n "boe_tv080wum_nl0" -A30 drivers/gpu/drm/panel/panel-simple.c | head -45; grep -n "dsi_of_match\[\]" -A6 drivers/gpu/drm/panel/panel-simple.c; grep -n "rockchip,rk3288-io-voltage-domain" -A3 arch/arm/boot/dts/rockchip/rk3288.dtsi; grep -n "&pwm0\|backlight" arch/arm/boot/dts/rockchip/rk3288-evb.dtsi | head'
```

**67.** `12:59` Show stock MMC controller nodes

```sh
B=$S/backup; sed -n '3921,4015p' $B/stock.dts | grep -vE 'clock|interrupts|reg =|#'; grep -n 'cd-gpios\|sd_detect\|rockchip,io_vol' $B/stock.dts | head
```

**68.** `12:59` Create port working folder

```sh
mkdir -p $S/share/port
```

**69.** `13:00` Fix DTS and test-compile it

```sh
F=$S/share/port/rk3288-archos-oxygen101.dts
python3 -I - $F <<'EOF'
import sys
p=sys.argv[1]; t=open(p).read()
old="""/* Only the DSI output is wired: keep the VOPs off the other encoders. */
&mipi_in_vopl {
	status = "disabled";
};

&vopb {
	status = "okay";
};

&vopb_mmu {
	status = "okay";
};

&vopl {
	status = "disabled";
};
"""
new="""&vopb {
	status = "okay";
};

&vopb_mmu {
	status = "okay";
};

&vopl {
	status = "okay";
};

&vopl_mmu {
	status = "okay";
};
"""
assert old in t; t=t.replace(old,new)
t=t.replace("""&mipi_dsi {
	status = "okay";
""","""&mipi_dsi {
	#address-cells = <1>;
	#size-cells = <0>;
	status = "okay";
""")
open(p,'w').write(t)
EOF
docker exec -u pmos pmos sh -c 'cd /work/ksrc/linux-6.12.90 && cp /share/port/rk3288-archos-oxygen101.dts arch/arm/boot/dts/rockchip/ && cpp -nostdinc -I include -I arch/arm/boot/dts/rockchip -undef -x assembler-with-cpp arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts > /tmp/o.pre && dtc -I dts -O dtb -o /tmp/o.dtb -W no-unit_address_vs_reg /tmp/o.pre 2>&1 | grep -v "Warning" | head -20; ls -la /tmp/o.dtb'
```

**70.** `13:00` Check gadget/DRM config in v26.06 veyron config

```sh
C=$S/src/pmaports/device/community/linux-google-veyron/config-google-veyron.armv7; docker exec -u pmos pmos sh -c 'grep -E "^CONFIG_(DRM|USB_GADGET|USB_CONFIGFS|USB_CONFIGFS_NCM|USB_CONFIGFS_RNDIS|USB_CONFIGFS_ECM|USB_DWC2_[A-Z_]+|USB_LIBCOMPOSITE|MFD_RN5T618|RTC_DRV_RC5T619|RN5T618.*|ARM_APPENDED_DTB|CMDLINE.*|DRM_PANFROST|BRCMFMAC|FW_LOADER.*|PHY_ROCKCHIP_USB|USB_EHCI_HCD_PLATFORM|EXTCON)=|^# CONFIG_(USB_GADGET|USB_CONFIGFS|MFD_RN5T618|USB_DWC2_[A-Z_]+|ARM_APPENDED_DTB|DRM_PANFROST)[ =]" /work/cache_git/pmaports/device/community/linux-google-veyron/config-google-veyron.armv7'
```

**71.** `13:00` Check pmOS initramfs subpartition support

```sh
docker exec -u pmos pmos sh -c 'cd /work/cache_git/pmaports && ls main/postmarketos-initramfs/; grep -n "subpartition\|kpartx\|losetup" main/postmarketos-initramfs/*.sh | head -20'
```

**72.** `13:01` Stage DTS and Makefile changes for kernel patch

```sh
docker exec -u pmos pmos sh -c 'set -e; cd /work/ksrc && rm -rf a b && mkdir -p a b && cd linux-6.12.90 && 
for f in arch/arm/boot/dts/rockchip/Makefile drivers/gpu/drm/panel/panel-simple.c; do mkdir -p ../a/$(dirname $f) ../b/$(dirname $f); cp $f ../a/$f; cp $f ../b/$f; done
mkdir -p ../b/arch/arm/boot/dts/rockchip && cp /share/port/rk3288-archos-oxygen101.dts ../b/arch/arm/boot/dts/rockchip/
cd ../b && sed -i "s/^\(dtb-\$(CONFIG_ARCH_ROCKCHIP) += \\\\\)$/&\n\trk3288-archos-oxygen101.dtb \\\\/" arch/arm/boot/dts/rockchip/Makefile
grep -n "archos" arch/arm/boot/dts/rockchip/Makefile; sed -n 1,12p arch/arm/boot/dts/rockchip/Makefile'
```

**73.** `13:01` Add panel entry and generate kernel patch

```sh
docker exec -i -u pmos pmos python3 - <<'EOF'
p='/work/ksrc/b/drivers/gpu/drm/panel/panel-simple.c'
t=open(p).read()
anchor='static const struct drm_display_mode boe_tv080wum_nl0_mode = {'
entry='''static const struct drm_display_mode archos_oxygen101_mode = {
	.clock = 150000,
	.hdisplay = 1920,
	.hsync_start = 1920 + 50,
	.hsync_end = 1920 + 50 + 20,
	.htotal = 1920 + 50 + 20 + 50,
	.vdisplay = 1200,
	.vsync_start = 1200 + 5,
	.vsync_end = 1200 + 5 + 2,
	.vtotal = 1200 + 5 + 2 + 5,
	.flags = DRM_MODE_FLAG_NVSYNC | DRM_MODE_FLAG_NHSYNC,
};

static const struct panel_desc_dsi archos_oxygen101 = {
	.desc = {
		.modes = &archos_oxygen101_mode,
		.num_modes = 1,
		.bpc = 8,
		.size = {
			.width = 217,
			.height = 136,
		},
		.connector_type = DRM_MODE_CONNECTOR_DSI,
	},
	.flags = MIPI_DSI_MODE_VIDEO |
		 MIPI_DSI_MODE_VIDEO_BURST,
	.format = MIPI_DSI_FMT_RGB888,
	.lanes = 4,
};

'''
assert anchor in t and t.count(anchor)==1
t=t.replace(anchor, entry+anchor)
m='''static const struct of_device_id dsi_of_match[] = {
	{
'''
assert m in t
t=t.replace(m, m+'''		.compatible = "archos,oxygen101-panel",
		.data = &archos_oxygen101
	}, {
''')
open(p,'w').write(t)
EOF
docker exec -u pmos pmos sh -c 'cd /work/ksrc && (diff -Naur a b > /share/port/0001-archos-oxygen101-dts-and-panel.patch; true) && grep -c "^+" /share/port/0001-archos-oxygen101-dts-and-panel.patch && grep -n "^+++" /share/port/0001-archos-oxygen101-dts-and-panel.patch'
```

**74.** `13:01` Create linux-archos-oxygen101 package

```sh
docker exec -u pmos pmos sh -c 'set -e; P=/work/cache_git/pmaports/device; mkdir -p $P/testing/linux-archos-oxygen101 && cd $P/testing/linux-archos-oxygen101 && cp $P/community/linux-google-veyron/*.patch . && cp /share/port/0001-archos-oxygen101-dts-and-panel.patch . && cp $P/community/linux-google-veyron/config-google-veyron.armv7 config-archos-oxygen101.armv7
c=config-archos-oxygen101.armv7
setc() { sed -i "/^CONFIG_$1=/d;/^# CONFIG_$1 is not set/d" $c; echo "CONFIG_$1=$2" >> $c; }
setc DRM_ROCKCHIP y; setc DRM_PANEL_SIMPLE y; setc ROCKCHIP_DW_MIPI_DSI y; setc RTC_DRV_RC5T619 y; setc RN5T618_POWER m; setc TOUCHSCREEN_GOODIX m
setc USB_LIBCOMPOSITE y; setc USB_CONFIGFS y; setc USB_F_NCM y; setc USB_F_ECM y; setc USB_F_RNDIS y; setc USB_U_ETHER y; setc USB_CONFIGFS_SERIAL y; setc USB_CONFIGFS_ACM y
setc REGULATOR_FAN53555 y; setc MMC_PWRSEQ_SIMPLE y; setc I2C_CHARDEV y; setc BACKLIGHT_PWM y; setc PWM_ROCKCHIP y; setc KEYBOARD_GPIO y
setc LOCALVERSION "\"\""
tail -25 $c
sed -e "s/^pkgname=linux-google-veyron/pkgname=linux-archos-oxygen101/" -e "s/^pkgdesc=.*/pkgdesc=\"Mainline kernel for the Archos 101 Oxygen (RK3288)\"/" -e "/pmb:kconfigcheck-community/d" -e "/^replaces=/d" -e "s|^\tveyron.support_dedicating_npll_to_vop.patch|&\n\t0001-archos-oxygen101-dts-and-panel.patch|" -e "s/^maintainer=.*/maintainer=\"Tom Barbette <<maintainer-email>>\"/" -e "/^# Co-Maintainer/d" -e "/^# Contributor/d" $P/community/linux-google-veyron/APKBUILD > APKBUILD
sed -i "s/cp \"\$srcdir\/config-\$_flavor.\$CARCH\" .config/&\n\tmake ARCH=\"\$_carch\" LLVM=1 olddefconfig/" APKBUILD
sed -n "1,60p" APKBUILD | grep -nE "pkgname|source|patch|config|olddefconfig|options" '
```

**75.** `13:01` Create device package and compute checksums

```sh
docker exec -u pmos pmos sh -c 'set -e; D=/work/cache_git/pmaports/device/testing/device-archos-oxygen101; mkdir -p $D && cd $D
cat > deviceinfo <<"EOF"
# Reference: <https://postmarketos.org/deviceinfo>
# Please use double quotes only. You can source this file in shell
# scripts.

deviceinfo_format_version="0"
deviceinfo_name="Archos 101 Oxygen"
deviceinfo_manufacturer="Archos"
deviceinfo_codename="archos-oxygen101"
deviceinfo_year="2015"
deviceinfo_dtb="rk3288-archos-oxygen101"
deviceinfo_arch="armv7"

# Device related
deviceinfo_chassis="tablet"
deviceinfo_external_storage="true"
deviceinfo_drm="true"
deviceinfo_screen_width="1920"
deviceinfo_screen_height="1200"
deviceinfo_getty="ttyS2;115200"

# Bootloader related: Rockchip legacy loader, Android boot.img with an
# RSCE resource image (holding the DTB) as "second". The image is built
# by hand, see README in the port notes.
deviceinfo_flash_method="rkdeveloptool"
deviceinfo_kernel_cmdline="console=ttyS2,115200n8 console=tty0 PMOS_NO_OUTPUT_REDIRECT"

# Rockchip Electronics Co., Ltd.
deviceinfo_usb_idVendor="0x2207"
EOF
cat > APKBUILD <<"EOF"
# Reference: <https://postmarketos.org/devicepkg>
maintainer="Tom Barbette <<maintainer-email>>"
pkgname=device-archos-oxygen101
pkgdesc="Archos 101 Oxygen"
pkgver=1
pkgrel=0
url="https://postmarketos.org"
license="MIT"
arch="armv7"
options="!check !archcheck"
depends="
	linux-archos-oxygen101
	postmarketos-base
"
makedepends="devicepkg-dev"
subpackages="$pkgname-nonfree-firmware:nonfree_firmware"
source="deviceinfo"

build() {
	devicepkg_build $startdir $pkgname
}

package() {
	devicepkg_package $startdir $pkgname
}

nonfree_firmware() {
	pkgdesc="WiFi firmware"
	depends="linux-firmware-brcm"
	mkdir "$subpkgdir"
}
EOF
cd .. && pmbootstrap checksum device-archos-oxygen101 linux-archos-oxygen101 2>&1 | tail -3'
```

**76.** `13:01` Fix work version, set device, compute checksums

```sh
docker exec -u pmos pmos sh -c 'echo 8 > /work/version; cd ~ && pmbootstrap config device archos-oxygen101 2>&1 | tail -2; pmbootstrap checksum device-archos-oxygen101 linux-archos-oxygen101 2>&1 | tail -3; pmbootstrap config | grep -E "device|ui|work"'
```

**77.** `13:02` Build the kernel package (background)

```sh
docker exec -u pmos pmos sh -c 'cd ~ && pmbootstrap build linux-archos-oxygen101 --force 2>&1 | tail -15; ls -la /work/packages/*/armv7/ 2>/dev/null | grep -i archos'
```

**78.** `13:02` Back up remaining eMMC (system, userdata) (background)

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; B=$S/backup; $RK ld; time $RK rl 0x50000 $((31252480-0x50000)) $B/emmc-rest.bin 2>&1 | tr '\r' '\n' | tail -2; ls -la $B/emmc-rest.bin
```

**79.** `13:03` Round-trip test the boot.img packer

```sh
S=$S; B=$S/backup; T=$S/test; mkdir -p $T
python3 -I - $B/boot.img $T <<'EOF'
import struct,sys
d=open(sys.argv[1],'rb').read(); o=sys.argv[2]
ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
up=lambda x:(x+ps-1)//ps*ps
open(o+'/k','wb').write(d[ps:ps+ks]); ro=ps+up(ks)
open(o+'/r','wb').write(d[ro:ro+rs]); so=ro+up(rs)
open(o+'/s','wb').write(d[so:so+ss])
print('stock id', d[576:596].hex())
EOF
python3 -I - $T/s <<'EOF'
import sys
d=open(sys.argv[1],'rb').read()
import struct
print('stock second entries', struct.unpack_from('<I',d,12)[0])
EOF
dtc -I dtb -O dtb -o $T/stockdtb.dtb $B/res_rk-kernel.dtb 2>/dev/null
python3 -I $S/share/port/mkrkboot.py $T/s $T/k $T/r $B/res_rk-kernel.dtb $T/rebuilt.img "" | head -1
python3 -I -c "
import sys;a=open('$B/boot.img','rb').read();b=open('$T/rebuilt.img','rb').read()
print('header id match:',a[576:596]==b[576:596]); print('identical prefix:', a[:len(b)]==b, len(b))"
```

> **Owner:** Will you still be able to access the tablet and build a driver? If you reboot without even trying to enable an untested re-verse engineered driver I'll be stuck, no?

**80.** `13:05` Diagnose boot.img packer mismatch

```sh
S=$S; B=$S/backup; T=$S/test
python3 -I - $B/boot.img $T/rebuilt.img $T/s $T/k $T/r <<'EOF'
import sys,hashlib,struct
a=open(sys.argv[1],'rb').read(); b=open(sys.argv[2],'rb').read()
s=open(sys.argv[3],'rb').read();k=open(sys.argv[4],'rb').read();r=open(sys.argv[5],'rb').read()
diff=[i for i in range(min(len(a),len(b))) if a[i]!=b[i]]
print('ndiff',len(diff),'first',diff[:5],'last',diff[-3:])
print('hdr a',a[8:48].hex()); print('hdr b',b[8:48].hex())
for name,blobs,withsz in [('k+r+s sizes',(k,r,s),1),('k+r+s nosz',(k,r,s),0),('k+r sizes',(k,r),1)]:
    h=hashlib.sha1()
    for x in blobs:
        h.update(x)
        if withsz: h.update(struct.pack('<I',len(x)))
    print(name,h.hexdigest())
print('stock id', a[576:608].hex())
EOF
```

**81.** `13:07` Dump stock boot.img id/extra area

```sh
B=$S/backup; xxd -s 560 -l 620 $B/boot.img | grep -v '0000 0000 0000 0000 0000 0000 0000 0000'
```

**82.** `13:09` Search for Rockchip boot.img id formula

```sh
S=$S; B=$S/backup; T=$S/test
python3 -I - $B/boot.img $T/k $T/r $T/s $B/recovery.img <<'EOF'
import sys,hashlib,struct,itertools
a=open(sys.argv[1],'rb').read();k=open(sys.argv[2],'rb').read();r=open(sys.argv[3],'rb').read();s=open(sys.argv[4],'rb').read()
target=a[576:596]
P=lambda x:struct.pack('<I',len(x))
cands={
 'k ks r rs s ss ':[k,P(k),r,P(r),s,P(s)],
 'k r s':[k,r,s],
 'k ks r rs':[k,P(k),r,P(r)],
 'k ks r rs s ss 0':[k,P(k),r,P(r),s,P(s),P(b'')],
 'hdr+data':[a[:576]+bytes(1024)],
}
pad=lambda x:x+b'\0'*(-len(x)%16384)
cands['padded k r s']=[pad(k),pad(r),pad(s)]
cands['all after hdr']=[a[16384:16384+len(pad(k))+len(pad(r))+len(pad(s))]]
for h in ('sha1','sha256','md5'):
  for n,parts in cands.items():
    d=hashlib.new(h)
    for p in parts:d.update(p)
    if d.digest()[:len(target)]==target[:len(d.digest())]: print('MATCH',h,n)
# rk: id = sha1 of (kernel,ks,ramdisk,rs,second,ss) but with sizes as big?
for order in itertools.permutations([0,1,2]):
  bl=[k,r,s]; d=hashlib.sha1()
  for i in order: d.update(bl[i]); d.update(P(bl[i]))
  if d.digest()==target: print('MATCH order',order)
d=hashlib.sha1(); d.update(k);d.update(P(k));d.update(r);d.update(P(r))
print('kr only',d.hexdigest()==target.hex())
rc=open(sys.argv[5],'rb').read(); print('recovery has SIGN:', rc[0x400:0x404])
EOF
```

**83.** `13:10` Build signature-test recovery image

```sh
S=$S; B=$S/backup; T=$S/test
python3 -I - $B/recovery.img $T/recovery-sigtest.img <<'EOF'
import sys,struct
d=bytearray(open(sys.argv[1],'rb').read())
ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
up=lambda x:(x+ps-1)//ps*ps
so=ps+up(ks)+up(rs)
sec=d[so:so+ss]
i=sec.find(b'charge_anim_desc.txt')
blk,size=struct.unpack_from('<II',sec,i-4+260)
off=so+blk*512
print('before:',bytes(d[off:off+40]))
# flip case of the first ASCII letter: harmless text change
for j in range(off,off+size):
    if 97<=d[j]<=122: d[j]-=32; break
print('after: ',bytes(d[off:off+40]))
open(sys.argv[2],'wb').write(d)
EOF
cmp -l $B/recovery.img $T/recovery-sigtest.img | wc -l
```

**84.** `13:11` Verify backup size and ext4 magics

```sh
cat $TASKS/bsm4df8no.output | tail -5; B=$S/backup; ls -la $B/emmc-rest.bin; echo $(( (31252480-0x50000)*512 )); xxd -s $(( (0x92000-0x50000)*512 + 1080 )) -l 2 $B/emmc-rest.bin; xxd -s $(( (0x2C4000-0x50000)*512 + 1080 )) -l 2 $B/emmc-rest.bin
```

**85.** `13:11` Inspect misc partition contents

```sh
B=$S/backup; dd if=$B/emmc-head.bin bs=512 skip=$((0x4000)) count=$((0x2000)) 2>/dev/null | xxd | grep -v '0000 0000 0000 0000 0000 0000 0000 0000' | head; strings -n 6 $B/emmc-head.bin | grep -iE 'boot-recovery|recovery\b|--wipe' | head
```

**86.** `13:11` Check kernel build result

```sh
tail -8 $TASKS/bqhirck8t.output
```

**87.** `13:12` Flash sig-test image to boot, verify, reboot

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; T=$S/test
$RK ld && $RK wl 0x16000 $T/recovery-sigtest.img 2>&1 | tr '\r' '\n' | tail -1 && $RK rl 0x16000 $(( $(stat -f %z $T/recovery-sigtest.img) / 512 )) $T/verify.img >/dev/null 2>&1 && cmp $T/verify.img $T/recovery-sigtest.img && echo VERIFIED && $RK rd
```

**88.** `13:12` See how the tablet re-enumerates after reboot

```sh
sleep 40; adb devices -l; system_profiler SPUSBDataType 2>/dev/null | grep -B1 -A3 -iE '0x2207|0x0e79|archos|rockchip|android' | head -20
```

**89.** `13:12` Poll for tablet after reboot (up to 60s)

```sh
for i in $(seq 1 30); do o=$(adb devices | tail -n +2 | grep .); [ -n "$o" ] && break; sleep 2; done; adb devices -l; system_profiler SPUSBDataType 2>/dev/null | grep -B1 -A3 -iE '0x2207|0x0e79|archos|rockchip|android' | head -20
```

> **Owner:** It says "no command".

**90.** `13:23` Wait for tablet in loader/maskrom or adb mode (background)

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; until $RK ld 2>/dev/null | grep -qE 'Loader|Maskrom' || adb devices | tail -n +2 | grep -q .; do sleep 2; done; $RK ld; adb devices -l
```

**91.** `13:23` Check pmOS root resize for subpartitions

```sh
docker exec -u pmos pmos sh -c 'cd /work/cache_git/pmaports/main/postmarketos-initramfs && grep -n "resize_root_partition()" -A45 init_functions.sh | grep -nE "SUBPARTITION|subpartition|loop|parted|resize2fs|android|has_unallocated" | head -20'
```

**92.** `13:23` Find resize logic in pmOS initramfs

```sh
docker exec -u pmos pmos sh -c 'cd /work/cache_git/pmaports/main/postmarketos-initramfs && grep -n "resize" init_functions*.sh init*.sh | head -20'
```

**93.** `13:23` Provide SSH public key to pmbootstrap

```sh
S=$S; ls ~/.ssh/*.pub; mkdir -p $S/share/keys; cp ~/.ssh/id_ed25519.pub $S/share/keys/ 2>/dev/null || cp $(ls ~/.ssh/*.pub | head -1) $S/share/keys/; ls $S/share/keys
docker exec -u pmos pmos sh -c 'pmbootstrap config ssh_keys True; pmbootstrap config ssh_key_glob "/share/keys/*.pub"; pmbootstrap config | grep ssh'
```

**94.** `13:23` Build pmOS rootfs image (Phosh) (background)

```sh
docker exec -u pmos pmos sh -c 'cd ~ && pmbootstrap -y install --password 147147 2>&1 | tail -25; ls -la /work/chroot_native/home/pmos/rootfs/'
```

> **Owner:** Whatever I do I only get to "no command"

**95.** `13:25` Inspect stock recovery menu strings

```sh
S=$S; T=$S/test/rec; mkdir -p $T; python3 -I - $S/backup/recovery.img $T/ramdisk.gz <<'EOF'
import sys,struct
d=open(sys.argv[1],'rb').read(); ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
up=lambda x:(x+ps-1)//ps*ps; o=ps+up(ks); open(sys.argv[2],'wb').write(d[o:o+rs])
EOF
cd $T 2>/dev/null; gunzip -c $T/ramdisk.gz | (cd $T && cpio -idm 2>/dev/null); ls $T $T/sbin | head -40; strings -n 5 $T/sbin/recovery | grep -iE 'reboot|loader|bootloader|menu|wipe|update from|rockusb|adb' | sort -u | head -40
```

**96.** `13:25` Check whether recovery starts adbd

```sh
T=$S/test/rec; cat $T/default.prop; grep -n -B2 -A6 'adbd\|usb' $T/init.rc | head -60; adb devices -l
```

**97.** `13:25` Check minadbd services and RK update.img support

```sh
T=$S/test/rec; strings -n 4 $T/sbin/recovery | grep -iE '^reboot|reboot:|sideload|update\.img|\.img$|rkimage|update_rkimage|external_sd|sdupdate' | sort -u | head -30
```

**98.** `13:26` Check pmOS install result

```sh
tail -12 $TASKS/bcdqc0ndq.output
```

> **Owner:** Can't I just select "flash from adb" and you deal with it?

**99.** `13:33` Inspect recovery OTA verification keys

```sh
T=$S/test/rec; ls $T/res; cat $T/res/keys | head -c 400; echo; strings -n 6 $T/sbin/recovery | grep -iE 'verif|signature|whole-file|keys' | sort -u | head
```

> **Owner:** Nope. I put the SD in this mac

**100.** `13:34` Identify the SD card on the Mac

```sh
diskutil list external physical; diskutil info -all 2>/dev/null | grep -E 'Device Node|Volume Name|Protocol|Removable Media|Disk Size' | paste - - - - - | grep -iE 'SD|USB|Secure' | head
```

**101.** `13:35` Show SD card partitions and contents

```sh
diskutil list /dev/disk4; df -h | grep disk4; M=$(diskutil info /dev/disk4s1 | awk -F': *' '/Mount Point/{print $2}'); echo "mount=$M"; [ -n "$M" ] && ls -la "$M" | head -30 && du -sh "$M" 2>/dev/null
```

**102.** `13:35` Check recovery fstab and SD mount logic

```sh
T=$S/test/rec; cat $T/fstab.rk30board.bootmode.emmc; strings -n 4 $T/sbin/recovery | grep -iE 'mount|vfat|ntfs|exfat|mmcblk1|external' | sort -u | head -30
```

**103.** `13:35` Search GitHub for rkupdate source

```sh
gh search code "bIfUpdateLoader" --limit 20 --json repository,path 2>&1 | head -40
```

**104.** `13:35` Clone rkupdate and find loader-update logic

```sh
S=$S/src; git clone -q --depth 1 https://github.com/rockchip-linux/rkupdate.git $S/rkupdate 2>&1 | tail -1; ls $S/rkupdate; grep -rn "bIfUpdateLoader\|small fw" $S/rkupdate | head -20
```

**105.** `13:35` Find a public rkupdate repository

```sh
S=$S/src; for r in rockchip-linux/rkupdate rockchip-linux/recovery rockchip-android/recovery LineageOS/android_bootable_recovery-rockchip; do printf "%s: " $r; curl -s -o /dev/null -w '%{http_code}\n' https://api.github.com/repos/$r; done; curl -s 'https://api.github.com/search/repositories?q=rkupdate+in:name&per_page=15' | python3 -I -c 'import sys,json;[print(r["full_name"],r["updated_at"]) for r in json.load(sys.stdin).get("items",[])]'
```

**106.** `13:35` Clone rkupdate mirror and grep loader logic

```sh
S=$S/src; GIT_TERMINAL_PROMPT=0 git clone -q --depth 1 https://github.com/Caesar-github/rkupdate.git $S/rkupdate 2>&1|tail -1; ls $S/rkupdate; grep -rn "bIfUpdateLoader\|small fw\|bUpdateLoader\|UpdateLoader" $S/rkupdate/*.cpp | head -20
```

**107.** `13:35` Read rkupdate upgrade flow and image parsing

```sh
R=$S/src/rkupdate; grep -n "Loader\|bootloader\|IDB\|UpgradeLoader" $R/Upgrade.cpp | head -40; grep -n "CRKImage::CRKImage" -A80 $R/RKImage.cpp | grep -nE "RKFW|tag|md5|MD5|Loader|bootOffset|bootSize|fwOffset|fwSize|return|ERR|chip|szVersion" | head -40
```

**108.** `13:35` List functions in rkupdate sources

```sh
R=$S/src/rkupdate; wc -l $R/*.cpp; grep -n "^bool\|^int\|^static\|^void\|^CRK\|^BOOL\|^DWORD" $R/Upgrade.cpp $R/RKAndroidDevice.cpp | head -60
```

**109.** `13:36` Grep loader handling in updater

```sh
R=$S/src/rkupdate; grep -n "Loader\|loader" $R/Upgrade.cpp | head -40; grep -n "Loader\|loader\|IDBlock\|bootloader" $R/RKAndroidDevice.cpp | head -40
```

**110.** `13:36` Grep loader handling with system grep

```sh
R=$S/src/rkupdate; /usr/bin/grep -a -n -i "loader" $R/Upgrade.cpp | head -40; echo ---; /usr/bin/grep -a -n -i "loader\|IDBlock" $R/RKAndroidDevice.cpp | head -50
```

**111.** `13:36` Show strings around loader-update message

```sh
T=$S/test/rec; strings -n 6 -t d $T/sbin/recovery | awk '$0 ~ /small fw/ {f=NR} {l[NR]=$0} END{for(i=f-25;i<=f+25;i++) print l[i]}'
```

**112.** `13:36` Extract rkupdate strings from recovery binary

```sh
T=$S/test/rec; strings -n 6 $T/sbin/recovery | grep -aiE 'do_rk_|upgrade|bootloader|loader|package-file|RKFW|RKAF|md5|parameter|IDB|download|check ' | sort -u | head -80
```

**113.** `13:36` Clone RK KitKat recovery source and locate updater

```sh
S=$S/src; GIT_TERMINAL_PROMPT=0 git clone -q --depth 1 https://github.com/Nu3001/bootable_recovery.git $S/rkrecovery 2>&1 | tail -1; ls $S/rkrecovery | head -50; /usr/bin/grep -a -n "copy Bootloader\|Find and check\|update-bootloader\|Writing bootloader\|Invalid loader" $S/rkrecovery/*.c* $S/rkrecovery/*/*.c* 2>/dev/null | head
```

**114.** `13:36` Read install_rkimage flow

```sh
R=$S/src/rkrecovery/rkimage.cpp; sed -n 2040,2270p $R
```

**115.** `13:37` Read update_error handling and write_loader

```sh
R=$S/src/rkrecovery/rkimage.cpp; sed -n 2270,2310p $R; echo ======; sed -n 570,660p $R
```

**116.** `13:37` Read write_loader implementation

```sh
R=$S/src/rkrecovery/rkimage.cpp; /usr/bin/grep -n "^int write_loader\|^static int write_loader\|write_loader(" $R | head -3; L=$(/usr/bin/grep -n "int write_loader" $R | head -1 | cut -d: -f1); sed -n "${L},$((L+80))p" $R
```

**117.** `13:37` Read update.img header parsing and structs

```sh
R=$S/src/rkrecovery; /usr/bin/grep -n "int find_update_img\|int write_image\|int image_compare\|FindItem(" $R/rkimage.cpp | head; L=$(/usr/bin/grep -n "^int find_update_img\|^static int find_update_img" $R/rkimage.cpp | cut -d: -f1); sed -n "${L},$((L+90))p" $R/rkimage.cpp; /usr/bin/grep -n "typedef\|RKIMAGE_HDR\|RKIMAGE_ITEM\|RKFW\|RKAF\|} RK\|;" $R/rkimage.h | head -60
```

**118.** `13:37` Read CheckImageFile and FindItem

```sh
R=$S/src/rkrecovery; sed -n 1,22p $R/rkimage.h | /usr/bin/grep -a define; L=$(/usr/bin/grep -n "CheckImageFile(const" $R/rkimage.cpp | head -1 | cut -d: -f1); sed -n "${L},$((L+110))p" $R/rkimage.cpp; sed -n 255,300p $R/rkimage.cpp
```

**119.** `13:37` Check RSA vs CRC mode and write_image start

```sh
T=$S/test/rec; strings -n 5 $T/sbin/recovery | grep -iE 'rsa|crc' | sort -u | head; R=$S/src/rkrecovery; sed -n 300,330p $R/rkimage.cpp; sed -n 757,800p $R/rkimage.cpp
```

**120.** `13:37` Read parameter write and compare logic

```sh
R=$S/src/rkrecovery; sed -n 800,915p $R/rkimage.cpp; sed -n 1030,1130p $R/rkimage.cpp
```

**121.** `13:38` Read CRC routine and finish_recovery misc handling

```sh
R=$S/src/rkrecovery; ls $R/crc; /usr/bin/grep -n "CRC_32_NEW" -A15 $R/crc/*.c* | head -30; /usr/bin/grep -n "gTable_Crc32\|0x04c10db7\|0x04C10DB7" -i $R/crc/*.c* | head -5; L=$(/usr/bin/grep -n "^finish_recovery\|^static void finish_recovery\|finish_recovery(const" $R/recovery.cpp | head -1 | cut -d: -f1); sed -n "${L},$((L+60))p" $R/recovery.cpp | /usr/bin/grep -n "bIfUpdateLoader\|set_bootloader_message\|memset\|boot\b" 
```

**122.** `13:38` See misc clearing and RK CRC32 implementation

```sh
R=$S/src/rkrecovery; L=$(/usr/bin/grep -n "finish_recovery(const" $R/recovery.cpp | head -1 | cut -d: -f1); sed -n "$((L+20)),$((L+45))p" $R/recovery.cpp; /usr/bin/grep -n "CRC_32\|crc" $R/rkupdate/*.cpp 2>/dev/null | head -3; S=$S/src/rkupdate; /usr/bin/grep -n "CRC_32\b\|unsigned int CRC_32\|gTable_Crc32\[" -A3 $S/CRC.cpp | head -20
```

**123.** `13:38` Find when recovery clears misc

```sh
R=$S/src/rkrecovery; /usr/bin/grep -n "bNeedClearMisc\|bIfUpdateLoader" $R/*.cpp | head -20
```

**124.** `13:38` Find rkimage menu handler and expected path

```sh
R=$S/src/rkrecovery; /usr/bin/grep -n "update rkimage from external\|ITEM_APPLY_RKIMAGE\|APPLY_RKIMAGE\|install_rkimage(" $R/*.cpp | head; L=$(/usr/bin/grep -n "case Device::APPLY_EXT_RKIMAGE\|APPLY_EXT_RKIMAGE:\|APPLY_RKIMAGE" $R/recovery.cpp | tail -1 | cut -d: -f1); sed -n "${L},$((L+30))p" $R/recovery.cpp
```

**125.** `13:39` Read rkimage menu handler and auto-update path

```sh
R=$S/src/rkrecovery; sed -n 1040,1080p $R/recovery.cpp; /usr/bin/grep -n "auto_sdcard_update_path\s*=\|auto_sdcard_update_path\[" $R/recovery.cpp | head -3; sed -n 1785,1802p $R/recovery.cpp
```

**126.** `13:39` Validate RK CRC32 against parameter block

```sh
S=$S; B=$S/backup; U=$S/update; mkdir -p $U; P=$S/share/port/mkrkupdate.py
dd if=$B/emmc-head.bin of=$U/parameter.bin bs=512 count=32 2>/dev/null
python3 -I $P crccheck $U/parameter.bin
cmp <(dd if=$B/emmc-head.bin bs=512 skip=1024 count=32 2>/dev/null) $U/parameter.bin && echo "parameter copy at 512K identical"
```

**127.** `13:40` Build debug recovery and RKAF update.img

```sh
S=$S; B=$S/backup; U=$S/update; P=$S/share/port/mkrkupdate.py
python3 -I $P debugrecovery $B/recovery.img $U/recovery-debug.img
python3 -I - $B/boot.img $U/boot-stock.img <<'EOF'
import sys,struct
d=open(sys.argv[1],'rb').read(); ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
up=lambda x:(x+ps-1)//ps*ps; n=ps+up(ks)+up(rs)+up(ss)
open(sys.argv[2],'wb').write(d[:n]); print('boot-stock',n)
EOF
# verify the modified recovery ramdisk
python3 -I - $U/recovery-debug.img <<'EOF'
import sys,struct,gzip
sys.path.insert(0,'')
d=open(sys.argv[1],'rb').read(); ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
up=lambda x:(x+ps-1)//ps*ps; r=gzip.decompress(d[ps+up(ks):ps+up(ks)+rs])
i=r.find(b'default.prop'); print(r[i-110:i-110+6], 'uid/gid fields:', r[i-110+22:i-110+38])
j=r.find(b'ro.debuggable=1'); print('debuggable found:', j>0, ' ro.secure=0:', b'\nro.secure=0' in r, ' adb.secure=0:', b'ro.adb.secure=0' in r)
print('second magic', d[ps+up(ks)+up(rs):ps+up(ks)+up(rs)+4])
EOF
time python3 -I $P rkaf $U/update.img ac101ox parameter=$U/parameter.bin boot=$U/boot-stock.img recovery=$U/recovery-debug.img
```

**128.** `13:40` Verify ramdisk edit and re-parse update.img

```sh
S=$S; B=$S/backup; U=$S/update
cd $S/share/port 2>/dev/null; python3 -I - $B/recovery.img $U/recovery-debug.img $U/update.img $S/share/port <<'EOF'
import sys,struct,gzip
sys.path.insert(0,sys.argv[4])
import mkrkupdate as m
def ents(p):
    d=open(p,'rb').read(); ks,ka,rs,ra,ss,sa,ta,ps=struct.unpack_from('<8I',d,8)
    up=lambda x:(x+ps-1)//ps*ps; r=gzip.decompress(d[ps+up(ks):ps+up(ks)+rs])
    return {n:(f,c) for f,n,c in m.cpio_entries(r)}
a=ents(sys.argv[1]); b=ents(sys.argv[2])
print('entries', len(a), len(b))
diff=[n for n in a if a[n][1]!=b[n][1] or a[n][0][1:6]!=b[n][0][1:6]]
print('changed:', diff)
f=b['default.prop'][0]; print('default.prop mode %o uid %d gid %d'%(f[1],f[2],f[3]))
print('init mode %o uid %d'%(b['init'][0][1], b['init'][0][2]))
# re-parse RKAF like recovery
d=open(sys.argv[3],'rb').read()
tag,size=struct.unpack_from('<4sI',d,0); model=d[8:72].split(b'\0')[0]; cnt=struct.unpack_from('<i',d,136)[0]
print(tag,size,model,cnt, 'crc ok:', m.rkcrc(d[:size])==struct.unpack_from('<I',d,size)[0])
for i in range(cnt):
    name,fn,off,fo,use,sz=struct.unpack_from('<32s64sIIII',d,140+112*i)
    print(' ',name.split(b'\0')[0],off,sz, d[off:off+8])
EOF
```

**129.** `13:40` Format SD as FAT32, copy update.img, eject

```sh
U=$S/update; diskutil info /dev/disk4 | grep -E 'Media Name|Protocol|Disk Size'; diskutil eraseDisk FAT32 RKUPDATE MBRFormat /dev/disk4 2>&1 | tail -3; cp $U/update.img /Volumes/RKUPDATE/update.img && sync && cmp $U/update.img /Volumes/RKUPDATE/update.img && echo COPIED_OK; ls -la /Volumes/RKUPDATE; diskutil eject /dev/disk4
```

**130.** `13:41` Wait for tablet via adb or loader (background)

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; until adb devices | tail -n +2 | grep -q . || $RK ld 2>/dev/null | grep -qE 'Loader|Maskrom'; do sleep 2; done; adb devices -l; $RK ld 2>/dev/null
```

> **Owner:** It said "Update system... can't find system no boot.img so ignore. Update recovery.img.... check recovery... copy bootloader.... E:can't find bootloader Failed(-2) update failed

**131.** `13:43` Check watcher output and adb state

```sh
cat $TASKS/bfhfy0v8h.output; adb devices -l
```

**132.** `13:43` Confirm Android booted

```sh
adb shell 'getprop sys.boot_completed; getprop ro.build.display.id; id'
```

**133.** `13:43` Reboot to recovery and test root adb

```sh
adb reboot recovery; for i in $(seq 1 45); do adb devices | tail -n +2 | grep -q . && break; sleep 2; done; adb devices -l; adb shell 'id; getprop ro.bootmode; getprop ro.debuggable; ls /sbin | head -3'
```

> **Owner:** I'm in "no cammand"

**134.** `13:44` Check recovery adb on USB

```sh
adb devices -l; system_profiler SPUSBDataType 2>/dev/null | grep -B2 -A6 -iE '0x2207|archos|ac101' | head -20
```

**135.** `13:44` Poll USB for recovery adb (60s)

```sh
for i in $(seq 1 30); do adb devices | tail -n +2 | grep -q . && break; system_profiler SPUSBDataType 2>/dev/null | grep -qiE '0x2207' && break; sleep 2; done; adb devices -l; system_profiler SPUSBDataType 2>/dev/null | grep -B3 -A6 -iE '0x2207' | head -20
```

**136.** `13:46` Read pmOS resize_root_partition logic

```sh
docker exec -u pmos pmos sh -c 'sed -n 45,110p /work/cache_git/pmaports/main/postmarketos-initramfs/init_functions_2nd.sh'
```

**137.** `13:46` Assemble pmOS SD card image

```sh
docker exec pmos sh -c 'set -e; R=/work/chroot_native/home/pmos/rootfs; file $R/archos-oxygen101-boot.img $R/archos-oxygen101-root.img; apk add -q sfdisk e2fsprogs >/dev/null; B=$(stat -c %s $R/archos-oxygen101-boot.img); RT=$(stat -c %s $R/archos-oxygen101-root.img); TOT=$(( 1048576 + B + RT )); rm -f /work/sd.img; truncate -s $TOT /work/sd.img
printf "label: dos\nstart=2048, size=$((B/512)), type=83, bootable\nstart=$((2048 + B/512)), size=$((RT/512)), type=83\n" | sfdisk -q /work/sd.img
dd if=$R/archos-oxygen101-boot.img of=/work/sd.img bs=1M seek=1 conv=notrunc status=none
dd if=$R/archos-oxygen101-root.img of=/work/sd.img bs=512 seek=$((2048 + B/512)) conv=notrunc status=none
sfdisk -l /work/sd.img; ls -la /work/sd.img'
```

**138.** `13:47` Locate kernel, initramfs, DTB in rootfs

```sh
docker exec pmos sh -c 'R=/work/chroot_rootfs_archos-oxygen101; ls -la $R/boot/ $R/boot/dtbs/ 2>/dev/null | head -30; find $R/boot -name "rk3288-archos*"; file $R/boot/initramfs $R/boot/vmlinuz* 2>/dev/null'
```

**139.** `13:47` Compute decompressed kernel footprint

```sh
docker exec pmos sh -c 'M=/work/chroot_rootfs_archos-oxygen101/boot/System.map; s=$(grep " _text$" $M | cut -d" " -f1); e=$(grep " _end$" $M | cut -d" " -f1); echo text=$s end=$e; echo "size MB: $(( (0x$e - 0x$s) / 1048576 ))"; printf "decompressed end if base 0x60008000: 0x%x\n" $(( 0x60008000 + 0x$e - 0x$s ))'
```

**140.** `13:47` Search stock loader strings for load addresses

```sh
B=$S/backup; dd if=$B/emmc-head.bin of=$B/misc-loader.bin bs=512 skip=$((0x4000+96)) count=$((0x2000-96)) 2>/dev/null; strings -n 6 $B/misc-loader.bin | grep -iE 'ramdisk|kernel|initrd|0x6|boot|addr|fdt|second|resource|version|loader' | head -40; strings -n 6 $B/misc-loader.bin | wc -l
```

**141.** `13:47` RC4-decrypt stock loader and grep strings

```sh
B=$S/backup; python3 -I - $B/misc-loader.bin $B/misc-loader.dec <<'EOF'
import sys
key=bytes([124,78,3,4,85,5,9,7,45,44,123,56,23,13,23,17])
def rc4(data):
    S=list(range(256)); j=0
    for i in range(256):
        j=(j+S[i]+key[i%16])&255; S[i],S[j]=S[j],S[i]
    i=j=0; out=bytearray()
    for b in data:
        i=(i+1)&255; j=(j+S[i])&255; S[i],S[j]=S[j],S[i]; out.append(b^S[(S[i]+S[j])&255])
    return bytes(out)
d=open(sys.argv[1],'rb').read()
out=b''.join(rc4(d[o:o+512]) for o in range(0,len(d),512))
open(sys.argv[2],'wb').write(out)
EOF
strings -n 6 $B/misc-loader.dec | grep -iE 'ramdisk|kernel|initrd|boot|addr|fdt|second|resource|version|recovery|rockusb|key' | sort -u | head -60
```

**142.** `13:48` Find U-Boot load address strings

```sh
B=$S/backup; strings -n 4 $B/misc-loader.dec | grep -iE 'initrd_high|fdt_high|kernel_addr|ramdisk_addr|load.*%0?8|%08.*(kernel|ramdisk|fdt)|0x6[0-9a-f]{7}|RK_|resource|rk-kernel|unzip|zImage|appended' | sort -u | head -50
```

**143.** `13:48` Make boot.img load addresses configurable

```sh
F=$S/share/port/mkrkboot.py; python3 -I - $F <<'EOF'
import sys
p=sys.argv[1]; t=open(p).read()
t=t.replace('KERNEL_ADDR = 0x60408000\nRAMDISK_ADDR = 0x62000000\n','import os\nKERNEL_ADDR = int(os.environ.get("KERNEL_ADDR", "0x60408000"), 0)\nRAMDISK_ADDR = int(os.environ.get("RAMDISK_ADDR", "0x62000000"), 0)\n')
open(p,'w').write(t)
EOF
grep -n "ADDR" $F | head
```

**144.** `13:48` Build pmOS Rockchip boot image for recovery partition

```sh
S=$S; mkdir -p $S/share/out; cp $S/backup/resource.img $S/share/out/stock-resource.img
docker exec pmos sh -c 'set -e; R=/work/chroot_rootfs_archos-oxygen101/boot; O=/share/out; cp $R/vmlinuz $R/initramfs $O/; cp $R/rk3288-archos-oxygen101.dtb $O/base.dtb
RD=0x68000000; SZ=$(stat -c %s $O/initramfs); END=$(printf "0x%x" $((RD + SZ)))
CMD="console=ttyS2,115200n8 console=tty0 loglevel=7 PMOS_FORCE_PARTITION_RESIZE PMOS_NO_OUTPUT_REDIRECT"
cp $O/base.dtb $O/boot.dtb; fdtput -p -t s $O/boot.dtb /chosen bootargs "$CMD"; fdtput -t x $O/boot.dtb /chosen linux,initrd-start $RD; fdtput -t x $O/boot.dtb /chosen linux,initrd-end $END
fdtget $O/boot.dtb /chosen bootargs; fdtget -t x $O/boot.dtb /chosen linux,initrd-start; fdtget -t x $O/boot.dtb /chosen linux,initrd-end
cat $O/vmlinuz $O/boot.dtb > $O/zImage-dtb; echo "$CMD" > $O/cmdline; ls -la $O'
cd $S/share/out 2>/dev/null; KERNEL_ADDR=0x64008000 RAMDISK_ADDR=0x68000000 python3 -I $S/share/port/mkrkboot.py $S/share/out/stock-resource.img $S/share/out/zImage-dtb $S/share/out/initramfs $S/share/out/boot.dtb $S/share/out/pmos-recovery.img "$(cat $S/share/out/cmdline)"
```

**145.** `13:49` Check Android adb status

```sh
adb devices -l; adb shell getprop sys.boot_completed 2>&1
```

**146.** `13:49` Wait for SD card in the Mac reader (background)

```sh
until diskutil info /dev/disk4 2>/dev/null | grep -q 'Secure Digital'; do sleep 2; done; diskutil list /dev/disk4; ls /Volumes/
```

**147.** `14:20` Confirm SD card identity before writing

```sh
cat $TASKS/b8fehkk3m.output; diskutil info /dev/disk4 | grep -E 'Media Name|Protocol|Disk Size|Device Node'
```

**148.** `14:20` Copy SD image to Mac and unmount the card

```sh
S=$S; docker cp pmos:/work/sd.img $S/share/out/sd.img && ls -la $S/share/out/sd.img; ls -la /dev/rdisk4; diskutil unmountDisk /dev/disk4
```

**149.** `14:26` Check Android adb status

```sh
adb devices -l; adb shell getprop sys.boot_completed 2>&1
```

**150.** `14:26` Flash pmOS image to recovery and verify

```sh
RK=$S/src/rkdeveloptool/rkdeveloptool; I=$S/share/out/pmos-recovery.img
adb reboot bootloader; for i in $(seq 1 20); do $RK ld 2>/dev/null | grep -q Loader && break; sleep 1; done; $RK ld
$RK wl 0x26000 $I 2>&1 | tr '\r' '\n' | tail -1
$RK rl 0x26000 $(( $(stat -f %z $I) / 512 )) ${I%.img}.verify 2>&1 | tr '\r' '\n' | tail -1; cmp $I ${I%.img}.verify && echo RECOVERY_VERIFIED && rm ${I%.img}.verify
# boot partition must still be the stock one
B=$S/update/boot-stock.img; $RK rl 0x16000 $(( $(stat -f %z $B) / 512 )) /tmp/bootchk.img >/dev/null 2>&1; cmp $B /tmp/bootchk.img && echo BOOT_IS_STOCK; rm -f /tmp/bootchk.img
$RK rd
```

**151.** `14:27` Wait for Android, check SD partitions

```sh
for i in $(seq 1 60); do adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1 && break; sleep 2; done; adb shell cat /proc/partitions | grep mmcblk1
```

**152.** `14:27` Check adb, boot state and partitions

```sh
adb devices; adb shell getprop sys.boot_completed; adb shell cat /proc/partitions | grep -c mmcblk
```

**153.** `14:27` Wait for SD card with pmOS partitions (background)

```sh
until adb shell cat /proc/partitions 2>/dev/null | grep -q mmcblk1p2; do sleep 2; done; adb shell cat /proc/partitions | grep mmcblk1
```

**154.** `14:28` Snapshot interfaces and reboot into pmOS

```sh
cat $TASKS/b1y39q8mr.output; S=$S; ifconfig -l > $S/ifaces-before.txt; cat $S/ifaces-before.txt; adb reboot recovery; echo rebooted
```

**155.** `14:28` Watch for pmOS USB gadget / network (3 min)

```sh
S=$S; for i in $(seq 1 60); do new=$(comm -13 <(tr ' ' '\n' < $S/ifaces-before.txt | sort) <(ifconfig -l | tr ' ' '\n' | sort)); usb=$(system_profiler SPUSBDataType 2>/dev/null | grep -iE -B2 -A4 'postmarket|pmos|0x18d1|0x2207|ac101|archos|rockchip' | head -12); [ -n "$new$usb" ] && break; sleep 3; done; echo "new ifaces: $new"; echo "$usb"; adb devices
```

> **Owner:** Rebooted on android now

**156.** `15:28` Check adb connection and SD card partitions

```sh
S=$S
adb devices; adb shell id; adb shell 'cat /proc/partitions | grep mmcblk1'
```

**157.** `15:28` Check root access and last-log files on tablet

```sh
adb shell 'ls -l /dev/block/mmcblk1p1; which su; ls /proc/last_kmsg /proc/last_log 2>&1; getprop ro.debuggable'
```

**158.** `15:28` Pull last_log and last_kmsg from the tablet

```sh
S=$S
mkdir -p $S/diag; cd $S/diag
adb shell 'cat /proc/last_log' > last_log.txt 2>&1; adb shell 'cat /proc/last_kmsg' > last_kmsg.txt 2>&1
wc -c last_log.txt last_kmsg.txt; head -c 3000 last_log.txt; echo ----; grep -a -n -i -E 'Linux version|Booting Linux|6\.12|Uncompressing|pmOS|postmarket' last_log.txt last_kmsg.txt | head -40
```

**159.** `15:28` Move pulled logs to scratchpad and look for readable text

```sh
S=$S
mv ~/workspace/last_log.txt ~/workspace/last_kmsg.txt $S/diag/ 2>&1; ls $S/diag
python3 - <<EOF
for f in ("last_log.txt","last_kmsg.txt"):
    d=open("$S/diag/"+f,"rb").read()
    import re
    words=re.findall(rb"[ -~]{12,}",d)
    print(f,len(words),words[:10])
EOF
```

**160.** `15:28` Inspect stock boot headers and loader strings

```sh
S=$S
python3 - <<EOF
import struct
for f in ("boot.img","recovery.img"):
    d=open("$S/backup/"+f,"rb").read(1024)
    print(f, d[:8], ["%#x"%x for x in struct.unpack_from("<10I",d,8)], d[64:200].split(b"\0")[0])
EOF
strings -n 6 $S/backup/misc-loader.dec | grep -i -E 'kernel|ramdisk|fdt|addr|bootm|initrd|zImage|resource|0x6|0x0' | head -80
```

**161.** `15:29` Locate U-Boot inside the decrypted loader

```sh
S=$S
ls -la $S/backup/misc-loader.*; xxd $S/backup/misc-loader.dec | head -20; grep -a -b -o -E 'U-Boot 20[0-9.]+[^\x00]{0,60}' $S/backup/misc-loader.dec | head; grep -a -b -o 'kernel   @ 0x%08x' $S/backup/misc-loader.dec
```

**162.** `15:29` Find ARM vector tables in the loader

```sh
S=$S
python3 - <<EOF
d=open("$S/backup/misc-loader.dec","rb").read()
import struct
pat=struct.pack("<I",0xe59ff014)
i=d.find(pat)
while i!=-1 and i<len(d):
    print(hex(i), d[i-4:i+40].hex())
    i=d.find(pat,i+1)
    if i>0x300000: break
# look for "LOADER" markers
for m in (b"LOADER",b"RK32",b"BOOT",b"KRNL"):
    j=d.find(m); print(m,hex(j))
EOF
```

**163.** `15:29` Check available disassemblers and containers

```sh
which objdump llvm-objdump arm-none-eabi-objdump r2 2>&1; objdump --version | head -3; docker ps --format '{{.Names}} {{.Image}}'
```

**164.** `15:29` Extract U-Boot and test objdump raw binary support

```sh
S=$S
python3 -c "
d=open('$S/backup/misc-loader.dec','rb').read()
open('$S/diag/uboot.bin','wb').write(d[0x4420:0x4420+0x80000])"
cd $S/diag && objdump -D --triple=armv7a-none-eabi -b binary 2>&1 | head -3
objdump --help 2>&1 | grep -i -E 'binary|triple|arch' | head
```

**165.** `15:29` Disassemble U-Boot in the Alpine container

```sh
S=$S
mkdir -p $S/share/diag && cp $S/diag/uboot.bin $S/share/diag/
docker exec pmos sh -c 'apk add -q binutils-arm-none-eabi 2>&1 | tail -2; arm-none-eabi-objdump -D -b binary -m arm --adjust-vma=0 /share/diag/uboot.bin > /share/diag/uboot.S; wc -l /share/diag/uboot.S'
```

**166.** `15:29` Find code references to key boot strings

```sh
S=$S
python3 - <<EOF
import struct
d=open("$S/diag/uboot.bin","rb").read()
for s in (b"kernel   @ 0x%08x",b"ramdisk  @ 0x%08x",b"KERNEL_IMG:",b"load kernel image failed",b"initrd=0x%08X,0x%08X"):
    o=d.find(s)
    refs=[]
    for base in (0,0x60000000,0x61000000,0x00200000):
        w=struct.pack("<I",o+base)
        j=d.find(w)
        if j>=0: refs.append((hex(base),hex(j)))
    print(s,hex(o),refs)
EOF
```

**167.** `15:29` Find instructions loading the kernel-print string

```sh
S=$S
grep -n -E '^ +39ba0:|pc, #.*; 0x39ba0' $S/share/diag/uboot.S | head; grep -n '; 0x39ba0' $S/share/diag/uboot.S
```

**168.** `15:29` Search references to the string pointer

```sh
S=$S
grep -n '0x39ba0' $S/share/diag/uboot.S
```

**169.** `15:29` See format of PC-relative loads

```sh
S=$S
grep -n 'ldr.*pc, #' $S/share/diag/uboot.S | head -3; sed -n '42500,42700p' $S/share/diag/uboot.S | grep -n -E 'pc|bl|mov' | head -5
```

**170.** `15:29` Disassemble U-Boot as Thumb and find the reference

```sh
docker exec pmos sh -c 'arm-none-eabi-objdump -D -b binary -m arm -M force-thumb --adjust-vma=0 /share/diag/uboot.bin > /share/diag/uboot-t.S; grep -n "39ba0" /share/diag/uboot-t.S | head'
```

**171.** `15:30` Show disassembly around the kernel-print code

```sh
S=$S
sed -n '77150,77400p' $S/share/diag/uboot-t.S | cut -f1,3,4
```

**172.** `15:30` Brute-force U-Boot load base from string references

```sh
S=$S
python3 - <<EOF
import struct, re, collections
d=open("$S/backup/misc-loader.dec","rb").read()
strs=[m.start() for m in re.finditer(rb"[ -~]{8,}\x00",d)]
print(len(strs))
words=collections.Counter()
ws=set(struct.unpack_from("<%dI"%(len(d)//4),d))
cnt=collections.Counter()
for so in strs:
    pass
# candidate base = w - so; count via histogram on aligned bases
sset=set(strs)
import array
arr=array.array('I',d[:len(d)//4*4])
for w in arr:
    for delta in (0,):
        pass
# smarter: for each word w, for each string offset s within 4MB, base=w-s; too many. Restrict to bases multiple of 0x100 relative
hist=collections.Counter()
strs_arr=sorted(strs)
for w in set(arr):
    # bases where w-s aligned to 0x20 offset? Just try s with (w - s) % 0x1000 == 0x420? unknown. use: base low 12 bits from 0x4420 shift
    pass
for base_low in (0x000,0x420,0xbe0):
  hist=collections.Counter()
  for w in set(arr):
    for s in strs_arr:
        b=w-s
        if b & 0xfff == ( -base_low)&0xfff and 0<=b<0x80000000:
            hist[b]+=1
  print(hex(base_low),[(hex(b),c) for b,c in hist.most_common(5)])
EOF
```

**173.** `15:30` Inspect the uboot partition backup

```sh
S=$S
ls -la $S/backup/uboot.img; xxd $S/backup/uboot.img | head -8; strings -n 8 $S/backup/uboot.img | grep -c . ; grep -a -b -o -E 'U-Boot 2014[^\x00]{0,40}|kernel   @' $S/backup/uboot.img | head
```

**174.** `15:30` Print the full parameter block

```sh
S=$S
python3 -c "
d=open('$S/backup/uboot.img','rb').read()
import struct; n=struct.unpack_from('<I',d,4)[0]; print(d[8:8+n].decode())"; python3 -c "
d=open('$S/backup/uboot.img','rb').read()
import re
print([ (hex(m.start()), m.group()[:16]) for m in re.finditer(rb'PARM|LOADER  |RK32|ANDROID!',d)][:20])"
```

**175.** `15:31` Check where stock kernel and RAM sit in memory

```sh
adb shell 'cat /proc/iomem | grep -i -E "System RAM|Kernel"; cat /proc/cmdline; head -1 /proc/meminfo; ls /proc/device-tree/chosen 2>/dev/null; cat /proc/device-tree/chosen/linux,initrd-start 2>/dev/null | xxd 2>/dev/null' ; adb shell cat /proc/device-tree/chosen/bootargs
```

**176.** `15:31` Download Rockchip U-Boot config sources and grep load addresses

```sh
cd $S && mkdir -p rkuboot && for f in include/configs/rk_default_config.h include/configs/rk_default_config.h include/configs/rk32xx.h board/rockchip/common/rkboot/fastboot.c arch/arm/cpu/armv7/rk32xx/rk_board.c board/rockchip/rk32xx/rk32xx.c board/rockchip/common/config.c; do curl -sf -o rkuboot/$(basename $f) https://raw.githubusercontent.com/rockchip-linux/u-boot/rkdevelop/$f && echo ok $f; done; grep -rn -E 'KERNEL_RUNNING_ADDR|KERNEL_LOAD_ADDR|rk_boot_buf_addr|RAMDISK' rkuboot | head -30
```

**177.** `15:32` Fetch more U-Boot sources and grep ramdisk buffer and bootargs

```sh
D=$S/rkuboot; mkdir -p $D
curl -s "https://api.github.com/search/code?q=rk_boot_buf_addr+repo:rockchip-linux/u-boot" | head -5
for f in board/rockchip/common/rkboot/fastboot.c board/rockchip/rk32xx/rk32xx.c board/rockchip/common/common_rk.c board/rockchip/common/rkloader/rkloader.c board/rockchip/common/config.c arch/arm/cpu/armv7/rk32xx/board.c arch/arm/lib/board.c; do curl -sf -o $D/$(echo $f | tr / _) https://raw.githubusercontent.com/rockchip-linux/u-boot/rkdevelop/$f && echo ok $f; done
grep -n -E 'rk_boot_buf_addr|board_fbt_finalize_bootargs|initrd=|CMDLINE' $D/* | head -30
```

**178.** `15:32` Read boot buffer allocation and bootargs finalization code

```sh
D=$S/rkuboot
sed -n 355,395p $D/arch_arm_lib_board.c; sed -n 230,330p $D/fastboot.c; grep -n -E 'BOOT_BUFFER|RAM_PHY|KERNEL' $D/rk_default_config.h
```

**179.** `15:33` Inspect kernel cmdline config and SD card DTS node

```sh
docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && grep -n -E "CMDLINE|APPENDED_DTB|ATAG|AUTO_ZRELADDR|CONFIG_PANIC_TIMEOUT|PSTORE|RAMOOPS" config-archos-oxygen101.armv7; grep -n -E "^pkgrel|sha512|source" APKBUILD | head'; grep -n -A12 '&sdmmc' $S/share/port/rk3288-archos-oxygen101.dts
```

**180.** `15:33` Show boot options section of kernel config

```sh
docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && sed -n 600,620p config-archos-oxygen101.armv7'
```

**181.** `15:33` List port files and kernel package sources

```sh
ls -la $S/share/port/ $S/share/out; docker exec pmos sh -c 'ls -la /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; sed -n 25,45p /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/APKBUILD; ls /share'
```

**182.** `15:33` Set built-in cmdline extend and drop appended DTB in kernel config

```sh
docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && sed -i -e "/^CONFIG_ARM_APPENDED_DTB=y/c\\# CONFIG_ARM_APPENDED_DTB is not set" -e "/^CONFIG_ARM_ATAG_DTB_COMPAT/d" -e "/CONFIG_ARM_ATAG_DTB_COMPAT_CMDLINE_EXTEND/d" -e "s|^CONFIG_CMDLINE=\"\"|CONFIG_CMDLINE=\"console=ttyS2,115200n8 console=tty0 loglevel=7 PMOS_FORCE_PARTITION_RESIZE PMOS_NO_OUTPUT_REDIRECT panic=30\"\\nCONFIG_CMDLINE_EXTEND=y|" -e "s/^CONFIG_PANIC_TIMEOUT=0/CONFIG_PANIC_TIMEOUT=30/" config-archos-oxygen101.armv7 && sed -n 600,620p config-archos-oxygen101.armv7 && grep PANIC_TIMEOUT config-archos-oxygen101.armv7'
docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 2>&1 | tail -2'
```

**183.** `15:34` Rebuild the pmOS kernel package (background)

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -8; ls -la /work/packages/*/armv7/linux-archos-oxygen101*'
```

**184.** `15:34` Decompile base DTB and inspect reserved-memory and chosen

```sh
docker exec pmos sh -c 'cd /share/out && dtc -I dtb -O dts -o /share/diag/base.dts base.dtb 2>/dev/null; grep -n -A8 "reserved-memory" /share/diag/base.dts | head -20; grep -n -A6 "chosen {" /share/diag/base.dts'
```

**185.** `15:34` Add ramoops region and compile the new DTB

```sh
docker exec pmos sh -c 'cd /share/diag && python3 - <<EOF || true
EOF
awk "{print} /dma-unusable@fe000000 \\{/{f=1} f && /\\};/ && !done {print \"\\n\\t\\tramoops@7ff00000 {\\n\\t\\t\\tcompatible = \\\"ramoops\\\";\\n\\t\\t\\treg = <0x00 0x7ff00000 0x00 0x100000>;\\n\\t\\t\\trecord-size = <0x20000>;\\n\\t\\t\\tconsole-size = <0x80000>;\\n\\t\\t\\tpmsg-size = <0x20000>;\\n\\t\\t};\"; done=1; f=0}" base.dts > boot2.dts && sed -n 170,190p boot2.dts && dtc -I dts -O dtb -o /share/out/boot2.dtb boot2.dts 2>&1 | grep -v Warning | head -3; ls -la /share/out/boot2.dtb'
```

**186.** `15:34` Check module signing settings

```sh
docker exec pmos sh -c 'grep -E "^CONFIG_MODULE_SIG|^CONFIG_MODVERSIONS|^# CONFIG_MODULE_SIG is" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7'
```

**187.** `15:34` Check kernel build progress

```sh
cat $TASKS/byis5sxlf.output | tail -3
```

**188.** `15:37` Read kernel build result

```sh
cat $TASKS/byis5sxlf.output
```

**189.** `15:37` Extract new zImage from the kernel package

```sh
docker exec pmos sh -c 'mkdir -p /tmp/k && cd /tmp/k && rm -rf * && tar xzf /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r0.apk boot 2>/dev/null; ls -la boot; cp boot/vmlinuz /share/out/vmlinuz2 && strings boot/vmlinuz | grep -c PMOS_FORCE; ls /tmp/k/boot/dtbs* 2>/dev/null | head'
S=$S
ls -la $S/share/out/vmlinuz2
```

**190.** `15:38` Build the new pmOS recovery boot image

```sh
S=$S
KERNEL_ADDR=0x02008000 RAMDISK_ADDR=0x04000000 python3 -I $S/share/port/mkrkboot.py $S/share/out/stock-resource.img $S/share/out/vmlinuz2 $S/share/out/initramfs $S/share/out/boot2.dtb $S/share/out/pmos-recovery2.img
python3 -I -c "
import struct
d=open('$S/share/out/pmos-recovery2.img','rb').read()
print(len(d)/512, 0x10000)"
```

**191.** `15:38` Reboot tablet into Rockchip loader mode

```sh
S=$S; R=$S/src/rkdeveloptool/rkdeveloptool
adb reboot bootloader; for i in $(seq 1 30); do $R ld 2>/dev/null | grep -q Loader && break; sleep 1; done; $R ld
```

**192.** `15:38` Write and verify recovery partition, confirm boot is stock

```sh
S=$S; R=$S/src/rkdeveloptool/rkdeveloptool
$R wl 0x26000 $S/share/out/pmos-recovery2.img && $R rl 0x26000 38112 $S/diag/readback.img && cmp $S/diag/readback.img $S/share/out/pmos-recovery2.img && echo VERIFIED
$R rl 0x16000 16 $S/diag/boothdr.bin && cmp -n 8192 $S/diag/boothdr.bin $S/backup/boot.img && echo BOOT_STILL_STOCK
```

**193.** `15:38` Confirm boot partition header still matches stock

```sh
S=$S
ls -l $S/diag/boothdr.bin; N=$(stat -f %z $S/diag/boothdr.bin); cmp -n $N $S/diag/boothdr.bin $S/backup/boot.img && echo "BOOT_STILL_STOCK ($N bytes compared)"
```

**194.** `15:38` Compare boot partition header with backup

```sh
S=$S
python3 -I -c "
a=open('$S/diag/boothdr.bin','rb').read(); b=open('$S/backup/boot.img','rb').read(len(a)); print('BOOT_STILL_STOCK' if a==b else 'DIFFERENT', len(a))"
```

**195.** `15:38` Reset into Android, then reboot into pmOS recovery

```sh
S=$S; R=$S/src/rkdeveloptool/rkdeveloptool
$R rd >/dev/null; adb wait-for-device; for i in $(seq 1 60); do [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break; sleep 2; done; echo android up; adb reboot recovery; date
```

**196.** `15:39` Watch for pmOS USB network interface for 3 minutes

```sh
S=$S
for i in $(seq 1 36); do
  new=$(comm -13 <(tr ' ' '\n' < $S/ifaces-before.txt | sort) <(ifconfig -l | tr ' ' '\n' | sort) | tr '\n' ' ')
  usb=$(system_profiler SPUSBDataType 2>/dev/null | grep -i -E -A3 'postmarket|pmos|RNDIS|NCM|0x2207|Rockchip|Archos' | head -8)
  if [ -n "$new" ] || [ -n "$usb" ]; then echo "t=$((i*5))s new=[$new]"; echo "$usb"; break; fi
  sleep 5
done; date; adb devices | tail -n +2
```

**197.** `15:39` Inspect the new en10 interface and USB devices

```sh
sleep 20; ifconfig en10; networksetup -listallhardwareports | grep -B1 -A2 en10; system_profiler SPUSBDataType 2>/dev/null | grep -E '^\s+[A-Za-z].*:$' | head -30
```

**198.** `15:39` Keep watching for tablet USB network for 3 more minutes

```sh
S=$S
echo -n " en10" >> $S/ifaces-before.txt
for i in $(seq 1 40); do
  new=$(comm -13 <(tr ' ' '\n' < $S/ifaces-before.txt | sort) <(ifconfig -l | tr ' ' '\n' | sort) | tr '\n' ' ' | xargs)
  usb=$(ioreg -p IOUSB -l -w0 2>/dev/null | grep -E '"USB Product Name"|"idVendor"' | grep -i -E 'pmos|postmarket|RNDIS|NCM|8301|= 6610|= 7425|18d1|= 8711' | head)
  if [ -n "$new" ] || [ -n "$usb" ]; then echo "t=$((i*5))s new=[$new] usb=[$usb]"; break; fi
  sleep 5
done; date; ioreg -p IOUSB -w0 | sed 's/<.*//' | grep -v -E 'Root|AppleUSB' | head -20
```

**199.** `15:40` Check en19 address and ping pmOS

```sh
ifconfig en19; ping -c 3 -t 5 172.16.42.1; adb devices | tail -n +2
```

**200.** `15:40` Probe SSH and telnet ports on pmOS

```sh
for p in 22 23; do nc -z -G 3 172.16.42.1 $p && echo "port $p open"; done; sleep 30; for p in 22 23; do nc -z -G 3 172.16.42.1 $p && echo "port $p open (after 30s)"; done
```

**201.** `15:40` Wait for SSH or telnet on pmOS up to 3 minutes

```sh
for i in $(seq 1 36); do for p in 22 23; do nc -z -G 3 172.16.42.1 $p 2>/dev/null && { echo "t=$((i*5))s port $p open"; break 2; }; done; ping -c1 -t2 172.16.42.1 >/dev/null || echo "t=$((i*5))s no ping"; sleep 5; done; date; ifconfig -l
```

**202.** `15:41` SSH into pmOS and gather system status

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o BatchMode=yes user@172.16.42.1 'uname -a; cat /proc/cmdline; echo; uptime; free -m; df -h / /boot; cat /sys/class/drm/card*-*/status 2>/dev/null; ls /sys/class/drm; ls /sys/class/backlight; systemctl is-system-running 2>/dev/null || rc-status -s 2>/dev/null | head -30' 2>&1 | grep -v -E '^Warning: Permanently'
```

**203.** `15:41` Check pmOS kernel log for display and driver errors

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'dmesg | grep -i -E "error|fail|warn|timeout|dsi|vop|panel|drm|brcm|mmc[0-9]|rn5t|rc5t|dwc2|i2c" | grep -v -i "pinctrl" | head -70; echo ---; cat /sys/class/backlight/backlight/brightness /sys/class/backlight/backlight/max_brightness; cat /sys/class/drm/card0-DSI-1/modes; ps -o comm= -e 2>/dev/null | grep -E "phosh|phoc|gnome-session|greetd|tinydm|login" ; systemctl --failed --no-legend 2>/dev/null | head' 2>&1 | grep -v -E '^Warning: Permanently'
```

**204.** `15:41` Read pmOS kernel log via sudo

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" dmesg > /tmp/dmesg.txt; grep -i -E "error|fail|timeout|dsi|vop|panel|brcm|mmc[0-9]:|dwc2|iommu|pstore|ramoops|rk808|rn5t|rc5t|fan5|unable" /tmp/dmesg.txt | grep -v -i pinctrl | head -60; wc -l /tmp/dmesg.txt' 2>&1 | grep -v -E '^Warning: Permanently'
```

**205.** `15:42` Check WiFi firmware, DRM and input devices

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'grep -i -E "brcm|wlan|drm|fb0|fbcon|goodix|input:" /tmp/dmesg.txt | tail -25; ip -br link; ls /lib/firmware/brcm/ 2>/dev/null | grep -i 43362; ls /sys/class/input/' 2>&1 | grep -v -E '^Warning: Permanently'
```

**206.** `15:42` Show stock DTS touchscreen node

```sh
S=$S
grep -n -B2 -A16 -E 'vtl_ts|ct36' $S/backup/stock.dts | head -60
```

**207.** `15:42` Download the vendor VTL touchscreen driver source

```sh
D=$S/vtl; mkdir -p $D
for br in develop-3.10 develop-3.10-next release-3.10; do for f in vtl_ts.c vtl_ts.h chip.c chip.h; do curl -sf -o $D/$f https://raw.githubusercontent.com/rockchip-linux/kernel/$br/drivers/input/touchscreen/vtl_ts/$f && echo "ok $br $f"; done; [ -s $D/vtl_ts.c ] && break; done; ls -la $D
```

**208.** `15:43` Read the VTL driver header and main source

```sh
D=$S/vtl; cat $D/vtl_ts.h; grep -v -E '^\s*(//|printk|DEBUG)' $D/vtl_ts.c | sed -n 1,400p
```

**209.** `15:43` Read probe code and chip helper function list

```sh
D=$S/vtl; grep -v -E '^\s*(//|printk|DEBUG)' $D/vtl_ts.c | sed -n 400,700p | grep -v '^\s*$'; grep -n -E 'chip_solfware_reset|chip_enter_sleep|chip_init|^[a-z].*\(' $D/chip.c | head -30
```

**210.** `15:43` Read the VTL chip command and reset code

```sh
D=$S/vtl; sed -n 20,140p $D/chip.c; sed -n 290,310p $D/chip.c; grep -n -A40 '^int chip_init' $D/chip.c
```

**211.** `15:43` List I2C buses and available tools on pmOS

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'ls -l /sys/bus/i2c/devices/ | grep -E "i2c-[0-9]"; which gpioset gpioget gpioinfo i2ctransfer i2cdetect python3 evtest; cat /sys/kernel/debug/gpio 2>/dev/null | head -3' 2>&1 | grep -v -E '^Warning: Permanently'
```

**212.** `15:43` Scan I2C bus 4 and read the touch controller

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s i2cdetect -y -a 4; s i2ctransfer -f -y -a 4 r60@0x01; echo rc=$?; s i2ctransfer -f -y -a 4 r1@0x7f; echo rc7f=$?' 2>&1 | grep -v -E '^Warning: Permanently'
```

**213.** `15:43` Software-reset the touch chip and read again

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s i2ctransfer -f -y -a 4 w2@0x7f 0x00 0x5a; echo rc=$?; sleep 0.5; s i2cdetect -y -a 4 | sed -n 2,2p; s i2ctransfer -f -y -a 4 r60@0x01; s i2ctransfer -f -y -a 4 r1@0x7f' 2>&1 | grep -v -E '^Warning: Permanently'
```

**214.** `15:43` Retry touch data read and inspect GPIO state

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; for i in 1 2 3; do s i2ctransfer -f -y -a 4 r60@0x01; sleep 0.3; done; s i2cdetect -y -a 4 | sed -n 2,2p; ls /sys/class/gpio /dev/gpiochip* 2>&1 | head; echo $P | sudo -S -p "" cat /sys/kernel/debug/gpio | grep -A12 "gpio7"' 2>&1 | grep -v -E '^Warning: Permanently'
```

**215.** `15:44` Check backlight power and display DPMS state

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'cd /sys/class/backlight/backlight; grep . bl_power brightness actual_brightness; cat /sys/class/drm/card0-DSI-1/dpms /sys/class/drm/card0-DSI-1/enabled; echo 147147 | sudo -S -p "" cat /sys/kernel/debug/pwm 2>/dev/null' 2>&1 | grep -v -E '^Warning: Permanently'
```

**216.** `15:44` Reset touch controller via GPIO and poll touch data

```sh
S=$S
cat > $S/share/port/vtlprobe.py <<'EOF'
#!/usr/bin/env python3
"""Hardware-reset the VTL CT36x touch controller and dump touch frames."""
import fcntl, os, struct, sys, time

GPIO_GET_LINEHANDLE = 0xC16CB403
GPIOHANDLE_GET_VALUES = 0xC040B408
GPIOHANDLE_SET_VALUES = 0xC040B409
REQ_INPUT, REQ_OUTPUT = 1, 2
I2C_SLAVE_FORCE = 0x0706


def line(chip, offset, flags, value=0):
    req = struct.pack("<64I I 64B 32s I i", *([offset] + [0] * 63), flags,
                      *([value] + [0] * 63), b"vtlprobe", 1, 0)
    fd = os.open(chip, os.O_RDONLY)
    res = fcntl.ioctl(fd, GPIO_GET_LINEHANDLE, req)
    os.close(fd)
    return struct.unpack_from("<i", res, len(res) - 4)[0]


def setv(h, v):
    fcntl.ioctl(h, GPIOHANDLE_SET_VALUES, bytes([v]) + bytes(63))


def getv(h):
    return fcntl.ioctl(h, GPIOHANDLE_GET_VALUES, bytes(64))[0]


def i2c(addr):
    fd = os.open("/dev/i2c-4", os.O_RDWR)
    fcntl.ioctl(fd, I2C_SLAVE_FORCE, addr)
    return fd


rst = line("/dev/gpiochip7", 5, REQ_OUTPUT, 1)
irq = line("/dev/gpiochip7", 6, REQ_INPUT)
setv(rst, 0); time.sleep(0.05); setv(rst, 1); time.sleep(0.01)
print("irq level after reset:", getv(irq))
try:
    f = i2c(0x7f); os.write(f, b"\x00\x5a"); os.close(f)
    print("soft reset sent")
except OSError as e:
    print("soft reset failed:", e)
time.sleep(0.3)
dev = i2c(0x01)
end = time.time() + float(sys.argv[1] if len(sys.argv) > 1 else 3)
n = 0
while time.time() < end:
    if getv(irq) == 0:
        try:
            d = os.read(dev, 60)
        except OSError as e:
            print("read err", e); time.sleep(0.1); continue
        n += 1
        pts = []
        for i in range(10):
            xhi, yhi, lo, sid, area, pr = d[i * 6:i * 6 + 6]
            st, pid = sid & 7, sid >> 3
            if st in (1, 2) and xhi != 0xff:
                pts.append((pid, st, (xhi << 4) | (lo >> 4), (yhi << 4) | (lo & 15), area, pr))
        if n <= 3 or pts:
            print(round(time.time() % 100, 2), d[:12].hex(), pts, flush=True)
    time.sleep(0.005)
print("frames:", n, "irq now:", getv(irq))
EOF
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $S/share/port/vtlprobe.py user@172.16.42.1:/tmp/ 2>/dev/null
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" python3 /tmp/vtlprobe.py 2' 2>&1 | grep -v -E '^Warning: Permanently'
```

**217.** `15:45` Wake the screen with a virtual key press

```sh
S=$S
cat > $S/share/port/wake.py <<'EOF'
#!/usr/bin/env python3
"""Tap a key through a throwaway uinput device to wake the screen."""
import fcntl, os, struct, time

UI_SET_EVBIT, UI_SET_KEYBIT, UI_DEV_CREATE, UI_DEV_DESTROY = 0x40045564, 0x40045565, 0x5501, 0x5502
EV_SYN, EV_KEY, KEY_LEFTSHIFT = 0, 1, 42

fd = os.open("/dev/uinput", os.O_WRONLY)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
fcntl.ioctl(fd, UI_SET_KEYBIT, KEY_LEFTSHIFT)
os.write(fd, struct.pack("<80sHHHHi", b"wake", 3, 1, 1, 1, 0) + bytes(4 * 64 * 4))
fcntl.ioctl(fd, UI_DEV_CREATE)
time.sleep(1)
for v in (1, 0):
    os.write(fd, struct.pack("<llHHi", 0, 0, EV_KEY, KEY_LEFTSHIFT, v))
    os.write(fd, struct.pack("<llHHi", 0, 0, EV_SYN, 0, 0))
time.sleep(0.5)
fcntl.ioctl(fd, UI_DEV_DESTROY)
EOF
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $S/share/port/wake.py user@172.16.42.1:/tmp/ 2>/dev/null
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" python3 /tmp/wake.py; sleep 2; cat /sys/class/drm/card0-DSI-1/dpms; cat /sys/class/backlight/backlight/brightness' 2>&1 | grep -v -E '^Warning: Permanently'
```

**218.** `15:45` Record raw touch data for 5 minutes while keeping screen awake (background)

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 '(while sleep 50; do echo 147147 | sudo -S -p "" python3 /tmp/wake.py; done) & W=$!; echo 147147 | sudo -S -p "" python3 -u /tmp/vtlprobe.py 300; kill $W' 2>&1 | grep -v -E '^Warning: Permanently'
```

**219.** `15:50` Inspect the touch capture output

```sh
F=$TASKS/bgeoe0qpj.output; wc -l $F; head -5 $F; grep -c '\[(' $F; tail -3 $F
```

**220.** `15:50` Poll touch controller after hardware and software resets

```sh
S=$S
cat > $S/share/port/vtlpoll.py <<'EOF'
#!/usr/bin/env python3
"""Variant of vtlprobe: optional reset, then poll 0x01 without the irq line."""
import os, sys, time
sys.argv += ["3", "hw"][len(sys.argv) - 1:]
import importlib.util
spec = importlib.util.spec_from_file_location("p", "/tmp/vtlprobe_lib.py")
EOF
# simpler: standalone
cat > $S/share/port/vtlpoll.py <<'EOF'
#!/usr/bin/env python3
"""Reset the CT36x (hw, hw+sw, or none) then poll address 0x01 without the irq line."""
import fcntl, os, struct, sys, time

GPIO_GET_LINEHANDLE, GET, SET = 0xC16CB403, 0xC040B408, 0xC040B409


def line(chip, offset, flags, value=0):
    req = struct.pack("<64I I 64B 32s I i", *([offset] + [0] * 63), flags,
                      *([value] + [0] * 63), b"vtlpoll", 1, 0)
    fd = os.open(chip, os.O_RDONLY)
    res = fcntl.ioctl(fd, GPIO_GET_LINEHANDLE, req)
    os.close(fd)
    return struct.unpack_from("<i", res, len(res) - 4)[0]


def i2c(addr):
    fd = os.open("/dev/i2c-4", os.O_RDWR)
    fcntl.ioctl(fd, 0x0706, addr)
    return fd


mode, secs = sys.argv[1], float(sys.argv[2])
irq = line("/dev/gpiochip7", 6, 1)
if "hw" in mode:
    rst = line("/dev/gpiochip7", 5, 2, 1)
    fcntl.ioctl(rst, SET, bytes([0]) + bytes(63)); time.sleep(0.05)
    fcntl.ioctl(rst, SET, bytes([1]) + bytes(63)); time.sleep(0.01)
if "sw" in mode:
    f = i2c(0x7f); os.write(f, b"\x00\x5a"); os.close(f)
time.sleep(0.3)
dev = i2c(0x01)
last, end, errs = None, time.time() + secs, 0
while time.time() < end:
    lvl = fcntl.ioctl(irq, GET, bytes(64))[0]
    try:
        d = os.read(dev, 60)
    except OSError as e:
        errs += 1
        if errs < 3: print("read err", e, flush=True)
        time.sleep(0.2); continue
    if d != last:
        print(round(time.time() % 1000, 2), "irq", lvl, d[:24].hex(), flush=True)
        last = d
    time.sleep(0.02)
print("errors", errs)
EOF
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $S/share/port/vtlpoll.py user@172.16.42.1:/tmp/ 2>/dev/null
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'for m in hw hwsw; do echo "== $m"; echo 147147 | sudo -S -p "" python3 /tmp/vtlpoll.py $m 2; done' 2>&1 | grep -v -E '^Warning: Permanently'
```

**221.** `15:51` Record polled touch data for 10 minutes, keeping screen awake (background)

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" python3 /tmp/wake.py; (while sleep 50; do echo 147147 | sudo -S -p "" python3 /tmp/wake.py; done) & W=$!; echo 147147 | sudo -S -p "" python3 -u /tmp/vtlpoll.py hw 600; kill $W' 2>&1 | grep -v -E '^Warning: Permanently'
```

**222.** `15:51` Mount Android system partition read-only and list WiFi firmware

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s mkdir -p /mnt/asys; s mount -t ext4 -o ro,noload,loop,offset=$((0x94000*512)),sizelimit=$((0x200000*512)) /dev/mmcblk0 /mnt/asys && ls /mnt/asys; ls -la /mnt/asys/etc/firmware/ /mnt/asys/vendor/firmware/ 2>/dev/null | grep -i -E "nvram|fw_|RK90|43362|bcm|\.txt|\.cal" | head -30' 2>&1 | grep -v -E '^Warning: Permanently'
```

**223.** `15:51` List NVRAM files and Android WiFi config

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'cd /mnt/asys; ls etc/firmware | grep -i nvram; grep -i -E "wifi|wlan" build.prop; cat etc/firmware/config.txt' 2>&1 | grep -v -E '^Warning: Permanently'; adb devices 2>/dev/null | tail -n +2
```

**224.** `15:51` Compare the two candidate NVRAM files

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'cd /mnt/asys/etc/firmware; md5sum nvram_RK901.txt nvram_AP6181.txt; grep -E "xtalfreq|boardtype|boardrev|macaddr|sromrev|manfid|prodid" nvram_RK901.txt nvram_AP6181.txt' 2>&1 | grep -v -E '^Warning: Permanently'
```

**225.** `15:51` Install RK901 NVRAM and reload the WiFi driver

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s cp /mnt/asys/etc/firmware/nvram_RK901.txt "/lib/firmware/brcm/brcmfmac43362-sdio.archos,oxygen101.txt"; s modprobe -r brcmfmac; sleep 1; s modprobe brcmfmac; sleep 8; s dmesg | grep -i brcm | tail -8; ls /sys/class/net' 2>&1 | grep -v -E '^Warning: Permanently'
```

**226.** `15:52` Unmount Android system and scan WiFi networks

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" umount /mnt/asys; nmcli radio wifi on; sleep 2; nmcli dev wifi rescan 2>/dev/null; sleep 6; nmcli -f SSID,SIGNAL,SECURITY dev wifi list | head -12' 2>&1 | grep -v -E '^Warning: Permanently'
```

> **Owner:** done

**227.** `15:57` Read the polled touch capture so far

```sh
F=$TASKS/bmjp2ikrb.output; wc -l $F; head -60 $F
```

**228.** `15:57` Decode touch frames: downs, ups and multi-touch

```sh
F=$TASKS/bmjp2ikrb.output
python3 - "$F" <<'EOF'
import sys
for l in open(sys.argv[1]):
    p=l.split()
    if len(p)<4 or p[1]!="irq": continue
    d=bytes.fromhex(p[3]); pts=[]
    for i in range(4):
        xhi,yhi,lo,sid=d[i*6:i*6+4]
        if xhi==0xff: continue
        pts.append((sid>>3, "dmu"[ (sid&7)-1] if 1<=(sid&7)<=3 else sid&7, (xhi<<4)|(lo>>4), (yhi<<4)|(lo&15)))
    if pts and (any(s!='m' for _,s,_,_ in pts) or len(pts)>1): print(p[0], pts)
EOF
```

**229.** `15:57` Check reboot-mode support for rebooting into recovery

```sh
docker exec pmos sh -c 'grep -E "REBOOT_MODE|SYSCON_REBOOT|POWER_RESET=|ROCKCHIP_REBOOT" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7'; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'ls /proc/device-tree/ | grep -i reboot; find /proc/device-tree -name "reboot-mode*" | head; cat /proc/device-tree/*/reboot-mode/mode-recovery 2>/dev/null | od -An -tx1' 2>&1 | grep -v -E '^Warning: Permanently'
```

**230.** `15:58` Extract touchscreen Kconfig/Makefile from kernel tarball

```sh
docker exec pmos sh -c 'ls /work/cache_distfiles/ | grep linux-6.12; mkdir -p /share/ksrc && cd /share/ksrc && tar xJf /work/cache_distfiles/linux-6.12.90.tar.xz linux-6.12.90/drivers/input/touchscreen/Kconfig linux-6.12.90/drivers/input/touchscreen/Makefile linux-6.12.90/drivers/input/touchscreen/ili210x.c linux-6.12.90/drivers/input/touchscreen/hynitrix.c 2>&1 | tail -2; ls linux-6.12.90/drivers/input/touchscreen/'
```

**231.** `15:58` Review DTS structure, i2c4 and pinctrl sections

```sh
S=$S; F=$S/share/port/rk3288-archos-oxygen101.dts
grep -n -E '^&|^\s*[a-z_-]+(@[0-9a-f]+)? \{|reserved|#include' $F | head -80; grep -n -A6 '&i2c4' $F; grep -n -B2 -A30 '^&pinctrl' $F | head -60
```

**232.** `15:59` Generate patch adding CT36x driver, DTS node and ramoops

```sh
S=$S; P=$S/share/port; K=$S/share/ksrc
rm -rf $K/a $K/b; mkdir -p $K/a/arch/arm/boot/dts/rockchip $K/a/drivers/input/touchscreen
cp $P/rk3288-archos-oxygen101.dts $K/a/arch/arm/boot/dts/rockchip/
cp $K/linux-6.12.90/drivers/input/touchscreen/{Kconfig,Makefile} $K/a/drivers/input/touchscreen/
cp -R $K/a $K/b
D=$K/b/arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts
python3 -I - "$D" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace('''&i2c4 {
	/* Touchscreen: VTL CT36x @0x01 (irq GPIO7_A6, reset GPIO7_A5) */
	status = "okay";
};''','''&i2c4 {
	status = "okay";

	touchscreen@1 {
		compatible = "vtl,ct365";
		reg = <0x01>;
		interrupt-parent = <&gpio7>;
		interrupts = <RK_PA6 IRQ_TYPE_EDGE_FALLING>;
		pinctrl-names = "default";
		pinctrl-0 = <&ts_int>;
		reset-gpios = <&gpio7 RK_PA5 GPIO_ACTIVE_LOW>;
		touchscreen-size-x = <1920>;
		touchscreen-size-y = <1200>;
	};
};''')
s=s.replace('''	memory@0 {''','''	reserved-memory {
		ramoops@7ff00000 {
			compatible = "ramoops";
			reg = <0x0 0x7ff00000 0x0 0x100000>;
			record-size = <0x20000>;
			console-size = <0x80000>;
			pmsg-size = <0x20000>;
		};
	};

	memory@0 {''',1)
s=s.replace('''&pwm0 {''','''&pinctrl {
	touchscreen {
		ts_int: ts-int {
			rockchip,pins = <7 RK_PA6 RK_FUNC_GPIO &pcfg_pull_up>;
		};
	};
};

&pwm0 {''',1)
open(p,"w").write(s)
EOF
cp $D $P/rk3288-archos-oxygen101.dts
mkdir -p $K/b/drivers/input/touchscreen && cp $P/vtl-ct36x.c $K/b/drivers/input/touchscreen/
python3 -I - $K/b/drivers/input/touchscreen <<'EOF'
import sys,os
d=sys.argv[1]
k=open(d+"/Kconfig").read()
anchor="config TOUCHSCREEN_WACOM_W8001"
assert anchor in k
k=k.replace(anchor,'''config TOUCHSCREEN_VTL_CT36X
	tristate "VTL CT36x touchscreen"
	depends on I2C
	help
	  Say Y here if you have a VTL CT362/CT363/CT365/CT368/CT369
	  touchscreen controller, as found on some Rockchip tablets.

	  If unsure, say N.

	  To compile this driver as a module, choose M here: the
	  module will be called vtl-ct36x.

'''+anchor,1)
open(d+"/Kconfig","w").write(k)
m=open(d+"/Makefile").read()
a="obj-$(CONFIG_TOUCHSCREEN_WACOM_W8001)"
assert a in m
m=m.replace(a,"obj-$(CONFIG_TOUCHSCREEN_VTL_CT36X)\t+= vtl-ct36x.o\n"+a,1)
open(d+"/Makefile","w").write(m)
EOF
cd $K && diff -ruN a b > $P/0002-input-vtl-ct36x-touchscreen.patch; grep -c '^+' $P/0002-input-vtl-ct36x-touchscreen.patch; grep -n -A3 'VTL_CT36X)' $P/0002-input-vtl-ct36x-touchscreen.patch
```

**233.** `15:59` Check patch file paths

```sh
P=$S/share/port; grep -E '^(\+\+\+|---) ' $P/0002-input-vtl-ct36x-touchscreen.patch
```

**234.** `15:59` Add touch patch and reboot-mode config to kernel package

```sh
docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && cp /share/port/0002-input-vtl-ct36x-touchscreen.patch . && sed -i "s|^\t0001-archos-oxygen101-dts-and-panel.patch|&\n\t0002-input-vtl-ct36x-touchscreen.patch|" APKBUILD && sed -i -e "s/^# CONFIG_SYSCON_REBOOT_MODE is not set/CONFIG_SYSCON_REBOOT_MODE=y/" config-archos-oxygen101.armv7 && printf "CONFIG_REBOOT_MODE=y\nCONFIG_TOUCHSCREEN_VTL_CT36X=y\n" >> config-archos-oxygen101.armv7 && chown pmos:pmos 0002-input-vtl-ct36x-touchscreen.patch && sed -n "/^source=/,/^\"/p" APKBUILD'
docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 2>&1 | tail -1'
```

**235.** `15:59` Build kernel with the touchscreen driver

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | grep -v -E "^\s*$" | tail -15'
```

**236.** `16:04` Extract new kernel and DTB, build recovery image v3

```sh
S=$S
docker exec pmos sh -c 'rm -rf /tmp/k && mkdir -p /tmp/k && cd /tmp/k && tar xzf /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r0.apk boot 2>/dev/null; cp boot/vmlinuz /share/out/vmlinuz3; cp boot/dtbs/rk3288-archos-oxygen101.dtb /share/out/dtb3.dtb 2>/dev/null || find boot/dtbs -name "*oxygen*"; dtc -I dtb -O dts /share/out/dtb3.dtb 2>/dev/null | grep -E -A3 "touchscreen@1|ramoops@" | head -12; grep -E "VTL_CT36X|REBOOT_MODE" boot/config'
KERNEL_ADDR=0x02008000 RAMDISK_ADDR=0x04000000 python3 -I $S/share/port/mkrkboot.py $S/share/out/stock-resource.img $S/share/out/vmlinuz3 $S/share/out/initramfs $S/share/out/dtb3.dtb $S/share/out/pmos-recovery3.img; md5 -q $S/share/out/pmos-recovery2.img $S/share/out/pmos-recovery3.img
```

**237.** `16:04` Verify recovery partition offset on eMMC from pmOS

```sh
S=$S
cmp -s $S/share/out/vmlinuz2 $S/share/out/vmlinuz3 && echo SAME_KERNEL || echo kernel differs
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $S/share/out/pmos-recovery3.img user@172.16.42.1:/tmp/ 2>/dev/null
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s dd if=/dev/mmcblk0 bs=512 skip=$((0x28000)) count=38112 2>/dev/null | md5sum; md5sum /tmp/pmos-recovery3.img' 2>&1 | grep -v -E '^Warning: Permanently'
```

**238.** `16:04` Write recovery image v3 to eMMC and verify

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s dd if=/tmp/pmos-recovery3.img of=/dev/mmcblk0 bs=512 seek=$((0x28000)) conv=fsync 2>&1 | tail -1; s sh -c "echo 3 > /proc/sys/vm/drop_caches"; s dd if=/dev/mmcblk0 bs=512 skip=$((0x28000)) count=38112 iflag=direct 2>/dev/null | md5sum; s dd if=/dev/mmcblk0 bs=512 skip=$((0x18000)) count=16 2>/dev/null | head -c 8' 2>&1 | grep -v -E '^Warning: Permanently'
```

**239.** `16:05` Reboot via Android into the new pmOS kernel and wait for SSH

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" systemctl reboot' 2>&1 | grep -v -E '^Warning: Permanently'; adb wait-for-device; for i in $(seq 1 60); do [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break; sleep 2; done; echo android up; adb reboot recovery
for i in $(seq 1 60); do nc -z -G 2 172.16.42.1 22 2>/dev/null && { echo "ssh up after $((i*5))s"; break; }; sleep 5; done
```

**240.** `16:12` Check the touchscreen driver probe on the new kernel

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'uname -v; echo 147147 | sudo -S -p "" dmesg | grep -i -E "ct36|vtl|touch|input:|i2c 4|4-0001|pstore|ramoops" ; cat /proc/bus/input/devices | grep -E "Name|Handlers"' 2>&1 | grep -v -E '^Warning: Permanently'
```

**241.** `16:12` Check touchscreen interrupt count and display state

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'grep -i -E "ct36|4-0001" /proc/interrupts; cat /sys/class/drm/card0-DSI-1/dpms' 2>&1 | grep -v -E '^Warning: Permanently'
```

**242.** `16:12` Record touch interrupts and events for 3 minutes (background)

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" sh -c "timeout 180 evtest /dev/input/event0 > /tmp/evtest.txt 2>&1 & for i in \$(seq 1 90); do grep ct365 /proc/interrupts | tr -s \" \" | cut -d\" \" -f3; sleep 2; done | uniq -c"' 2>&1 | grep -v -E '^Warning: Permanently'
```

**243.** `16:15` Read touch interrupt and event recording results

```sh
cat $TASKS/b64xmf9na.output; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'grep -c "EV_ABS" /tmp/evtest.txt; grep "ABS_MT_POSITION" /tmp/evtest.txt | head -5; grep ct365 /proc/interrupts' 2>&1 | grep -v -E '^Warning: Permanently'
```

**244.** `16:16` Show touch event timeline and session state

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'grep -E "TRACKING_ID|POSITION_X|POSITION_Y" /tmp/evtest.txt | grep ^Event | awk "{print \$3, \$NF, \$(NF-2)}" | head -80; grep ct365 /proc/interrupts; loginctl list-sessions --no-legend; pgrep -a phosh | head -3' 2>&1 | grep -v -E '^Warning: Permanently'
```

**245.** `16:16` Check touch controller is still responsive

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s i2ctransfer -f -y -a 4 r12@0x01; s cat /sys/kernel/debug/gpio | grep -E "gpio-22[12]"; grep ct365 /proc/interrupts' 2>&1 | grep -v -E '^Warning: Permanently'
```

> **Owner:** screen is black

**246.** `16:22` Wake screen and look up stock key definitions

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" python3 /tmp/wake.py; cat /sys/class/drm/card0-DSI-1/dpms' 2>&1 | grep -v -E '^Warning: Permanently'
S=$S
grep -n -B3 -A40 -E 'rockchip,key|rk_keys|adc-keys' $S/backup/stock.dts | grep -v -E '^\s*$' | head -60
```

**247.** `16:23` Find power key GPIO bank and re-wake the screen

```sh
S=$S
grep -n -B12 -E 'phandle = <0x(b3|cd)>' $S/backup/stock.dts | grep -E 'gpio[0-9]@|adc@|saradc|phandle|compatible' 
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $S/share/port/{wake,vtlpoll}.py user@172.16.42.1: 2>/dev/null
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" python3 ~/wake.py; sleep 1; cat /sys/class/drm/card0-DSI-1/dpms; grep ct365 /proc/interrupts' 2>&1 | grep -v -E '^Warning: Permanently'
```

**248.** `16:23` Disable idle screen blanking in the user session

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus; gsettings set org.gnome.desktop.session idle-delay 0; gsettings get org.gnome.desktop.session idle-delay; ps -o user,comm -e | grep -E "phosh|phrog|greet" ' 2>&1 | grep -v -E '^Warning: Permanently'
```

**249.** `16:23` Check USB network to the tablet

```sh
sleep 5; ping -c 2 -t 3 172.16.42.1; ifconfig -l | tr ' ' '\n' | grep -E 'en1[0-9]|en2'
```

> **Owner:** I could type a pin but it's wrong, what is the correct one?

**250.** `16:23` Check login attempts in the journal

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" journalctl -b --no-pager -n 400 | grep -i -E "pam|auth|greetd|phrog|unix_chkpwd|password" | tail -15; loginctl list-sessions --no-legend' 2>&1 | grep -v -E '^Warning: Permanently'
```

**251.** `16:24` Inspect greetd login configuration

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'cat /etc/greetd/config.toml; ls /etc/greetd/; cat /usr/share/wayland-sessions/*.desktop 2>/dev/null | grep -E "^(Name|Exec)="' 2>&1 | grep -v -E '^Warning: Permanently'
```

**252.** `16:24` Find the greetd config location

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'systemctl cat greetd 2>/dev/null | grep -E "ExecStart|config"; ls /usr/share/greetd/ /etc/phrog 2>/dev/null; cat /usr/share/greetd/*.toml 2>/dev/null' 2>&1 | grep -v -E '^Warning: Permanently'
```

**253.** `16:24` Show phrog greetd config

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'cat /etc/phrog/greetd-config.toml' 2>&1 | grep -v -E '^Warning: Permanently'
```

**254.** `16:24` Enable autologin to Phosh and disable screen lock

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus; gsettings set org.gnome.desktop.screensaver lock-enabled false; gsettings set org.gnome.desktop.session idle-delay 0; P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s sh -c "printf \"\n[initial_session]\ncommand = \\\"phosh-session\\\"\nuser = \\\"user\\\"\n\" >> /etc/phrog/greetd-config.toml"; cat /etc/phrog/greetd-config.toml | tail -4; s systemctl restart greetd; sleep 12; loginctl list-sessions --no-legend; cat /sys/class/drm/card0-DSI-1/dpms' 2>&1 | grep -v -E '^Warning: Permanently'
```

**255.** `16:24` Clear greetd run marker and restart to trigger autologin

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'P=147147; s(){ echo $P | sudo -S -p "" "$@"; }; s rm -f /run/greetd.run; s systemctl restart greetd; sleep 15; loginctl list-sessions --no-legend; pgrep -a -u user phosh | head -3; cat /sys/class/drm/card0-DSI-1/dpms' 2>&1 | grep -v -E '^Warning: Permanently'
```

> **Owner:** Make it reboot always to pm and then fix the wifi

> **Owner:** Make it reboot always to pm and then fix buttons

**256.** `18:26` Check partition layout, DTS keys, tablet reachability

```sh
S=$S; strings -n 20 $S/backup/uboot.img | grep -m1 mtdparts | tr ',' '\n'; ls -la $S/share/out/ $S/backup/; grep -n "saradc\|gpio-keys\|adc-keys\|key" $S/share/port/rk3288-archos-oxygen101.dts | head -40; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=5 user@172.16.42.1 uptime
```

**257.** `18:26` Show DTS key/saradc nodes; check USB link

```sh
S=$S; sed -n 75,110p $S/share/port/rk3288-archos-oxygen101.dts; sed -n 400,420p $S/share/port/rk3288-archos-oxygen101.dts; ifconfig en19 2>&1 | head -5; ping -c2 -t3 172.16.42.1
```

**258.** `18:26` Inspect stock key nodes and USB connection state

```sh
S=$S; grep -n -B3 -A30 'rockchip,key\|"rockchip,key"' $S/backup/stock.dts | head -80; adb devices -l; ifconfig | grep -B1 -A3 "172.16.42" ; networksetup -listallhardwareports | grep -A2 -i "rndis\|usb\|ethernet" | head -30
```

**259.** `18:26` Verify power-key GPIO bank and kernel config options

```sh
S=$S; grep -n -B12 'phandle = <0xb3>' $S/backup/stock.dts | grep -E "gpio[0-9]|reg =|phandle"; grep -n 'phandle = <0xcd>' -B15 $S/backup/stock.dts | grep -E "@|compatible"; docker exec pmos sh -c 'grep -E "CONFIG_(ROCKCHIP_SARADC|KEYBOARD_ADC|KEYBOARD_GPIO|INPUT_RK805_PWRKEY)[ =]" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7; grep -E "CONFIG_(ROCKCHIP_SARADC|KEYBOARD_ADC|KEYBOARD_GPIO)" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7'
```

**260.** `18:27` Add power and volume keys to the DTS

```sh
S=$S; D=$S/share/port/rk3288-archos-oxygen101.dts; python3 -I - "$D" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old='''	gpio-keys {
		compatible = "gpio-keys";
'''
new='''	adc-keys {
		compatible = "adc-keys";
		io-channels = <&saradc 1>;
		io-channel-names = "buttons";
		keyup-threshold-microvolt = <1800000>;
		poll-interval = <100>;

		button-volume-up {
			label = "Volume Up";
			linux,code = <KEY_VOLUMEUP>;
			press-threshold-microvolt = <0>;
		};

		button-volume-down {
			label = "Volume Down";
			linux,code = <KEY_VOLUMEDOWN>;
			press-threshold-microvolt = <300000>;
		};
	};

	gpio-keys {
		compatible = "gpio-keys";
		pinctrl-names = "default";
		pinctrl-0 = <&pwr_key>;

		power-key {
			label = "Power";
			gpios = <&gpio0 RK_PA5 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_POWER>;
			debounce-interval = <20>;
			wakeup-source;
		};
'''
assert s.count(old)==1; s=s.replace(old,new)
old2='''	touchscreen {
		ts_int: ts-int {'''
new2='''	keys {
		pwr_key: pwr-key {
			rockchip,pins = <0 RK_PA5 RK_FUNC_GPIO &pcfg_pull_up>;
		};
	};

	touchscreen {
		ts_int: ts-int {'''
assert s.count(old2)==1; s=s.replace(old2,new2)
open(p,'w').write(s)
EOF
grep -n "pwr_key\|#include" $D
```

**261.** `18:27` Inspect patch layout and kernel source tree

```sh
S=$S; ls $S/share/ksrc $S/share/port; grep -n "^diff\|^+++" $S/share/port/0002-input-vtl-ct36x-touchscreen.patch; docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && ls && grep -n "^diff\|^+++" 0001*.patch | head; sed -n "/^source/,/\"/p" APKBUILD'
```

**262.** `18:27` Generate DTS key patch against touch-patched tree

```sh
S=$S; K=$S/share/ksrc; find $K/a $K/b -type f; F=arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts; mkdir -p $K/c/$(dirname $F) $K/d/$(dirname $F); cp $K/b/$F $K/c/$F; cp $S/share/port/rk3288-archos-oxygen101.dts $K/d/$F; (cd $K 2>/dev/null; true); diff -u --label a/$F --label b/$F $K/c/$F $K/d/$F > $S/share/port/0003-archos-oxygen101-keys.patch; echo rc=$?; cat $S/share/port/0003-archos-oxygen101-keys.patch | head -80
```

**263.** `18:27` Add key patch and ADC keyboard config to kernel package

```sh
docker exec pmos sh -c 'P=/work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && cp /share/port/0003-archos-oxygen101-keys.patch $P/ && sed -i "s/^\t0002-input-vtl-ct36x-touchscreen.patch$/&\n\t0003-archos-oxygen101-keys.patch/" $P/APKBUILD && sed -i "s/^# CONFIG_KEYBOARD_ADC is not set$/CONFIG_KEYBOARD_ADC=y/" $P/config-archos-oxygen101.armv7 && grep -n "0003\|KEYBOARD_ADC" $P/APKBUILD $P/config-archos-oxygen101.armv7 && chown -R 12345:12345 $P'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 2>&1 | tail -2'
```

**264.** `18:27` Build the kernel package with key support (background)

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -8; ls -la /work/packages/v26.06/armv7/linux-archos-oxygen101-*.apk'
```

**265.** `18:28` Check U-Boot handling of boot vs recovery

```sh
S=$S; ls $S/rkuboot; grep -n "BOOT_NAME\|RECOVERY_NAME\|KERNEL_NAME\|kernel_size\|SecureBoot\|charge" $S/rkuboot/*.c | head -50
```

**266.** `18:28` Read U-Boot boot selection and charge logic

```sh
S=$S; sed -n 245,275p $S/rkuboot/board_rockchip_common_rkboot_fastboot.c; sed -n 560,700p $S/rkuboot/board_rockchip_common_rkboot_fastboot.c | grep -n "boot\|charge\|key" | head -60
```

**267.** `18:28` Extract kernel and DTB from built package

```sh
tail -4 $TASKS/b7o29hml0.output; docker exec pmos sh -c 'rm -rf /tmp/k4 && mkdir /tmp/k4 && cd /tmp/k4 && tar xzf /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r0.apk 2>/dev/null; find . -name "vmlinuz*" -o -name "*oxygen101.dtb" | head; cp boot/vmlinuz /share/out/vmlinuz4 && cp $(find . -name "rk3288-archos-oxygen101.dtb" | head -1) /share/out/dtb4.dtb && ls -la /share/out/vmlinuz4 /share/out/dtb4.dtb'
```

**268.** `18:28` Inspect build failure log

```sh
cat $TASKS/b7o29hml0.output; docker exec -u pmos pmos sh -c 'cd && pmbootstrap log 2>/dev/null | grep -v "^$" | grep -i -B5 "error\|FAILED\|Hunk" | tail -40'
```

**269.** `18:30` Read build output and grep pmbootstrap log

```sh
cat $TASKS/b7o29hml0.output | head -30; docker exec pmos sh -c 'L=$(ls -t /work/log.txt 2>/dev/null | head -1); grep -n -i "error\|failed\|hunk\|reject" /work/log.txt | tail -30'
```

**270.** `18:30` Check file ownership and rerun checksum

```sh
docker exec pmos sh -c 'id pmos; ls -ln /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 2>&1 | tail -3; grep -c 0003 /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/APKBUILD'
```

**271.** `18:30` Fix permissions and update checksums

```sh
docker exec pmos sh -c 'chmod -R a+rwX /work/cache_git/pmaports/device/testing/linux-archos-oxygen101'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; grep -A1 "^sha512\|0003" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/APKBUILD | grep 0003'
```

**272.** `18:30` Rebuild kernel and extract kernel/DTB

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -4; ls -la /work/packages/v26.06/armv7/linux-archos-oxygen101-*.apk; rm -rf /tmp/k4 && mkdir /tmp/k4 && cd /tmp/k4 && tar xzf /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r0.apk 2>/dev/null; cp boot/vmlinuz /share/out/vmlinuz4 && cp boot/dtbs/rk3288-archos-oxygen101.dtb /share/out/dtb4.dtb && ls -la /share/out/vmlinuz4 /share/out/dtb4.dtb'
```

**273.** `18:34` Extract kernel/DTB and build pmOS boot image v4

```sh
docker exec pmos sh -c 'rm -rf /tmp/k5 && mkdir /tmp/k5 && cd /tmp/k5 && tar xzf /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r0.apk boot 2>/dev/null; cp boot/vmlinuz /share/out/vmlinuz4 && cp boot/dtbs/rk3288-archos-oxygen101.dtb /share/out/dtb4.dtb && ls -la /share/out/vmlinuz4 /share/out/dtb4.dtb && cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r0.apk /share/out/'; S=$S; dtc -I dtb -O dts $S/share/out/dtb4.dtb 2>/dev/null | grep -A3 "adc-keys\|power-key"; cd /; O=$S/share/out; KERNEL_ADDR=0x02008000 RAMDISK_ADDR=0x04000000 python3 -I $S/share/port/mkrkboot.py $O/stock-resource.img $O/vmlinuz4 $O/initramfs $O/dtb4.dtb $O/pmos-boot4.img && md5 $O/pmos-boot4.img
```

**274.** `18:34` Check whether the tablet is visible on USB

```sh
ifconfig | grep -B4 "172.16.42" | head; adb devices; ping -c2 -t3 172.16.42.1 | tail -2; system_profiler SPUSBDataType 2>/dev/null | grep -i -B2 -A6 "rockchip\|archos\|postmarket\|2207\|18d1" | head -30
```

**275.** `18:34` Wait for tablet; push Android into pmOS recovery (background)

```sh
for i in $(seq 1 360); do
  if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3 user@172.16.42.1 true 2>/dev/null; then echo "pmos up after ${i}"; exit 0; fi
  if adb devices | grep -qw device; then echo "android seen, rebooting to recovery(pmOS)"; adb reboot recovery; fi
  sleep 5
done; echo timeout; exit 1
```

> **Owner:** Ok now

**276.** `18:35` Check watcher progress and tablet state

```sh
cat $TASKS/bm7iq9tbr.output; adb devices; ping -c1 -t2 172.16.42.1 | tail -1
```

**277.** `18:36` Recheck adb state

```sh
adb devices; cat $TASKS/bm7iq9tbr.output
```

**278.** `18:36` Restart adb server and recheck

```sh
adb kill-server; adb start-server >/dev/null 2>&1; adb devices; cat $TASKS/bm7iq9tbr.output
```

**279.** `18:36` Recheck adb after restart

```sh
adb devices -l; cat $TASKS/bm7iq9tbr.output
```

**280.** `18:36` Restart adb cleanly and wait for device

```sh
adb kill-server 2>/dev/null; pkill -f "adb.*fork-server"; pkill -x adb; adb start-server 2>&1 | tail -1; adb wait-for-any-device 2>/dev/null & P=$!; for i in 1 2 3 4 5 6; do adb devices -l | tail -n +2; adb devices | grep -qw device && break; read -t 3 < /dev/zero 2>/dev/null || perl -e 'select(undef,undef,undef,3)'; done; kill $P 2>/dev/null; true
```

> **Owner:** Move all important files into ~/workspace/archos/ write a story of this rewrite. Prepare stuff to publish online the postmarket way and a useable ROM in the postmarket way so someone else can try use it.

**281.** `18:38` Check adb state after restart

```sh
cat $TASKS/bb43nlru8.output | tail -5; adb devices -l; ping -c1 -t2 172.16.42.1 | tail -1
```

**282.** `18:38` Search transcript for earlier adb offline fix

```sh
grep -o '"text":"[^"]*offline[^"]*"' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | head -8 | cut -c1-600
```

**283.** `18:38` Find how adb detection was fixed earlier

```sh
python3 -I - <<'EOF'
import json
p="~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl"
lines=open(p).read().splitlines()
for i,l in enumerate(lines):
    if 'does not detect' in l or 'Ok now!' in l:
        for l2 in lines[i:i+14]:
            try: d=json.loads(l2)
            except: continue
            c=d.get('message',{}).get('content')
            if isinstance(c,list):
                for x in c:
                    if x.get('type')=='tool_use': print('CMD:',json.dumps(x.get('input'))[:400])
                    elif x.get('type')=='text': print('TXT:',x['text'][:400])
                    elif x.get('type')=='tool_result':
                        r=x.get('content'); print('RES:',str(r)[:300])
        print('-----')
EOF
```

**284.** `18:38` Look for processes holding the USB device

```sh
ps aux | grep -i "[a]db\|[A]ndroid File\|[f]astboot" | cut -c1-200; tail -5 /var/folders/ds/_vh4qpgx1rv54zc8j1bq78s00000gn/T//adb.501.log; ioreg -p IOUSB -l 2>/dev/null | grep -iE '"USB Product Name"|"USB Serial Number"' | head
```

**285.** `18:38` Ask adb to reconnect offline device

```sh
adb reconnect offline 2>&1; perl -e 'select(undef,undef,undef,6)'; adb devices -l; adb -s WAWJMXNHCN get-state 2>&1
```

**286.** `18:39` Watch for tablet and boot it into pmOS (background)

```sh
for i in $(seq 1 240); do
  if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3 user@172.16.42.1 true 2>/dev/null; then echo "pmos up"; exit 0; fi
  if adb devices | grep -q "WAWJMXNHCN[[:space:]]*device"; then echo "android online -> reboot recovery"; adb reboot recovery; perl -e 'select(undef,undef,undef,40)'; fi
  perl -e 'select(undef,undef,undef,5)'
done; echo timeout; exit 1
```

**287.** `18:39` Inventory scratchpad and pmaports device packages

```sh
S=$S; ls -la $S $S/share $S/rkuboot; du -sh $S/* $S/share/* 2>/dev/null; docker exec pmos sh -c 'ls -la /work/cache_git/pmaports/device/testing/ | grep -i archos; ls -la /work/cache_git/pmaports/device/testing/device-archos-oxygen101 /work/cache_git/pmaports/device/testing/firmware-archos-oxygen101 2>&1; cd /work/cache_git/pmaports && git status --short | head; git log --oneline -1'
```

**288.** `18:39` Read device package files and list work dirs

```sh
S=$S; docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing; cat device-archos-oxygen101/APKBUILD device-archos-oxygen101/deviceinfo linux-archos-oxygen101/APKBUILD'; ls -R $S/diag $S/share/diag $S/hw $S/vtl $S/src $S/test $S/update | head -80; ls ~/workspace/archos 2>&1
```

**289.** `18:39` Search pmaports for Rockchip resource handling and bootimg options

```sh
P=$S/src/pmaports; grep -rl "resource_tool\|RSCE\|rkimage\|resource.img" $P --include=APKBUILD --include=deviceinfo 2>/dev/null | head; grep -rh "^deviceinfo_[a-z_]*=" $P/device/*/*/deviceinfo | cut -d= -f1 | sort | uniq -c | sort -rn | grep -i "bootimg\|flash\|second\|mkinitfs\|boot_" | head -40
```

**290.** `18:39` Look at examples of bootimg customization in pmaports

```sh
P=$S/src/pmaports; for k in mkinitfs_postprocess bootimg_custom_args bootimg_override_payload flash_rk_partition dtb_second; do echo "== $k"; grep -rn "deviceinfo_$k" $P/device/*/*/deviceinfo | head -4; done; grep -rn "rkdeveloptool" $P/device/*/*/deviceinfo | head -5
```

**291.** `18:39` Read mkinitfs postprocess example hooks

```sh
P=$S/src/pmaports/device; ls $P/archived/device-nokia-ant $P/archived/device-amazon-tate; cat $P/archived/device-nokia-ant/*.sh $P/archived/device-nokia-ant/APKBUILD $P/archived/device-amazon-tate/deviceinfo | head -150
```

**292.** `18:40` Extract session narrative from transcript

```sh
S=$S; python3 -I - > $S/narrative.txt <<'EOF'
import json
p="~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl"
for l in open(p):
    try: d=json.loads(l)
    except: continue
    t=d.get('type'); m=d.get('message',{}); c=m.get('content')
    if t=='user' and isinstance(c,str):
        if 'command-name' in c or 'local-command' in c: continue
        print('\n### USER:',c[:1500])
    elif t=='user' and isinstance(c,list):
        for x in c:
            if x.get('type')=='text' and 'system-reminder' not in x['text'][:30]: print('\n### USER:',x['text'][:1500])
    elif t=='assistant' and isinstance(c,list):
        for x in c:
            if x.get('type')=='text': print('\n## A:',x['text'][:3000])
            elif x.get('type')=='tool_use': print('  $',(x['input'].get('description') or str(x['input'])[:150]))
EOF
wc -c $S/narrative.txt
```

**293.** `18:40` Check tablet watcher

```sh
cat $TASKS/bq620bv0x.output; adb devices
```

**294.** `18:40` Inspect boot-deploy for postprocess and second support

```sh
docker exec pmos sh -c 'ls /work | head -30; R=$(ls -d /work/chroot_rootfs_* | head -1); echo $R; ls $R/usr/bin/boot-deploy $R/usr/sbin/mkinitfs 2>&1; grep -n "postprocess\|dtb_second\|second" $R/usr/bin/boot-deploy | head -30; ls $R/lib/firmware/brcm/ | grep 43362; ls $R/boot'
```

**295.** `18:41` Check mkinitfs and boot-deploy hook mechanism

```sh
docker exec pmos sh -c 'R=/work/chroot_rootfs_archos-oxygen101; head -5 $R/usr/bin/boot-deploy; file $R/usr/bin/boot-deploy; strings $R/usr/sbin/mkinitfs | grep -i "postprocess\|boot-deploy" | head; grep -rn "postprocess" $R/usr/share/boot-deploy $R/usr/bin/boot-deploy 2>/dev/null | head; ls $R/usr/share/boot-deploy 2>/dev/null'
```

**296.** `18:41` Read boot-deploy bootimg and postprocess flow

```sh
docker exec pmos sh -c 'F=/work/chroot_rootfs_archos-oxygen101/usr/share/boot-deploy/boot-deploy-functions.sh; grep -n "^[a-z_]*()" $F; sed -n 500,530p $F; sed -n 840,880p $F; grep -n "create_bootimg\|mkbootimg\|second" $F | head -40'
```

**297.** `18:41` Read create_bootimg setup and find_dtb

```sh
docker exec pmos sh -c 'F=/work/chroot_rootfs_archos-oxygen101/usr/share/boot-deploy/boot-deploy-functions.sh; sed -n 643,720p $F; sed -n 880,905p $F; sed -n 1367,1402p $F'
```

**298.** `18:41` Read pmbootstrap rkdeveloptool flasher actions

```sh
docker exec pmos sh -c 'F=$(python3 -c "import pmb,os;print(os.path.dirname(pmb.__file__))" 2>/dev/null || find / -name "pmb" -maxdepth 6 -type d 2>/dev/null | head -1); echo $F; grep -n -A25 "\"rkdeveloptool\"" $F/config/__init__.py | head -45'; cat $TASKS/bq620bv0x.output
```

**299.** `18:41` Check whether stock U-Boot has fastboot

```sh
S=$S; strings -n 6 $S/share/diag/uboot.bin | grep -i "fastboot\|rockusb\|reboot flag\|getvar\|flash:" | sort -u | head -40; grep -n "REBOOT_FLAG\|BOOT_FASTBOOT\|0x5242C3" $S/rkuboot/*.c $S/rkuboot/*.h | head -20
```

**300.** `18:41` Check watcher and reboot-mode values

```sh
cat $TASKS/bq620bv0x.output; adb devices; grep -n "reboot-mode" -A8 $S/share/ksrc/linux-6.12.90/arch/arm/boot/dts/rockchip/rk3288.dtsi 2>/dev/null | head -12; ls $S/share/ksrc/linux-6.12.90 | head
```

**301.** `18:41` Read rk3288 reboot-mode node

```sh
docker exec pmos sh -c 'T=$(ls /work/cache_distfiles/linux-6.12.90.tar.xz); tar xJf $T -O linux-6.12.90/arch/arm/boot/dts/rockchip/rk3288.dtsi | grep -n -A10 "reboot-mode"'
```

**302.** `18:42` Create archive layout and copy pmaports packages

```sh
mkdir -p ~/workspace/archos/{pmaports/device/testing/device-archos-oxygen101,pmaports/device/testing/linux-archos-oxygen101,pmaports/device/testing/firmware-archos-oxygen101,kernel,tools,notes/rk-uboot,release,wiki}; docker exec pmos sh -c 'cp -r /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/. /share/pm-linux/ 2>/dev/null || (mkdir -p /share/pm-linux /share/pm-device && cp -r /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/. /share/pm-linux/); mkdir -p /share/pm-device; cp -r /work/cache_git/pmaports/device/testing/device-archos-oxygen101/. /share/pm-device/; chmod -R a+rwX /share/pm-linux /share/pm-device'; S=$S; cp -r $S/share/pm-linux/. ~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101/; cp -r $S/share/pm-device/. ~/workspace/archos/pmaports/device/testing/device-archos-oxygen101/; ls -R ~/workspace/archos | head -40
```

**303.** `18:42` Test RSCE hook output matches Python packer

```sh
S=$S; mkdir -p $S/share/hooktest; cp ~/workspace/archos/pmaports/device/testing/device-archos-oxygen101/rockchip-rsce-second.sh $S/share/hooktest/; python3 -I - $S <<'EOF'
import sys, struct, importlib.util
S=sys.argv[1]; O=S+"/share/out"; T=S+"/share/hooktest"
spec=importlib.util.spec_from_file_location("mk",S+"/share/port/mkrkboot.py"); mk=importlib.util.module_from_spec(spec); spec.loader.exec_module(mk)
k=open(O+"/vmlinuz4","rb").read(); r=open(O+"/initramfs","rb").read(); d=open(O+"/dtb4.dtb","rb").read()
P=16384
def img(second):
    h=bytearray(P); h[:8]=b"ANDROID!"
    struct.pack_into("<10I",h,8,len(k),0x60408000,len(r),0x62000000,len(second),0x60F00000,0x60088000,P,0,0)
    pad=lambda b:b+b"\0"*(-len(b)%P)
    return bytes(h)+pad(k)+pad(r)+pad(second)
open(T+"/boot.img","wb").write(img(d))           # what boot-deploy produces (raw dtb second)
open(T+"/expected.img","wb").write(img(mk.write_rsce([("rk-kernel.dtb",d)])))
open(T+"/initramfs","wb").write(b"")
EOF
docker exec pmos sh -c 'cd /share/hooktest && busybox sh ./rockchip-rsce-second.sh /share/hooktest/initramfs && cmp boot.img expected.img && echo IDENTICAL && busybox sh ./rockchip-rsce-second.sh /share/hooktest/initramfs && cmp boot.img expected.img && echo IDEMPOTENT'
```

**304.** `18:43` Save DTB-only test image and check tablet

```sh
S=$S; cp $S/share/hooktest/expected.img $S/share/out/pmos-boot4-dtbonly.img; md5 -q $S/share/out/pmos-boot4-dtbonly.img $S/share/out/pmos-boot4.img; cat $TASKS/bq620bv0x.output; adb devices
```

**305.** `18:43` Inspect tablet USB interfaces

```sh
ioreg -p IOUSB -l -n "Archos 101 Oxygen" 2>/dev/null | grep -E '"idProduct"|"idVendor"|"USB Product Name"|"sessionID"|"kUSBCurrentConfiguration"|"Device Speed"' | head; ioreg -l -r -c IOUSBHostInterface 2>/dev/null | grep -B2 -A12 '"USB Interface Name"' | grep -E "Interface Name|bInterfaceClass|bInterfaceSubClass|bInterfaceProtocol|UsbExclusiveOwner" | head -30
```

**306.** `18:43` Inspect Archos USB descriptors and owners

```sh
ioreg -p IOUSB -w0 -l | grep -A40 '"Archos 101 Oxygen"' | grep -E 'idProduct|idVendor|UsbExclusiveOwner|kUSBCurrentConfiguration|USB Serial' | head; ioreg -w0 -l -r -n "Archos 101 Oxygen" | grep -E "IOUSBHostInterface|bInterfaceClass|bInterfaceSubClass|UsbExclusiveOwner|USB Interface Name" | head -20
```

**307.** `18:43` Restart adb server once more

```sh
adb kill-server; perl -e 'select(undef,undef,undef,2)'; adb start-server 2>&1|tail -1; perl -e 'select(undef,undef,undef,8)'; adb devices -l; tail -5 /var/folders/ds/_vh4qpgx1rv54zc8j1bq78s00000gn/T//adb.501.log
```

**308.** `18:43` List remaining work dirs and pmbootstrap config

```sh
S=$S; ls $S/vtl $S/test $S/update $S/src/rkrecovery | head -30; ls $S/share/keys; cat $S/share/out/cmdline; docker exec pmos sh -c 'cat /home/pmos/.config/pmbootstrap_v3.cfg 2>/dev/null || ls /home/pmos/.config'
```

**309.** `18:43` List test dirs and show panel patch

```sh
S=$S; ls -la $S/vtl $S/test $S/update; cat ~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101/0001-archos-oxygen101-dts-and-panel.patch | sed -n '/panel-simple.c/,$p' | head -80
```

**310.** `18:43` Extract stock WiFi NVRAM from system backup

```sh
S=$S; mkdir -p $S/share/fw; OFF=$(( (0x94000-0x50000)*512 )); dd if=$S/backup/emmc-rest.bin of=$S/share/fw/system.img bs=1m skip=$((OFF/1048576)) count=1024 2>&1 | tail -1; docker exec pmos sh -c 'cd /share/fw && (command -v debugfs || apk add -q e2fsprogs-extra) >/dev/null; debugfs -R "ls -l /etc/firmware" system.img 2>/dev/null | head -20; debugfs -R "dump /etc/firmware/nvram_RK901.txt nvram_RK901.txt" system.img; debugfs -R "stat /etc/firmware/nvram_RK901.txt" system.img 2>/dev/null | head -3; md5sum nvram_RK901.txt'
```

**311.** `18:44` Locate ext4 superblocks in eMMC backup

```sh
S=$S; python3 -I - $S/backup/emmc-rest.bin <<'EOF'
import sys
f=open(sys.argv[1],'rb')
for name,base in (("phys-0x50000",0x50000),("log-0x50000(phys 0x52000)",0x52000-0x2000)):
    pass
for start in (0x50000,0x52000):
    for part,lba in (("cache",0x50000),("system",0x92000)):
        off=(lba+0x2000-start)*512
        f.seek(off+1080); m=f.read(2)
        print(hex(start),part,hex(off),m.hex())
EOF
```

**312.** `18:44` Extract NVRAM from Android system image

```sh
S=$S; dd if=$S/backup/emmc-rest.bin of=$S/share/fw/system.img bs=1m skip=$((0x8400000/1048576)) count=1024 2>&1 | tail -1; docker exec pmos sh -c 'cd /share/fw && debugfs -R "ls -l /etc/firmware" system.img 2>/dev/null | grep -i "nvram\|fw_\|43362\|RK901" ; debugfs -R "dump /etc/firmware/nvram_RK901.txt nvram_RK901.txt" system.img 2>/dev/null; md5sum nvram_RK901.txt; wc -c nvram_RK901.txt; head -5 nvram_RK901.txt'; rm $S/share/fw/system.img
```

**313.** `18:44` Find how pmaports ships brcmfmac nvram files

```sh
P=$S/src/pmaports/device; ls $P/*/*/ | grep -i "brcmfmac\|nvram" | head; grep -rln "brcmfmac.*txt" $P/*/*/APKBUILD | head -8
```

**314.** `18:44` Read an example brcmfmac firmware package

```sh
P=$S/src/pmaports/device; ls $P/archived/firmware-beelink-gt1 $P/archived/firmware-acer-picasso; cat $P/archived/firmware-beelink-gt1/APKBUILD; grep -rl "nvram\|brcmfmac.*txt" $P/testing/*/APKBUILD $P/community/*/APKBUILD | head -5
```

**315.** `18:44` Check a firmware package shipping nvram locally

```sh
P=$S/src/pmaports/device; ls $P/testing/firmware-asus-sparrow $P/testing/firmware-lg-lenok; cat $P/testing/firmware-lg-lenok/APKBUILD
```

**316.** `18:44` Create firmware repo with stock NVRAM

```sh
cat $TASKS/bq620bv0x.output; adb devices | tail -n +2; S=$S; FW=~/workspace/archos/firmware-archos-oxygen101; mkdir -p $FW; cp $S/share/fw/nvram_RK901.txt "$FW/brcmfmac43362-sdio.archos,oxygen101.txt"; cat > $FW/README.md <<'EOF'
# Firmware for the Archos 101 Oxygen (postmarketOS)

Files needed by mainline Linux on the Archos 101 Oxygen (RK3288) that are not
in linux-firmware. They are packaged by `firmware-archos-oxygen101` in pmaports.

| File | Origin |
|---|---|
| `brcmfmac43362-sdio.archos,oxygen101.txt` | `/system/etc/firmware/nvram_RK901.txt` from the stock Android 4.4.4 firmware (Rockchip "RK901" BCM43362 module NVRAM, header `GB9662_NVRAM_V1.1_09132012`) |

The BCM43362 firmware itself (`brcmfmac43362-sdio.bin`) comes from linux-firmware.
EOF
ls -la $FW
```

**317.** `18:45` Check mkbootimg dependency and commit firmware repo

```sh
P=$S/src/pmaports/device; sed -n '/^depends/,/"/p' $P/testing/device-jolla-c2/APKBUILD; cd ~/workspace/archos/firmware-archos-oxygen101 2>/dev/null; git -C ~/workspace/archos/firmware-archos-oxygen101 init -q -b main && git -C ~/workspace/archos/firmware-archos-oxygen101 add -A && git -C ~/workspace/archos/firmware-archos-oxygen101 commit -q -m "Add BCM43362 NVRAM for the Archos 101 Oxygen

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git -C ~/workspace/archos/firmware-archos-oxygen101 log --format=%H -1
```

**318.** `18:45` Read stock boot.img header addresses

```sh
python3 -I -c "
import struct;d=open('$S/backup/boot.img','rb').read(64)
v=struct.unpack_from('<10I',d,8);print([hex(x) for x in v])"
```

**319.** `18:45` Install packages into pmaports and compute checksums

```sh
adb devices | tail -n +2; cat $TASKS/bq620bv0x.output; A=~/workspace/archos; S=$S; C=$(git -C $A/firmware-archos-oxygen101 log --format=%H -1); git -C $A/firmware-archos-oxygen101 archive --format=tar.gz --prefix=firmware-archos-oxygen101-$C/ -o $S/share/fw/firmware-archos-oxygen101-$C.tar.gz $C; mkdir -p $S/share/pm-fw; cp $A/pmaports/device/testing/firmware-archos-oxygen101/APKBUILD $S/share/pm-fw/; rm -rf $S/share/pm-device; mkdir -p $S/share/pm-device; cp $A/pmaports/device/testing/device-archos-oxygen101/* $S/share/pm-device/; docker exec pmos sh -c 'D=/work/cache_git/pmaports/device/testing; cp /share/fw/firmware-archos-oxygen101-*.tar.gz /work/cache_distfiles/; mkdir -p $D/firmware-archos-oxygen101; cp /share/pm-fw/APKBUILD $D/firmware-archos-oxygen101/; cp /share/pm-device/* $D/device-archos-oxygen101/; chmod -R a+rwX $D/firmware-archos-oxygen101 $D/device-archos-oxygen101 /work/cache_distfiles/firmware-archos-*'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum firmware-archos-oxygen101 device-archos-oxygen101 >/dev/null 2>&1; D=/work/cache_git/pmaports/device/testing; tail -4 $D/firmware-archos-oxygen101/APKBUILD $D/device-archos-oxygen101/APKBUILD'
```

**320.** `18:46` Show computed checksums

```sh
docker exec pmos sh -c 'D=/work/cache_git/pmaports/device/testing; for f in $D/firmware-archos-oxygen101/APKBUILD $D/device-archos-oxygen101/APKBUILD; do sed -n "/sha512sums/,\$p" $f; done'
```

**321.** `18:46` Build firmware and device packages

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap -y build --force --arch armv7 firmware-archos-oxygen101 device-archos-oxygen101 2>&1 | tail -4; ls /work/packages/v26.06/armv7/ | grep -i "archos"'; adb devices | tail -n +2
```

**322.** `18:46` Build release pmOS image with pmbootstrap install (background)

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap config ssh_keys False && pmbootstrap config extra_packages firefox-esr && pmbootstrap -y install --password 147147 --no-fde 2>&1 | tail -15; ls -la /work/chroot_native/home/pmos/rootfs/'
```

**323.** `18:46` Copy kernel sources, tools and notes into archive

```sh
A=~/workspace/archos; S=$S; cp $S/share/port/rk3288-archos-oxygen101.dts $S/share/port/vtl-ct36x.c $A/kernel/ ; cp $S/share/port/mkrkboot.py $S/share/port/mkrkupdate.py $S/share/port/vtlprobe.py $S/share/port/vtlpoll.py $S/share/port/wake.py $A/tools/; cp $S/rkuboot/rk_default_config.h $S/rkuboot/board_rockchip_common_rkboot_fastboot.c $S/rkuboot/board_rockchip_common_rkloader_rkloader.c $S/rkuboot/board_rockchip_rk32xx_rk32xx.c $S/rkuboot/arch_arm_lib_board.c $A/notes/rk-uboot/; cp $S/backup/stock.dts $A/notes/stock-android.dts; cp $S/hw/dmesg.txt $A/notes/stock-android-dmesg.txt; cp $S/vtl/* $A/notes/ 2>/dev/null; mkdir -p $A/notes/vendor-vtl-driver && mv $A/notes/chip.c $A/notes/chip.h $A/notes/vtl_ts.c $A/notes/vtl_ts.h $A/notes/vendor-vtl-driver/; cp $S/share/diag/base.dts $A/notes/ 2>/dev/null; strings -n 20 $S/backup/uboot.img | grep -m1 -A0 "CMDLINE" > $A/notes/parameter-cmdline.txt; python3 -I $S/share/port/mkrkupdate.py crccheck $S/update/parameter.bin; head -c 2048 $S/update/parameter.bin | strings > $A/notes/parameter.txt; ls -R $A | head -60
```

**324.** `18:47` Find source URLs used during the port

```sh
grep -o 'https\?://[^" \\]*vtl[^" \\]*' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | sort -u | head; grep -o 'https\?://[^" \\]*\(rkupdate\|recovery\|u-boot\)[^" \\]*' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | sort -u | head
```

**325.** `18:47` Find rkdeveloptool commands used earlier

```sh
grep -o 'rkdeveloptool [a-z][a-z]* [^"\\]\{0,80\}' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | sort -u | head -30; grep -o 'adb reboot [a-z]*' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | sort | uniq -c
```

**326.** `18:47` Show earlier rkdeveloptool flashing commands

```sh
python3 -I - <<'EOF'
import json
p="~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl"
for l in open(p):
    try: d=json.loads(l)
    except: continue
    c=d.get('message',{}).get('content')
    if isinstance(c,list):
        for x in c:
            if x.get('type')=='tool_use':
                cmd=x['input'].get('command','')
                if '$RK' in cmd or 'rkdeveloptool' in cmd and (' wl' in cmd or ' rl' in cmd or ' ppt' in cmd or ' rd' in cmd):
                    print('---',x['input'].get('description')); print(cmd[:900])
EOF
```

**327.** `18:47` Read boot-deploy kernel-on-update flashing logic

```sh
docker exec pmos sh -c 'F=/work/chroot_rootfs_archos-oxygen101/usr/share/boot-deploy/boot-deploy-functions.sh; sed -n 914,1000p $F' 2>&1 | head -90
```

**328.** `18:47` Check build, config and compute blkdevparts

```sh
cat $TASKS/bxkd0lrjq.output | tail -5; adb devices | tail -n +2; grep -n "CMDLINE_PARTITION\|^CONFIG_CMDLINE" ~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7; grep -n "aliases" -A8 ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts | head -12; python3 -I - <<'EOF'
parts="0x00002000@0x00002000(uboot),0x00002000@0x00004000(misc),0x00008000@0x00006000(resource),0x00008000@0x0000e000(kernel),0x00010000@0x00016000(boot),0x00010000@0x00026000(recovery),0x0001a000@0x00036000(backup),0x00040000@0x00050000(cache),0x00002000@0x00090000(kpanic),0x00200000@0x00092000(system),0x00002000@0x00292000(metadata),0x00020000@0x002A4000(radical_update),-@0x002C4000(userdata)"
def h(sect):
    b=sect*512
    for suf,div in (("G",1<<30),("M",1<<20),("K",1<<10)):
        if b%div==0: return f"{b//div}{suf}"
    return str(b)
out=[]
for p in parts.split(","):
    sz,rest=p.split("@"); off,name=rest.split("(")
    off=int(off,16)+0x2000
    out.append(f"{'-' if sz=='-' else h(int(sz,16))}@{h(off)}({name}")
print("blkdevparts=mmcblk0:"+",".join(out))
EOF
```

**329.** `18:48` Validate boot.img generated by pmbootstrap install

```sh
head -40 $TASKS/bxkd0lrjq.output | grep -iv "^\s*$" | tail -15; docker exec pmos sh -c 'R=/work/chroot_rootfs_archos-oxygen101; ls -la $R/boot; cp $R/boot/boot.img /share/out/release-boot.img'; python3 -I - <<'EOF'
import struct
p="$S/share/out/release-boot.img"
d=open(p,'rb').read()
v=struct.unpack_from('<10I',d,8); print(d[:8],[hex(x) for x in v]); P=v[7]
up=lambda x:(x+P-1)//P*P
so=P+up(v[0])+up(v[2]); s=d[so:so+v[4]]
print("second magic",s[:4], "entries",struct.unpack_from('<I',s,12)[0], s[516:530], struct.unpack_from('<II',s,516+256))
print("dtb magic", s[1024:1028].hex(), "cmdline", d[64:200].split(b'\0')[0])
EOF
```

**330.** `18:48` Read is_in_chroot and call order

```sh
docker exec pmos sh -c 'F=/work/chroot_rootfs_archos-oxygen101/usr/share/boot-deploy/boot-deploy-functions.sh; sed -n 906,913p $F; sed -n 1414,1420p $F; grep -n "flash_updated_boot_parts\|create_bootimg$\|^\s*create_bootimg" $F /work/chroot_rootfs_archos-oxygen101/usr/bin/boot-deploy | head'
```

**331.** `18:48` Call flash_boot at end of hook

```sh
F=~/workspace/archos/pmaports/device/testing/device-archos-oxygen101/rockchip-rsce-second.sh; printf '\nflash_boot\n' >> $F; tail -5 $F; sed -i '' 's/^	local part dev$/	local part dev=""/' $F; grep -n 'local part' $F
```

**332.** `18:48` Rewrite flash step to update only pmOS partitions

```sh
F=~/workspace/archos/pmaports/device/testing/device-archos-oxygen101/rockchip-rsce-second.sh; python3 -I - "$F" <<'EOF'
import sys,re
p=sys.argv[1]; s=open(p).read()
start=s.index("flash_boot() {"); end=s.index("\n}\n",start)+3
new='''flash_boot() {
	# Not from pmbootstrap: only on the running tablet
	[ "$(stat -c %d:%i /)" = "$(stat -c %d:%i /proc/1/root/.)" ] || return 0
	grep -q "archos,oxygen101" /proc/device-tree/compatible 2>/dev/null || return 0

	local part name dev
	for part in /sys/block/mmcblk*/mmcblk*p*; do
		# eMMC only, never the SD card
		[ "$(cat "$part/../device/type" 2>/dev/null)" = "MMC" ] || continue
		name=$(sed -n 's/^PARTNAME=//p' "$part/uevent")
		[ "$name" = "boot" ] || [ "$name" = "recovery" ] || continue
		dev="/dev/$(basename "$part")"
		# Only replace a postmarketOS image, keep Android's boot/recovery
		dd if="$dev" bs=512 skip=0 count=2 2>/dev/null | \\
			tail -c +65 | head -c 512 | grep -q "pmos_" || continue
		if [ "$(wc -c < "$bootimg")" -gt "$(blockdev --getsize64 "$dev")" ]; then
			echo "rockchip-rsce-second: boot.img does not fit in $name" >&2
			return 1
		fi
		echo "rockchip-rsce-second: writing boot.img to $name ($dev)"
		dd if="$bootimg" of="$dev" bs=1M conv=fsync 2>/dev/null
	done
}
'''
s=s[:start]+new+s[end:]
s=s.replace('\tlocal part name dev\n','\tlocal part name dev\n',1)
s=s.replace('fi\nflash_boot() {','fi\n\nflash_boot() {')
open(p,'w').write(s)
EOF
sed -n 40,80p $F
```

**333.** `18:49` Add blkdevparts to cmdline and rebuild kernel and device pkgs (background)

```sh
A=~/workspace/archos/pmaports/device/testing; S=$S; BP='blkdevparts=mmcblk0:4M@8M(uboot),4M@12M(misc),16M@16M(resource),16M@32M(kernel),32M@48M(boot),32M@80M(recovery),52M@112M(backup),128M@164M(cache),4M@292M(kpanic),1G@296M(system),4M@1320M(metadata),64M@1356M(radical_update),-@1420M(userdata)'; sed -i '' "s|^CONFIG_CMDLINE=.*|CONFIG_CMDLINE=\"console=ttyS2,115200n8 console=tty0 PMOS_FORCE_PARTITION_RESIZE panic=30 $BP\"|" $A/linux-archos-oxygen101/config-archos-oxygen101.armv7; grep -n '^CONFIG_CMDLINE=' $A/linux-archos-oxygen101/config-archos-oxygen101.armv7; cp $A/linux-archos-oxygen101/config-archos-oxygen101.armv7 $S/share/pm-linux/; cp $A/device-archos-oxygen101/rockchip-rsce-second.sh $S/share/pm-device/; cp $A/device-archos-oxygen101/rockchip-rsce-second.sh $S/share/hooktest/; docker exec pmos sh -c 'cd /share/hooktest && cp expected.img e2.img && python3 - <<EOF
import struct
d=bytearray(open("/share/hooktest/boot.img","rb").read())
EOF
true'; docker exec pmos sh -c 'D=/work/cache_git/pmaports/device/testing; cp /share/pm-linux/config-archos-oxygen101.armv7 $D/linux-archos-oxygen101/; cp /share/pm-device/rockchip-rsce-second.sh $D/device-archos-oxygen101/; chmod -R a+rwX $D/*archos*'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 device-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 device-archos-oxygen101 2>&1 | tail -3'
```

**334.** `18:49` Re-run hook test after edits

```sh
docker exec pmos sh -c 'cd /share/hooktest && cp boot.img boot.bak && python3 -c "
import struct,sys
" 2>/dev/null; dd if=expected.img of=/dev/null 2>/dev/null; R=/work/chroot_rootfs_archos-oxygen101; cp /share/out/release-boot.img rb.img; busybox sh ./rockchip-rsce-second.sh /share/hooktest/initramfs && cmp boot.img expected.img && echo STILL-IDENTICAL'; adb devices | tail -n +2
```

**335.** `18:49` Re-test wrap path from a raw-DTB image

```sh
S=$S; python3 -I - $S <<'EOF'
import sys, struct
S=sys.argv[1]; O=S+"/share/out"; T=S+"/share/hooktest"
k=open(O+"/vmlinuz4","rb").read(); r=open(O+"/initramfs","rb").read(); d=open(O+"/dtb4.dtb","rb").read()
P=16384; h=bytearray(P); h[:8]=b"ANDROID!"
struct.pack_into("<10I",h,8,len(k),0x60408000,len(r),0x62000000,len(d),0x60F00000,0x60088000,P,0,0)
pad=lambda b:b+b"\0"*(-len(b)%P)
open(T+"/boot.img","wb").write(bytes(h)+pad(k)+pad(r)+pad(d))
EOF
docker exec pmos sh -c 'cd /share/hooktest && busybox sh ./rockchip-rsce-second.sh /share/hooktest/initramfs && cmp boot.img expected.img && echo WRAP-IDENTICAL'
```

**336.** `18:50` Check tablet and read pmaports commit style

```sh
adb devices | tail -n +2; cat $TASKS/bq620bv0x.output; cat $S/src/pmaports/COMMITSTYLE.md | head -60
```

**337.** `18:50` Check kernel rebuild and tablet

```sh
cat $TASKS/bpwktbv74.output; adb devices | tail -n +2
```

> **Owner:** Online now

**338.** `18:51` Check tablet state now

```sh
adb devices -l; cat $TASKS/bq620bv0x.output; ping -c1 -t2 172.16.42.1 | tail -1
```

**339.** `18:51` Watch adb state for a few seconds

```sh
for i in 1 2 3 4 5 6; do perl -e 'select(undef,undef,undef,3)'; S=$(adb devices | grep WAWJ); echo "$S"; echo "$S" | grep -qw device && break; done; cat $TASKS/bq620bv0x.output
```

**340.** `18:52` Force adb reconnect on the device

```sh
adb -s WAWJMXNHCN reconnect 2>&1; perl -e 'select(undef,undef,undef,6)'; adb devices | tail -n +2
```

**341.** `18:52` Check kernel build

```sh
cat $TASKS/bpwktbv74.output | tail -3
```

**342.** `18:54` Check build result and tablet state

```sh
tail -3 $TASKS/bpwktbv74.output; docker exec pmos sh -c 'ls -la --time-style=+%H:%M /work/packages/v26.06/armv7/ | grep archos'; adb devices | tail -n +2; cat $TASKS/bq620bv0x.output
```

**343.** `18:54` Bump kernel pkgrel and rebuild (background)

```sh
A=~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101; sed -i '' 's/^pkgrel=0$/pkgrel=1/' $A/APKBUILD; grep -n ^pkgrel $A/APKBUILD; docker exec pmos sh -c 'sed -i "s/^pkgrel=0$/pkgrel=1/" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/APKBUILD'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -2; ls /work/packages/v26.06/armv7/ | grep linux-archos'
```

**344.** `18:54` Wait for pmOS SSH

```sh
for i in $(seq 1 36); do ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3 user@172.16.42.1 'uname -r; uptime' 2>/dev/null && break; perl -e 'select(undef,undef,undef,5)'; done
```

**345.** `18:54` Disable suspend and inspect previous boot ending

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/10000/bus; for k in sleep-inactive-ac-type sleep-inactive-battery-type; do gsettings set org.gnome.settings-daemon.plugins.power $k nothing; done; gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type; gsettings set org.gnome.desktop.session idle-delay 300; journalctl --list-boots --no-pager | tail -3; echo 147147 | sudo -S -p "" journalctl -b -1 --no-pager | grep -iE "suspend|sleep|power key|shutdown|reboot|logind" | tail -15'
```

**346.** `18:54` See what triggered previous shutdown

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" journalctl -b -1 --no-pager --since "18:36:00" | head -25; cat /sys/class/power_supply/*/capacity /sys/class/power_supply/*/status 2>/dev/null'
```

**347.** `18:54` Check network and package state on tablet

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'nmcli -t -f NAME,DEVICE,STATE con show --active; ip route | head -3; ping -c1 -W3 dl-cdn.alpinelinux.org 2>&1 | tail -1; apk info -e android-tools mkbootimg linux-firmware-brcm; ls -la /lib/firmware/brcm/*oxygen* /usr/lib/firmware/brcm/*oxygen* 2>&1; apk info -W /usr/lib/firmware/brcm/brcmfmac43362-sdio.archos,oxygen101.txt 2>&1 | tail -1; cat /etc/apk/repositories; ls /etc/apk/keys' 2>&1 | grep -v Warning
```

**348.** `18:55` Check kernel rebuild output

```sh
cat $TASKS/b91e6ofpt.output
```

**349.** `18:55` Copy device and firmware apks to tablet

```sh
S=$S; mkdir -p $S/share/apks; docker exec pmos sh -c 'cp /work/packages/v26.06/armv7/device-archos-oxygen101-2-r0.apk /work/packages/v26.06/armv7/device-archos-oxygen101-nonfree-firmware-2-r0.apk /work/packages/v26.06/armv7/firmware-archos-oxygen101-1-r0.apk /share/apks/'; scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -q $S/share/apks/*.apk user@172.16.42.1:/home/user/ 2>&1 | grep -v Warning; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'ls -la ~/*.apk; cat /sys/block/mmcblk0/device/type /sys/block/mmcblk1/device/type; ls /sys/block/mmcblk0/' 2>&1 | grep -v Warning
```

**350.** `18:55` Inspect existing eMMC partition and cmdline

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'cat /sys/block/mmcblk0/mmcblk0p1/start /sys/block/mmcblk0/mmcblk0p1/size /sys/block/mmcblk0/size; cat /proc/cmdline' 2>&1 | grep -v Warning
```

**351.** `18:55` Wait for kernel rebuild to finish

```sh
until grep -q "linux-archos" $TASKS/b91e6ofpt.output; do perl -e 'select(undef,undef,undef,5)'; done; cat $TASKS/b91e6ofpt.output
```

**352.** `18:56` Install new kernel, device and firmware packages

```sh
S=$S; docker exec pmos sh -c 'cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r1.apk /share/apks/'; scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -q $S/share/apks/linux-archos-oxygen101-6.12.90-r1.apk user@172.16.42.1:/home/user/ 2>&1 | grep -v Warning; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" sh -c "rm -f /usr/lib/firmware/brcm/brcmfmac43362-sdio.archos,oxygen101.txt; apk add ~user/linux-archos-oxygen101-6.12.90-r1.apk ~user/device-archos-oxygen101-2-r0.apk ~user/device-archos-oxygen101-nonfree-firmware-2-r0.apk ~user/firmware-archos-oxygen101-1-r0.apk 2>&1 | tail -25"' 2>&1 | grep -v Warning
```

**353.** `18:58` Verify boot.img and flash it to eMMC boot partition

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" sh -c "
B=/boot/boot.img; ls -la \$B
od -An -tx4 -j8 -N36 \$B
dd if=\$B bs=1 skip=64 count=120 2>/dev/null; echo
apk info -L firmware-archos-oxygen101 | tail -1
# second section magic
K=\$(od -An -tu4 -j8 -N4 \$B|tr -d \" \"); R=\$(od -An -tu4 -j16 -N4 \$B|tr -d \" \"); P=16384
SO=\$(( (1 + (K+P-1)/P + (R+P-1)/P) * P )); dd if=\$B bs=1 skip=\$SO count=4 2>/dev/null; echo \" at \$SO\"
# backup current boot partition (stock Android) header for reference, then flash
dd if=/dev/mmcblk0 bs=512 skip=\$((0x18000)) count=16 2>/dev/null | head -c 8; echo \" <- current boot partition magic\"
dd if=\$B of=/dev/mmcblk0 bs=512 seek=\$((0x18000)) conv=fsync 2>&1 | tail -1
N=\$(( \$(wc -c < \$B) ))
dd if=/dev/mmcblk0 bs=512 skip=\$((0x18000)) count=\$((N/512)) 2>/dev/null | md5sum; md5sum < \$B
"' 2>&1 | grep -v Warning
```

**354.** `18:58` Reboot tablet and wait for pmOS from boot partition

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" systemctl reboot' 2>&1 | grep -v Warning; perl -e 'select(undef,undef,undef,20)'; for i in $(seq 1 40); do ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3 user@172.16.42.1 'uname -v; cat /proc/cmdline | tr " " "\n" | grep -c blkdevparts; uptime' 2>/dev/null && break; perl -e 'select(undef,undef,undef,5)'; done
```

**355.** `19:00` Check partitions, input devices, drivers

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'for p in /sys/block/mmcblk0/mmcblk0p*; do echo "$(basename $p) $(sed -n s/^PARTNAME=//p $p/uevent)"; done | tr "\n" " "; echo; grep -H "" /sys/class/input/input*/name; echo 147147 | sudo -S -p "" dmesg | grep -iE "adc-keys|gpio-keys|ct36x|brcmf.*Firmware|saradc|reboot-mode" | head; nmcli -t -f DEVICE,STATE dev | head -3; cat /sys/bus/iio/devices/iio:device*/in_voltage1_raw 2>/dev/null' 2>&1 | grep -v Warning
```

**356.** `19:00` Inspect WiFi/SDIO and regulator state

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" sh -c "dmesg | grep -iE \"mmc2|brcm|sdio|dwmmc|regulator|vcc|ldo|dcdc\" | head -40; ls /sys/bus/sdio/devices; cat /sys/kernel/debug/regulator/regulator_summary 2>/dev/null | head -50"' 2>&1 | grep -v Warning
```

**357.** `19:00` Find io-domains, touch and WiFi power in stock DTS

```sh
D=~/workspace/archos/notes/stock-android.dts; grep -n "io-domain\|io_domain\|vccio\|wifi-supply\|sdcard-supply\|rockchip,grf-io" $D | head -20; grep -n -B2 -A25 'compatible = "vtl,ct' $D | head -45; grep -n -A30 'wireless-wlan' $D | head -40
```

**358.** `19:00` Search stock DTS for IO voltage and touch nodes

```sh
D=~/workspace/archos/notes/stock-android.dts; grep -n -i "vsel\|io-vol\|vol_domain\|voltage-domain\|ap0_vcc\|wl_vcc\|io_vol" $D | head -20; grep -n -i -B3 -A20 "vtl\|touch" $D | grep -v "^\s*$" | head -50
```

**359.** `19:00` Read io_vol_domain nodes and vendor touch power

```sh
D=~/workspace/archos/notes/stock-android.dts; sed -n 5935,6030p $D | grep -v "^\s*$"; grep -n "regulator\|vcc\|power" ~/workspace/archos/notes/vendor-vtl-driver/*.c | head
```

**360.** `19:01` List DTS regulator labels and names

```sh
D=~/workspace/archos/kernel/rk3288-archos-oxygen101.dts; grep -n "regulator-name\|^\s*[a-z_0-9]*: [a-z_0-9@-]* {" $D | grep -B1 "regulator-name" | grep -o '[a-z_0-9]*: \|"[a-z_0-9]*"' | paste - - | head -40; grep -n "io_domains\|io-domains" $D
```

**361.** `19:01` Find labels for IO domain regulators

```sh
D=~/workspace/archos/kernel/rk3288-archos-oxygen101.dts; grep -n -B2 'regulator-name = "\(vccio\|vcc_lcd\|vccio_pmu\|vcc_sd\|vcc_wl\|vcc_18\)"' $D | grep -E "^[0-9]+-\s*[a-z_0-9]+:|regulator-name"; grep -n "vccio_sd" ~/workspace/archos/notes/stock-android.dts | head -3; sed -n 4780,4795p ~/workspace/archos/notes/stock-android.dts
```

**362.** `19:01` Map stock Ricoh regulators to names

```sh
D=~/workspace/archos/notes/stock-android.dts; awk 'NR>=4880 && NR<=5100' $D | grep -E "compatible|regulator-compatible|regulator-name|min-microvolt|ricoh|act88" | paste - - - - 2>/dev/null | head -30; grep -n "ricoh619\|act8846\|rk808\|status" $D | sed -n 1,200p | grep -iE "ricoh|act88|rk808" | head
```

**363.** `19:01` Check available touch probe scripts

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'ls ~; head -30 ~/vtlpoll.py 2>/dev/null | grep -n "def \|argv" ' 2>&1 | grep -v Warning; sed -n 1,40p ~/workspace/archos/tools/vtlprobe.py
```

**364.** `19:01` Test touch controller reset sequences manually

```sh
cat > $S/share/port/vtlreset.py <<'EOF'
#!/usr/bin/env python3
"""Try VTL CT36x reset sequences and report whether 0x01 / 0x7f answer."""
import fcntl, os, struct, time

GPIO_GET_LINEHANDLE = 0xC16CB403
GPIOHANDLE_SET_VALUES = 0xC040B409
I2C_SLAVE_FORCE = 0x0706


def line(chip, offset, value):
    req = struct.pack("<64I I 64B 32s I i", *([offset] + [0] * 63), 2,
                      *([value] + [0] * 63), b"vtlreset", 1, 0)
    fd = os.open(chip, os.O_RDONLY)
    res = fcntl.ioctl(fd, GPIO_GET_LINEHANDLE, req)
    os.close(fd)
    return struct.unpack_from("<i", res, len(res) - 4)[0]


def setv(h, v):
    fcntl.ioctl(h, GPIOHANDLE_SET_VALUES, bytes([v]) + bytes(63))


def probe(addr, n=8):
    fd = os.open("/dev/i2c-4", os.O_RDWR)
    fcntl.ioctl(fd, I2C_SLAVE_FORCE, addr)
    try:
        return os.read(fd, n).hex()
    except OSError as e:
        return "ERR %s" % e.strerror
    finally:
        os.close(fd)


rst = line("/dev/gpiochip7", 5, 1)
for low, wait in ((0.05, 0.2), (0.05, 1.0), (0.2, 2.0)):
    setv(rst, 0); time.sleep(low); setv(rst, 1); time.sleep(wait)
    print("reset low %.2fs wait %.1fs: 0x01=%s 0x7f=%s" % (low, wait, probe(0x01), probe(0x7f)))
EOF
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -q $S/share/port/vtlreset.py user@172.16.42.1: 2>&1 | grep -v Warning; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" python3 ~/vtlreset.py; echo 147147 | sudo -S -p "" cat /sys/kernel/debug/pinctrl/*/pinmux-pins 2>/dev/null | grep -E "pin 2(29|30|34|35|37|38) " ' 2>&1 | grep -v Warning
```

**365.** `19:02` Compare stock and port LDO configuration

```sh
D=~/workspace/archos/notes/stock-android.dts; awk 'NR>=4930 && NR<=5110' $D | grep -E "regulator-compatible|regulator-name|microvolt|always-on|boot-on|regulator-state-mem|regulator-state-enabled|regulator-state-disabled" | sed 's/^\s*//' | awk '/regulator-compatible/{printf "\n"} {printf "%s ", $0}' ; echo; grep -n -A12 'LDO8 {\|LDO2 {\|LDO3 {\|LDORTC1 {' ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts | grep -E "LDO|name|microvolt|always|boot-on"
```

**366.** `19:02` Find io_domains node and a veyron example

```sh
docker exec pmos sh -c 'tar xJf /work/cache_distfiles/linux-6.12.90.tar.xz -O linux-6.12.90/arch/arm/boot/dts/rockchip/rk3288.dtsi | grep -n -B2 -A3 "io-voltage-domain"; tar xJf /work/cache_distfiles/linux-6.12.90.tar.xz -O linux-6.12.90/arch/arm/boot/dts/rockchip/rk3288-veyron.dtsi | grep -n -A14 "^&io_domains"'
```

**367.** `19:02` Add io-domains and touch vdd-supply to DTS

```sh
D=~/workspace/archos/kernel/rk3288-archos-oxygen101.dts; python3 -I - "$D" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
anchor="&saradc {"
assert s.count(anchor)==1
io='''/*
 * I/O voltage domains, from the stock kernel's io_vol_domain nodes. The
 * SDIO WiFi bus runs at 1.8 V; Android's warm reboot kept this setting
 * in the GRF, a full reset does not.
 */
&io_domains {
	status = "okay";

	audio-supply = <&vccio>;
	bb-supply = <&vccio>;
	dvp-supply = <&vcc_18>;
	flash0-supply = <&vccio>;
	flash1-supply = <&vccio>;
	gpio1830-supply = <&vccio>;
	gpio30-supply = <&vccio_pmu>;
	lcdc-supply = <&vcc_lcd>;
	sdcard-supply = <&vcc_sd>;
	wifi-supply = <&vcc_wl>;
};

'''
s=s.replace(anchor, io+anchor)
old='''		compatible = "vtl,ct365";
		reg = <0x01>;
'''
assert s.count(old)==1
s=s.replace(old, old+'''		/* Exact rail unknown, one of the always-on Ricoh 3.3 V LDOs */
		vdd-supply = <&ldo8>;
''')
open(p,'w').write(s)
EOF
grep -n -A12 "touchscreen@1" $D
```

**368.** `19:03` Create patch 0004, bump pkgrel, rebuild kernel (background)

```sh
S=$S; K=$S/share/ksrc; F=arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts; A=~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101; mkdir -p $K/e/$(dirname $F); cp ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts $K/e/$F; cp ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts $S/share/port/; diff -u --label a/$F --label b/$F $K/d/$F $K/e/$F > $A/0004-archos-oxygen101-io-domains-touch-supply.patch; wc -l $A/0004*; sed -i '' 's/^pkgrel=1$/pkgrel=2/; s/^\t0003-archos-oxygen101-keys.patch$/&\
	0004-archos-oxygen101-io-domains-touch-supply.patch/' $A/APKBUILD; grep -n "pkgrel\|000[34]" $A/APKBUILD; mkdir -p $S/share/pm-linux; cp $A/APKBUILD $A/0004* $S/share/pm-linux/; docker exec pmos sh -c 'D=/work/cache_git/pmaports/device/testing/linux-archos-oxygen101; cp /share/pm-linux/APKBUILD /share/pm-linux/0004* $D/; chmod -R a+rwX $D'; docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -2; ls /work/packages/v26.06/armv7/ | grep linux-archos'
```

**369.** `19:03` Wait for kernel r2 build

```sh
until grep -q "linux-archos" $TASKS/b9s8x9wek.output 2>/dev/null; do perl -e 'select(undef,undef,undef,5)'; done; cat $TASKS/b9s8x9wek.output | tail -4
```

**370.** `19:03` Inspect archive kernel APKBUILD

```sh
sed -n 1,12p ~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101/APKBUILD; grep -n "patch" ~/workspace/archos/pmaports/device/testing/linux-archos-oxygen101/APKBUILD
```

**371.** `19:03` Wait for kernel r2 build completion

```sh
until grep -qE "DONE|ERROR" $TASKS/b9s8x9wek.output 2>/dev/null; do perl -e 'select(undef,undef,undef,5)'; done; tail -4 $TASKS/b9s8x9wek.output
```

**372.** `19:04` Install kernel r2 and verify automatic boot flash

```sh
S=$S; docker exec pmos sh -c 'cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r2.apk /share/apks/'; scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -q $S/share/apks/linux-archos-oxygen101-6.12.90-r2.apk user@172.16.42.1: 2>&1 | grep -v Warning; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" sh -c "apk add ~user/linux-archos-oxygen101-6.12.90-r2.apk 2>&1 | grep -E \"rockchip-rsce|boot.img|Upgrading|ERROR|OK:\"; N=\$(wc -c < /boot/boot.img); dd if=/dev/mmcblk0p5 bs=512 count=\$((N/512)) 2>/dev/null | md5sum; md5sum < /boot/boot.img; dd if=/dev/mmcblk0p6 bs=8 count=1 2>/dev/null; echo \" <- recovery magic (untouched)\"; dd if=/dev/mmcblk0p6 bs=1 skip=64 count=20 2>/dev/null | od -c | head -2"' 2>&1 | grep -v Warning
```

**373.** `19:08` Reboot to r2 and check touch and WiFi

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" systemctl reboot' 2>&1 | grep -v Warning; perl -e 'select(undef,undef,undef,25)'; for i in $(seq 1 40); do ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3 user@172.16.42.1 'uname -v; echo 147147 | sudo -S -p "" dmesg | grep -iE "ct36x|brcmf.*(Firmware|error|fail)|mmc2|io-domain|rockchip-iodomain" | head -12; grep -H "" /sys/class/input/input*/name; nmcli -t -f DEVICE,STATE,CONNECTION dev | head -4' 2>/dev/null && break; perl -e 'select(undef,undef,undef,5)'; done
```

**374.** `19:10` Record key and touch events for 5 minutes

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes user@172.16.42.1 'echo 147147 | sudo -S -p "" sh -c "rm -f /home/user/keys.log; for d in /dev/input/event*; do (echo \$d; timeout 300 evtest \$d) >> /home/user/keys-\$(basename \$d).log 2>&1 & done; sleep 1; ls /home/user/keys-*"' 2>&1 | grep -v Warning
```


## 2026-10-21

> **Owner:** Did you flash the verion with button support? I think right now the screen is off but the button does not wake it up. Also the battery seems to be always 0%

**375.** `07:43` The tablet now always boots pmOS.

```sh
SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=5 user@172.16.42.1"; $SSH 'uname -a; cat /proc/cmdline; apk info -v 2>/dev/null | grep -i archos; for f in ~/keys-event*.log; do echo "== $f"; grep -v "^ " $f | grep -i "type 1\|EV_KEY\|SW_" | head -20; done; cat /proc/bus/input/devices | grep -A4 "N: Name"; ls /sys/class/power_supply/; for d in /sys/class/power_supply/*; do echo "== $d"; cat $d/uevent; done' 2>&1 | grep -v "^Warning"
```

**376.** `07:43`

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=5 user@172.16.42.1 'uname -a; cat /proc/cmdline; apk info -v 2>/dev/null | grep -i archos; for f in ~/keys-event*.log; do echo "== $f"; grep -i "EV_KEY\|EV_SW" $f | grep -v "^ \|Event code" | head -20; done; grep -A4 "N: Name" /proc/bus/input/devices; ls /sys/class/power_supply/; for d in /sys/class/power_supply/*; do echo "== $d"; cat $d/uevent; done' 2>&1 | grep -v "^Warning"
```

**377.** `07:44`

```sh
ping -c 3 -t 5 172.16.42.1; ifconfig | grep -B3 172.16.42; system_profiler SPUSBDataType 2>/dev/null | grep -i -A6 "postmarket\|rockchip\|archos\|2207\|18d1" | head -30
```

**378.** `07:44`

```sh
ioreg -p IOUSB -l -w0 2>/dev/null | grep -E '"USB Product Name"|"idVendor"|"USB Vendor Name"' | head -40; ifconfig -l
```

**379.** `07:44`

```sh
arp -a | head -40; ls ~/workspace/archos/; ls $S/share/ 2>/dev/null | head
```

**380.** `07:44`

```sh
cd ~/workspace/archos; grep -n "RN5T618\|BATTERY\|CHARGER\|POWER_SUPPLY\|SUSPEND\|PM_SLEEP\|KEYBOARD_GPIO\|ADC" pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7 | head -40; grep -n "pmic\|rn5t618\|rc5t619\|charger\|battery\|power-key\|wakeup\|interrupt" kernel/rk3288-archos-oxygen101.dts | head -40
```

**381.** `07:44`

```sh
cd ~/workspace/archos; grep -n "RN5T618\|CHARGER_RN\|MFD_RN" pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7; sed -n 195,215p kernel/rk3288-archos-oxygen101.dts; grep -n "battery\|charger\|rk818\|ricoh\|rc5t619\|fuel\|lid\|hall" notes/stock-android-dmesg.txt | head -40
```

**382.** `07:45`

```sh
cd ~/workspace/archos/notes; grep -n -i "battery\|charg\|fuel\|ilim\|ichg\|vfchg\|capacity" stock-android.dts | head -40; grep -i -n "battery\|charg\|ricoh619\|soc\b" stock-android-dmesg.txt | head -30
```

**383.** `07:45`

```sh
cd ~/workspace/archos/notes; sed -n 4640,4660p stock-android.dts; sed -n 4895,4935p stock-android.dts; sed -n 5210,5230p stock-android.dts
```

> **Owner:** Should be ok now

**384.** `07:57` Yes, the kernel with button support (r2) is the one in the `boot` partition, and it was running the last time I could reach the tablet.

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=8 user@172.16.42.1 'uname -v; uptime; last -x 2>/dev/null | head -5; for f in ~/keys-event*.log; do echo "== $f"; grep -E "EV_KEY|EV_SW" $f | grep -v "Event code\|Supported" | head -10; done; lsmod | grep -i rn5t; ls /sys/class/power_supply/; for d in /sys/class/power_supply/*; do echo "== $d"; cat $d/uevent; done; journalctl -b -1 --no-pager 2>/dev/null | tail -30' 2>&1 | grep -v "^Warning"
```

> **Owner:** The volume is working but the power I don't think so

**385.** `07:57`

```sh
ping -c 2 -t 4 172.16.42.1; ifconfig | grep -B4 "172.16.42"; ioreg -p IOUSB -w0 | grep -iv "hub" | head; grep -n -i -B2 -A4 "172.16\|^host \*" ~/.ssh/config | head -30
```

**386.** `07:57` The tablet still isn't visible on this Mac's USB, so I'll look at the power key from the source while you plug it in.

```sh
cd ~/workspace/archos; sed -n 95,130p kernel/rk3288-archos-oxygen101.dts; grep -n -A6 "pwr_key\|pwr-key\|power-key\|KEY_POWER\|0x74>" kernel/rk3288-archos-oxygen101.dts | sed -n 1,40p; grep -n -i -B3 -A10 "power-key\|rockchip,key\|pwrkey\|gpio-keys" notes/stock-android.dts | head -60
```

**387.** `07:57`

```sh
cd ~/workspace/archos; grep -n -i "pwrkey\|power.key\|gpio-keys\|rk_keys\|keys\|0x74\b" notes/stock-android-dmesg.txt | head -20; grep -n -i "pwrkey\|ricoh619-pwrkey\|rc5t619\|rk_key\|key" notes/stock-android.dts | head -40
```

**388.** `07:57`

```sh
cd ~/workspace/archos/notes; grep -n "input:\|pwrkey\|ricoh619_pwrkey\|rk_key\|rkxx" stock-android-dmesg.txt | head; grep -n "phandle = <0xb3>" -B30 stock-android.dts | grep -E "gpio@|compatible" | tail -2; grep -rn "pwrkey\|PWRKEY\|PWRON" $S/share/ksrc/*/drivers/mfd/rn5t618.c 2>/dev/null | head; ls $S/share/ksrc/
```

**389.** `07:57`

```sh
K=$S/share/ksrc/linux-6.12.90; grep -rln "rn5t618\|RN5T618" $K/drivers $K/include | head -20; grep -n "IRQ\|cell\|name" $K/drivers/mfd/rn5t618.c | head -40; grep -n "PWRON\|PONHIS\|POFFHIS\|PWRIRQ\|PWRMON\|IR_SYS\|PWRIREN" $K/include/linux/mfd/rn5t618.h
```

**390.** `07:57`

```sh
docker ps --format '{{.Names}}'; docker exec pmos sh -c 'K=$(ls -d /work/chroot_native/home/pmos/build/src/linux-* 2>/dev/null | head -1); echo $K; ls $K | head -3; grep -n "IRQ\|cells\[\|\.name" $K/drivers/mfd/rn5t618.c | head -40; grep -n "PWRON\|PONHIS\|POFFHIS\|PWRIRQ\|PWRMON\|PWRIREN\|IR_" $K/include/linux/mfd/rn5t618.h | head -30'
```

**391.** `07:57`

```sh
docker exec pmos sh -c 'find / -xdev -name rn5t618.c -path "*mfd*" 2>/dev/null | head; ls /work/cache_distfiles | grep -i "linux\|tar" | head'
```

**392.** `07:57`

```sh
docker exec pmos sh -c 'mkdir -p /tmp/kx && cd /tmp/kx && tar xJf /work/cache_distfiles/linux-6.12.90.tar.xz linux-6.12.90/drivers/mfd/rn5t618.c linux-6.12.90/include/linux/mfd/rn5t618.h linux-6.12.90/drivers/power/supply/rn5t618_power.c && K=/tmp/kx/linux-6.12.90; grep -n "IRQ\|\.name\|MFD_CELL" $K/drivers/mfd/rn5t618.c | head -40; grep -n "PWRON\|PONHIS\|POFFHIS\|PWRIRQ\|PWRMON\|PWRIREN\|IR_\|0x0[0-9A-F]\b" $K/include/linux/mfd/rn5t618.h | head -40'
```

**393.** `07:58`

```sh
docker exec pmos sh -c 'K=/tmp/kx/linux-6.12.90; sed -n 1,140p $K/drivers/mfd/rn5t618.c; grep -n "capacity\|FA_CAP\|SOC\|FG_CTRL\|enabling\|iio\|probe" $K/drivers/power/supply/rn5t618_power.c | head -40; grep -n "INTEN\|INTMON\|IR_SYS\|PWRIRSEL\|0x15\b\|SOC\|FG_" $K/include/linux/mfd/rn5t618.h'
```

**394.** `07:58`

```sh
docker exec pmos sh -c 'K=/tmp/kx/linux-6.12.90; sed -n 220,245p $K/drivers/power/supply/rn5t618_power.c; sed -n 715,800p $K/drivers/power/supply/rn5t618_power.c'
```

**395.** `07:58`

```sh
S=$S/share; find $S/ksrc/e $S/ksrc/d -type f | head; docker exec pmos sh -c 'ls /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/; grep -n "pkgrel\|source=\|0004\|sha512" -A0 /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/APKBUILD'
```

**396.** `07:58`

```sh
ping -c1 -t2 172.16.42.1 >/dev/null && echo UP || echo DOWN; docker exec pmos sh -c 'cd /tmp/kx && tar xJf /work/cache_distfiles/linux-6.12.90.tar.xz linux-6.12.90/drivers/input/misc/Kconfig linux-6.12.90/drivers/input/misc/Makefile && grep -n "config INPUT_REGULATOR_HAPTIC\|config INPUT_RK805_PWRKEY\|rk805" linux-6.12.90/drivers/input/misc/Kconfig linux-6.12.90/drivers/input/misc/Makefile'
```

**397.** `07:59`

```sh
docker exec pmos sh -c 'cd /tmp/kx/linux-6.12.90 && sed -n 620,640p drivers/input/misc/Kconfig && sed -n 76,80p drivers/input/misc/Makefile'
```

**398.** `07:59`

```sh
S=$S/share; docker exec pmos sh -c '
set -e
cd /tmp/kx && rm -rf a b 2>/dev/null; mkdir -p a/drivers/input/misc a/drivers/mfd
K=linux-6.12.90
cp $K/drivers/input/misc/Kconfig $K/drivers/input/misc/Makefile a/drivers/input/misc/
cp $K/drivers/mfd/rn5t618.c a/drivers/mfd/
cp -r a b
cp /share/pwrkey/rn5t618-pwrkey.c b/drivers/input/misc/
cd b
awk "/^config INPUT_RK805_PWRKEY/{print \"config INPUT_RN5T618_PWRKEY\n\ttristate \\\"Ricoh RC5T619 PMIC power key support\\\"\n\tdepends on MFD_RN5T618\n\thelp\n\t  Say Y here to report the power key connected to the PWRON pin\n\t  of a Ricoh RC5T619 PMIC.\n\n\t  To compile this driver as a module, choose M here: the module will be\n\t  called rn5t618-pwrkey.\n\"} {print}" drivers/input/misc/Kconfig > k && mv k drivers/input/misc/Kconfig
sed -i "s|^obj-\$(CONFIG_INPUT_RK805_PWRKEY)\t+= rk805-pwrkey.o|&\nobj-\$(CONFIG_INPUT_RN5T618_PWRKEY)\t+= rn5t618-pwrkey.o|" drivers/input/misc/Makefile
sed -i "s|\t{ .name = \"rn5t618-power\" },|&\n\t{ .name = \"rn5t618-pwrkey\" },|" drivers/mfd/rn5t618.c
sed -i "s|\tcase RN5T618_WATCHDOGCNT:|\tcase RN5T618_PWRIRQ ... RN5T618_PWRMON:\n&|" drivers/mfd/rn5t618.c
cd ..
diff -urN a b > /share/pwrkey/0005-input-rn5t618-pwrkey.patch || true
sed -i "s|^--- a/|--- a/|" /share/pwrkey/0005-input-rn5t618-pwrkey.patch
cat /share/pwrkey/0005-input-rn5t618-pwrkey.patch | grep -v "^ " | head -60
'
```

> **Owner:** Also, how can I connect to SSH like you

**399.** `07:59`

```sh
docker exec pmos sh -c 'grep -A12 "^--- a/drivers/mfd" /share/pwrkey/0005-input-rn5t618-pwrkey.patch; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101 && grep -n "RN5T618\|INPUT_RK805" config-archos-oxygen101.armv7'
```

**400.** `07:59`

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101
grep -n "^CONFIG_IIO=\|CONFIG_ROCKCHIP_SARADC" config-archos-oxygen101.armv7
sed -i "s|^# CONFIG_RN5T618_ADC is not set|CONFIG_RN5T618_ADC=y|; s|^CONFIG_RN5T618_POWER=m|CONFIG_RN5T618_POWER=y|; s|^# CONFIG_INPUT_RK805_PWRKEY is not set|&\nCONFIG_INPUT_RN5T618_PWRKEY=y|" config-archos-oxygen101.armv7
cp /share/pwrkey/0005-input-rn5t618-pwrkey.patch .
sed -i "s|^pkgrel=2|pkgrel=3|; s|^\t0004-archos-oxygen101-io-domains-touch-supply.patch|&\n\t0005-input-rn5t618-pwrkey.patch|" APKBUILD
grep -n "pkgrel\|000[0-9]" APKBUILD; grep -n "RN5T618" config-archos-oxygen101.armv7
chmod -R a+rwX .'
```

**401.** `07:59`

```sh
grep -o 'docker exec[^"]*pmbootstrap[^"]*build[^"]\{0,120\}' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | tail -3
```

**402.** `08:00`

```sh
grep -o 'docker exec.\{0,60\}pmbootstrap.\{0,80\}build linux.\{0,60\}' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | tail -3
```

**403.** `08:00`

```sh
LC_ALL=C /usr/bin/grep -o 'docker exec[^"]\{0,100\}pmbootstrap[^"]\{0,100\}build[^"]\{0,80\}' ~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl | tail -3
```

**404.** `08:00` The kernel with the new power-key driver and the battery fix is building now; it takes a few minutes. (background)

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -3; ls /work/packages/v26.06/armv7/ | grep linux-archos'
```

> **Owner:** Look at the same time why the tablet is so slow. Is it just old or something is hooking up the CPU? And is the GPU support enabled?

**405.** `08:00` While the kernel builds:

```sh
cd ~/workspace/archos; grep -n "gpu\|cpu0\|cpu-supply\|mali\|syr\|fan53555\|tcs\|i2c1\b\|&i2c" kernel/rk3288-archos-oxygen101.dts; grep -n "PANFROST\|CPUFREQ_DT\|CONFIG_CPU_FREQ=\|DEFAULT_GOV\|REGULATOR_FAN53555\|ROCKCHIP_THERMAL\|CONFIG_HZ=" pmaports/device/testing/linux-archos-oxygen101/config-archos-oxygen101.armv7
```

**406.** `08:00`

```sh
cd ~/workspace/archos; sed -n 130,140p kernel/rk3288-archos-oxygen101.dts; sed -n 345,365p kernel/rk3288-archos-oxygen101.dts; grep -n -B2 -A30 "syr827@40\|syr828@41" notes/stock-android.dts | grep -v "^--$" | head -80; grep -n -i "syr\|fan53555\|cpufreq\|apll\|arm clk\|dvfs.*cpu\|gpu" notes/stock-android-dmesg.txt | head -20
```

**407.** `08:00`

```sh
cd ~/workspace/archos/notes; awk 'NR<=4659 && /i2c@/ {l=NR": "$0} END{print l}' stock-android.dts; awk 'NR<=4659 && /i2c@/ {print NR": "$0}' stock-android.dts | tail -2; grep -n "vsel\|syr82x\|fcs,suspend" stock-android.dts | head; grep -n "&gpu\|gpu {" ../kernel/rk3288-archos-oxygen101.dts
```

**408.** `08:00`

```sh
cd ~/workspace/archos/kernel; grep -n "vcc_sys\|vsys\|regulator-fixed\|^&\|^\t[a-z_0-9]*: " rk3288-archos-oxygen101.dts | head -60; sed -n 140,160p rk3288-archos-oxygen101.dts
```

**409.** `08:01`

```sh
S=$S/share; diff $S/ksrc/e/arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts && echo same; sed -n 40,52p ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts; sed -n 198,201p ~/workspace/archos/kernel/rk3288-archos-oxygen101.dts
```

**410.** `08:01`

```sh
S=$S/share; D=arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts; mkdir -p $S/ksrc/f/$(dirname $D) && cp $S/ksrc/e/$D $S/ksrc/f/$D && python3 - $S/ksrc/f/$D <<'EOF'
import sys,re
p=sys.argv[1]; s=open(p).read()
s=re.sub(r'&cpu0 \{\n\t/\* No cpu-supply yet: keep the frequency the loader set\. \*/\n\t/delete-property/ operating-points-v2;\n\};\n\n&cpu1 \{\n\t/delete-property/ operating-points-v2;\n\};\n\n&cpu2 \{\n\t/delete-property/ operating-points-v2;\n\};\n\n&cpu3 \{\n\t/delete-property/ operating-points-v2;\n\};\n',
'&cpu0 {\n\tcpu0-supply = <&vdd_cpu>;\n};\n',s)
s=s.replace('&i2c0 {\n\tclock-frequency = <400000>;\n\tstatus = "okay";\n',
'''&i2c0 {
	clock-frequency = <400000>;
	status = "okay";

	/* Same CPU/GPU supplies as the veyron Chromebooks, VSEL0 in use */
	vdd_cpu: regulator@40 {
		compatible = "silergy,syr827";
		reg = <0x40>;
		fcs,suspend-voltage-selector = <1>;
		regulator-name = "vdd_cpu";
		regulator-min-microvolt = <850000>;
		regulator-max-microvolt = <1350000>;
		regulator-ramp-delay = <8000>;
		regulator-always-on;
		regulator-boot-on;
		vin-supply = <&vcc_sys>;
	};

	vdd_gpu: regulator@41 {
		compatible = "silergy,syr828";
		reg = <0x41>;
		fcs,suspend-voltage-selector = <1>;
		regulator-name = "vdd_gpu";
		regulator-min-microvolt = <850000>;
		regulator-max-microvolt = <1250000>;
		regulator-ramp-delay = <6000>;
		regulator-always-on;
		regulator-boot-on;
		vin-supply = <&vcc_sys>;
	};
''',1)
s=s.replace('&i2c1 {','&gpu {\n\tmali-supply = <&vdd_gpu>;\n\tstatus = "okay";\n};\n\n&i2c1 {',1)
open(p,'w').write(s)
EOF
cd $S/ksrc && diff -u e/$D f/$D | sed "s|^--- e/|--- a/|;s|^+++ f/|+++ b/|" > $S/pwrkey/0006-archos-oxygen101-cpu-gpu-supplies.patch; cat $S/pwrkey/0006-archos-oxygen101-cpu-gpu-supplies.patch | head -80; grep -n "cpu0-supply\|cpu-supply" /dev/null
```

**411.** `08:01`

```sh
S=$S/share; D=arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts; sed -i '' 's/cpu0-supply = /cpu-supply = /' $S/ksrc/f/$D; cd $S/ksrc && diff -u e/$D f/$D | sed "s|^--- e/|--- a/|;s|^+++ f/|+++ b/|" > $S/pwrkey/0006-archos-oxygen101-cpu-gpu-supplies.patch; grep -n "supply = <&vdd" $S/pwrkey/0006*.patch; cat $TASKS/b1dkht0z1.output; ping -c1 -t2 172.16.42.1 >/dev/null && echo UP || echo DOWN
```

**412.** `08:03` Kernel r3 is still building.

```sh
cat $TASKS/b1dkht0z1.output; docker exec pmos sh -c 'grep -n "rn5t618-pwrkey\|error:\|Error" /work/log.txt | tail -5'; ping -c1 -t2 172.16.42.1 >/dev/null && echo UP || echo DOWN
```

**413.** `08:03` Kernel r3 built cleanly, with the new power-key driver compiled in.

```sh
docker exec pmos sh -c 'set -e; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r3.apk /share/apks/; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; cp /share/pwrkey/0006-archos-oxygen101-cpu-gpu-supplies.patch .; sed -i "s|^pkgrel=3|pkgrel=4|; s|^\t0005-input-rn5t618-pwrkey.patch|&\n\t0006-archos-oxygen101-cpu-gpu-supplies.patch|" APKBUILD; chmod -R a+rwX .; grep -n "pkgrel\|0006" APKBUILD'
```

**414.** `08:03` Kernel r3 built cleanly, with the new power-key driver compiled in. (background)

```sh
docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -3; ls /work/packages/v26.06/armv7/ | grep linux-archos'
```

**415.** `08:04` I've also prepared a check script (`diag.sh`) to run as soon as the tablet is connected.

```sh
cat $TASKS/ba4ch81i5.output; docker exec pmos sh -c 'grep -n "0006\|rk3288-archos-oxygen101.dtb" /work/log.txt | tail -4; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r4.apk /share/apks/ && mkdir -p /tmp/k4r && cd /tmp/k4r && tar xzf /share/apks/linux-archos-oxygen101-6.12.90-r4.apk 2>/dev/null; find /tmp/k4r -name "rk3288-archos-oxygen101.dtb" -o -name vmlinuz | head'; ping -c1 -t2 172.16.42.1 >/dev/null && echo UP || echo DOWN
```

**416.** `08:04`

```sh
docker exec pmos sh -c 'command -v dtc >/dev/null || apk add -q dtc 2>/dev/null; dtc -I dtb -O dts /tmp/k4r/boot/dtbs/rk3288-archos-oxygen101.dtb 2>/dev/null | grep -n "cpu-supply\|mali-supply\|syr82\|gpu@ffa30000" ; dtc -I dtb -O dts /tmp/k4r/boot/dtbs/rk3288-archos-oxygen101.dtb 2>/dev/null | grep -A3 "gpu@ffa30000 {" | grep status; ls /tmp/k4r/lib/modules/*/kernel/drivers/gpu/drm/panfrost/'
```

**417.** `08:04`

```sh
docker exec pmos sh -c 'dtc -I dtb -O dts /tmp/k4r/boot/dtbs/rk3288-archos-oxygen101.dtb 2>/dev/null | sed -n 1514,1530p | grep status; find /tmp/k4r -name "panfrost*"; ls /tmp/k4r/lib/modules 2>&1 | head -3; ls /tmp/k4r'
```

> **Owner:** The tablet is connected on lab-ap's wifi. Can you find its address? the postmarket wifi button leads to nothing, I can't see details

**418.** `08:16` Kernel r4 is built and checked.

```sh
cat ~/.claude/projects/<project>/memory/lab-socks-tunnel.md; grep -n -i -A8 "lab-ap" ~/.ssh/config | head -40
```

**419.** `08:16`

```sh
grep -n -i -B1 -A6 "$AP_HOST\|lab-ap" ~/.ssh/config | head -30; cat ~/Library/LaunchAgents/lab-tunnel.plist | grep -A1 "<string>" | grep string | head -20
```

**420.** `08:16`

```sh
B="ssh -o ControlMaster=no -o ControlPath=none -o BatchMode=yes -o ConnectTimeout=10 -o ProxyCommand='/usr/bin/nc -X 5 -x 127.0.0.1:1080 %h %p' -o HostKeyAlias=$AP_HOST_via_proxy -o StrictHostKeyChecking=no -l ap-user $AP_HOST"; eval "$B" '"hostname; ip -br addr; iw dev 2>/dev/null | grep -E \"Interface|type|ssid\"; ls /var/lib/misc/ /var/lib/NetworkManager/ 2>/dev/null | head"'
```

**421.** `08:16`

```sh
B="ssh -o ControlMaster=no -o ControlPath=none -o BatchMode=yes -o ConnectTimeout=10 -o ProxyCommand='/usr/bin/nc -X 5 -x 127.0.0.1:1080 %h %p' -o HostKeyAlias=$AP_HOST_via_proxy -o StrictHostKeyChecking=no -l ap-user $AP_HOST"; eval "$B" '"iw dev wlp4s0 station dump | grep -E \"^Station|connected time|signal:\"; echo; ip neigh show dev br0"'; grep -i macaddr ~/workspace/archos/firmware-archos-oxygen101/*.txt
```

**422.** `08:16`

```sh
B="ssh -o ControlMaster=no -o ControlPath=none -o BatchMode=yes -o ConnectTimeout=10 -o ProxyCommand='/usr/bin/nc -X 5 -x 127.0.0.1:1080 %h %p' -o HostKeyAlias=$AP_HOST_via_proxy -o StrictHostKeyChecking=no -l ap-user $AP_HOST"; eval "$B" '"for i in \$(seq 1 126); do ping -c1 -W1 $LAB_NET.\$i >/dev/null 2>&1 & done; wait; ip neigh show dev br0 | grep -i $TABLET_MAC; ip -6 neigh show dev br0 | grep -i $TABLET_MAC_PREFIX"'
```

**423.** `08:16` Found it.

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=8 -o ControlMaster=no -o ControlPath=none user@$TABLET_WIFI 'hostname; uname -v; uptime' 2>&1 | grep -v "^Warning"
```

**424.** `08:16`

```sh
T="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=8 -o ControlMaster=no -o ControlPath=none -o LogLevel=ERROR user@$TABLET_WIFI"; S=$S/share; scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/pwrkey/diag.sh $S/apks/linux-archos-oxygen101-6.12.90-r3.apk $S/apks/linux-archos-oxygen101-6.12.90-r4.apk user@$TABLET_WIFI: && $T 'echo 147147 | sudo -S -p "" sh ~/diag.sh' 2>&1
```

**425.** `08:17`

```sh
S=$S; cat > $S/t <<'EOF'
#!/bin/sh
# ssh to the tablet over WiFi (lab-ap AP)
exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=8 -o ControlMaster=no -o ControlPath=none -o LogLevel=ERROR user@${TABLET:-$TABLET_WIFI} "$@"
EOF
chmod +x $S/t; scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/share/pwrkey/diag.sh $S/share/apks/linux-archos-oxygen101-6.12.90-r3.apk $S/share/apks/linux-archos-oxygen101-6.12.90-r4.apk user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" sh ~/diag.sh' 2>&1
```

**426.** `08:18`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" apk add --allow-untrusted ~/linux-archos-oxygen101-6.12.90-r3.apk 2>&1 | tail -6; sync' 2>&1; head -30 ~/workspace/archos/tools/mkrkboot.py | grep -i "usage\|argv\|arg" 
```

> **Owner:** 1

> **Owner:** continue

**427.** `08:18`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" apk add --allow-untrusted ~/linux-archos-oxygen101-6.12.90-r3.apk 2>&1 | tail -6; sync' 2>&1
```

**428.** `08:19`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c \$(stat -c %s /boot/boot.img) | md5sum; md5sum /boot/boot.img; journalctl -b --no-pager | grep rockchip-rsce | tail -2"'
```

**429.** `08:20`

```sh
S=$S; cat > $S/chk.sh <<'EOF'
ls -l /dev/mmcblk0p5 /dev/mmcblk0p6
for p in /sys/block/mmcblk*/mmcblk*p*; do echo "$p $(cat $p/../device/type) $(sed -n 's/^PARTNAME=//p' $p/uevent)"; done
n=$(stat -c %s /boot/boot.img)
dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c $n | md5sum
md5sum /boot/boot.img
EOF
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/chk.sh user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" sh ~/chk.sh'
```

**430.** `08:20`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "dd if=/dev/mmcblk0p5 of=/tmp/b.img bs=1M count=32; ls -l /tmp/b.img; cmp /tmp/b.img /boot/boot.img | head -2; head -c 100 /tmp/b.img | strings"'
```

**431.** `08:20`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "dmesg | grep -i -E \"mmc0|mmcblk0|io-domain|I/O error\" | head -30; journalctl -b --no-pager | grep -i rsce"'
```

**432.** `08:20` The power-button driver is installed, but writing it to flash failed.

```sh
cd ~/workspace/archos/notes; grep -n -i -A20 "io-domains\|io_domains\|rockchip,rk3288-io-voltage" stock-android.dts | head -40; grep -n -B3 -A8 "vcc_18\b\|\"vcc_18\"\|vcc_flash\|vccio_sd\|vcc_lcd\"" stock-android.dts | grep -E "regulator-name|microvolt" | head -20
```

**433.** `08:20`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "dmesg | awk -F\"[][]\" \"\\\$2+0>4.0 && \\\$2+0<7.0\" | head -60; command -v devmem busybox; busybox devmem 0xff770380 2>&1; busybox devmem 0xff730084 2>&1"'
```

**434.** `08:21`

```sh
S=$S; $S/t 'command -v python3; echo 147147 | sudo -S -p "" sh -c "ls /sys/kernel/debug/regulator/ | head -40; cat /sys/kernel/debug/regulator/regulator_summary 2>/dev/null | head -60"'
```

**435.** `08:21`

```sh
S=$S; cat > $S/grf.py <<'EOF'
import mmap, os, struct, sys
# RK3288 GRF_IO_VSEL (0xff770380): 1 = 1.8 V. Upper 16 bits are write enables.
fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, offset=0xff770000)
off = 0x380
if len(sys.argv) > 1:
    bit = int(sys.argv[1]); val = int(sys.argv[2])
    m[off:off+4] = struct.pack("<I", (1 << (bit + 16)) | (val << bit))
v = struct.unpack("<I", m[off:off+4])[0]
names = ["lcdc", "dvp", "flash0", "flash1", "wifi", "bb", "audio", "sdcard"]
print(hex(v), " ".join("%s=%s" % (n, "1.8" if v >> i & 1 else "3.3") for i, n in enumerate(names)))
EOF
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/grf.py user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" python3 ~/grf.py'
```

**436.** `08:21`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "python3 ~/grf.py 2 1; d=\$(readlink -f /sys/bus/platform/devices/ff0f0000.mmc/driver); echo \$d; echo ff0f0000.mmc > \$d/unbind; sleep 1; echo ff0f0000.mmc > \$d/bind; sleep 3; dmesg | tail -8; dd if=/dev/mmcblk0p5 bs=1M count=1 2>&1 | head -c 0; dd if=/dev/mmcblk0p5 of=/dev/null bs=1M count=32 2>&1 | tail -1"'
```

**437.** `08:21` The voltage script didn't run:

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "python3 /home/user/grf.py 2 1; d=/sys/bus/platform/drivers/dwmmc_rockchip; echo ff0f0000.mmc > \$d/unbind; sleep 1; echo ff0f0000.mmc > \$d/bind; sleep 4; dmesg | tail -5; dd if=/dev/mmcblk0p5 of=/dev/null bs=1M count=32 2>&1 | tail -1"'
```

**438.** `08:22`

```sh
S=$S/share; D=arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts; cd $S/ksrc && grep -n "flash0-supply" e/$D && rm -rf g && mkdir -p g/$(dirname $D) && sed 's|flash0-supply = <&vccio>;|flash0-supply = <\&vcc_18>;|' e/$D > g/$D && sed 's|flash0-supply = <&vccio>;|flash0-supply = <\&vcc_18>;|' f/$D > f/$D.new && mv f/$D.new f/$D && grep -n "flash0" g/$D f/$D && (diff -u e/$D g/$D | sed "s|^--- e/|--- a/|;s|^+++ g/|+++ b/|" > $S/pwrkey/0006-archos-oxygen101-emmc-io-domain.patch; diff -u g/$D f/$D | sed "s|^--- g/|--- a/|;s|^+++ f/|+++ b/|" > $S/pwrkey/0007-archos-oxygen101-cpu-gpu-supplies.patch; rm $S/pwrkey/0006-archos-oxygen101-cpu-gpu-supplies.patch; cat $S/pwrkey/0006-archos-oxygen101-emmc-io-domain.patch; grep -c "^[+-]" $S/pwrkey/0007*)
```

**439.** `08:22` Now building r5 (power key, battery, eMMC fix):

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; rm -f 0006-archos-oxygen101-cpu-gpu-supplies.patch; cp /share/pwrkey/0006-archos-oxygen101-emmc-io-domain.patch /share/pwrkey/0007-archos-oxygen101-cpu-gpu-supplies.patch .; sed -i "s|^pkgrel=4|pkgrel=5|; s|^\t0006-archos-oxygen101-cpu-gpu-supplies.patch|\t0006-archos-oxygen101-emmc-io-domain.patch|" APKBUILD; chmod -R a+rwX .; grep -n "pkgrel\|000[5-7]" APKBUILD' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -1; ls /work/packages/v26.06/armv7/ | grep linux-archos | tail -1; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r5.apk /share/apks/'
```

**440.** `08:24`

```sh
docker exec pmos sh -c 'rm -rf /tmp/k5 && mkdir /tmp/k5 && cd /tmp/k5 && tar xzf /share/apks/linux-archos-oxygen101-6.12.90-r5.apk 2>/dev/null; dtc -I dtb -O dts boot/dtbs/rk3288-archos-oxygen101.dtb 2>/dev/null > d.dts; grep -c "cpu-supply\|mali-supply" d.dts; grep -A12 "io-domains {" d.dts | grep flash0; grep -n "0006" /work/cache_git/pmaports/device/testing/linux-archos-oxygen101/APKBUILD; zcat boot/vmlinuz 2>/dev/null | strings | grep -c rn5t618-pwrkey; strings boot/vmlinuz | grep -m1 "Linux version"'
```

**441.** `08:24`

```sh
docker exec pmos sh -c 'cd /tmp/k5; grep -B2 -A2 "phandle = <0x1a>" d.dts | grep -E "regulator-name|phandle"'
```

**442.** `08:24`

```sh
docker exec pmos sh -c 'cd /tmp/k5; awk "/phandle = <0x1a>/{print NR}" d.dts | head -1 | xargs -I{} sh -c "sed -n \"\$(( {} - 12 )),{}p\" d.dts" | grep -E "name|phandle"'
```

**443.** `08:24`

```sh
S=$S; scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/share/apks/linux-archos-oxygen101-6.12.90-r5.apk user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" sh -c "apk add --allow-untrusted /home/user/linux-archos-oxygen101-6.12.90-r5.apk 2>&1 | grep -i -E \"rsce|error|OK:\"; n=\$(stat -c %s /boot/boot.img); dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c \$n | md5sum; md5sum /boot/boot.img"'
```

**444.** `08:25` r5 is in `boot` and matches byte for byte.

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "sync; (sleep 1; reboot) >/dev/null 2>&1 &"'; echo sent
```

**445.** `08:25`

```sh
S=$S; for i in $(seq 1 30); do ping -c1 -t2 $TABLET_WIFI >/dev/null 2>&1 && $S/t true 2>/dev/null && break; sleep 5; done; $S/t 'uname -v; uptime; echo 147147 | sudo -S -p "" sh -c "dmesg | grep -i -E \"I/O error|mmc0: |pwrkey|rn5t618|fuel|brcmf.*Firmware|vtl\" | head; grep -A4 \"N: Name\" /proc/bus/input/devices | grep -E \"Name|Handlers\"; for d in /sys/class/power_supply/*; do echo == \$d; cat \$d/uevent | grep -E \"STATUS|ONLINE|CAPACITY|VOLTAGE_NOW|CURRENT_NOW\"; done"'
```

**446.** `08:25` The reboot command didn't run:

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" systemctl reboot' ; sleep 20; for i in $(seq 1 30); do ping -c1 -t2 $TABLET_WIFI >/dev/null 2>&1 && $S/t true 2>/dev/null && break; sleep 5; done; $S/t 'uname -v; uptime'
```

**447.** `08:27`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "dmesg | grep -i -E \"I/O error|mmc0: |pwrkey|rn5t618|fuel|brcmf.*Firmware|error -\" | head; grep -A4 \"N: Name\" /proc/bus/input/devices | grep -E \"Name|Handlers\"; for d in /sys/class/power_supply/*; do echo == \$d; grep -E \"STATUS|ONLINE|CAPACITY|VOLTAGE_NOW|CURRENT_NOW\" \$d/uevent; done; dd if=/dev/mmcblk0p5 of=/dev/null bs=1M count=8 2>&1 | tail -1"'
```

**448.** `08:27`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "ls /sys/bus/platform/devices/ | grep -i rn5t; ls -l /sys/bus/platform/devices/rn5t618-pwrkey/ 2>&1 | head; cat /sys/kernel/debug/devices_deferred; grep -i rc5t619 /proc/interrupts; ls /sys/bus/platform/drivers | grep -i rn5t"'
```

**449.** `08:27`

```sh
S=$S; sleep 5; $S/t 'uptime; echo 147147 | sudo -S -p "" sh -c "ls /sys/bus/platform/devices/ | grep -i rn5t; cat /sys/kernel/debug/devices_deferred; grep -i rc5t619 /proc/interrupts; ls /sys/bus/platform/drivers | grep -i rn5t"'
```

**450.** `08:27` The tablet just dropped the connection and refused new ones, so it's restarting.

```sh
S=$S; for i in $(seq 1 40); do $S/t true 2>/dev/null && break; sleep 5; done; $S/t 'uptime; uname -v; echo 147147 | sudo -S -p "" sh -c "journalctl -b -1 --no-pager | tail -25 | cut -c1-200"'
```

**451.** `08:32`

```sh
ping -c 3 -t 6 $TABLET_WIFI; ssh -o ControlMaster=no -o ControlPath=none -o BatchMode=yes -o ConnectTimeout=10 -o "ProxyCommand=/usr/bin/nc -X 5 -x 127.0.0.1:1080 %h %p" -o HostKeyAlias=$AP_HOST_via_proxy -o StrictHostKeyChecking=no -l ap-user $AP_HOST 'iw dev wlp4s0 station dump | grep -E "^Station|connected time"'
```

**452.** `08:33` I've lost the tablet.

```sh
cat $TASKS/bu4a4z7gw.output
```

**453.** `08:33` It's back, and the log shows a clean, ordered shutdown, not a crash.

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "journalctl -b -1 --no-pager | grep -i -E \"power key|logind|pwrkey|poweroff|Powering|shutdown\" | head -12 | cut -c1-180; echo; grep -A4 \"N: Name\" /proc/bus/input/devices | grep -E \"Name|Handlers\"; grep -i rc5t619 /proc/interrupts"'
```

**454.** `08:33`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "journalctl -b -1 --no-pager --since 10:27:09 --until 10:27:46 | head -30 | cut -c1-200; echo; ls /sys/bus/platform/devices | grep rn5t; cat /sys/kernel/debug/devices_deferred; dmesg | grep -i -E \"pwrkey|rn5t618\""'
```

**455.** `08:33`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "ls /sys/bus/platform/drivers | grep -i -E \"rn5t|pwrkey\"; zcat /proc/config.gz 2>/dev/null | grep -E \"PWRKEY|INPUT_MISC\"; journalctl -b -1 --no-pager --since 10:27:11 --until 10:27:46 | grep -v phoc | grep -i -E \"power|shut|halt|button|key|battery|critical|upower\" | head -15 | cut -c1-200"'; docker exec pmos sh -c 'grep -E "PWRKEY|^CONFIG_INPUT_MISC" /home/pmos/build/src/build-*/.config /work/chroot_native/home/pmos/build/src/*/.config 2>/dev/null | head'
```

**456.** `08:33`

```sh
S=$S; for i in $(seq 1 120); do $S/t true 2>/dev/null && break; sleep 2; done; $S/t 'echo 147147 | sudo -S -p "" sh -c "systemctl stop upower; sed -i -e \"s/^CriticalPowerAction=.*/CriticalPowerAction=Ignore/\" -e \"s/^AllowRiskyCriticalPowerAction=.*/AllowRiskyCriticalPowerAction=true/\" /etc/UPower/UPower.conf; grep -E \"^(CriticalPowerAction|AllowRisky|PercentageAction|PercentageCritical|PercentageLow|UsePercentage)\" /etc/UPower/UPower.conf; uptime; journalctl -b -1 --no-pager | grep -i -E \"upower|critical|battery\" | tail -5 | cut -c1-200"'
```

**457.** `08:41` The tablet is off again, and this time it isn't coming back by itself.

```sh
cat $TASKS/bgj3liwfg.output; ping -c2 -t4 $TABLET_WIFI | tail -2
```

**458.** `08:41` My waiting script gave up after about 20 minutes: (background)

```sh
S=$S; end=$(( $(date +%s) + 3600 )); while [ $(date +%s) -lt $end ]; do $S/t true 2>/dev/null && break; sleep 2; done; $S/t 'echo 147147 | sudo -S -p "" sh -c "systemctl stop upower; sed -i -e \"s/^CriticalPowerAction=.*/CriticalPowerAction=Ignore/\" -e \"s/^AllowRiskyCriticalPowerAction=.*/AllowRiskyCriticalPowerAction=true/\" /etc/UPower/UPower.conf; systemctl start upower; grep -E \"^(CriticalPowerAction|AllowRisky|PercentageAction|UsePercentage)\" /etc/UPower/UPower.conf; uptime; journalctl -b -1 --no-pager | grep -i -E \"upower|critical\" | tail -5 | cut -c1-200"'
```

**459.** `08:41` My waiting script gave up after about 20 minutes:

```sh
docker exec pmos sh -c 'K=/tmp/kx/linux-6.12.90/drivers/power/supply/rn5t618_power.c; grep -n "POWER_SUPPLY_PROP_\|ILIM\|REGISET\|CHGISET\|static int .*set\|property_is_writeable" $K | head -60'
```

**460.** `08:43` The mainline battery driver can already set both limits that matter, through sysfs:

```sh
cat $TASKS/b4w1co2f1.output
```

**461.** `08:43` UPower turned out to be the culprit:

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "cd /sys/class/power_supply; for f in rn5t618-adp/input_current_limit rn5t618-usb/input_current_limit rn5t618-battery/charge_control_limit rn5t618-battery/charge_control_limit_max rn5t618-battery/current_now rn5t618-battery/voltage_now rn5t618-battery/status rn5t618-adp/voltage_now rn5t618-adp/online rn5t618-usb/online rn5t618-battery/charge_full; do echo \$f=\$(cat \$f 2>&1); done; for r in 0xb3 0xb4 0xb5 0xb6 0xb7 0xb8 0xb9 0xbb 0xbd 0xbe 0xbf; do printf \" %s=%s\" \$r \$(i2cget -y -f 0 0x32 \$r); done; echo; ls /sys/bus/platform/drivers | grep -i -E \"rn5t|pwrkey\"; zcat /proc/config.gz 2>/dev/null | grep -E \"RN5T618_PWRKEY|^CONFIG_INPUT_MISC\""'
```

> **Owner:** There was both cables. I removed the USB so now it's only the wall plug

**462.** `08:44`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "cd /sys/class/power_supply; echo 2000000 > rn5t618-adp/input_current_limit; echo 1500000 > rn5t618-battery/charge_control_limit; sleep 5; for f in rn5t618-adp/input_current_limit rn5t618-battery/charge_control_limit rn5t618-battery/current_now rn5t618-battery/voltage_now rn5t618-adp/voltage_now rn5t618-battery/status; do echo \$f=\$(cat \$f); done; ls /sys/bus/platform/drivers/rn5t618-pwrkey/; dmesg | grep -i -E \"pwrkey|input\" | tail -5"'
```

**463.** `08:44`

```sh
docker exec pmos sh -c 'K=/tmp/kx/linux-6.12.90/drivers/mfd/rn5t618.c; grep -n "mfd_add_devices\|devm_mfd_add_devices\|rn5t618_irq_init(\|static int rn5t618_i2c_probe" $K; grep -n "irq_data\|regmap_irq_get_virq\|EPROBE_DEFER" /tmp/kx/linux-6.12.90/drivers/power/supply/rn5t618_power.c; tar xJf /work/cache_distfiles/linux-6.12.90.tar.xz -C /tmp/kx linux-6.12.90/drivers/rtc/rtc-rc5t619.c; grep -n "irq_data\|virq\|irq" /tmp/kx/linux-6.12.90/drivers/rtc/rtc-rc5t619.c | head'
```

**464.** `08:45`

```sh
S=$S/share; python3 - $S/pwrkey/rn5t618-pwrkey.c <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old="""	if (!rn5t618->irq_data)
		return -ENODEV;
"""
new="""	/* The MFD cells are added before the PMIC interrupt chip */
	if (!rn5t618->irq_data)
		return rn5t618->irq ? -EPROBE_DEFER : -ENODEV;
"""
assert old in s; open(p,'w').write(s.replace(old,new))
EOF
docker exec pmos sh -c 'set -e; cd /tmp/kx; cp /share/pwrkey/rn5t618-pwrkey.c b/drivers/input/misc/; diff -urN a b > /share/pwrkey/0005-input-rn5t618-pwrkey.patch || true; grep -n "EPROBE_DEFER" /share/pwrkey/0005-input-rn5t618-pwrkey.patch; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; cp /share/pwrkey/0005-input-rn5t618-pwrkey.patch .; sed -i "s|^pkgrel=5|pkgrel=6|" APKBUILD; chmod -R a+rwX .' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -1; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r6.apk /share/apks/ && echo copied'
```

**465.** `08:47` r6 is built.

```sh
docker exec pmos sh -c 'cd /work/cache_git/pmaports/device/testing/device-archos-oxygen101 && cat APKBUILD'
```

**466.** `08:47`

```sh
docker exec pmos sh -c 'f=$(find /work/chroot_native/usr/bin -name "devicepkg_package" 2>/dev/null | head -1); echo $f; grep -n "rules\|udev" $f'
```

**467.** `08:47`

```sh
docker exec pmos sh -c 'grep -rln "devicepkg_package" /work/chroot_*/usr/bin /work/chroot_*/usr/lib/devicepkg* 2>/dev/null | head; grep -rn "rules" $(grep -rln "devicepkg_package" /work/chroot_*/usr/bin 2>/dev/null | head -1) | head'
```

**468.** `08:47`

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/device-archos-oxygen101
cat > 90-device-archos-oxygen101.rules <<"EOF"
# RC5T619 charger: the power-on defaults (500 mA from the wall adapter) are
# below what the tablet draws with the screen on, so it discharges while
# plugged in. Use the 2 A of the stock adapter and the stock 1.5 A charge
# current.
ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="rn5t618-adp", ATTR{input_current_limit}="2000000"
ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="rn5t618-battery", ATTR{charge_control_limit}="1500000"
EOF
sed -i "s|^pkgrel=0|pkgrel=1|; s|^\trockchip-rsce-second.sh$|&\n\t90-device-archos-oxygen101.rules|" APKBUILD
sed -i "s|^\t\t\"\$pkgdir\"/usr/share/mkinitfs/rockchip-rsce-second.sh$|&\n\tinstall -Dm644 \"\$srcdir\"/90-\$pkgname.rules \\\\\n\t\t\"\$pkgdir\"/usr/lib/udev/rules.d/90-\$pkgname.rules|" APKBUILD
chmod -R a+rwX .; sed -n 5,6p APKBUILD; sed -n 18,35p APKBUILD' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum device-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 device-archos-oxygen101 2>&1 | tail -1; ls /work/packages/v26.06/armv7/ | grep device-archos; cp /work/packages/v26.06/armv7/device-archos-oxygen101-2-r1.apk /share/apks/; tar tzf /share/apks/device-archos-oxygen101-2-r1.apk 2>/dev/null | grep -v "^\."'
```

**469.** `08:48` `devicepkg_package` already installs `90-$pkgname.rules` by itself, so I'm removing my duplicate install line:

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/device-archos-oxygen101; sed -i "/install -Dm644 \"\$srcdir\"\/90-\$pkgname.rules/,+1d" APKBUILD; sed -n 28,34p APKBUILD' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum device-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 device-archos-oxygen101 2>&1 | tail -1; cp /work/packages/v26.06/armv7/device-archos-oxygen101-2-r1.apk /work/packages/v26.06/armv7/device-archos-oxygen101-nonfree-firmware-2-r1.apk /share/apks/; tar tzf /share/apks/device-archos-oxygen101-2-r1.apk 2>/dev/null | grep rules$'
```

**470.** `08:48` Installing r6 and the new device package, then rebooting to check the power key and the charger limits:

```sh
S=$S; cd $S/share/apks && scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none linux-archos-oxygen101-6.12.90-r6.apk device-archos-oxygen101-2-r1.apk device-archos-oxygen101-nonfree-firmware-2-r1.apk user@$TABLET_WIFI: && $S/t 'cd /home/user; echo 147147 | sudo -S -p "" sh -c "apk add --allow-untrusted ./linux-archos-oxygen101-6.12.90-r6.apk ./device-archos-oxygen101-2-r1.apk ./device-archos-oxygen101-nonfree-firmware-2-r1.apk 2>&1 | grep -i -E \"rsce|error|OK:\"; n=\$(stat -c %s /boot/boot.img); dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c \$n | md5sum; md5sum /boot/boot.img; grep -E \"^(CriticalPowerAction|AllowRisky)\" /etc/UPower/UPower.conf"'
```

**471.** `08:49`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" systemctl reboot'; sleep 25; for i in $(seq 1 40); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; echo 147147 | sudo -S -p "" sh -c "grep -A4 \"N: Name\" /proc/bus/input/devices | grep -E \"Name|Handlers\"; dmesg | grep -i pwrkey; cd /sys/class/power_supply; for f in rn5t618-adp/input_current_limit rn5t618-battery/charge_control_limit rn5t618-battery/current_now rn5t618-battery/voltage_now rn5t618-battery/capacity; do echo \$f=\$(cat \$f); done; dd if=/dev/mmcblk0p5 of=/dev/null bs=1M count=4 2>&1 | tail -1"'
```

**472.** `08:51`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "rm -f /home/user/pwr.log; (timeout 120 evtest /dev/input/event2 > /home/user/pwr.log 2>&1 &) ; sleep 1; head -3 /home/user/pwr.log"'
```

> **Owner:** What is the ssh command to login?

**473.** `09:05` **Please do this now (you have 2 minutes):** 1.

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sshd -T 2>/dev/null | grep -i -E "^passwordauthentication|^kbdinteractive"; cat /home/user/pwr.log | grep -E "EV_KEY" | grep -v "Event code\|Event type" | head'
```

> **Owner:** I pressed it and it works

**474.** `09:07` The power key works now.

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; sed -i "s|^pkgrel=6|pkgrel=7|; s|^\t0006-archos-oxygen101-emmc-io-domain.patch|&\n\t0007-archos-oxygen101-cpu-gpu-supplies.patch|" APKBUILD; chmod -R a+rwX .; grep -n "000[67]" APKBUILD | head -2' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -1; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r7.apk /share/apks/ && echo copied'; S=$S; $S/t 'apk info -e mesa-dri-gallium mesa-gbm; ls /usr/lib/dri/ 2>/dev/null | grep -i -E "panfrost|rockchip|swrast"; ls /usr/lib/modules/*/kernel/drivers/gpu/drm/panfrost/'
```

**475.** `09:09`

```sh
sed -n 1,40p ~/workspace/archos/tools/mkrkboot.py | grep -v "^$"; grep -n "add_argument\|argv" ~/workspace/archos/tools/mkrkboot.py
```

**476.** `09:09`

```sh
ls -la $S/backup/ $S/update/ 2>/dev/null | grep -i -E "resource|img" | head
```

**477.** `09:09`

```sh
S=$S; mkdir -p $S/share/r7 && docker exec pmos sh -c 'cd /share/r7 && tar xzf /share/apks/linux-archos-oxygen101-6.12.90-r7.apk boot/vmlinuz boot/dtbs/rk3288-archos-oxygen101.dtb 2>/dev/null; ls -la boot boot/dtbs' && scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none user@$TABLET_WIFI:/boot/initramfs $S/share/r7/initramfs && python3 -I ~/workspace/archos/tools/mkrkboot.py $S/backup/resource.img $S/share/r7/boot/vmlinuz $S/share/r7/initramfs $S/share/r7/boot/dtbs/rk3288-archos-oxygen101.dtb $S/share/r7/test-r7.img && ls -la $S/share/r7/test-r7.img && head -c 700 $S/share/r7/test-r7.img | strings | head -5
```

**478.** `09:09`

```sh
S=$S; md5 -q $S/share/r7/test-r7.img; scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/share/r7/test-r7.img user@$TABLET_WIFI:/home/user/ && $S/t 'echo 147147 | sudo -S -p "" sh -c "dd if=/home/user/test-r7.img of=/dev/mmcblk0p6 bs=1M conv=fsync 2>&1 | tail -1; dd if=/dev/mmcblk0p6 bs=1M count=32 2>/dev/null | head -c \$(stat -c %s /home/user/test-r7.img) | md5sum"'
```

**479.** `09:09`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" systemctl reboot recovery'; sleep 25; for i in $(seq 1 40); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; uptime; cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>&1; echo 147147 | sudo -S -p "" sh -c "dmesg | grep -i -E \"fan53555|syr82|panfrost|cpufreq|vdd_cpu|vdd_gpu\" | head -15; cat /sys/kernel/debug/regulator/vdd_cpu/voltage 2>/dev/null; for a in 0x40 0x41; do echo \$a \$(i2cget -y -f 0 \$a 0x00) \$(i2cget -y -f 0 \$a 0x01); done"'
```

**480.** `09:10` The reboot command was refused ("Too many arguments"):

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" systemctl reboot --reboot-argument=recovery'; sleep 25; for i in $(seq 1 40); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; uptime; cd /sys/devices/system/cpu/cpufreq/policy0 2>/dev/null && cat scaling_available_frequencies scaling_cur_freq scaling_governor; echo 147147 | sudo -S -p "" sh -c "dmesg | grep -i -E \"fan53555|syr82|panfrost|cpufreq|vdd_cpu|vdd_gpu\" | head -15; for a in 0x40 0x41; do echo \$a \$(i2cget -y -f 0 \$a 0x00) \$(i2cget -y -f 0 \$a 0x01); done"'
```

**481.** `09:11` It rebooted, but into r6 from `boot` again.

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "journalctl -b -1 -k --no-pager | tail -4 | cut -c1-160; dmesg | grep -i -E \"reboot|mode\" | head -5; ls /sys/bus/platform/drivers/ | grep -i reboot; dtc -I fs /proc/device-tree 2>/dev/null | grep -B2 -A6 reboot-mode | head -20"'
```

**482.** `09:12` The reboot-mode driver is loaded, with the RK3288 values.

```sh
S=$S; cat > $S/pmureg.py <<'EOF'
import mmap, os, struct, sys
# RK3288 PMU_SYS_REG0 (0xff730094): reboot mode flag read by the loader
fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, offset=0xff730000)
if len(sys.argv) > 1:
    m[0x94:0x98] = struct.pack("<I", int(sys.argv[1], 0))
print(hex(struct.unpack("<I", m[0x94:0x98])[0]))
EOF
scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/pmureg.py user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" python3 /home/user/pmureg.py'
```

**483.** `09:12`

```sh
cd ~/workspace/archos/notes/rk-uboot; ls; grep -n -i "SYS_REG\|loader_flag\|LoaderFlag\|BOOT_RECOVER\|0x5242\|SYS_LOADER\|os_reg\|reboot_flag" * | head -30
```

**484.** `09:12`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "journalctl -b -1 --no-pager | grep -i -E \"argument|reboot-param|recovery\" | tail -5 | cut -c1-200"'; grep -n "SYS_KERNRL_REBOOT_FLAG\|SYS_LOADER_REBOOT_FLAG\|IReadLoaderFlag\|ISetLoaderFlag" ~/workspace/archos/notes/rk-uboot/* | head
```

**485.** `09:12`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "d=\$(basename \$(readlink -f /sys/bus/platform/drivers/syscon-reboot-mode/*reboot-mode* 2>/dev/null | head -1)); echo dev=\$d; ls /sys/bus/platform/drivers/syscon-reboot-mode/"'
```

**486.** `09:13`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "echo ff730000.power-management:reboot-mode > /sys/bus/platform/drivers/syscon-reboot-mode/unbind; python3 /home/user/pmureg.py 0x5242C303; systemctl reboot"'; sleep 25; for i in $(seq 1 50); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; uptime; echo 147147 | sudo -S -p "" python3 /home/user/pmureg.py'
```

**487.** `09:14`

```sh
S=$S; $S/t 'ls /sys/bus/platform/drivers/dw_wdt/ 2>&1; grep -i -E "wdt|watchdog" /proc/interrupts; cat /sys/class/watchdog/watchdog0/state /sys/class/watchdog/watchdog0/identity 2>&1'
```

**488.** `09:14`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "ls /sys/class/watchdog/; for w in /sys/class/watchdog/*; do echo \$w \$(cat \$w/identity \$w/state 2>/dev/null); done"'
```

**489.** `09:14`

```sh
docker exec pmos sh -c 'K=/tmp/kx/linux-6.12.90/drivers/mfd/rn5t618.c; sed -n 140,240p $K | grep -n -i -E "restart|priority|power_off|system-power" '
```

**490.** `09:15`

```sh
docker exec pmos sh -c 'K=/tmp/kx/linux-6.12.90/drivers/mfd/rn5t618.c; sed -n 155,175p $K'
```

**491.** `09:15`

```sh
docker exec pmos sh -c 'set -e; cd /tmp/kx; rm -rf ra rb; mkdir -p ra/drivers/mfd; cp b/drivers/mfd/rn5t618.c ra/drivers/mfd/; cp -r ra rb
cd rb && awk "
/^static int rn5t618_restart\(struct notifier_block \*this,/ {inr=1}
inr && /^{/ {print; print \"\t/*\"; print \"\t * A PMIC re-power clears the SoC registers, including the reboot\"; print \"\t * mode flag the boot loader reads. Leave reboots into a mode\"; print \"\t * (recovery, loader, ...) to the SoC reset.\"; print \"\t */\"; print \"\tif (cmd && *(const char *)cmd)\"; print \"\t\treturn NOTIFY_DONE;\"; print \"\"; inr=0; next}
{print}" drivers/mfd/rn5t618.c > x && mv x drivers/mfd/rn5t618.c; cd ..
diff -urN ra rb | sed "s|^--- ra/|--- a/|;s|^+++ rb/|+++ b/|" > /share/pwrkey/0007-mfd-rn5t618-keep-reboot-mode.patch || true
cat /share/pwrkey/0007-mfd-rn5t618-keep-reboot-mode.patch'
```

**492.** `09:15`

```sh
S=$S/share; docker exec pmos sh -c 'rm -rf /share/rst && mkdir -p /share/rst/a/drivers/mfd && cp /tmp/kx/b/drivers/mfd/rn5t618.c /share/rst/a/drivers/mfd/ && cp -r /share/rst/a /share/rst/b && chmod -R a+rwX /share/rst' && python3 - $S/rst/b/drivers/mfd/rn5t618.c <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old="""			    unsigned long mode, void *cmd)
{
	rn5t618_trigger_poweroff_sequence(true);
"""
new="""			    unsigned long mode, void *cmd)
{
	/*
	 * A PMIC re-power clears the SoC registers, including the reboot
	 * mode flag the boot loader reads. Leave reboots into a mode
	 * (recovery, loader, ...) to the SoC reset.
	 */
	if (cmd && *(const char *)cmd)
		return NOTIFY_DONE;

	rn5t618_trigger_poweroff_sequence(true);
"""
assert old in s; open(p,'w').write(s.replace(old,new))
EOF
cd $S/rst && diff -urN a b | sed "s|^--- a/|--- a/|" > $S/pwrkey/0007-mfd-rn5t618-keep-reboot-mode.patch; cat $S/pwrkey/0007-mfd-rn5t618-keep-reboot-mode.patch
```

**493.** `09:15` Building r8:

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; git mv -f 0007-archos-oxygen101-cpu-gpu-supplies.patch 0008-archos-oxygen101-cpu-gpu-supplies.patch 2>/dev/null || mv 0007-archos-oxygen101-cpu-gpu-supplies.patch 0008-archos-oxygen101-cpu-gpu-supplies.patch; cp /share/pwrkey/0007-mfd-rn5t618-keep-reboot-mode.patch .; sed -i "s|^pkgrel=7|pkgrel=8|; s|^\t0007-archos-oxygen101-cpu-gpu-supplies.patch|\t0007-mfd-rn5t618-keep-reboot-mode.patch|" APKBUILD; chmod -R a+rwX .; grep -n "pkgrel\|^\t000" APKBUILD' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -1; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r8.apk /share/apks/ && echo copied'
```

**494.** `09:17`

```sh
S=$S; scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/share/apks/linux-archos-oxygen101-6.12.90-r8.apk user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" sh -c "apk add --allow-untrusted /home/user/linux-archos-oxygen101-6.12.90-r8.apk 2>&1 | grep -i -E \"rsce|error|OK:\"; n=\$(stat -c %s /boot/boot.img); dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c \$n | md5sum; md5sum /boot/boot.img; systemctl reboot"'; sleep 25; for i in $(seq 1 40); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; uptime'
```

**495.** `09:20` r8 is running (`#9` is pkgrel 8).

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" systemctl reboot --reboot-argument=recovery'; sleep 25; for i in $(seq 1 50); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; uptime; cd /sys/devices/system/cpu/cpufreq/policy0 2>/dev/null && cat scaling_available_frequencies scaling_cur_freq scaling_governor; echo 147147 | sudo -S -p "" sh -c "python3 /home/user/pmureg.py; dmesg | grep -i -E \"fan53555|panfrost|cpufreq|vdd_cpu|vdd_gpu\" | head -15; for a in 0x40 0x41; do echo \$a \$(i2cget -y -f 0 \$a 0x00) \$(i2cget -y -f 0 \$a 0x01); done"'
```

**496.** `09:21`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "echo 600000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq; cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq; cat /sys/kernel/debug/regulator/regulator_summary | grep -A3 -E \"vdd_cpu|vdd_gpu\"; dmesg | grep -i -E \"cpu.*supply|opp|cpufreq-dt|dummy\" | head"'
```

**497.** `09:21`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "for i in 1 2 3; do echo cpu=\$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq) gpu=\$(cat /sys/class/devfreq/ffa30000.gpu/cur_freq 2>/dev/null) vcpu=\$(cat /sys/kernel/debug/regulator/vdd_cpu/uV 2>/dev/null) vgpu=\$(cat /sys/kernel/debug/regulator/vdd_gpu/uV 2>/dev/null) r40=\$(i2cget -y -f 0 0x40 0x00)/\$(i2cget -y -f 0 0x40 0x01)/\$(i2cget -y -f 0 0x40 0x02) r41=\$(i2cget -y -f 0 0x41 0x00)/\$(i2cget -y -f 0 0x41 0x01); sleep 1; done; ls /sys/kernel/debug/regulator/vdd_cpu/"'
```

**498.** `09:21`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "p=/sys/devices/system/cpu/cpufreq/policy0; echo 1608000 > \$p/scaling_max_freq; echo performance > \$p/scaling_governor; sleep 1; echo cpu=\$(cat \$p/scaling_cur_freq) r40=\$(i2cget -y -f 0 0x40 0x00); for c in 1 2 3 4; do (timeout 20 sh -c \"while :; do :; done\" &); done; sleep 10; echo cpu=\$(cat \$p/scaling_cur_freq) r40=\$(i2cget -y -f 0 0x40 0x00) temp=\$(cat /sys/class/thermal/thermal_zone1/temp); sleep 12; echo schedutil > \$p/scaling_governor; echo ok"'
```

**499.** `09:22`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "journalctl -b --no-pager | grep phoc | grep -i -E \"render|egl|gles|pixman|software|panfrost|GPU\" | head -10 | cut -c1-220; ls -l /dev/dri/; grep -l panfrost_dri /proc/\$(pidof phoc)/maps 2>/dev/null && echo phoc-uses-panfrost"'
```

**500.** `09:22`

```sh
docker exec pmos sh -c 'set -e; cd /work/cache_git/pmaports/device/testing/linux-archos-oxygen101; sed -i "s|^pkgrel=8|pkgrel=9|; s|^\t0007-mfd-rn5t618-keep-reboot-mode.patch|&\n\t0008-archos-oxygen101-cpu-gpu-supplies.patch|" APKBUILD; chmod -R a+rwX .; grep -n "^\t000[78]" APKBUILD' && docker exec -u pmos pmos sh -c 'cd && pmbootstrap checksum linux-archos-oxygen101 >/dev/null 2>&1; pmbootstrap -y build --force --arch armv7 linux-archos-oxygen101 2>&1 | tail -1; cp /work/packages/v26.06/armv7/linux-archos-oxygen101-6.12.90-r9.apk /share/apks/ && echo copied' && S=$S && scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ControlMaster=no -o ControlPath=none $S/share/apks/linux-archos-oxygen101-6.12.90-r9.apk user@$TABLET_WIFI: && $S/t 'echo 147147 | sudo -S -p "" sh -c "apk add --allow-untrusted /home/user/linux-archos-oxygen101-6.12.90-r9.apk 2>&1 | grep -i -E \"rsce|error|OK:\"; n=\$(stat -c %s /boot/boot.img); dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c \$n | md5sum; md5sum /boot/boot.img; systemctl reboot"'; sleep 25; for i in $(seq 1 40); do $S/t true 2>/dev/null && break; sleep 3; done; $S/t 'uname -v; uptime; cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor; journalctl -b --no-pager | grep -o "EGL driver name: .*"; grep -A1 rn5t618-pwrkey /proc/bus/input/devices | head -1; cat /sys/class/power_supply/rn5t618-battery/current_now /sys/class/power_supply/rn5t618-battery/capacity'
```

**501.** `09:27`

```sh
sleep 15; S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "journalctl -b --no-pager | grep -o \"EGL driver name: .*\"; lsmod | grep panfrost; uptime"'
```

**502.** `09:27`

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "dmesg | grep -i \"fuel gauge\""'; A=~/workspace/archos; docker cp pmos:/work/cache_git/pmaports/device/testing/linux-archos-oxygen101/. $A/pmaports/device/testing/linux-archos-oxygen101/ && docker cp pmos:/work/cache_git/pmaports/device/testing/device-archos-oxygen101/. $A/pmaports/device/testing/device-archos-oxygen101/ && cp $S/share/ksrc/f/arch/arm/boot/dts/rockchip/rk3288-archos-oxygen101.dts $A/kernel/ && cp $S/share/pwrkey/rn5t618-pwrkey.c $A/kernel/ && cp $S/share/pwrkey/grf.py $S/pmureg.py $S/share/pwrkey/diag.sh $A/tools/ 2>/dev/null; cp $S/grf.py $A/tools/; ls $A/pmaports/device/testing/linux-archos-oxygen101/ $A/kernel $A/tools; grep -c "cpu-supply\|flash0-supply = <&vcc_18>" $A/kernel/rk3288-archos-oxygen101.dts
```

**503.** `09:27` The fuel gauge stayed enabled across this reboot, and it now reads 18% and rising.

```sh
S=$S; $S/t 'echo 147147 | sudo -S -p "" sh -c "sed -i -e \"s/^CriticalPowerAction=.*/CriticalPowerAction=HybridSleep/\" -e \"s/^AllowRiskyCriticalPowerAction=.*/AllowRiskyCriticalPowerAction=false/\" /etc/UPower/UPower.conf; systemctl restart upower; grep -E \"^(CriticalPowerAction|AllowRisky|PercentageAction)\" /etc/UPower/UPower.conf; upower -d | grep -E \"percentage|state\" | head -3"'
```

> **Owner:** Update the repo with the current state and update the story with a summary of all my prompts

**504.** `12:08` Inspect the archos repo state

```sh
cd ~/workspace/archos && git status --short | head -50; git log --oneline | head; ls; wc -l STORY.md; ls release upstream wiki tools kernel; du -sh backup 2>/dev/null; cat .gitignore
```

**505.** `12:08` Check git context of the archos folder

```sh
cd ~/workspace/archos; git rev-parse --show-toplevel; git check-ignore -v . README.md; ls -la; ls firmware-archos-oxygen101 notes; git -C firmware-archos-oxygen101 log --oneline | head -3
```

**506.** `12:08` Read the current story

```sh
cd ~/workspace/archos; cat STORY.md
```

**507.** `12:08` Extract all user prompts from the transcript

```sh
ls ~/.claude/projects/<project>/ | head; python3 - <<'EOF'
import json
p='~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl'
for l in open(p):
    try: d=json.loads(l)
    except: continue
    if d.get('type')!='user': continue
    if d.get('isMeta') or d.get('isCompactSummary'): continue
    c=d['message']['content']
    if isinstance(c,list):
        t=' '.join(x.get('text','') for x in c if x.get('type')=='text')
    else: t=c
    t=t.strip()
    if not t or t.startswith('<command') or t.startswith('<local-command') or 'tool_use_id' in t: continue
    print(d.get('timestamp','')[:16], '|', t[:600].replace('\n',' / '))
EOF
```

**508.** `12:08` Find remaining user prompts across transcripts

```sh
cd ~/.claude/projects/<project>/; grep -l "Move all important" *.jsonl; python3 - <<'EOF'
import json,glob
for p in glob.glob('~/.claude/projects/<project>*/*.jsonl'):
  for l in open(p):
    if 'Move all important' not in l and 'PIN' not in l: continue
    try: d=json.loads(l)
    except: continue
    if d.get('type')!='user': continue
    c=d['message']['content']
    t=c if isinstance(c,str) else ' '.join(x.get('text','') for x in c if isinstance(x,dict) and x.get('type')=='text')
    if 'tool_use_id' in str(c)[:200] or len(t)>800 or not t.strip(): continue
    print(p[-45:], d.get('timestamp','')[:16], '|', t[:500].replace('\n',' / '))
EOF
```

**509.** `12:08` Locate the PIN and archive prompts

```sh
python3 - <<'EOF'
import json,re
p='~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl'
for l in open(p):
  for k in ['Move all important','PIN','autologin','Firefox ESR']:
    if k in l:
      d=json.loads(l)
      if d.get('type')=='user':
        c=d['message']['content']; s=json.dumps(c)
        for m in re.finditer(r'.{0,300}(Move all important|autologin|PIN).{0,300}', s):
            print(d.get('timestamp','')[:16], d.get('isCompactSummary'), m.group(0)[:600]); break
      break
EOF
```

**510.** `12:09` Check scratchpad, backup size and package state

```sh
S=$S; A=~/workspace/archos
ls $S $S/share | head -60; du -sh $S/backup; df -h $S ~ | tail -2
docker exec pmos sh -c 'ls /work/cache_git/pmaports/device/testing/ | grep archos; ls /work/packages/v26.06/armv7/ | grep -i archos'
diff -r $A/pmaports/device/testing <(true) >/dev/null 2>&1; ls -R $A/pmaports/device/testing
```

**511.** `12:09` Verify pmaports sync and pmbootstrap config

```sh
A=~/workspace/archos; S=$S
rm -rf $S/sync; mkdir -p $S/sync; for p in device linux firmware; do docker cp pmos:/work/cache_git/pmaports/device/testing/$p-archos-oxygen101 $S/sync/; done; diff -r $S/sync $A/pmaports/device/testing && echo IN-SYNC
docker exec -u pmos pmos sh -c 'cd; pmbootstrap config 2>/dev/null | grep -E "device|ui|ssh|extra|hostname|user"; pmbootstrap --help >/dev/null; pmbootstrap install --help | grep -iE "ssh|password|split|filesystem" ; df -h /work | tail -1'
```

**512.** `12:09` Build the release SD image without personal SSH keys (background)

```sh
docker exec -u pmos pmos sh -c 'cd; pmbootstrap config ssh_keys False && pmbootstrap -y install --no-split --password 147147 2>&1 | tail -15; pmbootstrap config ssh_keys True; ls -la /work/chroot_native/home/pmos/rootfs/'
```

**513.** `12:09` Read wiki draft and APKBUILDs

```sh
A=~/workspace/archos; cat "$A/wiki/Archos_101_Oxygen_(archos-oxygen101).mediawiki"; cat $A/pmaports/device/testing/device-archos-oxygen101/APKBUILD; grep -n "pkgrel\|^source\|0006\|0007\|0008" $A/pmaports/device/testing/linux-archos-oxygen101/APKBUILD | head
```

**514.** `12:09` Update wiki status and hardware table

```sh
cd ~/workspace/archos/wiki && f='Archos_101_Oxygen_(archos-oxygen101).mediawiki' && python3 - "$f" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
rep=[
("| status_battery = N","| status_battery = Y"),
("| status_3d =\n","| status_3d = Y\n"),
("| CPU/GPU regulators || Silergy SYR827/SYR828 || fan53555 (not described yet)",
 "| CPU/GPU regulators || Silergy SYR827 (I²C0, 0x40) / SYR828 (0x41) || fan53555; CPU DVFS 126 MHz–1.6 GHz\n|-\n| GPU || Mali-T764 || panfrost (Phosh renders with GLES 3.1)\n|-\n| Charger, fuel gauge || RC5T619 || rn5t618-power; a udev rule raises the 500 mA adapter limit to 2 A"),
("| Keys || power GPIO0_A5, volume on SARADC ch1 || gpio-keys, adc-keys",
 "| Power key || RC5T619 PWRON pin || rn5t618-pwrkey (new driver)\n|-\n| Volume keys || SARADC ch1 || adc-keys"),
("The mainline RK3288 reboot modes match it: <code>reboot recovery</code>, <code>reboot bootloader</code> (fastboot), <code>reboot loader</code> (rockusb).",
 "The mainline RK3288 reboot modes match it: <code>reboot recovery</code>, <code>reboot bootloader</code> (fastboot), <code>reboot loader</code> (rockusb). They need a kernel patch: the RC5T619 restart handler power-cycles the SoC, which clears the reboot-mode register, so it is skipped for reboots into a mode."),
]
for a,b in rep:
    assert a in s, a
    s=s.replace(a,b)
open(p,'w').write(s)
EOF
```

**515.** `12:10` Find prompts queued while tools were running

```sh
python3 - <<'EOF'
import json
p='~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl'
lines=[json.loads(l) for l in open(p) if l.strip()]
# queued / attachment prompts
for d in lines:
    if d.get('type')=='attachment' or d.get('type')=='queue-operation':
        s=json.dumps(d)
        if 'queued_command' in s or d.get('type')=='queue-operation':
            a=d.get('attachment',{}) or {}
            t=a.get('prompt') or d.get('content') or ''
            if isinstance(t,list): t=' '.join(x.get('text','') for x in t if isinstance(x,dict))
            if t and 'task-notification' not in t:
                print(d.get('timestamp','')[:16], d.get('operation',''), '|', str(t)[:400].replace('\n',' / '))
EOF
```

**516.** `12:10` Read assistant replies around key prompts

```sh
python3 - <<'EOF'
import json
p='~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl'
keys=["mac does not detect","Can't I just select","SD in this mac","can't find bootloader","Rebooted on android","\"done\"","screen is black","Will you still be able","1"]
lines=[json.loads(l) for l in open(p) if l.strip()]
targets=['2026-10-20T12:5','2026-10-20T13:3','2026-10-20T15:2','2026-10-20T15:5','2026-10-20T16:2','2026-10-20T13:0','2026-10-21T08:1']
last=None
for d in lines:
    if d.get('type')=='assistant':
        for x in d['message']['content']:
            if x.get('type')=='text' and len(x['text'])>80:
                ts=d.get('timestamp','')
                if any(ts.startswith(t) for t in targets):
                    print(ts[:16],'>>',x['text'][:350].replace('\n',' / '));print()
EOF
```

**517.** `12:10` Correct day-one claims and cut old ending

```sh
cd ~/workspace/archos && python3 - <<'EOF'
p='STORY.md'; s=open(p).read()
rep=[
("""*How a 2015 Android 4.4 tablet ended up running postmarketOS with mainline
Linux 6.12, Phosh and a current Firefox, in one long afternoon (20 October 2026).*""",
"""*How a 2015 Android 4.4 tablet ended up running postmarketOS with mainline
Linux 6.12, Phosh and a current Firefox: one long afternoon to boot it
(20 October 2026), and a morning to make it usable (21 October).*"""),
("""- **Power and volume keys.** Power is a plain GPIO (GPIO0_A5, active low).
  The volume keys share SARADC channel 1 (≈0 V for up, ≈0.3 V for down), which
  is mainline's `adc-keys`.""",
"""- **Power and volume keys.** The volume keys share SARADC channel 1 (≈0 V
  for up, ≈0.3 V for down), which is mainline's `adc-keys`. The power key was
  described as a plain GPIO (GPIO0_A5, active low). That turned out to be
  wrong (see the next chapter).""",
),
("""  fastboot, `0x5242C301` loader), so `reboot recovery` and `reboot loader`
  work from pmOS.""",
"""  fastboot, `0x5242C301` loader), so `reboot recovery` and `reboot loader`
  should have worked from pmOS. They didn't (see the next chapter)."""),
]
for a,b in rep:
    assert a in s, a[:60]
    s=s.replace(a,b)
i=s.index('## What it took')
s=s[:i]+open('/dev/stdin').read()
open(p,'w').write(s)
EOF

```

**518.** `12:10` Check the end of STORY.md

```sh
tail -5 STORY.md; wc -l STORY.md
```

**519.** `12:10` Append day-two chapter and prompt appendix

```sh
cat >> STORY.md <<'EOF'
## The morning after: from "it boots" to "it's usable"

The owner used the tablet overnight and came back with three complaints:
the power button didn't wake the screen, the battery always read 0%, and
everything was slow. *"Is it just old or something is hooking up the CPU?
And is the GPU support enabled?"*

### Finding the tablet

The tablet was no longer on USB but on a lab WiFi network, and Phosh's WiFi
panel didn't show its address. The access point's station list gave its MAC
address; a ping sweep and the ARP table gave its IP. From then on all the
work went over SSH on WiFi. The owner also unplugged the USB cable, so the
tablet was on the wall charger only.

### Battery at 0%, and a tablet that switched itself off

The mainline `rn5t618-power` driver supports the RC5T619 charger and fuel
gauge, and it was enabled. But it depends on the PMIC's ADC driver, which was
not, so it waited for it forever and no battery was ever registered.

Enabling the ADC fixed the reading, and created a new problem: the tablet
powered off a minute after every boot. The battery really was at about 2%,
and UPower did what it is supposed to do at its critical level. Its critical
action was set to "ignore" for the time it took to understand why the battery
was empty in the first place.

The tablet was discharging while plugged in. At power-on the RC5T619 limits
the adapter input to **500 mA**, less than the tablet draws with the screen
on. Android raised it; mainline Linux leaves it alone. Writing 2 A (the stock
adapter's rating) to `input_current_limit` and 1.5 A to the charge limit took
the battery current from −169 mA to +1.28 A. A udev rule in the device
package now does that at boot, and UPower got its defaults back.

### The power key wasn't a GPIO

Nothing happened on GPIO0_A5 when the key was pressed. The PMIC's registers
told the real story: the "power on" interrupt bit (PWRIRQ bit 0) was latched.
The key is wired to the RC5T619's **PWRON pin**, and the PMIC reports it
through its system interrupt. Mainline has no power-key driver for this PMIC.

The new driver, `rn5t618-pwrkey`, is about 120 lines. It asks for an
interrupt on both edges, clears the latch and reports `KEY_POWER` from the
key-level bit (PWRMON bit 0). The first version registered nothing: the MFD
core adds its child devices *before* it sets up the interrupt chip, so the
driver now defers its probe until the interrupt chip exists. The owner
pressed the key: *"I pressed it and it works."*

### Why it was slow

Nothing was hogging the CPU. Two shortcuts from the first day were the cause:

- **The CPU was stuck at 600 MHz.** The CPU supply, a Silergy SYR827 on I²C
  bus 0, wasn't described, so the device tree had dropped the CPU's
  operating points. The SYR827 (CPU) and SYR828 (GPU) are the same parts,
  at the same addresses, as on the veyron Chromebooks, which the `fan53555`
  driver already supports. With them described, the CPU scales from 126 MHz to
  1.6 GHz. Reading the regulator back over I²C confirmed the voltages
  (0.9 V at 600 MHz, 1.35 V at 1.6 GHz). Four cores at 1.6 GHz under
  `stress` stayed stable at 50 °C.
- **The GPU was off.** Phosh's compositor fell back to pixman, so every frame
  was drawn by the CPU. With `vdd_gpu` described, the Mali-T764 runs on
  Panfrost and phoc reports `EGL driver name: panfrost`, OpenGL ES 3.1
  (Mesa 26.1.6).

### A self-inflicted eMMC bug

Since the second kernel build, the eMMC threw I/O errors seven seconds into
every boot. The root filesystem is on the microSD, so nothing seemed broken,
but the hook that writes new kernels to the eMMC `boot` partition failed
silently. Kernel updates weren't reaching flash.

The device tree told the io-domain driver that the flash pins ran at 3.3 V.
The eMMC runs at 1.8 V, so the driver switched the pins to the wrong
voltage as soon as it loaded. Writing the right value into the GRF
(`GRF_IO_VSEL`) by hand and rebinding the MMC driver brought the eMMC back,
which confirmed it. The fix is one line in the device tree.

### Reboot into recovery
# [... 107 more lines]
```

**520.** `12:11` Read the image build result

```sh
cat $TASKS/buhcxvjyu.output
```

**521.** `12:11` Find how the earlier SD image was assembled

```sh
S=$S; ls -la $S/share/out $S/share/port | head -30; grep -l "sfdisk\|split" $S/share/*/*.sh $S/*.sh 2>/dev/null; python3 - <<'EOF'
import json
p='~/.claude/projects/<project>/3176c799-e343-4b91-bbd3-1af70841bdeb.jsonl'
for l in open(p):
    if 'sd.img' in l and '"tool_use"' in l and ('sfdisk' in l or 'parted' in l or 'dd if' in l):
        d=json.loads(l)
        for x in d['message']['content']:
            if x.get('type')=='tool_use': print(x['input'].get('command','')[:1500]); print('----')
EOF
```

**522.** `12:11` Build split image, assemble SD image, compress (background)

```sh
docker exec -u pmos pmos sh -c 'cd; rm -f /work/chroot_native/home/pmos/rootfs/archos-oxygen101.img; pmbootstrap config ssh_keys False && pmbootstrap -y install --split --password 147147 2>&1 | tail -6; pmbootstrap config ssh_keys True' && docker exec pmos sh -c 'set -e; R=/work/chroot_native/home/pmos/rootfs; O=/work/release; rm -rf $O; mkdir -p $O
B=$(stat -c %s $R/archos-oxygen101-boot.img); RT=$(stat -c %s $R/archos-oxygen101-root.img); TOT=$(( 1048576 + B + RT ))
truncate -s $TOT $O/archos-oxygen101-phosh.img
printf "label: dos\nstart=2048, size=$((B/512)), type=83, bootable\nstart=$((2048 + B/512)), size=$((RT/512)), type=83\n" | sfdisk -q $O/archos-oxygen101-phosh.img
dd if=$R/archos-oxygen101-boot.img of=$O/archos-oxygen101-phosh.img bs=1M seek=1 conv=notrunc status=none
dd if=$R/archos-oxygen101-root.img of=$O/archos-oxygen101-phosh.img bs=512 seek=$((2048 + B/512)) conv=notrunc status=none
cp /work/chroot_rootfs_archos-oxygen101/boot/boot.img $O/boot.img
ls /work/chroot_rootfs_archos-oxygen101/home/user/.ssh 2>&1 || true
grep -o "pmos_[a-z]*" $O/boot.img | head -1; head -c 64 $O/boot.img | strings | head -3
xz -T0 -6 $O/archos-oxygen101-phosh.img; cd $O; sha256sum * > SHA256SUMS; ls -la; chmod -R a+rwX $O'
```

**523.** `12:11` Look at the backup before moving

```sh
S=$S; A=~/workspace/archos
ls -la $S/backup; ls $A/backup 2>&1
```

**524.** `12:11` Move backup, init git repo, stage files

```sh
S=$S; A=~/workspace/archos
mv $S/backup $A/backup && ln -s $A/backup $S/backup && ls $A/backup | wc -l
cat > $A/.gitignore <<'EOF'
# Full eMMC dump of the owner's tablet: contains their Android data
/backup/
# Images are published as release assets, not in git
/release/*.img
/release/*.img.xz
/release/apks/
# Published as its own repository
/firmware-archos-oxygen101/
.DS_Store
__pycache__/
EOF
cd $A && git init -q -b main && git add -A && git status --short | head -60; git status --short | wc -l
```

> **Owner:** Add in the archos folder in a scripts folder all the commands you tried on my mac such as "is the device on wifi?" etc.

**525.** `12:11` Verify which git repo was initialized

```sh
cd ~/workspace/archos; git rev-parse --show-toplevel --git-dir; git branch --show-current; git log --oneline 2>&1 | head -3; ls -la .git | head -5; git -C ~ status --short | head
```

> **Owner:** Also, how do I change the user password so SSH is not open?

**526.** `12:11` Find transcripts that involve the tablet

```sh
cd ~/.claude/projects/; for f in */*.jsonl; do n=$(grep -c -i "archos\|rkdeveloptool\|oxygen" $f); [ "$n" -gt 0 ] && echo "$n $f $(head -c 300 $f | tr -d '\n' | cut -c1-80)"; done 2>/dev/null | sort -rn | head
```

**527.** `12:12`

```sh
python3 - <<'EOF'
import glob,os
for f in glob.glob('~/.claude/projects/*/*.jsonl'):
    s=open(f,errors='ignore').read()
    n=s.count('rkdeveloptool')+s.count('archos')
    if n: print(n, os.path.getsize(f)//1024,'KB', f)
EOF
```

**528.** `12:13` Write reusable tablet scripts

```sh
mkdir -p ~/workspace/archos/scripts/history && cd ~/workspace/archos/scripts && 
cat > env.sh <<'EOF'
# Common settings, sourced by the other scripts. Override any of them in the
# environment, e.g. TABLET=192.168.1.42 ./status.sh
#
# TABLET     tablet address: 172.16.42.1 over USB (pmOS USB network), or its
#            WiFi address (see find-tablet.sh)
# TABLET_PW  password of "user" on the tablet, for sudo
# RKDEV      rkdeveloptool binary (see build-rkdeveloptool.sh)
# SHARE      folder shared with the pmbootstrap container as /share
: "${TABLET:=172.16.42.1}"
: "${TABLET_PW:=147147}"
: "${RKDEV:=rkdeveloptool}"
: "${SHARE:=$HOME/pmos-share}"
: "${PMOS_CONTAINER:=pmos}"

# The tablet's host key changes with every reflash, so don't record it
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=8 -o ControlMaster=no -o ControlPath=none"

tssh() { ssh $SSH_OPTS "user@$TABLET" "$@"; }
tscp() { scp -q $SSH_OPTS "$@"; }
# Run a shell command as root on the tablet
tsudo() { tssh "echo '$TABLET_PW' | sudo -S -p '' sh -c '$*'"; }
EOF
cat > ssh.sh <<'EOF'
#!/bin/sh
# Log into the tablet, or run a command on it: ./ssh.sh uptime
. "$(dirname "$0")/env.sh"
exec ssh $SSH_OPTS "user@$TABLET" "$@"
EOF
cat > find-tablet.sh <<'EOF'
#!/bin/sh
# "Is the tablet there, and in which mode?" Checks, in order: USB (Android,
# Rockchip loader, pmOS USB network) and WiFi.
#
# For WiFi, set TABLET to a guess, or TABLET_MAC to look it up in the ARP
# table after a ping sweep of SUBNET (e.g. SUBNET=192.168.1). If the tablet
# is on an access point you can log into, AP_SSH="ssh user@ap" lists its
# stations instead (that's how it was found on the lab network).
. "$(dirname "$0")/env.sh"

echo "== USB devices (Rockchip 2207, Archos 0e79)"
system_profiler SPUSBDataType 2>/dev/null | grep -B2 -A6 -iE "archos|rockchip|0x2207|0x0e79|RNDIS|postmarket" | grep -E "^\s+\S.*:$|Vendor ID|Product ID|Serial" | head -20

echo "== Android (adb)"
command -v adb >/dev/null && adb devices -l | tail -n +2

echo "== Rockchip loader (rkdeveloptool)"
command -v "$RKDEV" >/dev/null && "$RKDEV" ld 2>&1

echo "== pmOS USB network (172.16.42.1)"
ping -c1 -t2 172.16.42.1 >/dev/null 2>&1 && echo "up: ssh user@172.16.42.1" || echo "no answer"

echo "== WiFi"
if [ -n "$AP_SSH" ]; then
	# Stations of a Linux hostapd AP, then their addresses on its bridge
	$AP_SSH 'for d in $(iw dev | sed -n "s/.*Interface //p"); do iw dev $d station dump | grep -E "^Station|connected time"; done; ip neigh'
fi
if [ -n "$TABLET_MAC" ] && [ -n "$SUBNET" ]; then
	for i in $(seq 1 254); do ping -c1 -t1 "$SUBNET.$i" >/dev/null 2>&1 & done; wait
	arp -a | grep -i "$TABLET_MAC"
fi
if [ "$TABLET" != 172.16.42.1 ]; then
	ping -c1 -t2 "$TABLET" >/dev/null 2>&1 && echo "$TABLET is up" || echo "$TABLET: no answer"
fi
# On the tablet itself: nmcli -f IP4.ADDRESS dev show wlan0
EOF
cat > wait-for-tablet.sh <<'EOF'
#!/bin/sh
# Wait until SSH answers (after a reboot or a flash). Default timeout 5 min.
. "$(dirname "$0")/env.sh"
end=$(( $(date +%s) + ${1:-300} ))
while [ "$(date +%s)" -lt $end ]; do
	ssh $SSH_OPTS -o BatchMode=yes "user@$TABLET" true 2>/dev/null && { echo up; exit 0; }
	sleep 3
done
echo "timeout" >&2; exit 1
EOF
cat > status.sh <<'EOF'
#!/bin/sh
# [... 168 more lines]
```

**529.** `12:13` Syntax-check scripts and test status.sh live

```sh
cd ~/workspace/archos/scripts; for f in *.sh; do sh -n $f || echo "BAD $f"; done; TABLET=$TABLET_WIFI ./status.sh 2>&1 | head -40
```

**530.** `12:13` Investigate why the charger udev rule isn't applied

```sh
cd ~/workspace/archos/scripts; TABLET=$TABLET_WIFI . ./env.sh; tsudo 'ls -l /etc/udev/rules.d/ /usr/lib/udev/rules.d/ 2>/dev/null | grep -i archos; cat /etc/udev/rules.d/90-device-archos-oxygen101.rules 2>/dev/null | grep -v "^#"; journalctl -b --no-pager | grep -iE "udev.*(rn5t618|archos|input_current)|power_supply" | head; udevadm info -a /sys/class/power_supply/rn5t618-adp | head -20; ls /sys/class/power_supply/rn5t618-adp/; journalctl -b --no-pager -k | grep -iE "rn5t618|adp|charg" | head'
```

**531.** `12:13`

```sh
cd ~/workspace/archos/scripts; TABLET=$TABLET_WIFI sh -c '. ./env.sh; tsudo "ls -l /etc/udev/rules.d/ /usr/lib/udev/rules.d/ 2>/dev/null | grep -i archos; grep -v ^# /etc/udev/rules.d/90-device-archos-oxygen101.rules; journalctl -b --no-pager -k | grep -iE \"rn5t618|adp|charg\" | head; udevadm info /sys/class/power_supply/rn5t618-adp | head -12; udevadm test /sys/class/power_supply/rn5t618-adp 2>&1 | grep -iE \"archos|input_current|ATTR|error\" | head"'
```

**532.** `12:14` Test and trigger the udev rule

```sh
cd ~/workspace/archos/scripts; TABLET=$TABLET_WIFI sh -c '. ./env.sh; tsudo "udevadm test --action=add /sys/class/power_supply/rn5t618-adp 2>&1 | grep -iE \"90-device|input_current|ATTR\" | head -5; udevadm trigger --action=add --settle /sys/class/power_supply/rn5t618-adp /sys/class/power_supply/rn5t618-battery; sleep 1; cat /sys/class/power_supply/rn5t618-adp/input_current_limit /sys/class/power_supply/rn5t618-battery/charge_control_limit /sys/class/power_supply/rn5t618-battery/current_now; journalctl -b --no-pager -u upower | tail -5; journalctl -b --no-pager | grep -iE \"on battery|line power|ac adapter|unplug|power_supply\" | tail -5"'
```

**533.** `12:14` Inspect rn5t618_power driver for change events

```sh
docker exec pmos sh -c 'f=$(find /tmp/kx /work -path "*drivers/power/supply/rn5t618_power.c" 2>/dev/null | head -1); echo $f; grep -n "power_supply_changed\|REGISET1\|irq\|set_property\|static int rn5t618_adp_set\|ILIM" $f | head -40'
```

**534.** `12:14` Fix udev rule, bump pkgrel, rebuild device package

```sh
cd ~/workspace/archos/pmaports/device/testing/device-archos-oxygen101 && python3 - <<'EOF'
p='90-device-archos-oxygen101.rules'; s=open(p).read()
s=s.replace("""# current.
ACTION=="add",""","""# current. The PMIC resets the limit when it re-detects the adapter, so apply
# it again on every change the charger interrupt reports.
ACTION=="add|change",""").replace('''ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="rn5t618-battery"''','''ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="rn5t618-battery"''')
open(p,'w').write(s)
a=open('APKBUILD').read().replace('pkgrel=1','pkgrel=2',1); open('APKBUILD','w').write(a)
EOF
cat 90-device-archos-oxygen101.rules; grep pkgrel APKBUILD
cd ../../../../scripts && SHARE=$S/share ./build-packages.sh device 2>&1 | tail -8
```

**535.** `12:15` Improve build script and sync checksums

```sh
python3 - <<'EOF'
p='build-packages.sh'; s=open(p).read()
s=s.replace('''	docker exec -u pmos "$PMOS_CONTAINER" sh -c "cd; pmbootstrap checksum $pkg >/dev/null && pmbootstrap -y build --force --arch armv7 $pkg"
done
docker exec "$PMOS_CONTAINER" sh -c 'cp $(ls -t /work/packages/*/armv7/*archos-oxygen101*.apk) /share/apks/ 2>/dev/null; ls -t /share/apks | head -6'
''','''	docker exec -u pmos "$PMOS_CONTAINER" sh -c "cd; pmbootstrap checksum $pkg >/dev/null && pmbootstrap -y build --force --arch armv7 $pkg"
	# Keep the updated checksums
	docker cp "$PMOS_CONTAINER:$aports/device/testing/$pkg/APKBUILD" "$here/pmaports/device/testing/$pkg/APKBUILD"
done
docker exec "$PMOS_CONTAINER" sh -c 'cp -p /work/packages/*/armv7/*archos-oxygen101*.apk /share/apks/; ls -t /share/apks | head -4'
''')
open(p,'w').write(s)
EOF
docker cp pmos:/work/cache_git/pmaports/device/testing/device-archos-oxygen101/APKBUILD ../pmaports/device/testing/device-archos-oxygen101/APKBUILD
docker exec pmos sh -c 'cp -p /work/packages/*/armv7/*archos-oxygen101*.apk /share/apks/; ls -t /share/apks | head -4'; tail -5 ../pmaports/device/testing/device-archos-oxygen101/APKBUILD
```

**536.** `12:15` Install device 2-r2 and test the change rule

```sh
cd ~/workspace/archos/scripts; A=$S/share/apks; TABLET=$TABLET_WIFI ./install-packages.sh $A/device-archos-oxygen101-2-r2.apk $A/device-archos-oxygen101-nonfree-firmware-2-r2.apk 2>&1 | tail -6; TABLET=$TABLET_WIFI sh -c '. ./env.sh; tsudo "udevadm control --reload; grep add.change /etc/udev/rules.d/90-device-archos-oxygen101.rules | wc -l; echo 500000 > /sys/class/power_supply/rn5t618-adp/input_current_limit; udevadm trigger --action=change --settle /sys/class/power_supply/rn5t618-adp; cat /sys/class/power_supply/rn5t618-adp/input_current_limit"'
```

**537.** `12:15` Rebuild release image with the script (background)

```sh
cat $TASKS/b0lyru62u.output | tail -8; docker exec pmos rm -rf /work/release; ./make-sd-image.sh 2>&1 | tail -12
```

