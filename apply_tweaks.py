import socket
import time

IAC  = b'\xff'
DONT = b'\xfe'
DO   = b'\xfd'
WONT = b'\xfc'
WILL = b'\xfb'

def read_until(s, expected_list, timeout=3.0):
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

def run_command(s, cmd, wait_time=3.0):
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
        
        # 1. Backup the original script
        print("[*] Creating backup of run_goahead.sh...")
        run_command(s, "cp -n /customer/wifi/run_goahead.sh /customer/wifi/run_goahead.sh.bak")
        
        # 2. Write the new run_goahead.sh script with CPU Performance Tweak
        print("[*] Writing CPU Performance Tweak to startup script...")
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
        
        # Verify the change
        print("[*] Verifying CPU Tweak integration...")
        print(run_command(s, "cat /customer/wifi/run_goahead.sh"))
        
        # Apply instantly now as well
        print("[*] Activating performance governor right now...")
        run_command(s, "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor")
        print(f"Current Governor: {run_command(s, 'cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor').strip()}")
        
        s.close()
        print("[+] Tweaks applied successfully!")
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
