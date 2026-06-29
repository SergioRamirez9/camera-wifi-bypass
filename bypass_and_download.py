import socket
import time
import os
import urllib.request

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

def run_command(s, cmd, wait_time=3.0):
    s.sendall(f"{cmd}\n".encode('utf-8'))
    result, _ = read_until(s, ["/ #", "# ", "$ "], timeout=wait_time)
    return result

def setup_bypass():
    print("[*] Connecting to Telnet (192.168.1.1:23) to set up HTTP bypass...")
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
            return False
            
        print("[+] Logged into Camera Shell!")
        
        # 1. Create a symlink to the SD card DCIM directory inside the web server root.
        # This exposes the DCIM folder directly over HTTP.
        print("[*] Creating symlink to DCIM in GoAhead web root...")
        run_command(s, "ln -sf /mnt/mmc/DCIM /customer/wifi/webserver/www/DCIM")
        
        # 2. Generate a text file containing the relative paths of all media files.
        # This acts as our directory listing since directory browsing is disabled.
        print("[*] Generating index of media files...")
        run_command(s, "find /mnt/mmc/DCIM -type f | sed 's|/mnt/mmc/DCIM|/DCIM|' > /customer/wifi/webserver/www/files.txt")
        
        s.close()
        print("[+] Bypass setup complete on the camera!")
        return True
    except Exception as e:
        print(f"[-] Setup failed: {e}")
        print("[!] Please make sure the camera's Wi-Fi is active and you are connected to it.")
        return False

def download_photos():
    print("\n[*] Fetching file list from http://192.168.1.1/files.txt...")
    local_dir = "/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass/downloads"
    os.makedirs(local_dir, exist_ok=True)
    
    try:
        # Fetch the file list
        url = "http://192.168.1.1/files.txt"
        with urllib.request.urlopen(url, timeout=5) as response:
            file_list_data = response.read().decode('utf-8')
            
        files = [f.strip() for f in file_list_data.splitlines() if f.strip()]
        if not files:
            print("[*] No media files found on the camera.")
            return
            
        print(f"[+] Found {len(files)} files on the camera.")
        
        for file_path in files:
            # file_path is like "/DCIM/100MEDIA/DSC_0001.JPG"
            file_url = f"http://192.168.1.1{file_path}"
            local_filename = os.path.basename(file_path)
            local_filepath = os.path.join(local_dir, local_filename)
            
            if os.path.exists(local_filepath):
                print(f"[-] Skipping {local_filename} (already downloaded)")
                continue
                
            print(f"[*] Downloading {local_filename}...")
            try:
                urllib.request.urlretrieve(file_url, local_filepath)
                print(f"    [+] Saved to {local_filepath}")
            except Exception as download_error:
                print(f"    [-] Failed to download {local_filename}: {download_error}")
                
        print("\n[+] Download process finished successfully!")
        
    except Exception as e:
        print(f"[-] Error fetching file list or downloading: {e}")

if __name__ == "__main__":
    if setup_bypass():
        # Wait a moment for web server filesystem updates
        time.sleep(1)
        download_photos()
