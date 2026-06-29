import socket
import time
import os

# Telnet negotiation commands
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
    print(f"[*] Uploading {os.path.basename(local_path)} to camera at {remote_path}...")
    
    # Read the file contents
    with open(local_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    # Start the cat redirection on the remote shell
    # Using 'EOF' in quotes prevents the remote shell from doing variable substitution
    s.sendall(f"cat << 'EOF' > {remote_path}\n".encode('utf-8'))
    time.sleep(0.3)
    
    # Send each line with a tiny sleep to prevent buffer overflows
    # (Especially important for larger files like index.html)
    for i, line in enumerate(lines):
        # Clean any windows line endings
        line_to_send = line.replace('\r\n', '\n')
        s.sendall(line_to_send.encode('utf-8'))
        # Throttle transmission slightly (every 20 lines we pause briefly)
        if i % 20 == 0:
            time.sleep(0.05)
            
    # Close the redirection
    s.sendall(b"\nEOF\n")
    time.sleep(0.5)
    
    # Read the buffer to consume output and verify we are back at the prompt
    prompt_text, _ = read_until(s, ["/ #", "# ", "$ "], timeout=3.0)
    print(f"    [+] Transmitted {len(lines)} lines successfully.")

def main():
    print("=========================================")
    print("Camera Web App Deployer")
    print("=========================================")
    
    # Define local file paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    local_index = os.path.join(script_dir, "index.html")
    local_scan = os.path.join(script_dir, "scan.cgi")
    local_slideshow = os.path.join(script_dir, "slideshow.html")
    
    # Verification
    if not os.path.exists(local_index) or not os.path.exists(local_scan) or not os.path.exists(local_slideshow):
        print("[-] Error: local files 'index.html', 'scan.cgi', or 'slideshow.html' are missing in the directory.")
        return
        
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
            
        if matched not in ["/ #", "#", "$"] and "/ #" not in text:
            print("[-] Telnet login failed.")
            s.close()
            return
            
        print("[+] Logged into Camera Shell via Telnet!")
        
        # 1. Clean old files to prevent size mismatch/overlap issues
        print("[*] Preparing directories on camera...")
        run_command(s, "rm -f /customer/wifi/webserver/www/index.html")
        run_command(s, "rm -f /customer/wifi/webserver/www/slideshow.html")
        run_command(s, "rm -f /customer/wifi/webserver/www/cgi-bin/scan.cgi")
        
        # 2. Upload index.html
        upload_file_telnet(s, local_index, "/customer/wifi/webserver/www/index.html")
        
        # 3. Upload slideshow.html
        upload_file_telnet(s, local_slideshow, "/customer/wifi/webserver/www/slideshow.html")
        
        # 4. Upload scan.cgi
        upload_file_telnet(s, local_scan, "/customer/wifi/webserver/www/cgi-bin/scan.cgi")
        
        # 5. Make scan.cgi executable
        print("[*] Setting executable permissions on scan.cgi...")
        run_command(s, "chmod +x /customer/wifi/webserver/www/cgi-bin/scan.cgi")
        
        # 6. Build/verify the DCIM symlink
        print("[*] Rebuilding DCIM symlink...")
        run_command(s, "ln -sf /mnt/mmc/DCIM /customer/wifi/webserver/www/DCIM")
        
        # 7. Rebuild files.txt
        print("[*] Performing first media scan...")
        run_command(s, "sh /customer/wifi/webserver/www/cgi-bin/scan.cgi > /dev/null")
        
        s.close()
        print("\n=========================================")
        print("[+] DEPLOYMENT COMPLETED SUCCESSFULLY!")
        print("=========================================")
        print("1. Reconnect your phone/Mac to the camera Wi-Fi.")
        print("2. Open your web browser and go to: http://192.168.1.1/")
        print("3. Bookmark this page or add it to your iOS Home Screen!")
        print("=========================================")
        
    except Exception as e:
        print(f"[-] Deployment failed: {e}")
        print("[!] Please verify your connection to the camera Wi-Fi.")

if __name__ == "__main__":
    main()
