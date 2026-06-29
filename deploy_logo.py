import socket
import time
import threading
import http.server
import socketserver

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

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("192.168.1.1", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "192.168.1.10"
    finally:
        s.close()
    return ip

def start_server():
    import os
    os.chdir("/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass")
    handler = http.server.SimpleHTTPRequestHandler
    httpd = socketserver.TCPServer(("", 8080), handler)
    print("[*] Local Mac server running on port 8080...")
    
    t = threading.Thread(target=httpd.serve_forever)
    t.daemon = True
    t.start()
    return httpd

def main():
    httpd = start_server()
    local_ip = get_local_ip()
    print(f"[*] Mac Local IP on camera network: {local_ip}")
    
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
        
        # 1. Deploy Boot Logo
        print("[*] Backing up original bootlogo.jpg...")
        run_command(s, "cp -n /misc/bootlogo.jpg /misc/bootlogo.jpg.bak")
        print("[*] Downloading new bootlogo.jpg to camera...")
        run_command(s, f"wget http://{local_ip}:8080/bootlogo.jpg -O /misc/bootlogo.jpg")
        
        # 2. Deploy Shutdown Logo
        print("[*] Backing up original poweroff.jpg...")
        run_command(s, "cp -n /misc/poweroff.jpg /misc/poweroff.jpg.bak")
        print("[*] Downloading new poweroff.jpg to camera...")
        run_command(s, f"wget http://{local_ip}:8080/poweroff.jpg -O /misc/poweroff.jpg")
        
        # Verify both files are written
        print("\n=== Verification ===")
        print(run_command(s, "ls -la /misc/bootlogo.jpg /misc/poweroff.jpg"))
        
        s.close()
        print("\n[+] Custom Boot and Shutdown logos deployed successfully!")
        
    except Exception as e:
        print(f"[-] Error: {e}")
    finally:
        print("[*] Stopping local Mac server...")
        httpd.shutdown()
        httpd.server_close()

if __name__ == "__main__":
    main()
