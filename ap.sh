#!/bin/sh

case "$1" in
  start)
  	echo "Launch Wifi module AP Mode ..."

	echo 1 > /sys/class/switch/wifi_pwr/state
	echo 1 > /sys/class/switch/wifi_rst/state
	usleep 100000
	echo 0 > /sys/class/switch/wifi_rst/state
	usleep 300000
	echo 1 > /sys/class/switch/wifi_rst/state
	usleep 300000
	
	if [ "$WIFI_MODULE" == "bcmdhd" ]; then
		HOSTAPD="hostapd_ap6256"
	elif [ "$WIFI_MODULE" == "ssv6x5x" ]; then
		HOSTAPD="hostapd_ssv6x5x"
	else
		HOSTAPD="hostapd"     
	fi
	
	if [ "`lsmod|grep $WIFI_MODULE`" == "" ]; then
		if [ "$WIFI_MODULE" == "bcmdhd" ]; then
			echo "wifi module is ap6256"
			HOSTAPD="hostapd_ap6256"
			insmod /customer/wifi/lib/bcmdhd.ko firmware_path=/customer/wifi/lib/fw_bcm43456c5_ag_apsta.bin nvram_path=/customer/wifi/lib/nvram_ap6256.txt
		elif [ "$WIFI_MODULE" == "ssv6x5x" ]; then
			echo "wifi module is ssv6x5x"
			insmod /customer/wifi/lib/ssv6x5x.ko stacfgpath=/customer/wifi/ssv6x5x-wifi.cfg
			HOSTAPD="hostapd_ssv6x5x"
		else
			echo "wifi modu1e is $WIFI_MODULE.ko"
			HOSTAPD="hostapd"
			insmod /customer/wifi/lib/$WIFI_MODULE.ko        
		fi
	fi

	sleep 1

	if [ $? -eq 1 ]; then
		exit 1
	fi

	IPADDR="`nvconf get 1 wireless.ap.ipaddr`"
	SUBNETMASK="`nvconf get 1 wireless.ap.subnetmask`"
	SSIDMAC="`nvconf get 1 wireless.ap.bssidmac`"
	#sleep 1
	ifconfig wlan0 up
	ifconfig wlan0 $IPADDR netmask $SUBNETMASK
	sleep 1
	/usr/sbin/udhcpd -S /customer/wifi/udhcpd-ap.conf &
	usleep 100000
	NSSID="MyCameraWiFi"
	SSID="MyCameraWiFi"
	sed -i "s/^ssid.*$/ssid=MyCameraWiFi/" /customer/wifi/$HOSTAPD.conf
	nvconf set 1 wireless.ap.ssid "MyCameraWiFi"
	nvconf set 1 devinfo.macaddr `cat /sys/class/net/wlan0/address`
	uPSK=`cat /misc/misc_config.ini | grep PASSWORD | /usr/bin/awk -F \" '{print $2}'`
	PSK=$uPSK
	if [ "$PSK" == "" ]; then
		PSK="`nvconf get 1 wireless.ap.wpa.psk`"
	fi
	echo "PSK=[$PSK]"
	nvconf set 1 wireless.ap.wpa.psk "$PSK"
	sed -i "s/^wpa_passphrase.*$/wpa_passphrase=$PSK/" /customer/wifi/$HOSTAPD.conf
	sed -i "s/^channel.*$/channel=$((RANDOM%7+5))/" /customer/wifi/$HOSTAPD.conf
	hostapd /customer/wifi/$HOSTAPD.conf -B                                    
	run_goahead.sh
	# if [ "$WIFI_MODULE" == "ssw101b_wifi_usb" ]; then
	# 	echo "wifi set_txpower 63"
	# 	iwpriv wlan0 fwcmd set_txpower,63
	# 	iwpriv wlan0 fwcmd set_rate_txpower_mode,6
	# 	iwpriv wlan0 common setEfuse_dcxo,86,0
	# fi
	echo rtsp 1 > /tmp/cardv_fifo
;;
  stop)
	echo " Kill all process of AP Mode"
	busybox killall udhcpd
	busybox killall hostapd
	busybox killall goahead
	ifconfig wlan0 down
	rmmod $WIFI_MODULE
	echo 0 > /sys/class/switch/wifi_pwr/state
	echo 0 > /sys/class/switch/wifi_rst/state
;;
  restart)
	echo " restart AP Mode"
	busybox killall udhcpd
	busybox killall hostapd
	busybox killall goahead
	ifconfig wlan0 down
	sleep 1 

	IPADDR="`nvconf get 1 wireless.ap.ipaddr`"
	SUBNETMASK="`nvconf get 1 wireless.ap.subnetmask`"
	sleep 1
	ifconfig wlan0 up
	ifconfig wlan0 $IPADDR netmask $SUBNETMASK
	sleep 1
	/usr/sbin/udhcpd -S /customer/wifi/udhcpd-ap.conf &
	
	NSSID="MyCameraWiFi"
	SSID="MyCameraWiFi"
	sed -i "s/^ssid.*$/ssid=MyCameraWiFi/" /customer/wifi/$HOSTAPD.conf
	nvconf set 1 wireless.ap.ssid "MyCameraWiFi"
	nvconf set 1 devinfo.macaddr `cat /sys/class/net/wlan0/address`
	PSK="`nvconf get 1 wireless.ap.wpa.psk`"
	sed -i "s/^wpa_passphrase.*$/wpa_passphrase=$PSK/" /customer/wifi/$HOSTAPD.conf
	hostapd /customer/wifi/$HOSTAPD.conf -B
	run_goahead.sh

;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?

