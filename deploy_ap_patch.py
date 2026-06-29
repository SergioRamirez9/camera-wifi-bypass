import socket
import time
import os

# --- CONFIGURATION SETTINGS ---
try:
    from wifi_credentials import WIFI_SSID
except ImportError:
    WIFI_SSID = "MyCameraWiFi"

IAC  = b'\xff'
DONT = b'\xfe'
DO   = b'\xfd'
WONT = b'\xfc'
WILL = b'\xfb'

def read_until(s, expected_list, timeout=4.0):
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

def run_command(s, cmd, wait_time=2.0):
    s.sendall(f"{cmd}\n".encode('utf-8'))
    result, _ = read_until(s, ["/ #", "# ", "$ "], timeout=wait_time)
    return result

def upload_file_telnet(s, local_path, remote_path):
    print(f"[*] Uploading patched {os.path.basename(local_path)}...")
    with open(local_path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("MyCameraWiFi", WIFI_SSID)
    lines = content.splitlines(keepends=True)
    
    s.sendall(f"cat << 'EOF' > {remote_path}\n".encode('utf-8'))
    time.sleep(0.3)
    for i, line in enumerate(lines):
        line_to_send = line.replace('\r\n', '\n')
        s.sendall(line_to_send.encode('utf-8'))
        if i % 20 == 0:
            time.sleep(0.05)
    s.sendall(b"\nEOF\n")
    time.sleep(0.5)
    read_until(s, ["/ #", "# ", "$ "], timeout=3.0)
    print(f"    [+] Transmitted {len(lines)} lines.")

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
        
        # 1. Back up ap.sh
        print("[*] Backing up original ap.sh to ap.sh.bak...")
        run_command(s, "cp -n /customer/wifi/ap.sh /customer/wifi/ap.sh.bak")
        
        # 2. Upload patched ap.sh
        local_ap = "/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass/ap.sh"
        upload_file_telnet(s, local_ap, "/customer/wifi/ap.sh")
        run_command(s, "chmod +x /customer/wifi/ap.sh")
        
        # 3. Synchronize NVRAM to clean the SSID
        print("[*] Resetting NVRAM wireless SSID...")
        run_command(s, f"nvconf set 1 wireless.ap.ssid {WIFI_SSID}")
        run_command(s, "nvconf update 1")
        
        # 4. Reboot
        print("[*] Rebooting the camera...")
        s.sendall(b"reboot\n")
        s.close()
        
        print(f"\n[+] SUCCESS! Patched SSID script uploaded. Reconnect to '{WIFI_SSID}' in 30 seconds!")
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
