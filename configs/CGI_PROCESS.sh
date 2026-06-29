#!/bin/sh

##############################
## CGI_CMD
##############################
export PATH=/sbin:/bin:/customer/wifi:/bootconfig/bin:/usr/bin:/usr/sbin
export LD_LIBRARY_PATH=/lib:/customer/wifi/lib

SDCARD_PATH=/mnt/mmc/
REC_STATUS=/tmp/rec_status
BATTERY=/tmp/battery
RTSP_STATUS=/tmp/rtsp_info
SOLUTION_PROVIDER=/tmp/solution_provider
AHD_SENSOR_STATUS=/tmp/ahd_sensor_status
MMC_BLK=`mount | grep /mnt/mmc | awk '{print $1}'`
VIDEOPARAM=/tmp/cardv_fifo

##with no need for I6E
if [ -f "/config/bin/fw_setenv" ]; then
FW_SETENV=/config/bin/fw_setenv
else
FW_SETENV=echo
fi

RECORDING()
{
        echo "($0): RECORDING $1"
        REC_ING=`cat $REC_STATUS`

        if [ "$1" = "1" ]; then
                if [ "$REC_ING" = "0" ]; then
                        echo "ON"
                        #echo "1" > $REC_STATUS
                        #echo "rec 1" > $VIDEOPARAM
                        cardv_msg 0x0301
                fi
        elif [ "$1" = "0" ]; then
                if [ "$REC_ING" = "1" ]; then
                        echo "OFF"
                        #echo "rec 0" > $VIDEOPARAM
                        cardv_msg 0x0302
                fi
        elif [ "$1" = "2" ]; then
                if [ "$REC_ING" = "1" ]; then
                        echo "OFF"
                        #echo "rec 0" > $VIDEOPARAM
                        cardv_msg 0x0302
                else
                        echo "ON"
                        #echo "rec 1" > $VIDEOPARAM
                        cardv_msg 0x0301
                fi
        else
                echo "none"
        fi
        sync
}

TAKE_PICTURE()
{
        echo "($0): TAKE_PICTURE $1"
        if [ "$1" = "1" ]; then
                echo "ON"
                cardv_msg 0x0403 
                #echo "capture" > $VIDEOPARAM
                sync
        elif [ "$1" = "0" ]; then
                echo "OFF"
        else
                echo "none"
        fi
}

#VIDEO_RESOLUTION_FPS()
#{
#       echo "VIDEO_RESOLUTION_FPS $1"
#       case $1 in
#               "2160P25fps")
#                       REC_RES=3840\ 2160
#                       REC_FPS=30
#                       ;;
#               "1440P30fps")
#                       REC_RES=2560\ 1440
#                       REC_FPS=30
#                       ;;
#               "1080P30fps")
#                       REC_RES=1920\ 1080
#                       REC_FPS=30
#                       ;;
#               "1080P27.5fpsHDR")
#                       REC_RES=1920\ 1080
#                       REC_FPS=27.5
#                       ;;
#               "720P30fps")
#                       REC_RES=1280\ 720
#                       REC_FPS=30
#                       ;;
#               "720P27.5fpsHDR")
#                       REC_RES=1280\ 720
#                       REC_FPS=27.5
#                       ;;
#               "720P60fps")
#                       REC_RES=1280\ 720
#                       REC_FPS=60
#                       ;;
#               "VGA")
#                       REC_RES=640\ 480
#                       REC_FPS=30
#                       ;;
#               *)
#                       REC_RES=1920\ 1080
#                       REC_FPS=30
#                       ;;
#       esac
#       echo "vidres $REC_RES " > $VIDEOPARAM
#       nvconf set 0 Camera.Menu.VideoRes $1
#}

JPG_RESOLUTION()
{
        echo "JPEG_RESOLUTION $1"
        case $1 in
                "3M")
                        REC_RES=2304\ 1296
                        ;;
                "2M")
                        REC_RES=1920\ 1080
                        ;;
                "1D2M")
                        REC_RES=1280\ 960
                        ;;
                "8M")
                        REC_RES=3840\ 2160
                        ;;
                *)
                        REC_RES=1920\ 1080
                        ;;
        esac
        echo "capres $REC_RES " > $VIDEOPARAM
        nvconf set 0 Camera.Menu.ImageRes $1
}

ZOOM()
{
        echo "($0): ZOOM $1"
        case $1 in
                "WIDE")
                        VALUE=0x8802
                        ;;
                "TELE")
                        VALUE=0x8803
                        ;;
                "STOP")
                        VALUE=0x8804
                        ;;
                *)
                        VALUE=0x8804
                        ;;
        esac
        cardv_msg $VALUE
}

BRIGHTNESS()
{
        echo "($0): BRIGHTNESS $1"
        VALUE=$1
        if [ $VALUE -gt 100 ];then
                VALUE=100
        elif [ $VALUE -lt 0 ];then
                VALUE=0
        fi
        echo "bri $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Brightness $1
}

CONTRAST()
{
        echo "($0): CONTRAST $1"
        VALUE=$1
        if [ $VALUE -gt 100 ];then
                VALUE=100
        elif [ $VALUE -lt -0 ];then
                VALUE=0
        fi
        echo "con $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Contrast $1
}

HUE()
{
        echo "($0): HUE $1"
        VALUE=$1
        echo "hue $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Hue $1
}

SATURATION()
{
        echo "($0): SATURATION $1"
        VALUE=$1
        if [ $VALUE -gt 127 ];then
                VALUE=100
        elif [ $VALUE -lt 0 ];then
                VALUE=0
        fi
        echo "sat $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Saturation $1
}

SHARPNESS()
{
        echo "($0): SHARPNESS $1"
        VALUE=$1
        if [ $VALUE -gt 1023 ];then
                VALUE=100
        elif [ $VALUE -lt 0 ];then
                VALUE=0
        fi
        echo "sha $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Sharpness $1
}

GAMMA()
{
        echo "($0): GAMMA $1"
        VALUE=$1
        VALUE=`expr $VALUE - 128`
        if [ $VALUE -gt 100 ];then
                VALUE=100
        elif [ $VALUE -lt 0 ];then
                VALUE=0
        fi
        echo "gamma $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Gamma $1
}
BKLIGHT()
{
        echo "($0): BKLIGHT $1"
        VALUE=$1
        if [ $VALUE -gt 100 ];then
                VALUE=100
        elif [ $VALUE -lt 0 ];then
                VALUE=0
        fi
        echo "Bklight $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Bklight $1     
}
EXPOSURE()
{
        echo "($0): EXPOSURE $1"
        case $1 in
                "EVN200")
                        VALUE=-6
                        ;;
                "EVN167")
                        VALUE=-5
                        ;;
                "EVN133")
                        VALUE=-4
                        ;;
                "EVN100")
                        VALUE=-3
                        ;;
                "EVN67")
                        VALUE=-2
                        ;;
                "EVN33")
                        VALUE=-1
                        ;;
                "EV0")
                        VALUE=0
                        ;;
                "EVP33")
                        VALUE=1
                        ;;
                "EVP67")
                        VALUE=2
                        ;;
                "EVP100")
                        VALUE=3
                        ;;
                "EVP133")
                        VALUE=4
                        ;;
                "EVP167")
                        VALUE=5
                        ;;
                "EVP200")
                        VALUE=6
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.EV $1
}

EXPOSURE_AUTO()
{
        echo "($0): EXPOSURE_AUTO $1"
        VALUE=$1
        echo "3a $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.ISO $1
}

ISO()
{
        echo "($0): ISO $1"
        case $1 in
                "ISO_AUTO")
                        VALUE=0
                        ;;
                "ISO_100")
                        VALUE=1
                        ;;
                "ISO_200")
                        VALUE=2
                        ;;
                "ISO_400")
                        VALUE=3
                        ;;
                "ISO_800")
                        VALUE=4
                        ;;
                "ISO_1600")
                        VALUE=5
                        ;;
                "ISO_3200")
                        VALUE=6
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.ISO $1
}

EFFECT()
{
        echo "($0): EFFECT $1"
        case $1 in
                "noraml")
                        VALUE=0
                        ;;
                "sepia")
                        VALUE=1
                        ;;
                "blackwhite")
                        VALUE=2
                        ;;
                "emboss")
                        VALUE=3
                        ;;
                "negative")
                        VALUE=3
                        ;;
                "sketch")
                        VALUE=3
                        ;;
                "oli")
                        VALUE=4
                        ;;
                "crayon")
                        VALUE=5
                        ;;
                "beauty")
                        VALUE=6
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "effect $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.effect $1
}

FLICKER()
{
        echo "($0): FLICKER $1"
        case $1 in
                "50HZ")
                        VALUE=50
                        ;;
                "60HZ")
                        VALUE=60
                        ;;
                *)
                        VALUE=50
                        ;;
        esac
        echo "flicker $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Flicker $1
}

WHITE_BALANCE()
{
        echo "($0): WHITE_BALANCE $1"
        case $1 in
                "Auto")
                        VALUE=0
                        ;;
                "Daylight")
                        VALUE=1
                        ;;
                "Cloudy")
                        VALUE=2
                        ;;
                "Fluorescent1")
                        VALUE=3
                        ;;
                "Fluorescent2")
                        VALUE=3
                        ;;
                "Fluorescent3")
                        VALUE=3
                        ;;
                "Incandescent")
                        VALUE=4
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.AWB $1
}

SHUTTER_SPEED()
{
        echo "($0): SHUTTER_SPEED $1"
        VALUE=$1
        VALUE=`expr $VALUE - 1`
        VALUE=`expr 100 + $VALUE \* 146`

        echo "shutter $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Shutter $1
}

LCDBrightness()
{
        echo "($0) : LCDBRI $1"
        VALUE=$1
        if [ $VALUE -gt 100 ]; then
                VALUE=100
        elif [ $VALUE -lt -0 ]; then
                VALUE=0
        fi
        echo "lcdbri $VALUE" > $VIDEOPARAM
        nvconf set 0 Cemera.Menu.LCDBrightness $1
}

setDateTimeFormat()
{
        case $1 in
                "NONE")
                        VALUE=0
                        ;;
                "YMD")
                        VALUE=1
                        ;;
                "MDY")
                        VALUE=2
                        ;;
                "DMY")
                        VALUE=3
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "timeformat $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.DateTimeFormat $1
}

setDateLogoStamp()
{
        case $1 in
                "DATELOGO")
                        VALUE=0
                        ;;
                "DATE")
                        VALUE=1
                        ;;
                "LOGO")
                        VALUE=2
                        ;;
                "OFF")
                        VALUE=3
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "datelogoStamp $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TimeStampLogoTXT $1
}

setGpsStamp()
{
        case $1 in
                "ON")
                        VALUE=0
                        ;;
                "OFF")
                        VALUE=1
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "gpsstamp $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.GpsStamp $1
}

setSpeedStamp()
{
        case $1 in
                "ON")
                        VALUE=0
                        ;;
                "OFF")
                        VALUE=1
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "speedstamp $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SpeedStamp $1
}

setLanguage()
{
        case $1 in
                "English")
                        VALUE=0
                        ;;
                "Spanish")
                        VALUE=1
                        ;;
                "Portuguese")
                        VALUE=2
                        ;;
                "Russian")
                        VALUE=3
                        ;;
                "Simplified Chinese")
                        VALUE=4
                        ;;
                "Traditional Chinese")
                        VALUE=5
                        ;;
                "German")
                        VALUE=6
                        ;;
                "Italian")
                        VALUE=7
                        ;;
                "Latvian")
                        VALUE=8
                        ;;
                "Polish")
                        VALUE=9
                        ;;
                "Romanian")
                        VALUE=10
                        ;;
                "Slovak")
                        VALUE=11
                        ;;
                "UKRomanian")
                        VALUE=12
                        ;;
                "French")
                        VALUE=13
                        ;;
                "Japanese")
                        VALUE=14
                        ;;
                "Korean")
                        VALUE=15
                        ;;
                "Czech")
                        VALUE=16
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        #echo "lang $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Language $1
}

setUsbFunction()
{
        case $1 in
                "MSDC")
                        VALUE=0
                        ;;
                "PCAM")
                        VALUE=1
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        #echo "usbmode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.USB $1
}

setLcdPowerSave()
{
        case $1 in
                "OFF")
                        VALUE=0
                        ;;
                "10SEC")
                        VALUE=10
                        ;;
                "30SEC")
                        VALUE=30
                        ;;
                "1MIN")
                        VALUE=60
                        ;;
                "3MIN")
                        VALUE=180
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        #echo "lcdpwrsave $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.PowerSaving $1
}

setPowerOnGSensor()
{
        case $1 in
                "OFF")
                        VALUE=0
                        ;;
                "LEVEL0")
                        VALUE=1
                        ;;
                "LEVEL1")
                        VALUE=2
                        ;;
                "LEVEL2")
                        VALUE=3
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "park $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.GSensorPowerOnSens $1
}

setMotionDetect()
{
        case $1 in
                "OFF")
                        VALUE=0
                        ;;
                "LOW")
                        VALUE=1
                        ;;
                "MID")
                        VALUE=2
                        ;;
                "HIGH")
                        VALUE=3
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "mdt $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.MotionSensitivity $1
}

Camera_System_Power()
{
        echo "($0): Camera_System_Power $1"
}

TimeSettings()
{
        LEN=${#1}

        if [ "$LEN" = "44" ]; then
                echo "LEN=$LEN"

                YYYY=`echo $1 | sed 's/[[:print:]]\{40\}$//' `
                MM=`echo $1   | sed 's/[[:print:]]\{33\}$//'  |sed 's/^[[:print:]]\{9\}//' `
                DD=`echo $1   | sed 's/[[:print:]]\{26\}$//'  |sed 's/^[[:print:]]\{16\}//' `
                hh=`echo $1   | sed 's/[[:print:]]\{19\}$//'  |sed 's/^[[:print:]]\{23\}//'  `
                mm=`echo $1   | sed 's/[[:print:]]\{12\}$//'  |sed 's/^[[:print:]]\{30\}//'  `
                ss=`echo $1   | sed 's/[[:print:]]\{5\}$//'  |sed 's/^[[:print:]]\{37\}//'  `

        elif [ "$LEN" = "38" ]; then
                echo "LEN=$LEN"

                YYYY=`echo $1 | sed 's/[[:print:]]\{34\}$//' `
                MM=`echo $1   | sed 's/[[:print:]]\{28\}$//'  |sed 's/^[[:print:]]\{8\}//' `
                DD=`echo $1   | sed 's/[[:print:]]\{22\}$//'  |sed 's/^[[:print:]]\{14\}//' `
                hh=`echo $1   | sed 's/[[:print:]]\{16\}$//'  |sed 's/^[[:print:]]\{20\}//'  `
                mm=`echo $1   | sed 's/[[:print:]]\{10\}$//'  |sed 's/^[[:print:]]\{26\}//'  `
                ss=`echo $1   | sed 's/[[:print:]]\{4\}$//'  |sed 's/^[[:print:]]\{32\}//'  `
        elif [ "$LEN" = "32" ]; then
                echo "LEN=$LEN"

                YYYY=`echo $1 | sed 's/[[:print:]]\{28\}$//' `
                MM=`echo $1   | sed 's/[[:print:]]\{23\}$//'  |sed 's/^[[:print:]]\{7\}//' `
                DD=`echo $1   | sed 's/[[:print:]]\{18\}$//'  |sed 's/^[[:print:]]\{12\}//' `
                hh=`echo $1   | sed 's/[[:print:]]\{13\}$//'  |sed 's/^[[:print:]]\{17\}//'  `
                mm=`echo $1   | sed 's/[[:print:]]\{8\}$//'  |sed 's/^[[:print:]]\{22\}//'  `
                ss=`echo $1   | sed 's/[[:print:]]\{3\}$//'  |sed 's/^[[:print:]]\{27\}//'  `

        else
                echo "LEN=$LEN"
                echo "no handle this LEN"
        fi

        DATE=$YYYY-$MM-$DD
        TIME=$hh:$mm:$ss
        echo $DATE
        echo $TIME

        date -s "$DATE $TIME" &
        hwclock -w &
}

setbitrate()
{
        echo "($0): setbitrate $1"
        echo "bitrate $1" > $VIDEOPARAM
}

reset_to_default()
{
        #CMD="resetdefault.sh"
        #$CMD
        #echo "reset_default" > $VIDEOPARAM
        cardv_msg 0x5909

}

REBOOT()
{
        sync
        sleep 1
        echo "restart wifi ..."
        CMD="ap.sh restart"
        $CMD
}

SD_Format()
{
        REC_ING=`cat $REC_STATUS`
        if [ "$REC_ING" = "0" ]; then
                echo "Format SDMMC!"
        else
                echo "Stop rec first!"
                cardv_msg 0x0302
                #echo "rec 0" > $VIDEOPARAM
                usleep 500000
                echo "Format SDMMC!"
        fi
        #echo "format" > $VIDEOPARAM
        cardv_msg 0x5907
}

Setting_Update()
{
        case $1 in
                "enter")
                        #echo "app_setting 1" > $VIDEOPARAM
                        cardv_msg 0x5905
                        ;;
                "exit")
                        #echo "app_setting 0" > $VIDEOPARAM
                        cardv_msg 0x5906
                        ;;
        esac
}

setVideoClipTime()
{
        case $1 in
                "OFF")
                        echo "loop rec Off"
                        VALUE=1
                ;;
                "1MIN")
                        echo "loop rec 1 MIN"
                        VALUE=1
                ;;
                "2MIN")
                        echo "loop rec 2 MIN"
                        VALUE=2
                ;;
                "3MIN")
                        echo "loop rec 3 MIN"
                        VALUE=3
                ;;
                "5MIN")
                        echo "loop rec 5 MIN"
                        VALUE=5
                ;;
                "10MIN")
                        echo "loop rec 10 MIN"
                        VALUE=10
                ;;
                "15MIN")
                        echo "loop rec 15 MIN"
                        VALUE=15
                ;;
                *)
                        VALUE=1
                ;;
        esac
        nvconf set 0 Camera.Menu.LoopingVideo $1
        echo "loop $VALUE" > $VIDEOPARAM
        $FW_SETENV LoopingVideo $VALUE
}

setStillBurstShot()
{
        case $1 in
                "OFF")
                        echo "burstshot level off"
                        VALUE=0
                ;;
                "LO")
                        echo "burstshot level low"
                        VALUE=1
                ;;
                "MID")
                        echo "burstshot level middle"
                        VALUE=2
                ;;
                "HI")
                        echo "burstshot level high"
                        VALUE=3
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "burstshot $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.BurstShot $1
}

setLDWS()
{
        case $1 in
                "OFF")
                        echo "adas ldws off"
                        VALUE=0
                ;;
                "ON")
                        echo "adas ldws on"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "adas ldws $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Preview.Adas.LDWS $1
}

setFCWS()
{
        case $1 in
                "OFF")
                        echo "adas fcws off"
                        VALUE=0
                ;;
                "ON")
                        echo "adas fcws on"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "adas fcws $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Preview.Adas.FCWS $1
}

setSAG()
{
        case $1 in
                "OFF")
                        echo "adas sag off"
                        VALUE=0
                ;;
                "ON")
                        echo "adas sag on"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "adas sag $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Preview.Adas.SAG $1
}

setNightMode()
{
        case $1 in
                "OFF")
                        echo "nightmode off"
                        VALUE=0
                ;;
                "ON")
                        echo "nightmode on"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "night $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NightMode $1
}

setWNR()
{
        case $1 in
                "OFF")
                        echo "wnr off"
                        VALUE=0
                ;;
                "ON")
                        echo "wnr on"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "wnr $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.WNR $1
}

setHDR()
{
        case $1 in
                "OFF")
                        echo "hdr off"
                        VALUE=0
                ;;
                "ON")
                        echo "hdr on"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "hdr $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.HDR $1
}

setSlowMotion()
{
        case $1 in
                "X1")
                        echo "slowmotion X1"
                        VALUE=0
                ;;
                "X2")
                        echo "slowmotion X2"
                        VALUE=1
                ;;
                "X4")
                        echo "slowmotion X4"
                        VALUE=2
                ;;
                "X8")
                        echo "slowmotion X8"
                        VALUE=3
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "slowmotion $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SlowMotion $1
}

setTimelapse()
{
        case $1 in
                "OFF")
                        echo "timelapse OFF"
                        VALUE=0
                ;;
                "1SEC")
                        echo "timelapse 1SEC"
                        VALUE=1
                ;;
                "5SEC")
                        echo "timelapse 5SEC"
                        VALUE=5
                ;;
                "10SEC")
                        echo "timelapse 10SEC"
                        VALUE=10
                ;;
                "30SEC")
                        echo "timelapse 30SEC"
                        VALUE=30
                ;;
                "60SEC")
                        echo "timelapse 60SEC"
                        VALUE=60
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "timelapse $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Timelapse $1
}

setAutoRec()
{
        case $1 in
                "OFF"|"off")
                        echo "AutoRec OFF"
                        VALUE=1
                ;;
                "ON"|"on")
                        echo "AutoRec ON"
                        VALUE=0
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "autorec $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.AutoRec $1
}

PreRecord()
{
        echo "($0): PreRecord $1"
        # echo "prerec $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.PreRecord $1
        cardv_msg 0x7300
}

setMicSensitivity()
{
        case $1 in
                "STANDARD")
                        echo "MicSensitivity STANDARD"
                        VALUE=1
                ;;
                "LOW")
                        echo "MicSensitivity LOW"
                        VALUE=0
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "micsen $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.MicSensitivity $1
}

setVideoQuality()
{
        case $1 in
                "SUPER_FINE")
                        echo "VideoQuality STANDARD"
                        VALUE=0
                ;;
                "FINE")
                        echo "VideoQuality LOW"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "quality $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.VideoQuality $1
}

setVideoOffTime()
{
        case $1 in
                "0MIN")
                        echo "videoofftime OFF"
                        VALUE=0
                ;;
                "5SEC")
                        echo "videoofftime 5SEC"
                        VALUE=5
                ;;
                "10SEC")
                        echo "videoofftime 10SEC"
                        VALUE=10
                ;;
                "15SEC")
                        echo "videoofftime 15SEC"
                        VALUE=15
                ;;
                "30SEC")
                        echo "videoofftime 30SEC"
                        VALUE=30
                ;;
                "1MIN")
                        echo "videoofftime 1MIN"
                        VALUE=60
                ;;
                "2MIN")
                        echo "videoofftime 2MIN"
                        VALUE=120
                ;;
                "3MIN")
                        echo "videoofftime 3MIN"
                        VALUE=180
                ;;
                "5MIN")
                        echo "videoofftime 5MIN"
                        VALUE=300
                ;;
                "10MIN")
                        echo "videoofftime 10MIN"
                        VALUE=600
                ;;
                "15MIN")
                        echo "videoofftime 15MIN"
                        VALUE=900
                ;;
                "30MIN")
                        echo "videoofftime 30MIN"
                        VALUE=1800
                ;;
                "60MIN")
                        echo "videoofftime 60MIN"
                        VALUE=3600
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "videoofftime $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.VideoOffTime $1
}

setPlaybackVolume()
{
        case $1 in
                "00")
                        echo "pbvolume 00"
                        VALUE=0
                ;;
                "01")
                        echo "pbvolume 01"
                        VALUE=1
                ;;
                "02")
                        echo "pbvolume 02"
                        VALUE=2
                ;;
                "03")
                        echo "pbvolume 03"
                        VALUE=3
                ;;
                "04")
                        echo "pbvolume 04"
                        VALUE=4
                ;;
                "05")
                        echo "pbvolume 05"
                        VALUE=5
                ;;
                "06")
                        echo "pbvolume 06"
                        VALUE=6
                ;;
                "07")
                        echo "pbvolume 07"
                        VALUE=7
                ;;
                "08")
                        echo "pbvolume 08"
                        VALUE=8
                ;;
                "09")
                        echo "pbvolume 09"
                        VALUE=9
                ;;
                "10")
                        echo "pbvolume 10"
                        VALUE=10
                ;;
                *)
                        VALUE=5
                ;;
        esac
        echo "pbvolume $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.PlaybackVolume $1
}

setBeep()
{
        case $1 in
                "OFF"|"off")
                        echo "Beep OFF"
                        VALUE=1
                ;;
                "ON"|"on")
                        echo "Beep ON"
                        VALUE=0
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "beep $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Beep $1
}

setAutoPowerOff()
{
        case $1 in
                "NEVER")
                        echo "AutoPowerOff NEVER"
                        VALUE=0
                ;;
                "15SEC")
                        echo "AutoPowerOff 15SEC"
                        VALUE=15
                ;;
                "30SEC")
                        echo "AutoPowerOff 30SEC"
                        VALUE=30
                ;;
                "1MIN")
                        echo "AutoPowerOff 1MIN"
                        VALUE=60
                ;;
                "2MIN")
                        echo "AutoPowerOff 2MIN"
                        VALUE=120
                ;;
                "3MIN")
                        echo "AutoPowerOff 3MIN"
                        VALUE=180
                ;;
                "5MIN")
                        echo "AutoPowerOff 5MIN"
                        VALUE=300
                ;;
                *)
                        VALUE=0
                ;;
        esac
        #echo "AutoPowerOff $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.AutoPowerOff $1
}

setSoundRecord()
{
        nvconf set 0 Camera.Menu.SoundRecord $1
        case $1 in
                "OFF"|"off")
                        echo "SoundRecord OFF"
                        VALUE=1
                        cardv_msg 0x0502
                ;;
                "ON"|"on")
                        echo "SoundRecord ON"
                        VALUE=0
                        cardv_msg 0x0501
                ;;
                *)
                        VALUE=0
                ;;
        esac
        #echo "audiorec $VALUE" > $VIDEOPARAM
}

setMotionVideoTime()
{
        case $1 in
                "5")
                        echo "VMD 5sec"
                        VALUE=5
                ;;
                "10")
                        echo "VMD 10sec"
                        VALUE=10
                ;;
                "30")
                        echo "VMD 30sec"
                        VALUE=30
                ;;
                "60")
                        echo "VMD 60sec"
                        VALUE=60
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "vmd $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.MotionVideoTime $1
}

setRecStamp()
{
        case $1 in
                "OFF")
                        echo "RecStamp OFF"
                        VALUE=0
                ;;
                "ON")
                        echo "RecStamp ON"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "recstamp $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.DateTimeFormat $1
}

setSpeedUint()
{
        case $1 in
                "km/h")
                        echo "SpeedUint km/h"
                        VALUE=0
                ;;
                "mph")
                        echo "SpeedUint mph"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "speeduint $VALUE" > $VIDEOPARAM
}

setSpeedCamAlert()
{
        case $1 in
                "OFF")
                        echo "SpeedCamAlert OFF"
                        VALUE=0
                ;;
                "ON")
                        echo "SpeedCamAlert ON"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "speedCamAlert $VALUE" > $VIDEOPARAM
}

setSpeedLimitAlert()
{
        case $1 in
                "OFF")
                        echo "SpeedLimitAlert OFF"
                        VALUE=0
                ;;
                "30mph"|"50km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=50
                ;;
                "35mph"|"60km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=60
                ;;
                "40mph"|"70km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=70
                ;;
                "50mph"|"80km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=80
                ;;
                "55mph"|"90km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=90
                ;;
                "60mph"|"100km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=100
                ;;
                "65mph"|"110km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=110
                ;;
                "75mph"|"120km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=120
                ;;
                "80mph"|"130km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=130
                ;;
                "85mph"|"140km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=140
                ;;
                "90mph"|"150km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=150
                ;;
                "100mph"|"160km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=160
                ;;
                "105mph"|"170km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=170
                ;;
                "110mph"|"180km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=180
                ;;
                "115mph"|"190km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=190
                ;;
                "123mph"|"200km/h")
                        echo "SpeedLimitAlert $1"
                        VALUE=200
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "SpeedLimitAlert $VALUE" > $VIDEOPARAM
}

setTimeZone()
{
        case $1 in
                "GMT_M_12")
                        echo "TimeZone $1"
                        VALUE="GMT-12:00"
                ;;
                "GMT_M_11")
                        echo "TimeZone $1"
                        VALUE="GMT-11:00"
                ;;
                "GMT_M_10")
                        echo "TimeZone $1"
                        VALUE="GMT-10:00"
                ;;
                "GMT_M_9")
                        echo "TimeZone $1"
                        VALUE="GMT-09:00"
                ;;
                "GMT_M_8")
                        echo "TimeZone $1"
                        VALUE="GMT-08:00"
                ;;
                "GMT_M_7")
                        echo "TimeZone $1"
                        VALUE="GMT-07:00"
                ;;
                "GMT_M_6")
                        echo "TimeZone $1"
                        VALUE="GMT-06:00"
                ;;
                "GMT_M_5")
                        echo "TimeZone $1"
                        VALUE="GMT-05:00"
                ;;
                "GMT_M_4")
                        echo "TimeZone $1"
                        VALUE="GMT-04:00"
                ;;
                "GMT_M_3_30")
                        echo "TimeZone $1"
                        VALUE="GMT-03:30"
                ;;
                "GMT_M_3")
                        echo "TimeZone $1"
                        VALUE="GMT-03:00"
                ;;
                "GMT_M_2")
                        echo "TimeZone $1"
                        VALUE="GMT-02:00"
                ;;
                "GMT_M_1")
                        echo "TimeZone $1"
                        VALUE="GMT-01:00"
                ;;
                "GMT00")
                        echo "TimeZone $1"
                        VALUE="GMT-00:00"
                ;;
                "GMT_P_1")
                        echo "TimeZone $1"
                        VALUE="GMT+01:00"
                ;;
                "GMT_P_2")
                        echo "TimeZone $1"
                        VALUE="GMT+02:00"
                ;;
                "GMT_P_3")
                        echo "TimeZone $1"
                        VALUE="GMT+03:00"
                ;;
                "GMT_P_3_30")
                        echo "TimeZone $1"
                        VALUE="GMT+03:30"
                ;;
                "GMT_P_4")
                        echo "TimeZone $1"
                        VALUE="GMT+04:00"
                ;;
                "GMT_P_4_30")
                        echo "TimeZone $1"
                        VALUE="GMT+04:30"
                ;;
                "GMT_P_5")
                        echo "TimeZone $1"
                        VALUE="GMT+05:00"
                ;;
                "GMT_P_5_30")
                        echo "TimeZone $1"
                        VALUE="GMT+05:30"
                ;;
                "GMT_P_5_45")
                        echo "TimeZone $1"
                        VALUE="GMT+05:45"
                ;;
                "GMT_P_6")
                        echo "TimeZone $1"
                        VALUE="GMT+06:00"
                ;;
                "GMT_P_6_30")
                        echo "TimeZone $1"
                        VALUE="GMT+06:30"
                ;;
                "GMT_P_7")
                        echo "TimeZone $1"
                        VALUE="GMT+07:00"
                ;;
                "GMT_P_8")
                        echo "TimeZone $1"
                        VALUE="GMT+08:00"
                ;;
                "GMT_P_9")
                        echo "TimeZone $1"
                        VALUE="GMT+09:00"
                ;;
                "GMT_P_9_30")
                        echo "TimeZone $1"
                        VALUE="GMT+09:30"
                ;;
                "GMT_P_10")
                        echo "TimeZone $1"
                        VALUE="GMT+10:00"
                ;;
                "GMT_P_11")
                        echo "TimeZone $1"
                        VALUE="GMT+11:00"
                ;;
                "GMT_P_12")
                        echo "TimeZone $1"
                        VALUE="GMT+12:00"
                ;;
                "GMT_P_13")
                        echo "TimeZone $1"
                        VALUE="GMT+13:00"
                ;;
                "GMT_P_14")
                        echo "TimeZone $1"
                        VALUE="GMT+14:00"
                ;;
                *)
                        VALUE="GMT-00:00"
                ;;
        esac
        echo "timezone $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TimeZone $VALUE
}

setSyncTime()
{
        case $1 in
                "OFF")
                        echo "SyncTime OFF"
                        VALUE=0
                ;;
                "ON")
                        echo "SyncTime ON"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "synctime $VALUE" > $VIDEOPARAM
}

setPosSetting_Add()
{
        echo "setPosSetting_Add"
        echo "setPosSetting 0" > $VIDEOPARAM
}

setPosSetting_DelLast()
{
        echo "PosSetting_DelLast"
        echo "setPosSetting 1" > $VIDEOPARAM
}

setPosSetting_DelAll()
{
        echo "PosSetting_DelAll"
        echo "setPosSetting 2" > $VIDEOPARAM
}

setParkingMonitor()
{
        case $1 in
                "DISABLE")
                        echo "ParkingMonitor OFF"
                        VALUE=0
                ;;
                "ENABLE")
                        echo "ParkingMonitor ON"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "park $VALUE" > $VIDEOPARAM
        $FW_SETENV ParkingMonitor $VALUE
}
setVoiceSwitch()
{
        case $1 in
                "OFF")
                        echo "VoiceSwitch OFF"
                        VALUE=0
                ;;
                "ON")
                        echo "VoiceSwitch ON"
                        VALUE=1
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "voice $VALUE" > $VIDEOPARAM
        $FW_SETENV VoiceSwitch $VALUE
}
setGSensor()
{
        case $1 in
                "OFF")
                        ##echo "GSensorSensitivity OFF"
                        VALUE=0
                ;;
                "LEVEL0")
                        ##echo "GSensorSensitivity U-LOW"
                        VALUE=1
                ;;
                "LEVEL1")
                        ##echo "GSensorSensitivity LOW"
                        VALUE=2
                ;;
                "LEVEL2")
                        ##echo "GSensorSensitivity MID"
                        VALUE=3
                ;;
                "LEVEL3")
                        ##echo "GSensorSensitivity HIGH"
                        VALUE=4
                ;;
                "LEVEL4")
                        ##echo "GSensorSensitivity U-HIGH"
                        VALUE=5
                ;;
                *)
                        VALUE=0
                ;;
        esac
        echo "gsensor $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.GSensorSensitivity $1
        $FW_SETENV GSensor $VALUE
}

Playback_Update()
{
        #if [ "$MMC_BLK" = "" ]; then
                         #exit 1 ## return system() return value
                #else                           
                        if [ "$1" = "enter" ];then
                                # echo "dumpfilecnt" > $VIDEOPARAM
                                #echo "app_playback 1" > $VIDEOPARAM
                                cardv_msg 0x5902
                        else                
                                #echo "app_playback 0" > $VIDEOPARAM            
                                cardv_msg 0x5903
                        fi              
        #fi             
}
APPConnectionStatus()
{
                        if [ "$1" = "exit" ];then
                                #echo "app_connection 0" > $VIDEOPARAM  
                                cardv_msg 0x5904
                        elif [ "$1" = "enter" ];then
                                #echo "app_connection 1" > $VIDEOPARAM
                                cardv_msg 0x5908
                        fi              
}
reboot_system()
{
        CMD="rebootsystem.sh"
        $CMD
}

VIDEO_RESOLUTION_FPS()
{
        echo "VIDEO_RESOLUTION_FPS $1"
        case $1 in
                "2160P25fps")
                        #REC_RES=3840\ 2160
                        #REC_FPS=60
                        REC_RES=0x3201
                        nvconf set 0 Camera.Menu.NRecRes 4K60FPS
                        ;;
                "1440P30fps")
                        #REC_RES=3840\ 2160
                        #REC_FPS=30
                        REC_RES=0x3202
                        nvconf set 0 Camera.Menu.NRecRes 4K30FPS
                        ;;
                "1080P30fps")
                        #REC_RES=1920\ 1080
                        #REC_FPS=30
                        REC_RES=0x3205
                        nvconf set 0 Camera.Menu.NRecRes 1080P30FPS
                        ;;
                *)
                        #REC_RES=1920\ 1080
                        #REC_FPS=30
                        REC_RES=0x3205
                        ;;
        esac
        cardv_msg $REC_RES
}

N_VIDEO_RESOLUTION_FPS()
{
        echo "N_VIDEO_RESOLUTION_FPS $1"
        nvconf set 0 Camera.Menu.NRecRes $1
        #echo "n_rec_res 0 $REC_RES " > $VIDEOPARAM
        cardv_msg 0x3200
}

n_rec_wb()
{
        echo "($0): n_rec_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        #echo "n_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecWb $1
        cardv_msg $VALUE
}

n_rec_filter()
{
        echo "($0): n_rec_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        #echo "n_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecFilter $1
        cardv_msg $VALUE        
}

n_rec_ev()
{
        echo "($0): n_rec_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "n_rec_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecEv $1
        cardv_msg $VALUE
}

n_rec_me_mode()
{
        echo "($0): n_rec_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "n_rec_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecMeMode $1
        cardv_msg $VALUE
}

n_rec_shap()
{
        echo "($0): n_rec_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "n_rec_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecShap $1
        cardv_msg $VALUE
}

n_rec_effect()
{
        echo "($0): n_rec_effect $1"
        case $1 in
                "HIGH")
                        VALUE=0x6001
                        ;;
                "MID")
                        VALUE=0x6002
                        ;;
                "LOW")
                        VALUE=0x6003
                        ;;
                *)
                        VALUE=0x6001
                        ;;
        esac
        
        #echo "n_rec_effect $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecEffect $1
        cardv_msg $VALUE
}

n_rec_iso()
{
        echo "($0): n_rec_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "n_rec_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecISO $1
        cardv_msg $VALUE
}

n_rec_water_m()
{
        echo "($0): n_rec_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "n_rec_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecWaterM $1
        cardv_msg $VALUE
}

n_rec_mute()
{
        echo "($0): n_rec_mute $1"
        case $1 in
                "MICMUTEON")
                        VALUE=0x3700
                        ;;
                "MICMUTEOFF")
                        VALUE=0x3701
                        ;;
                *)
                        VALUE=0x3700
                        ;;
        esac
        
        #echo "n_rec_mute $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecMMute $1
        cardv_msg $VALUE
}

n_rec_mtd()
{
        echo "($0): n_rec_mtd $1"
        case $1 in
                "OFF")
                        VALUE=0x8809
                        ;;
                "LOW")
                        VALUE=0x8809
                        ;;
                "MID")
                        VALUE=0x8809
                        ;;
                "HIGH")
                        VALUE=0x8809
                        ;;
                *)
                        VALUE=0x8809
                        ;;
        esac
        
        #echo "n_rec_mtd $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecMTD $1
        cardv_msg $VALUE
}

n_rec_eis()
{
        echo "($0): NRecEIS $1"
        case $1 in
                "ON")
                        VALUE=0x880e
                        ;;
                "OFF")
                        VALUE=0x880e
                        ;;
                *)
                        VALUE=0x880e
                        ;;
        esac
        
        #echo "n_rec_mute $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NRecEIS $1
        cardv_msg $VALUE
}
NRecDelay()
{
        echo "($0): NRecDelay $1"
        nvconf set 0 Camera.Menu.NRecDelay $1
        cardv_msg 0x3500
}
s_rec_type()
{
        echo "($0): s_rec_type $1"
        case $1 in
                "2D7K2X")
                        VALUE=0x3300
                        ;;
                "1080P4X")
                        VALUE=0x3300
                        ;;
                "1080P2X")
                        VALUE=0x3301
                        ;;
                "720P8X")
                        VALUE=0x3302
                        ;;
                "720P4X")
                        VALUE=0x3303
                        ;;
                *)
                        VALUE=0x3300
                        ;;
        esac
        
        #echo "s_rec_type $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecType $1
        cardv_msg $VALUE
}

s_rec_wb()
{
        echo "($0): s_rec_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecWb $1
        cardv_msg $VALUE
}

s_rec_filter()
{
        echo "($0): s_rec_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecFilter $1
        cardv_msg $VALUE
}

s_rec_ev()
{
        echo "($0): s_rec_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "s_rec_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecEv $1
        cardv_msg $VALUE
}

s_rec_me_mode()
{
        echo "($0): s_rec_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "s_rec_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecMeMode $1

        cardv_msg $VALUE
}

s_rec_shap()
{
        echo "($0): s_rec_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "s_rec_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecShap $1
        cardv_msg $VALUE
}

s_rec_effect()
{
        echo "($0): s_rec_effect $1"
        case $1 in
                "HIGH")
                        VALUE=0x6000
                        ;;
                "MID")
                        VALUE=0x6001
                        ;;
                "LOW")
                        VALUE=0x6002
                        ;;
                *)
                        VALUE=0x6000
                        ;;
        esac
        
        #echo "s_rec_effect $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecEffect $1
        cardv_msg $VALUE
}

s_rec_water_m()
{
        echo "($0): s_rec_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "n_rec_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecWaterM $1
        cardv_msg $VALUE
}

s_rec_iso()
{
        echo "($0): s_rec_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "s_rec_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.SRecISO $1
        cardv_msg $VALUE
}

l_rec_res()
{
        echo "($0): l_rec_res $1"
        nvconf set 0 Camera.Menu.LRecRes $1
        cardv_msg 0x3200
        #echo "l_rec_res 0 $REC_RES " > $VIDEOPARAM
}

l_rec_time()
{
        echo "($0): l_rec_time $1"
        case $1 in
                "1MIN")
                        VALUE=0x3600
                        ;;
                "2MIN")
                        VALUE=0x3601
                        ;;
                "3MIN")
                        VALUE=0x3602
                        ;;
                "5MIN")
                        VALUE=0x3603
                        ;;
                "10MIN")
                        VALUE=0x3604
                        ;;
                *)
                        VALUE=0x3600
                        ;;
        esac
        
        #echo "l_rec_time $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecTime $1
        cardv_msg $VALUE
}

l_rec_wb()
{
        echo "($0): l_rec_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "l_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecWb $1
        cardv_msg $VALUE
}

l_rec_filter()
{
        echo "($0): l_rec_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecFilter $1
        cardv_msg $VALUE
}

l_rec_ev()
{
        echo "($0): l_rec_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "l_rec_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecEv $1
        cardv_msg $VALUE
}

l_rec_me_mode()
{
        echo "($0): l_rec_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "l_rec_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecMeMode $1
        cardv_msg $VALUE
}

l_rec_shap()
{
        echo "($0): l_rec_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "l_rec_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecShap $1
        cardv_msg $VALUE
}

l_rec_effect()
{
        echo "($0): l_rec_effect $1"
        case $1 in
                "HIGH")
                        VALUE=0x6000
                        ;;
                "LOW")
                        VALUE=0x6001
                        ;;
                "MID")
                        VALUE=0x6002
                        ;;
                *)
                        VALUE=0x6000
                        ;;
        esac
        
        #echo "l_rec_effect $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecEffect $1
        cardv_msg $VALUE
}

l_rec_iso()
{
        echo "($0): l_rec_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "l_rec_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecISO $1
        cardv_msg $VALUE
}

l_rec_water_m()
{
        echo "($0): l_rec_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "l_rec_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecWaterM $1
        cardv_msg $VALUE
}

l_rec_mute()
{
        echo "($0): l_rec_mute $1"
        case $1 in
                "MICMUTEON")
                        VALUE=0x3700
                        ;;
                "MICMUTEOFF")
                        VALUE=0x3701
                        ;;
                *)
                        VALUE=0x3700
                        ;;
        esac
        
        #echo "l_rec_mute $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecMMute $1
        cardv_msg $VALUE
}

l_rec_mtd()
{
        echo "($0): l_rec_mtd $1"
        case $1 in
                "OFF")
                        VALUE=0x8809
                        ;;
                "LOW")
                        VALUE=0x8809
                        ;;
                "MID")
                        VALUE=0x8809
                        ;;
                "HIGH")
                        VALUE=0x8809
                        ;;
                *)
                        VALUE=0x8809
                        ;;
        esac
        
        #echo "l_rec_mtd $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecMTD $1
        cardv_msg $VALUE
}

l_rec_eis()
{
        echo "($0): LRecEIS $1"
        case $1 in
                "ON")
                        VALUE=0x880e
                        ;;
                "OFF")
                        VALUE=0x880e
                        ;;
                *)
                        VALUE=0x880e
                        ;;
        esac
        
        #echo "n_rec_mute $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LRecEIS $1
        cardv_msg $VALUE
}
LRecDelay()
{
        echo "($0): LRecDelay $1"
        nvconf set 0 Camera.Menu.LRecDelay $1
        cardv_msg 0x3500
}
t_l_rec_res()
{
        echo "($0): t_l_rec_res $1"
        nvconf set 0 Camera.Menu.TLRecRes $1
        cardv_msg 0x3100
}

t_l_rec_intervals()
{
        echo "($0): t_l_rec_intervals $1"
        case $1 in
                "0.5S")
                        VALUE=0x6200
                        ;;
                "1S")
                        VALUE=0x6200
                        ;;
                "2S")
                        VALUE=0x6201
                        ;;
                "5S")
                        VALUE=0x6202
                        ;;
                "10S")
                        VALUE=0x6203
                        ;;
                "30S")
                        VALUE=0x6204
                        ;;
                "60S")
                        VALUE=0x6205
                        ;;
                *)
                        VALUE=0x6200
                        ;;
        esac
        
        #echo "t_l_rec_intervals $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecIntervals $1
        cardv_msg $VALUE
}

t_l_rec_wb()
{
        echo "($0): t_l_rec_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "t_l_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecWb $1
        cardv_msg $VALUE
}

t_l_rec_filter()
{
        echo "($0): t_l_rec_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecFilter $1
        cardv_msg $VALUE
}

t_l_rev_ev()
{
        echo "($0): t_l_rev_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "t_l_rev_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecEv $1
        cardv_msg $VALUE
}

t_l_rec_time()
{
        echo "($0): t_l_rec_time $1"
        case $1 in
                "UNLIMITED")
                        VALUE=0x6300
                        ;;
                "6S")
                        VALUE=0x6301
                        ;;
                "8S")
                        VALUE=0x6302
                        ;;
                "10S")
                        VALUE=0x6303
                        ;;
                "30S")
                        VALUE=0x6304
                        ;;
                "60S")
                        VALUE=0x6305
                        ;;
                "120S")
                        VALUE=0x6306
                        ;;
                *)
                        VALUE=0x6300
                        ;;
        esac
        
        #echo "t_l_rec_time $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecTime $1
        cardv_msg $VALUE
}

t_l_rec_me_mode()
{
        echo "($0): t_l_rec_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "t_l_rec_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecMeMode $1
        cardv_msg $VALUE
}

t_l_rec_shap()
{
        echo "($0): t_l_rec_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "t_l_rec_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecShap $1
        cardv_msg $VALUE
}

t_l_rec_effect()
{
        echo "($0): t_l_rec_effect $1"
        case $1 in
                "HIGH")
                        VALUE=0x6000
                        ;;
                "MID")
                        VALUE=0x6001
                        ;;
                "LOW")
                        VALUE=0x6002
                        ;;
                *)
                        VALUE=0x6000
                        ;;
        esac
        
        #echo "t_l_rec_effect $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecEffect $1
        cardv_msg $VALUE
}

t_l_rec_iso()
{
        echo "($0): t_l_rec_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "t_l_rec_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecISO $1
        cardv_msg $VALUE
}
t_l_rec_water_m()
{
        echo "($0): t_l_rec_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "n_rec_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TLRecWaterM $1
        cardv_msg $VALUE
}
n_photo_res()
{
        echo "($0): n_photo_res $1"
        #echo "n_photo_res $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoRes $1
        cardv_msg 0x5A00
}

n_photo_wb()
{
        echo "($0): n_photo_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "n_photo_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoWb $1
        cardv_msg $VALUE
}

n_photo_filter()
{
        echo "($0): n_photo_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoFilter $1
        cardv_msg $VALUE
}

n_photo_ev()
{
        echo "($0): n_photo_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        echo " n_photo_ev $VALUE"
        
        #echo "n_photo_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoEv $1
        cardv_msg $VALUE
}

n_photo_me_mode()
{
        echo "($0): n_photo_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "n_photo_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoMeMode $1
        cardv_msg $VALUE
}

n_photo_shap()
{
        echo "($0): n_photo_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "n_photo_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoShap $1
        cardv_msg $VALUE
}

n_photo_iso()
{
        echo "($0): n_photo_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "n_photo_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoISO $1
        cardv_msg $VALUE
}

n_photo_water_m()
{
        echo "($0): n_photo_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "n_photo_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoWaterM $1
        cardv_msg $VALUE
}


n_photo_l_ev()
{
        echo "($0): n_photo_l_ev $1"
        case $1 in
                "AUTO")
                        VALUE=0x6400
                        ;;
                "2S")
                        VALUE=0x6401
                        ;;
                "5S")
                        VALUE=0x6402
                        ;;
                "10S")
                        VALUE=0x6403
                        ;;
                "15S")
                        VALUE=0x6404
                        ;;
                "20S")
                        VALUE=0x6405
                        ;;
                "30S")
                        VALUE=0x6406
                        ;;
                *)
                        VALUE=0x6400
                        ;;
        esac
        
        #echo "n_photo_l_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.NPhotoLEv $1
        cardv_msg $VALUE
}

a_photo_res()
{
        echo "($0): a_photo_res $1"
        nvconf set 0 Camera.Menu.APhotoRes $1
        cardv_msg 0x5A00
}

a_photo_intervals()
{
        echo "($0): a_photo_intervals $1"
        case $1 in
                "3S")
                        VALUE=0x6500
                        ;;
                "10S")
                        VALUE=0x6501
                        ;;
                "15S")
                        VALUE=0x6502
                        ;;
                "20S")
                        VALUE=0x6503
                        ;;
                "30S")
                        VALUE=0x6504
                        ;;
                *)
                        VALUE=0x6500
                        ;;
        esac
        
        #echo "a_photo_intervals $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoIntervals $1
        cardv_msg $VALUE
}

a_photo_wb()
{
        echo "($0): a_photo_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "a_photo_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoWb $1
        cardv_msg $VALUE
}

a_photo_filter()
{
        echo "($0): a_photo_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoFilter $1
        cardv_msg $VALUE
}

a_photo_ev()
{
        echo "($0): a_photo_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "a_photo_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoEv $1
        cardv_msg $VALUE
}

a_photo_me_mode()
{
        echo "($0): a_photo_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "a_photo_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoMeMode $1
        cardv_msg $VALUE
}

a_photo_shap()
{
        echo "($0): a_photo_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "a_photo_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoShap $1
        cardv_msg $VALUE
}

a_photo_iso()
{
        echo "($0): a_photo_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "a_photo_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoISO $1
        cardv_msg $VALUE
}

a_photo_water_m()
{
        echo "($0): a_photo_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "a_photo_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.APhotoWaterM $1
        cardv_msg $VALUE
}

c_photo_res()
{
        echo "($0): c_photo_res $1"

        nvconf set 0 Camera.Menu.CPhotoRes $1
        cardv_msg 0x5A00
}

c_photo_intervals()
{
        echo "($0): c_photo_intervals $1"
        case $1 in
                "3S")
                        VALUE=0x6600
                        ;;
                "5S")
                        VALUE=0x6601
                        ;;
                "10S")
                        VALUE=0x6602
                        ;;
                *)
                        VALUE=0x6600
                        ;;
        esac
        
        #echo "c_photo_intervals $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoFEQ $1
        cardv_msg $VALUE
}
c_photo_wb()
{
        echo "($0): c_photo_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "c_photo_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoWb $1
        cardv_msg $VALUE
}

c_photo_filter()
{
        echo "($0): c_photo_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoFilter $1
        cardv_msg $VALUE
}

c_photo_ev()
{
        echo "($0): c_photo_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "c_photo_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoEv $1
        cardv_msg $VALUE
}

c_photo_me_mode()
{
        echo "($0): c_photo_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "c_photo_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoMeMode $1
        cardv_msg $VALUE
}

c_photo_shap()
{
        echo "($0): c_photo_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "c_photo_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoShap $1
        cardv_msg $VALUE
}

c_photo_iso()
{
        echo "($0): c_photo_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "c_photo_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoISO $1
        cardv_msg $VALUE
}

c_photo_water_m()
{
        echo "($0): c_photo_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "c_photo_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CPhotoWaterM $1
        cardv_msg $VALUE
}

t_photo_res()
{
        echo "($0): t_photo_res $1"

        nvconf set 0 Camera.Menu.TPhotoRes $1
        cardv_msg 0x5A00
}

t_photo_count_down()
{
        echo "($0): t_photo_count_down $1"
        case $1 in
                "3S")
                        VALUE=0x6700
                        ;;
                "5S")
                        VALUE=0x6701
                        ;;
                "10S")
                        VALUE=0x6702
                        ;;
                "20S")
                        VALUE=0x6703
                        ;;
                *)
                        VALUE=0x6701
                        ;;
        esac
        
        #echo "t_photo_count_down $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoCountDown $1
        cardv_msg $VALUE
}

t_photo_wb()
{
        echo "($0): t_photo_wb $1"
        case $1 in
                "AUTO")
                        VALUE=0x5B00
                        ;;
                "SUNNY")
                        VALUE=0x5B01
                        ;;
                "CLOUDY")
                        VALUE=0x5B02
                        ;;
                "INCANDESCENT")
                        VALUE=0x5B03
                        ;;
                "FLUORESCENCE")
                        VALUE=0x5B04
                        ;;
                *)
                        VALUE=0x5B00
                        ;;
        esac
        
        #echo "t_photo_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoWb $1
        cardv_msg $VALUE
}

t_photo_filter()
{
        echo "($0): t_photo_filter $1"
        case $1 in
                "none")
                        VALUE=0x5800
                        ;;
                "gray")
                        VALUE=0x5801
                        ;;
                "negative")
                        VALUE=0x5802
                        ;;
                "antique")
                        VALUE=0x5803
                        ;;
                "brow")
                        VALUE=0x5804
                        ;;
                "warm")
                        VALUE=0x5805
                        ;;
                "cool")
                        VALUE=0x5806
                        ;;
                "colorful")
                        VALUE=0x5807
                        ;;
                "red")
                        VALUE=0x5808
                        ;;
                "green")
                        VALUE=0x5809
                        ;;
                "blue")
                        VALUE=0x580a
                        ;;
                *)
                        VALUE=0x5800
                        ;;
        esac
        
        #echo "s_rec_wb $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoFilter $1
        cardv_msg $VALUE
}


t_photo_ev()
{
        echo "($0): t_photo_ev $1"
        case $1 in
                "EVN0")
                        VALUE=0x5C00
                        ;;
                "EVN1")
                        VALUE=0x5C01
                        ;;
                "EVN2")
                        VALUE=0x5C02
                        ;;
                "EVN3")
                        VALUE=0x5C03
                        ;;
                "EVN4")
                        VALUE=0x5C04
                        ;;
                "EVN5")
                        VALUE=0x5C05
                        ;;
                "EVN6")
                        VALUE=0x5C06
                        ;;
                *)
                        VALUE=0x5C00
                        ;;
        esac
        
        #echo "t_photo_ev $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoEv $1
        cardv_msg $VALUE
}

t_photo_me_mode()
{
        echo "($0): t_photo_me_mode $1"
        case $1 in
                "METER0")
                        VALUE=0x5D00
                        ;;
                "METER1")
                        VALUE=0x5D01
                        ;;
                "METER2")
                        VALUE=0x5D02
                        ;;
                "METER3")
                        VALUE=0x5D03
                        ;;
                *)
                        VALUE=0x5D00
                        ;;
        esac
        
        #echo "t_photo_me_mode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoMeMode $1
        cardv_msg $VALUE
}

t_photo_shap()
{
        echo "($0): t_photo_shap $1"
        case $1 in
                "SHARPNESSH")
                        VALUE=0x5E00
                        ;;
                "SHARPNESSM")
                        VALUE=0x5E01
                        ;;
                "SHARPNESSL")
                        VALUE=0x5E02
                        ;;
                *)
                        VALUE=0x5E00
                        ;;
        esac
        
        #echo "t_photo_shap $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoShap $1
        cardv_msg $VALUE
}

t_photo_iso()
{
        echo "($0): t_photo_iso $1"
        case $1 in
                "ISOAUTO")
                        VALUE=0x5F00
                        ;;
                "ISO100")
                        VALUE=0x5F01
                        ;;
                "ISO200")
                        VALUE=0x5F02
                        ;;
                "ISO400")
                        VALUE=0x5F03
                        ;;
                "ISO800")
                        VALUE=0x5F04
                        ;;
                "ISO1600")
                        VALUE=0x5F05
                        ;;
                "ISO3200")
                        VALUE=0x5F06
                        ;;
                "ISO6400")
                        VALUE=0x5F07
                        ;;
                *)
                        VALUE=0x5F00
                        ;;
        esac
        
        #echo "t_photo_iso $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoISO $1
        cardv_msg $VALUE
}

t_phoot_water_m()
{
        echo "($0): t_phoot_water_m $1"
        case $1 in
                "WATERMARKON")
                        VALUE=0x6100
                        ;;
                "WATERMARKOFF")
                        VALUE=0x6101
                        ;;
                *)
                        VALUE=0x6100
                        ;;
        esac
        
        #echo "t_phoot_water_m $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.TPhotoWaterM $1
        cardv_msg $VALUE
}

movie_sin()
{
        echo "($0): movie_sin $1"
        case $1 in
                "ON")
                        VALUE=0x6800
                        ;;
                "OFF")
                        VALUE=0x6801
                        ;;
                *)
                        VALUE=0x6800
                        ;;
        esac
        
        #echo "movie_sin $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.MovieSin $1
        cardv_msg $VALUE
}

NRecLenLdc()
{
        echo "($0): NRecLenLdc $1"

        nvconf set 0 Camera.Menu.NRecLenLdc $1
        cardv_msg 0x7500
}
LRecLenLdc()
{
        echo "($0): LRecLenLdc $1"

        nvconf set 0 Camera.Menu.LRecLenLdc $1
        cardv_msg 0x7500
}
CapLenLdc()
{
        echo "($0): CapLenLdc $1"

        nvconf set 0 Camera.Menu.CapLenLdc $1
        cardv_msg 0x7500
}
EncoderType()
{
        echo "($0): EncoderType $1"

        nvconf set 0 Camera.Menu.EncoderType $1
        cardv_msg 0x7600
}
WiFi()
{
        echo "($0): WiFi $1"
        case $1 in
                "ON")
                        VALUE=0
                        ;;
                "OFF")
                        VALUE=1
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        echo "WiFi $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.WiFi $1
}

flicker()
{
        echo "($0): flicker $1"
        case $1 in
                "AUTO")
                        VALUE=0x3f00
                        ;;
                "50HZ")
                        VALUE=0x3f01
                        ;;
                "60HZ")
                        VALUE=0x3f02
                        ;;
                *)
                        VALUE=0x3f00
                        ;;
        esac
        #echo "flicker $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Flicker $1
        cardv_msg $VALUE
}

ledon()
{
        echo "($0): ledon $1"
        case $1 in
                "ON")
                        VALUE=0x6900
                        ;;
                "OFF")
                        VALUE=0x6901
                        ;;
                *)
                        VALUE=0x6901
                        ;;
        esac
        
        #echo "ledon $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.LedOn $1
        cardv_msg $VALUE
}

bl_level_set()
{
        echo "($0): bl_level_set $1"
        case $1 in
                "LOW")
                        VALUE=0
                        ;;
                "MID")
                        VALUE=1
                        ;;      
                "HIGH")
                        VALUE=2
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        #echo "bl_level_set $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.BLlevel $1
        cardv_msg 0x4c00
}

bl_time()
{
        echo "($0): bl_time $1"
        case $1 in
                "OFF")
                        VALUE=0
                        ;;
                "30S")
                        VALUE=1
                        ;;
                "1MIN")
                        VALUE=2
                        ;;
                "2MIN")
                        VALUE=3
                        ;;              
                "3MIN")
                        VALUE=4
                        ;;              
                "5MIN")
                        VALUE=5
                        ;;      
                *)
                        VALUE=0
                        ;;
        esac
        #echo "bl_time $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.BLTime $1
        cardv_msg 0x0903
}


powerofftime()
{
        echo "($0): powerofftime $1"
        case $1 in
                "OFF")
                        VALUE=0x6A00
                        ;;
                "1MIN")
                        VALUE=0x6A01
                        ;;
                "3MIN")
                        VALUE=0x6A01
                        ;;
                "5MIN")
                        VALUE=0x6A02
                        ;;
                "10MIN")
                        VALUE=0x6A03
                        ;;                      
                *)
                        VALUE=0x6A00
                        ;;
        esac
        
        #echo "powerofftime $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.PowerOffTime $1
        cardv_msg $VALUE
}

keytone()
{
        echo "($0): keytone $1"
        case $1 in
                "HIGH")
                        VALUE=0
                        ;;
                "MID")
                        VALUE=1
                        ;;
                "LOW")
                        VALUE=2
                        ;;
                "OFF")
                        VALUE=3
                        ;;                      
                *)
                        VALUE=0
                        ;;
        esac
        #echo "keytone $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.KeyTone $1
        cardv_msg 0x0903
}

poweronaudio()
{
        echo "($0): poweronaudio $1"
        case $1 in
                "ON")
                        VALUE=0
                        ;;
                "OFF")
                        VALUE=1
                        ;;                      
                *)
                        VALUE=0
                        ;;
        esac
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.PowerOnAudio $1
        cardv_msg 0x0903
}

irRemote_set()
{
        echo "($0): irRemote_set $1"
        case $1 in
                "ON")
                        VALUE=0
                        ;;
                "OFF")
                        VALUE=1
                        ;;                      
                *)
                        VALUE=0
                        ;;
        esac
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.irRemote $1
        cardv_msg 0x6E00        
}

CarDriverMode()
{
        echo "($0): CarDriverMode $1"
        case $1 in
                "ON")
                        VALUE=0
                        ;;
                "OFF")
                        VALUE=1
                        ;;                      
                *)
                        VALUE=0
                        ;;
        esac
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CarDriverMode $1
        cardv_msg 0x7000
}

CameraAngle()
{
        echo "($0): CameraAngle $1"
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.CameraAngle $1
        cardv_msg 0x7200
}

DiveMode()
{
        echo "($0): DiveMode $1"
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.DiveMode $1
        cardv_msg 0x5700
}
Beautiful()
{
        echo "($0): Beautiful $1"
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Beautiful $1
        cardv_msg 0x7400
}
ShutterAudio()
{
        echo "($0): ShutterAudio $1"
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.ShutterAudio $1
        cardv_msg 0x0903
}

lan_set()
{
        echo "($0): lan_set $1"
        ##case $1 in
        ##      "zh_CN")
        ##              VALUE=0
        ##              ;;
        ##      "zh_TW")
        ##              VALUE=1
        ##              ;;      
        ##      "en_US")
        ##              VALUE=2
        ##              ;;
        ##      *)
        ##              VALUE=0
        ##              ;;
        ##esac
        #echo "lan_set $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.Lan $1
        cardv_msg 0x3900
}
ShotVertical()
{
        echo "($0): ShotVertical $1"
        #echo "poweronaudio $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.ShotVertical $1
        cardv_msg 0x8815
}

datetimemode()
{
        echo "($0): datetimemode $1"
        case $1 in
                "YMD")
                        VALUE=0
                        ;;
                "MDY")
                        VALUE=1
                        ;;      
                "DMY")
                        VALUE=2
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        #echo "datetimemode $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.DateTimeMode $1
        cardv_msg 0x880c
}

playback_volume()
{
        echo "($0): playback_volume $1"
        case $1 in
                "00")
                        VALUE=0
                        ;;
                "01")
                        VALUE=1
                        ;;      
                "02")
                        VALUE=2
                        ;;
                "03")
                        VALUE=3
                        ;;
                "04")
                        VALUE=4
                        ;;
                "05")
                        VALUE=5
                        ;;
                "06")
                        VALUE=6
                        ;;
                "07")
                        VALUE=7
                        ;;
                "08")
                        VALUE=8
                        ;;
                "09")
                        VALUE=9
                        ;;
                "10")
                        VALUE=10
                        ;;
                *)
                        VALUE=0
                        ;;
        esac
        #echo "playback_volume $VALUE" > $VIDEOPARAM
        nvconf set 0 Camera.Menu.PlaybackVolume $1
        cardv_msg 0x0903
}

AudioAnr()
{
        echo "($0): AudioAnr $1"
        nvconf set 0 Camera.Menu.AudioAnr $1
        cardv_msg 0x3800
}

AF()
{
        echo "($0): AF $1"
        nvconf set 0 Camera.Menu.AF $1
        cardv_msg 0x6F00
}

PhotoAF()
{
        echo "($0): PhotoAF $1"
        nvconf set 0 Camera.Menu.PhotoAF $1
        cardv_msg 0x6F00
}
AFIrLed()
{
        echo "($0): AFIrLed $1"
        nvconf set 0 Camera.Menu.AFIrLed $1
        cardv_msg 0x0903
}
viewgrid()
{
        echo "($0): ViewGrid $1"
        nvconf set 0 Camera.Menu.ViewGrid $1
        cardv_msg 0x0903
}

sysworkmode()
{
        echo "($0): sysworkmode $1"
        case $1 in
                "MODE0")
                        VALUE=0x6b00
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.sysrecmode $1
                        ;;
                "MODE1")
                        VALUE=0x6b01
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.sysrecmode $1
                        ;;      
                "MODE2")
                        VALUE=0x6b02
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.sysrecmode $1
                        ;;
                "MODE3")
                        VALUE=0x6b03
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.sysrecmode $1
                        ;;
                "MODE4")
                        VALUE=0x6b04
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.syspicmode MODE0
                        ;;
                "MODE5")
                        VALUE=0x6b05
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.syspicmode MODE1
                        ;;
                "MODE6")
                        VALUE=0x6b06
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.syspicmode MODE2
                        ;;
                "MODE7")
                        VALUE=0x6b07
                        nvconf set 0 Camera.Menu.sysworkmode $1
                        nvconf set 0 Camera.Menu.syspicmode MODE3
                        ;;
                *)
                        VALUE=0x6b00
                        nvconf set 0 Camera.Menu.sysworkmode MODE0
                        nvconf set 0 Camera.Menu.sysrecmode MODE0
                        ;;
        esac
        cardv_msg $VALUE
}

SET()
{
        echo "($0): SET $1 $2 "
        case $1 in
                "Camera.Preview.MJPEG.TimeStamp")
                        TimeSettings $2
                        ;;
                "StreamStatus")
                        if [ "$2" = "ON" ]; then
                                echo "StreamStatus 1" >$VIDEOPARAM 
                                #cardv_msg 0x5901
                        fi
                        ;;
                "Playback")
                        Playback_Update $2
                        ;;
                "Camera.Menu.APPConnection")
                        APPConnectionStatus $2
                        ;;
                "Net")
                        if [ "$2" = "reset" ];then
                                REBOOT
                        elif [ "$2" = "findme" ];then
                                echo $@
                        fi
                        ;;
                "Net.WIFI_AP.SSID")
                        CMD="nvconf set 1 wireless.ap.ssid $2"
                        $CMD
                        ;;
                "Net.WIFI_AP.CryptoKey")
                        CMD="nvconf set 1 wireless.ap.wpa.psk $2"
                        $CMD
                        ;;
                "Net.WIFI_STA.AP.2.SSID")
                        CMD="nvconf set 1 wireless.sta.ssid $2"
                        $CMD
                        ;;
                "Net.WIFI_STA.AP.2.CryptoKey")
                        CMD="nvconf set 1 wireless.sta.wpa.psk $2"
                        $CMD
                        ;;
                "Net.WIFI_STA.AP.Switch")
                        echo "$1:$2"
                        if [ "$2" = "ENABLE" ]; then
                                apsta_switch.sh
                        fi
                        ;;
                "Video")
                        if [ "$2" = "recordon" ];then

                                if [ "$MMC_BLK" = "" ]; then
                                        exit 1 ## return system() return value
                                else
                                        RECORDING 1
                                fi
                        elif [ "$2" = "recordoff" ];then

                                if [ "$MMC_BLK" = "" ]; then
                                        exit 1 ## return system() return value
                                else
                                        RECORDING 0
                                fi
                        elif [ "$2" = "record" ];then

                                if [ "$MMC_BLK" = "" ]; then
                                        exit 1 ## return system() return value
                                else
                                        RECORDING 2
                                fi
                        elif [ "$2" = "capture" ];then

                                if [ "$MMC_BLK" = "" ]; then
                                        exit 1 ## system() return value
                                else
                                        TAKE_PICTURE 1
                                fi
                        else
                                echo $@
                        fi
                        ;;
                "Imageres"|"ImageRes")
                        JPG_RESOLUTION $2
                        ;;
                "Videores"|"VideoRes")
                        VIDEO_RESOLUTION_FPS $2
                        ;;
                "LcdPowerSave")
                        setLcdPowerSave $2
                        ;;
                "DateTimeFormat")
                        setDateTimeFormat $2
                        ;;      
                "DateLogoStamp"|"RecStamp")
                        setDateLogoStamp $2
                        ;;
                "GpsStamp")
                        setGpsStamp $2
                        ;;
                "SpeedStamp")
                        setSpeedStamp $2
                        ;;
                "Language")
                        setLanguage $2
                        ;;
                "UsbFunction")
                        setUsbFunction $2
                        ;;
                "PowerOnGSensor")
                        setPowerOnGSensor $2
                        ;;
                "MotionDetect")
                        setMotionDetect $2
                        ;;
                "ZOOM")
                        ZOOM $2
                        ;;
                "Brightness")
                        BRIGHTNESS $2
                        ;;
                "Contrast")
                        CONTRAST $2
                        ;;
                "Hue")
                        HUE $2
                        ;;
                "Saturation")
                        SATURATION $2
                        ;;
                "Sharpness")
                        SHARPNESS $2
                        ;;
                "Gamma")
                        GAMMA $2
                        ;;
                "EV"|"Exposure")
                        EXPOSURE $2
                        ;;
                "AE")
                        EXPOSURE_AUTO $2
                        ;;
                "ISO")
                        ISO $2
                        ;;
                "Effect")
                        EFFECT $2
                        ;;
                "Flicker")
                        FLICKER $2
                        ;;
                "AWB")
                        WHITE_BALANCE $2
                        ;;
                "Shutter")
                        SHUTTER_SPEED $2
                        ;;
                "Camera.System.Power")
                        Camera_System_Power $2
                        ;;
                "TimeSettings")
                        TimeSettings $2
                        ;;
                "setbitrate")
                        setbitrate $2
                        ;;
                "FactoryReset"|"reset_to_default")
                        reset_to_default $2
                        ;;
                "reboot")
                        REBOOT
                        ;;
                "SD0")
                        SD_Format
                        ;;
                "Setting")
                        Setting_Update $2
                        ;;
                "VideoClipTime"|"LoopingVideo")
                        setVideoClipTime $2
                        ;;
                "StillBurstShot")
                        setStillBurstShot $2
                        ;;
                "LDWS")
                        setLDWS $2
                        ;;
                "FCWS")
                        setFCWS $2
                        ;;
                "SAG")
                        setSAG $2
                        ;;
                "NightMode")
                        setNightMode $2
                        ;;
                "WNR")
                        setWNR $2
                        ;;
                "HDR")
                        setHDR $2
                        ;;
                "SlowMotion")
                        setSlowMotion $2
                        ;;
                "Timelapse")
                        setTimelapse $2
                        ;;
                "AutoRec")
                        setAutoRec $2
                        ;;
                "VideoOffTime")
                        setVideoOffTime $2
                        ;;
                "PreRecord")
                        PreRecord $2
                        ;;
                "MicSensitivity")
                        setMicSensitivity $2
                        ;;
                "VideoQuality")
                        setVideoQuality $2
                        ;;
                "PlaybackVolume")
                        setPlaybackVolume $2
                        ;;
                "Beep")
                        setBeep $2
                        ;;
                "LCDBrightness")
                        LCDBrightness $2
                        ;;
                "AutoPowerOff")
                        setAutoPowerOff $2
                        ;;
                "SoundRecord"|"MovieAudio")
                        setSoundRecord $2
                        ;;
                "MotionVideoTime")
                        setMotionVideoTime $2
                        ;;
                "RecStamp")
                        setRecStamp $2
                        ;;
                "SpeedUint")
                        setSpeedUint $2
                        ;;
                "SpeedCamAlert")
                        setSpeedCamAlert $2
                        ;;
                "SpeedLimitAlert")
                        SpeedLimitAlert $2
                        ;;
                "TimeZone")
                        setTimeZone $2
                        ;;
                "SyncTime")
                        setSyncTime $2
                        ;;
                "PosSetting_Add")
                        setPosSetting_Add $2
                        ;;
                "PosSetting_DelLast")
                        setPosSetting_DelLast $2
                        ;;
                "PosSetting_DelAll")
                        setPosSetting_DelAll $2
                        ;;
                "ParkingMonitor")
                        setParkingMonitor $2
                        ;;
                "VoiceSwitch")
                        setVoiceSwitch $2
                        ;;
                "GSensor")
                        setGSensor $2
                        ;;
                "RebootSystem")
                        reboot_system $2
                        ;;
                "NRecRes")
                        N_VIDEO_RESOLUTION_FPS $2
                        ;;
                "NRecWb")
                        n_rec_wb $2
                        ;;
                "NRecFilter")
                        n_rec_filter $2
                        ;;
                "NRecEv")
                        n_rec_ev $2
                        ;;
                "NRecMeMode")
                        n_rec_me_mode $2
                        ;;
                "NRecShap")
                        n_rec_shap $2
                        ;;
                "NRecEffect")
                        n_rec_effect $2
                        ;;
                "NRecISO")
                        n_rec_iso $2
                        ;;
                "NRecWaterM")
                        n_rec_water_m $2
                        ;;
                "NRecMMute")
                        n_rec_mute $2
                        ;;
                "NRecMTD")
                        n_rec_mtd $2
                        ;;
                "NRecEIS")
                        n_rec_eis $2
                        ;;
                "NRecDelay")
                        NRecDelay $2
                        ;;
                "SRecType")
                        s_rec_type  $2
                        ;;
                "SRecWb")
                        s_rec_wb $2
                        ;;
                "SRecFilter")
                        s_rec_filter $2
                        ;;
                "SRecEv")
                        s_rec_ev $2
                        ;;
                "SRecMeMode")
                        s_rec_me_mode $2
                        ;;
                "SRecShap")
                        s_rec_shap $2
                        ;;
                "SRecEffect")
                        s_rec_effect $2
                        ;;
                "SRecISO")
                        s_rec_iso $2
                        ;;
                "LRecRes")
                        l_rec_res $2
                        ;;
                "LRecTime")
                        l_rec_time $2
                        ;;
                "LRecWb")
                        l_rec_wb $2
                        ;;
                "LRecFilter")
                        l_rec_filter $2
                        ;;
                "LRecEv")
                        l_rec_ev $2
                        ;;
                "LRecMeMode")
                        l_rec_me_mode $2
                        ;;
                "LRecShap")
                        l_rec_shap $2
                        ;;
                "LRecEffect")
                        l_rec_effect $2
                        ;;
                "LRecISO")
                        l_rec_iso $2
                        ;;
                "LRecWaterM")
                        l_rec_water_m $2
                        ;;
                "LRecMMute")
                        l_rec_mute $2
                        ;;
                "LRecMTD")
                        l_rec_mtd $2
                        ;;
                "LRecEIS")
                        l_rec_eis $2
                        ;;
                "LRecDelay")
                        LRecDelay $2
                        ;;
                "TLRecRes")
                        t_l_rec_res $2
                        ;;
                "TLRecIntervals")
                        t_l_rec_intervals $2
                        ;;
                "TLRecWb")
                        t_l_rec_wb $2
                        ;;
                "TLRecFilter")
                        t_l_rec_filter $2
                        ;;
                "TLRecEv")
                        t_l_rev_ev $2
                        ;;
                "TLRecTime")
                        t_l_rec_time $2
                        ;;
                "TLRecMeMode")
                        t_l_rec_me_mode $2
                        ;;
                "TLRecShap")
                        t_l_rec_shap $2
                        ;;
                "TLRecEffect")
                        t_l_rec_effect $2
                        ;;
                "TLRecISO")
                        t_l_rec_iso $2
                        ;;
                "NPhotoRes")
                        n_photo_res $2
                        ;;
                "NPhotoWb")
                        n_photo_wb $2
                        ;;
                "NPhotoFilter")
                        n_photo_filter $2
                        ;;
                "NPhotoEv")
                        n_photo_ev $2
                        ;;
                "NPhotoLEv")
                        n_photo_l_ev $2
                        ;;
                "NPhotoMeMode")
                        n_photo_me_mode $2
                        ;;
                "NPhotoISO")
                        n_photo_iso $2
                        ;;
                "NPhotoWaterM")
                        n_photo_water_m $2
                        ;;
                "APhotoRes")
                        a_photo_res $2
                        ;;
                "APhotoIntervals")
                        a_photo_intervals $2
                        ;;
                "APhotoWb")
                        a_photo_wb $2
                        ;;
                "APhotoFilter")
                        a_photo_filter $2
                        ;;
                "APhotoEv")
                        a_photo_ev $2
                        ;;
                "APhotoMeMode")
                        a_photo_me_mode $2
                        ;;
                "APhotoShap")
                        a_photo_shap $2
                        ;;
                "APhotoISO")
                        a_photo_iso $2
                        ;;
                "APhotoWaterM")
                        a_photo_water_m $2
                        ;;
                "CPhotoRes")
                        c_photo_res $2
                        ;;
                "CPhotoFEQ")
                        c_photo_intervals $2
                        ;;
                "CPhotoWb")
                        c_photo_wb $2
                        ;;
                "CPhotoFilter")
                        c_photo_filter $2
                        ;;
                "CPhotoEv")
                        c_photo_ev $2
                        ;;
                "CPhotoMeMode")
                        c_photo_me_mode $2
                        ;;
                "CPhotoShap")
                        c_photo_shap $2
                        ;;
                "CPhotoISO")
                        c_photo_iso $2
                        ;;
                "CPhotoWaterM")
                        c_photo_water_m $2
                        ;;
                "TPhotoRes")
                        t_photo_res $2
                        ;;
                "TPhotoCountDown")
                        t_photo_count_down $2
                        ;;
                "TPhotoWb")
                        t_photo_wb $2
                        ;;
                "TPhotoFilter")
                        t_photo_filter $2
                        ;;
                "TPhotoEv")
                        t_photo_ev $2
                        ;;
                "TPhotoMeMode")
                        t_photo_me_mode $2
                        ;;
                "TPhotoShap")
                        t_photo_shap $2
                        ;;
                "TPhotoISO")
                        t_photo_iso $2
                        ;;
                "TPhotoWaterM")
                        t_phoot_water_m $2
                        ;;
                "MovieSin")
                        movie_sin $2
                        ;;
                "NRecLenLdc")
                        NRecLenLdc $2
                        ;;
                "LRecLenLdc")
                        LRecLenLdc $2
                        ;;
                "CapLenLdc")
                        CapLenLdc $2
                        ;;
                "EncoderType")
                        EncoderType $2
                        ;;
                "WiFi")
                        wifi_sw $2
                        ;;
                "Flicker")
                        flicker $2
                        ;;
                "LedOn")
                        ledon $2
                        ;;
                "BLTime")
                        bl_time $2
                        ;;
                "BLlevel")
                        bl_level_set $2
                        ;;      
                "PowerOffTime")
                        powerofftime $2
                        ;;
                "KeyTone")
                        keytone $2
                        ;;
                "PowerOnAudio")
                        poweronaudio $2
                        ;;
                "irRemote")
                        irRemote_set $2
                        ;;
                "CarDriverMode")
                        CarDriverMode $2
                        ;;
                "CameraAngle")
                        CameraAngle $2
                        ;;
                "DiveMode")
                        DiveMode $2
                        ;;
                "Beautiful")
                        Beautiful $2
                        ;;
                "ShutterAudio")
                        ShutterAudio $2
                        ;;
                "Lan")
                        lan_set $2
                        ;;
                "ShotVertical")
                        ShotVertical $2
                        ;;
                "DateTimeMode")
                        datetimemode $2
                        ;;
                "PlaybackVolume")
                        playback_volume $2
                        ;;
                "AudioAnr")
                        AudioAnr $2
                        ;;
                "AF") 
                        AF $2
                        ;;
                "PhotoAF") 
                        PhotoAF $2
                        ;;
                "AFIrLed") 
                        AFIrLed $2
                        ;;
                "sysworkmode")
                        sysworkmode $2
                        ;;
                "Camera.Menu.sysworkmode")
                        sysworkmode $2
                        ;;                      
                "SyncTime")
                        synctime $2
                        ;;
                "ViewGrid")
                        viewgrid $2
                        ;;
                "")
                        echo "You MUST input parameters, ex> {$Para0 someword}"
                        ;;
                *)
                        echo "Usage $Para0 {no this parameter}"
                        ;;

        esac
}

GET()
{
        #echo "($0): GET $1 "
        case $1 in
                "Camera.Menu.SDInfo")
                        echo "Get SD Status"
                        SD0INFO=`cat /tmp/mmc_status`
                        echo SD0INFO=$SD0INFO
                        if [ "$SD0INFO" == "1" ]; then
                                echo "$1=ON"
                        else
                                echo "$1=OFF"
                        fi
                        ;;
                "Camera.Menu.CardInfo.*")
                        if [ "$MMC_BLK" = "" ]; then
                                echo "$1=NONE"
                        else
                                echo "Camera.Menu.CardInfo.LifeTimeTotal=$(df /mnt/mmc/ |sed -n '2p' |awk '{print $2}')"
                                echo "Camera.Menu.CardInfo.RemainLifeTime=$(df /mnt/mmc/ |sed -n '2p' |awk '{print $4}')"
                                #str=$(cat /sys/devices/soc0/soc/soc:sdmmc/mmc_host/mmc0/mmc0:1388/cardlife)
                                #RemainWrGBNumInfo=$(echo ${str#*,})
                                #SizeOfDevSMARTInfo=$(echo ${str%,*})
                                #echo "Camera.Menu.CardInfo.RemainWrGBNum=$RemainWrGBNumInfo"
                                #echo "Camera.Menu.CardInfo.SizeOfDevSMART=$SizeOfDevSMARTInfo"
                        fi
                        ;;
                "Camera.Preview.MJPEG.TimeStamp")
                        CMD="date +"%d""
                        echo "Camera.Preview.MJPEG.TimeStamp.day=`$CMD`"
                        CMD="date +"%H""
                        echo "Camera.Preview.MJPEG.TimeStamp.hour=`$CMD`"
                        CMD="date +"%M""
                        echo "Camera.Preview.MJPEG.TimeStamp.minute=`$CMD`"
                        CMD="date +"%m""
                        echo "Camera.Preview.MJPEG.TimeStamp.month=`$CMD`"
                        CMD="date +"%S""
                        echo "Camera.Preview.MJPEG.TimeStamp.second=`$CMD`"
                        CMD="date +"%Y""
                        echo "Camera.Preview.MJPEG.TimeStamp.year=`$CMD`"
                        ;;
                "Camera.Preview.MJPEG.TimeStamp.*")
                        CMD="date +"%d""
                        echo "Camera.Preview.MJPEG.TimeStamp.day=`$CMD`"
                        CMD="date +"%H""
                        echo "Camera.Preview.MJPEG.TimeStamp.hour=`$CMD`"
                        CMD="date +"%M""
                        echo "Camera.Preview.MJPEG.TimeStamp.minute=`$CMD`"
                        CMD="date +"%m""
                        echo "Camera.Preview.MJPEG.TimeStamp.month=`$CMD`"
                        CMD="date +"%S""
                        echo "Camera.Preview.MJPEG.TimeStamp.second=`$CMD`"
                        CMD="date +"%Y""
                        echo "Camera.Preview.MJPEG.TimeStamp.year=`$CMD`"
                        ;;
                "Net.WIFI_AP.SSID")
                        CMD="nvconf get 1 wireless.ap.ssid"
                        echo "Net.WIFI_AP.SSID=`$CMD`"
                        ;;
                "Net.WIFI_AP.CryptoKey")
                        CMD="nvconf get 1 wireless.ap.wpa.psk"
                        echo "Net.WIFI_AP.CryptoKey=`$CMD`"
                        ;;
                "Net.WIFI_STA.AP.2.SSID")
                        CMD="nvconf get 1 wireless.sta.ssid"
                        echo "Net.WIFI_STA.AP.2.SSID=`$CMD`"
                        ;;
                "Net.WIFI_STA.AP.2.CryptoKey")
                        CMD="nvconf get 1 wireless.sta.wpa.psk"
                        echo "Net.WIFI_STA.AP.2.CryptoKey=`$CMD`"
                        ;;
                "Net.WIFI_STA.AP.Switch")
                        ;;
                "Camera.Preview.MJPEG.status.*")
                        REC_ING=`cat $REC_STATUS`
                        if [ "$REC_ING" = "1" ] || [ "$REC_ING" = "2" ]; then
                                OUTPUT="Recording"
                        else
                                OUTPUT="Standby"
                        fi
                        echo "Camera.Preview.MJPEG.status.mode=Videomode"
                        echo "Camera.Preview.MJPEG.status.record=$OUTPUT"
                        ;;
                "Camera.Preview.Source.1.Camid")
                        ;;
                "Camera.Preview.Adas.*")
                        ;;
                "Solution_provider")
                        SP_INFO=`cat $SOLUTION_PROVIDER`
                        echo "$SP_INFO"
                        ;;
                "battery")
                        BATTERY_INFO=`cat $BATTERY`
                        echo "$BATTERY_INFO"
                        ;;
                "rtsp_info")
                        RTSP_INFO=`cat $RTSP_STATUS`
                        echo "$RTSP_INFO"
                        ;;
                "Videores")
                        CMD="nvconf get 0 Camera.Menu.VideoRes"
                        echo "$1=`$CMD`"
                        ;;
                "ZOOM")
                        echo "$1=1"
                        ;;
                "Brightness")
                        CMD="nvconf get 0 Camera.Menu.Brightness"
                        echo "$1=`$CMD`"
                        ;;
                "Contrast")
                        CMD="nvconf get 0 Camera.Menu.Contrast"
                        echo "$1=`$CMD`"
                        ;;
                "Hue")
                        CMD="nvconf get 0 Camera.Menu.Hue"
                        echo "$1=`$CMD`"
                        ;;
                "Saturation")
                        CMD="nvconf get 0 Camera.Menu.Saturation"
                        echo "$1=`$CMD`"
                        ;;
                "Sharpness")
                        CMD="nvconf get 0 Camera.Menu.Sharpness"
                        echo "$1=`$CMD`"
                        ;;
                "Gamma")
                        CMD="nvconf get 0 Camera.Menu.gamma"
                        echo "$1=`$CMD`"
                        ;;
                "EV")
                        CMD="nvconf get 0 Camera.Menu.EV"
                        echo "$1=`$CMD`"
                        ;;
                "AE")
                        CMD="nvconf get 0 Camera.Menu.AE"
                        echo "$1=`$CMD`"
                        ;;
                "Flicker")
                        CMD="nvconf get 0 Camera.Menu.Flicker"
                        echo "$1=`$CMD`"
                        ;;
                "AWB")
                        CMD="nvconf get 0 Camera.Menu.AWB"
                        echo "$1=`$CMD`"
                        ;;
                "Shutter")
                        CMD="nvconf get 0 Camera.Menu.Shutter"
                        echo "$1=`$CMD`"
                        ;;
                "FwVer")
                        CMD="nvconf get 1 devinfo.fwver"
                        echo "$1=`$CMD`"
                        ;;
                "StillBurstShot")
                        CMD="nvconf get 0 Camera.Menu.BurstShot"
                        echo "$1=`$CMD`"
                        ;;
                "LDWS")
                        CMD="nvconf get 0 Camera..Preview.Adas.LDWS"
                        echo "$1=`$CMD`"
                        ;;
                "FCWS")
                        CMD="nvconf get 0 Camera..Preview.Adas.FCWS"
                        echo "$1=`$CMD`"
                        ;;
                "SAG")
                        CMD="nvconf get 0 Camera..Preview.Adas.SAG"
                        echo "$1=`$CMD`"
                        ;;
                "NightMode")
                        CMD="nvconf get 0 Camera.Menu.NightMode"
                        echo "$1=`$CMD`"
                        ;;
                "WNR")
                        CMD="nvconf get 0 Camera.Menu.WNR"
                        echo "$1=`$CMD`"
                        ;;
                "HDR")
                        CMD="nvconf get 0 Camera.Menu.HDR"
                        echo "$1=`$CMD`"
                        ;;
                "SlowMotion")
                        CMD="nvconf get 0 Camera.Menu.SlowMotion"
                        echo "$1=`$CMD`"
                        ;;
                "Timelapse")
                        CMD="nvconf get 0 Camera.Menu.Timelapse"
                        echo "$1=`$CMD`"
                        ;;
                "AutoRec")
                        CMD="nvconf get 0 Camera.Menu.AutoRec"
                        echo "$1=`$CMD`"
                        ;;
                "VideoOffTime")
                        CMD="nvconf get 0 Camera.Menu.VideoOffTime"
                        echo "$1=`$CMD`"
                        ;;
                "PreRecord")
                        CMD="nvconf get 0 Camera.Menu.PreRecord"
                        echo "$1=`$CMD`"
                        ;;
                "VideoClipTime")
                        CMD="nvconf get 0 Camera.Menu.VideoClipTime"
                        echo "$1=`$CMD`"
                        ;;
                "MicSensitivity")
                        CMD="nvconf get 0 Camera.Menu.MicSensitivity"
                        echo "$1=`$CMD`"
                        ;;
                "VideoQuality")
                        CMD="nvconf get 0 Camera.Menu.VideoQuality"
                        echo "$1=`$CMD`"
                        ;;
                "SoundRecord")
                        CMD="nvconf get 0 Camera.Menu.RecordWithAudio"
                        echo "$1=`$CMD`"
                        ;;
                "ParkingMonitor")
                        CMD="nvconf get 0 Camera.Menu.ParkingMonitor"
                        echo "$1=`$CMD`"
                        ;;
                "MotionVideoTime")
                        CMD="nvconf get 0 Camera.Menu.MotionVideoTime"
                        echo "$1=`$CMD`"
                        ;;
                "PlaybackVolume")
                        CMD="nvconf get 0 Camera.Menu.PlaybackVolume"
                        echo "$1=`$CMD`"
                        ;;
                "Beep")
                        CMD="nvconf get 0 Camera.Menu.Beep"
                        echo "$1=`$CMD`"
                        ;;
                "AutoPowerOff")
                        CMD="nvconf get 0 Camera.Menu.AutoPowerOff"
                        echo "$1=`$CMD`"
                        ;;
                "DateTimeFormat")
                        CMD="nvconf get 0 Camera.Menu.DateTimeFormat"
                        echo "$1=`$CMD`"
                        ;;
                "DateLogoStamp")
                        CMD="nvconf get 0 Camera.Menu.DateLogoStamp"
                        echo "$1=`$CMD`"
                        ;;
                "GpsStamp")
                        CMD="nvconf get 0 Camera.Menu.GpsStamp"
                        echo "$1=`$CMD`"
                        ;;
                "SpeedStamp")
                        CMD="nvconf get 0 Camera.Menu.SpeedStamp"
                        echo "$1=`$CMD`"
                        ;;
                "Language")
                        CMD="nvconf get 0 Camera.Menu.Language"
                        echo "$1=`$CMD`"
                        ;;
                "UsbFunction")
                        CMD="nvconf get 0 Camera.Menu.USB"
                        echo "$1=`$CMD`"
                        ;;
                "LcdPowerSave")
                        CMD="nvconf get 0 Camera.Menu.PowerSaving"
                        echo "$1=`$CMD`"
                        ;;
                "GSensor")
                        CMD="nvconf get 0 Camera.Menu.GSensorSensitivity"
                        echo "$1=`$CMD`"
                        ;;
                "PowerOnGSensor")
                        CMD="nvconf get 0 Camera.Menu.GSensorPowerOnSens"
                        echo "$1=`$CMD`"
                        ;;
                "MotionDetect")
                        CMD="nvconf get 0 Camera.Menu.MotionSensitivity"
                        echo "$1=`$CMD`"
                        ;;
                "TimeZone")
                        CMD="nvconf get 0 Camera.Menu.TimeZone"
                        echo "$1=`$CMD`"
                        ;;
                "Camera.menu.FWVersion"|"FWVersion")
                        CMD=`cat /tmp/MenuFWVersion`
                        echo "$1=$CMD"
                        ;;
                "OTAUpdate"|"FWUpdateDate")
                        CMD=`cat /tmp/MenuOTAVersion`
                        echo "$1=$CMD"
                        ;;
                "device_name")
                        CMD=`cat /tmp/device_name`
                        echo "$1=$CMD"
                        ;;
                "Camera.menu.DeviceUUID"|"Camera.menu.UUID")
                        CMD=`cat /tmp/MenuUUID`
                        echo "$1=$CMD"
                        ;;
                "Camera.Preview.RTSP.av")
                        echo "$1=4"
                        ;;
                "NRecRes")
                        CMD="nvconf get 0 Camera.Menu.NRecRes"
                        echo "$1=`$CMD`"
                        ;;
                "NRecWb")
                        CMD="nvconf get 0 Camera.Menu.NRecWb"
                        echo "$1=`$CMD`"
                        ;;
                "NRecFilter")
                        CMD="nvconf get 0 Camera.Menu.NRecFilter"
                        echo "$1=`$CMD`"
                        ;;
                "NRecEv")
                        CMD="nvconf get 0 Camera.Menu.NRecEv"
                        echo "$1=`$CMD`"
                        ;;
                "NRecMeMode")
                        CMD="nvconf get 0 Camera.Menu.NRecMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "NRecShap")
                        CMD="nvconf get 0 Camera.Menu.NRecShap"
                        echo "$1=`$CMD`"
                        ;;
                "NRecEffect")
                        CMD="nvconf get 0 Camera.Menu.NRecEffect"
                        echo "$1=`$CMD`"
                        ;;
                "NRecISO")
                        CMD="nvconf get 0 Camera.Menu.NRecISO"
                        echo "$1=`$CMD`"
                        ;;
                "NRecWaterM")
                        CMD="nvconf get 0 Camera.Menu.NRecWaterM"
                        echo "$1=`$CMD`"
                        ;;
                "NRecMMute")
                        CMD="nvconf get 0 Camera.Menu.NRecMMute"
                        echo "$1=`$CMD`"
                        ;;
                "NRecMTD")
                        CMD="nvconf get 0 Camera.Menu.NRecMTD"
                        echo "$1=`$CMD`"
                        ;;
                "NRecEIS")
                        CMD="nvconf get 0 Camera.Menu.NRecEIS"
                        echo "$1=`$CMD`"
                        ;;
                "NRecDelay")
                        CMD="nvconf get 0 Camera.Menu.NRecDelay"
                        echo "$1=`$CMD`"
                        ;;
                "SRecType")
                        CMD="nvconf get 0 Camera.Menu.SRecType"
                        echo "$1=`$CMD`"
                        ;;
                "SRecWb")
                        CMD="nvconf get 0 Camera.Menu.SRecWb"
                        echo "$1=`$CMD`"
                        ;;
                "SRecFilter")
                        CMD="nvconf get 0 Camera.Menu.SRecFilter"
                        echo "$1=`$CMD`"
                        ;;
                "SRecEv")
                        CMD="nvconf get 0 Camera.Menu.SRecEv"
                        echo "$1=`$CMD`"
                        ;;
                "SRecMeMode")
                        CMD="nvconf get 0 Camera.Menu.SRecMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "SRecShap")
                        CMD="nvconf get 0 Camera.Menu.SRecShap"
                        echo "$1=`$CMD`"
                        ;;
                "SRecEffect")
                        CMD="nvconf get 0 Camera.Menu.SRecEffect"
                        echo "$1=`$CMD`"
                        ;;
                "SRecISO")
                        CMD="nvconf get 0 Camera.Menu.SRecISO"
                        echo "$1=`$CMD`"
                        ;;
                "LRecRes")
                        CMD="nvconf get 0 Camera.Menu.LRecRes"
                        echo "$1=`$CMD`"
                        ;;
                "LRecTime")
                        CMD="nvconf get 0 Camera.Menu.LRecTime"
                        echo "$1=`$CMD`"
                        ;;
                "LRecWb")
                        CMD="nvconf get 0 Camera.Menu.LRecWb"
                        echo "$1=`$CMD`"
                        ;;
                "LRecFilter")
                        CMD="nvconf get 0 Camera.Menu.LRecFilter"
                        echo "$1=`$CMD`"
                        ;;
                "LRecEv")
                        CMD="nvconf get 0 Camera.Menu.LRecEv"
                        echo "$1=`$CMD`"
                        ;;
                "LRecMeMode")
                        CMD="nvconf get 0 Camera.Menu.LRecMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "LRecShap")
                        CMD="nvconf get 0 Camera.Menu.LRecShap"
                        echo "$1=`$CMD`"
                        ;;
                "LRecEffect")
                        CMD="nvconf get 0 Camera.Menu.LRecEffect"
                        echo "$1=`$CMD`"
                        ;;
                "LRecISO")
                        CMD="nvconf get 0 Camera.Menu.LRecISO"
                        echo "$1=`$CMD`"
                        ;;
                "LRecWaterM")
                        CMD="nvconf get 0 Camera.Menu.LRecWaterM"
                        echo "$1=`$CMD`"
                        ;;
                "LRecMMute")
                        CMD="nvconf get 0 Camera.Menu.LRecMMute"
                        echo "$1=`$CMD`"
                        ;;
                "LRecMTD")
                        CMD="nvconf get 0 Camera.Menu.LRecMTD"
                        echo "$1=`$CMD`"
                        ;;
                "LRecEIS")
                        CMD="nvconf get 0 Camera.Menu.LRecEIS"
                        echo "$1=`$CMD`"
                        ;;
                "LRecDelay")
                        CMD="nvconf get 0 Camera.Menu.LRecDelay"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecRes")
                        CMD="nvconf get 0 Camera.Menu.TLRecRes"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecIntervals")
                        CMD="nvconf get 0 Camera.Menu.TLRecIntervals"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecWb")
                        CMD="nvconf get 0 Camera.Menu.TLRecWb"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecFilter")
                        CMD="nvconf get 0 Camera.Menu.TLRecFilter"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecEv")
                        CMD="nvconf get 0 Camera.Menu.TLRecEv"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecTime")
                        CMD="nvconf get 0 Camera.Menu.TLRecTime"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecMeMode")
                        CMD="nvconf get 0 Camera.Menu.TLRecMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecShap")
                        CMD="nvconf get 0 Camera.Menu.TLRecShap"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecEffect")
                        CMD="nvconf get 0 Camera.Menu.TLRecEffect"
                        echo "$1=`$CMD`"
                        ;;
                "TLRecISO")
                        CMD="nvconf get 0 Camera.Menu.TLRecISO"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoRes")
                        CMD="nvconf get 0 Camera.Menu.NPhotoRes"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoWb")
                        CMD="nvconf get 0 Camera.Menu.NPhotoWb"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoFilter")
                        CMD="nvconf get 0 Camera.Menu.NPhotoFilter"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoEv")
                        CMD="nvconf get 0 Camera.Menu.NPhotoEv"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoLEv")
                        CMD="nvconf get 0 Camera.Menu.NPhotoLEv"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoMeMode")
                        CMD="nvconf get 0 Camera.Menu.NPhotoMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoShap")
                        CMD="nvconf get 0 Camera.Menu.NPhotoShap"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoLEv")
                        CMD="nvconf get 0 Camera.Menu.NPhotoLEv"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoISO")
                        CMD="nvconf get 0 Camera.Menu.NPhotoISO"
                        echo "$1=`$CMD`"
                        ;;
                "NPhotoWaterM")
                        CMD="nvconf get 0 Camera.Menu.NPhotoWaterM"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoRes")
                        CMD="nvconf get 0 Camera.Menu.APhotoRes"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoIntervals")
                        CMD="nvconf get 0 Camera.Menu.APhotoIntervals"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoWb")
                        CMD="nvconf get 0 Camera.Menu.APhotoWb"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoFilter")
                        CMD="nvconf get 0 Camera.Menu.APhotoFilter"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoEv")
                        CMD="nvconf get 0 Camera.Menu.APhotoEv"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoMeMode")
                        CMD="nvconf get 0 Camera.Menu.APhotoMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoShap")
                        CMD="nvconf get 0 Camera.Menu.APhotoShap"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoISO")
                        CMD="nvconf get 0 Camera.Menu.APhotoISO"
                        echo "$1=`$CMD`"
                        ;;
                "APhotoWaterM")
                        CMD="nvconf get 0 Camera.Menu.APhotoWaterM"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoRes")
                        CMD="nvconf get 0 Camera.Menu.CPhotoRes"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoFEQ")
                        CMD="nvconf get 0 Camera.Menu.CPhotoFEQ"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoWb")
                        CMD="nvconf get 0 Camera.Menu.CPhotoWb"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoFilter")
                        CMD="nvconf get 0 Camera.Menu.CPhotoFilter"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoEv")
                        CMD="nvconf get 0 Camera.Menu.CPhotoEv"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoMeMode")
                        CMD="nvconf get 0 Camera.Menu.CPhotoMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoShap")
                        CMD="nvconf get 0 Camera.Menu.CPhotoShap"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoISO")
                        CMD="nvconf get 0 Camera.Menu.CPhotoISO"
                        echo "$1=`$CMD`"
                        ;;
                "CPhotoWaterM")
                        CMD="nvconf get 0 Camera.Menu.CPhotoWaterM"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoRes")
                        CMD="nvconf get 0 Camera.Menu.TPhotoRes"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoCountDown")
                        CMD="nvconf get 0 Camera.Menu.TPhotoCountDown"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoWb")
                        CMD="nvconf get 0 Camera.Menu.TPhotoWb"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoFilter")
                        CMD="nvconf get 0 Camera.Menu.TPhotoFilter"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoEv")
                        CMD="nvconf get 0 Camera.Menu.TPhotoEv"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoMeMode")
                        CMD="nvconf get 0 Camera.Menu.TPhotoMeMode"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoShap")
                        CMD="nvconf get 0 Camera.Menu.TPhotoShap"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoISO")
                        CMD="nvconf get 0 Camera.Menu.TPhotoISO"
                        echo "$1=`$CMD`"
                        ;;
                "TPhotoWaterM")
                        CMD="nvconf get 0 Camera.Menu.TPhotoWaterM"
                        echo "$1=`$CMD`"
                        ;;
                "MovieSin")
                        CMD="nvconf get 0 Camera.Menu.MovieSin"
                        echo "$1=`$CMD`"
                        ;;
                "NRecLenLdc")
                        CMD="nvconf get 0 Camera.Menu.NRecLenLdc"
                        echo "$1=`$CMD`"
                        ;;
                "LRecLenLdc")
                        CMD="nvconf get 0 Camera.Menu.LRecLenLdc"
                        echo "$1=`$CMD`"
                        ;;
                "CapLenLdc")
                        CMD="nvconf get 0 Camera.Menu.CapLenLdc"
                        echo "$1=`$CMD`"
                        ;;
                "EncoderType")
                        CMD="nvconf get 0 Camera.Menu.EncoderType"
                        echo "$1=`$CMD`"
                        ;;
                "WiFi")
                        CMD="nvconf get 0 Camera.Menu.WiFi"
                        echo "$1=`$CMD`"
                        ;;
                "Flicker")
                        CMD="nvconf get 0 Camera.Menu.Flicker"
                        echo "$1=`$CMD`"
                        ;;
                "LedOn")
                        CMD="nvconf get 0 Camera.Menu.LedOn"
                        echo "$1=`$CMD`"
                        ;;
                "BLTime")
                        CMD="nvconf get 0 Camera.Menu.BLTime"
                        echo "$1=`$CMD`"
                        ;;
                "BLlevel")
                        CMD="nvconf get 0 Camera.Menu.BLlevel"
                        echo "$1=`$CMD`"
                        ;;
                "PowerOffTime")
                        CMD="nvconf get 0 Camera.Menu.PowerOffTime"
                        echo "$1=`$CMD`"
                        ;;
                "KeyTone")
                        CMD="nvconf get 0 Camera.Menu.KeyTone"
                        echo "$1=`$CMD`"
                        ;;
                "PowerOnAudio")
                        CMD="nvconf get 0 Camera.Menu.PowerOnAudio"
                        echo "$1=`$CMD`"
                        ;;
                "irRemote")
                        CMD="nvconf get 0 Camera.Menu.irRemote"
                        echo "$1=`$CMD`"
                        ;;
                "CarDriverMode")
                        CMD="nvconf get 0 Camera.Menu.CarDriverMode"
                        echo "$1=`$CMD`"
                        ;;
                "CameraAngle")
                        CMD="nvconf get 0 Camera.Menu.CameraAngle"
                        echo "$1=`$CMD`"
                        ;;      
                "DiveMode")
                        CMD="nvconf get 0 Camera.Menu.DiveMode"
                        echo "$1=`$CMD`"
                        ;;
                "Beautiful")
                        CMD="nvconf get 0 Camera.Menu.Beautiful"
                        echo "$1=`$CMD`"
                        ;;
                "ShutterAudio")
                        CMD="nvconf get 0 Camera.Menu.ShutterAudio"
                        echo "$1=`$CMD`"
                        ;;
                "Lan")
                        CMD="nvconf get 0 Camera.Menu.Lan"
                        echo "$1=`$CMD`"
                        ;;
                "ShotVertical")
                        CMD="nvconf get 0 Camera.Menu.ShotVertical"
                        echo "$1=`$CMD`"
                        ;;
                "DateTimeMode")
                        CMD="nvconf get 0 Camera.Menu.DateTimeMode"
                        echo "$1=`$CMD`"
                        ;;
                "PlaybackVolume")
                        CMD="nvconf get 0 Camera.Menu.PlaybackVolume"
                        echo "$1=`$CMD`"
                        ;;
                "AudioAnr")
                        CMD="nvconf get 0 Camera.Menu.AudioAnr"
                        echo "$1=`$CMD`"
                        ;;
                "AF")
                        CMD="nvconf get 0 Camera.Menu.AF"
                        echo "$1=`$CMD`"
                        ;;
                "PhotoAF")
                        CMD="nvconf get 0 Camera.Menu.PhotoAF"
                        echo "$1=`$CMD`"
                        ;;
                "AFIrLed")
                        CMD="nvconf get 0 Camera.Menu.AFIrLed"
                        echo "$1=`$CMD`"
                        ;;
                "sysworkmode")
                        CMD="nvconf get 0 Camera.Menu.sysworkmode"
                        echo "$1=`$CMD`"
                        ;;
                "SyncTime")
                        CMD="nvconf get 0 Camera.Menu.SyncTime"
                        echo "$1=`$CMD`"
                        ;;
                "ViewGrid")
                        CMD="nvconf get 0 Camera.Menu.ViewGrid"
                        echo "$1=`$CMD`"
                        ;;
                "BLUESTA")
                        BLUE_INFO=`cat /tmp/bluesta`
                        echo "$BLUE_INFO"
                        ;;
                "DEFAULT_MODEL")
                        DEFAULT_MODEL_INFO=`cat /tmp/default_model`
                        echo "$1=$DEFAULT_MODEL_INFO"
                        ;;
                "")
                        echo "You MUST input parameters, ex> {$Para0 someword}"
                        ;;
                *)
                        echo "Usage $Para0 {no this parameter}"
                        ;;
        esac
}

DEL()
{
        echo "($0): DEL $1 "
        echo "rm $1" > $VIDEOPARAM
}

Para0=$0
Para1=$1
Para2=$2
Para3=$3
Para4=$4
Para5=$5
Para6=$6

case $Para1 in
  "set")
        SET $Para2 $Para3
        ;;
  "get")
        GET $Para2
        ;;
  "del")
        DEL $Para2
        ;;
  "")
        echo "You MUST input parameters, ex> {$Para0 someword}"
        ;;
  *)
        echo "Usage $Para0 {no this parameter}"
        ;;
esac


exit 0