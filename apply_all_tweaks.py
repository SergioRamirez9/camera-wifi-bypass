import socket
import time

# --- CONFIGURATION SETTINGS ---
# Reads credentials from git-ignored wifi_credentials.py
try:
    from wifi_credentials import WIFI_SSID, WIFI_PASS
except ImportError:
    WIFI_SSID = "MyCameraWiFi"
    WIFI_PASS = "MySecurePassword"

IAC  = b'\xff'
DONT = b'\xfe'
DO   = b'\xfd'
WONT = b'\xfc'
WILL = b'\xfb'

def read_until(s, expected_list, timeout=5.0):
    s.settimeout(timeout)
    buffer = b""
    start_time = time.time()
    try:
        while time.time() - start_time < timeout:
            char = s.recv(1)
            if not char:
                break
            if char == IAC:
                cmd = s.recv(1)
                opt = s.recv(1)
                if cmd == WILL or cmd == DO:
                    reply_cmd = DONT if cmd == WILL else WONT
                    s.sendall(IAC + reply_cmd + opt)
            else:
                buffer += char
                text = buffer.decode('utf-8', errors='ignore')
                for expected in expected_list:
                    if expected in text:
                        return text, expected
    except socket.timeout:
        pass
    return buffer.decode('utf-8', errors='ignore'), None

def run_command(s, cmd, wait_time=5.0):
    s.sendall(f"{cmd}\n".encode('utf-8'))
    result, _ = read_until(s, ["/ #", "# ", "$ "], timeout=wait_time)
    return result

def main():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("192.168.1.1", 23))
        
        # Log in
        text, matched = read_until(s, ["login:", "Username:"], timeout=3.0)
        s.sendall(b"root\n")
        text, matched = read_until(s, ["Password:", "password:", "/ #", "#", "$"], timeout=2.0)
        if matched in ["Password:", "password:"]:
            s.sendall(b"\n")
            text, matched = read_until(s, ["/ #", "#", "$"], timeout=3.0)
            
        print("[+] Connected to Camera Shell!")
        
        # --- TWEAK 1: CPU Performance ---
        print("[*] Backing up run_goahead.sh...")
        run_command(s, "cp -n /customer/wifi/run_goahead.sh /customer/wifi/run_goahead.sh.bak")
        
        print("[*] Injecting CPU Performance governor config...")
        new_script = """cat << 'EOF' > /customer/wifi/run_goahead.sh
#!/bin/sh
# Lock CPU to Max Performance on Boot
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

APSTA=`nvconf get 1 wireless.apstaswitch`
if [ $APSTA = "STA" ]; then
        IPADDR="`nvconf get 1 wireless.sta.ipaddr`"
else
        IPADDR="`nvconf get 1 wireless.ap.ipaddr`"
fi

sync
echo 1 > /proc/sys/vm/drop_caches

if [ "`pidof goahead`" = "" ]; then
echo "Start Goahead ..."
goahead -v  --home /customer/wifi/webserver/conf/ /customer/wifi/webserver/www $IPADDR:80&
fi

sleep 1
EOF
"""
        run_command(s, new_script, wait_time=2.0)
        run_command(s, "chmod +x /customer/wifi/run_goahead.sh")
        
        # Activating performance right now
        run_command(s, "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor")
        
        # --- TWEAK 2: Wi-Fi SSID, Passphrase & Limit ---
        print("[*] Backing up hostapd.conf...")
        run_command(s, "cp -n /customer/wifi/hostapd.conf /customer/wifi/hostapd.conf.bak")
        
        print("[*] Updating SSID and WPA passphrase in hostapd.conf...")
        run_command(s, f"sed -i 's/ssid=WD300-8K/ssid={WIFI_SSID}/g' /customer/wifi/hostapd.conf")
        run_command(s, f"sed -i 's/wpa_passphrase=12345678/wpa_passphrase={WIFI_PASS}/g' /customer/wifi/hostapd.conf")
        run_command(s, "sed -i 's/max_num_sta=1/max_num_sta=10/g' /customer/wifi/hostapd.conf")
        
        # Also update NVRAM settings for system-wide consistency
        print("[*] Synchronizing Wi-Fi parameters in system NVRAM...")
        run_command(s, f"nvconf set 1 wireless.ap.ssid {WIFI_SSID}")
        run_command(s, f"nvconf set 1 wireless.ap.wpa.psk {WIFI_PASS}")
        run_command(s, "nvconf update 1")
        
        # Verification
        print("\n=== Verification ===")
        print(f"Current Governor: {run_command(s, 'cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor').strip()}")
        print(f"Wi-Fi SSID: {run_command(s, 'grep ^ssid= /customer/wifi/hostapd.conf').strip()}")
        print(f"Wi-Fi Limit Line: {run_command(s, 'grep max_num_sta /customer/wifi/hostapd.conf').strip()}")
        print(f"NVRAM SSID: {run_command(s, 'nvconf get 1 wireless.ap.ssid').strip()}")
        
        s.close()
        print("\n[+] Success! CPU performance, custom Wi-Fi network details, and device limits applied.")
        print("[+] Please reboot the camera to activate your new Wi-Fi credentials!")
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
