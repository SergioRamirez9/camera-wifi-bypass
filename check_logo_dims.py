import socket
import time
import urllib.request
import subprocess

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
        
        # Create symlink
        print("[*] Creating symlink in web root...")
        run_command(s, "ln -sf /misc/bootlogo.jpg /customer/wifi/webserver/www/bootlogo_orig.jpg")
        
        # Download file
        print("[*] Downloading original bootlogo to Mac...")
        url = "http://192.168.1.1/bootlogo_orig.jpg"
        local_path = "/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass/bootlogo_orig.jpg"
        urllib.request.urlretrieve(url, local_path)
        
        # Remove symlink
        print("[*] Removing symlink...")
        run_command(s, "rm -f /customer/wifi/webserver/www/bootlogo_orig.jpg")
        s.close()
        
        # Get dimensions
        print("[*] Querying dimensions of original logo...")
        cmd = f"sips -g pixelWidth -g pixelHeight {local_path}"
        output = subprocess.check_output(cmd, shell=True).decode('utf-8')
        print(output)
        
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
