import socket
import time
import os

# Telnet negotiation commands
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

def cat_file(s, remote_path, local_path):
    print(f"[*] Retrieving {remote_path} -> {local_path}...")
    s.sendall(f"cat {remote_path}\n".encode('utf-8'))
    
    # Read the response until the shell prompt
    # Since files can be large, we set a longer timeout and read in chunks
    buffer = b""
    s.settimeout(10.0)
    prompt_found = False
    
    # We read until the prompt "/ # " appears at the end of the text
    while True:
        try:
            char = s.recv(4096)
            if not char:
                break
            buffer += char
            # Check if it ends with prompt
            text = buffer.decode('utf-8', errors='ignore')
            if text.endswith("/ # ") or text.endswith("# ") or text.endswith("$ "):
                prompt_found = True
                break
        except socket.timeout:
            print("    [!] Timeout reading file chunk...")
            break
            
    text = buffer.decode('utf-8', errors='ignore')
    # Clean up the command echo at the start and prompt at the end
    lines = text.splitlines()
    if len(lines) > 1:
        # Check if first line is command echo
        start_idx = 1 if f"cat {remote_path}" in lines[0] else 0
        end_idx = -1 if prompt_found else len(lines)
        file_content = "\n".join(lines[start_idx:end_idx])
    else:
        file_content = text
        
    with open(local_path, "w", encoding="utf-8") as f:
        f.write(file_content)
    print(f"    [+] Saved ({len(file_content)} bytes)")

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
            
        print("[+] Logged into Camera Shell!")
        
        dest_dir = "/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass/configs"
        os.makedirs(dest_dir, exist_ok=True)
        
        # Retrieve target files
        files_to_get = [
            ("/customer/wifi/webserver/conf/route.txt", f"{dest_dir}/route.txt"),
            ("/customer/wifi/webserver/conf/auth.txt", f"{dest_dir}/auth.txt"),
            ("/customer/wifi/webserver/www/cgi-bin/CGI_COMMAND.txt", f"{dest_dir}/CGI_COMMAND.txt"),
            ("/customer/wifi/webserver/www/CGI_PROCESS.sh", f"{dest_dir}/CGI_PROCESS.sh"),
        ]
        
        for remote, local in files_to_get:
            cat_file(s, remote, local)
            
        s.close()
        print("\n[+] All transfers complete. Check the configs directory.")
        
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
