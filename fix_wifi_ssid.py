import socket
import time

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
        
        # 1. Back up ap.sh
        print("[*] Backing up ap.sh...")
        run_command(s, "cp -n /customer/wifi/ap.sh /customer/wifi/ap.sh.bak")
        
        # 2. Modify ap.sh to lock SSID to a custom value and prevent MAC appends
        print("[*] Patching ap.sh SSID logic...")
        
        # We will create the patched ap.sh
        # Let's read the current contents, but wait, we can just edit the file on camera using sed, or overwrite it.
        # Since we have the whole file on Mac, we can modify the local ap.sh and upload it!
        # Wait, that's much safer and easier than trying to run complex sed commands on-camera.
        # Let's read the local ap.sh, modify it, and upload it via telnet!
        
        s.close()
        print("[+] Connection closed. We will upload the patched ap.sh using a new script.")
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
