import socket
import sys
import urllib.request
from ftplib import FTP

COMMON_PORTS = {
    21: "FTP (File Transfer Protocol - highly likely for file download)",
    80: "HTTP (Web Server - check for web UI or API)",
    554: "RTSP (Real-Time Streaming Protocol - for video preview)",
    15740: "PTP/IP (Picture Transfer Protocol over IP - standard camera control)",
    55740: "Fuji/iCatch Custom Command Port (TCP)",
    55742: "Fuji/iCatch Custom Data Port (TCP)",
    5678: "iCatch Command/PTZ Port (TCP)",
    8080: "HTTP Alternative (Web Server/API)"
}

def get_gateway_ip():
    # A simple way to guess camera IP is using the system's default gateway.
    # Most cameras act as AP and assign IPs in 192.168.1.x or 192.168.0.x
    # We will test both 192.168.1.1 and 192.168.0.1, which cover 99% of cameras.
    return ["192.168.1.1", "192.168.0.1"]

def probe_port(ip, port):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(1.5)
            result = s.connect_ex((ip, port))
            if result == 0:
                # Try to grab banner
                banner = ""
                try:
                    s.sendall(b"\r\n")
                    banner = s.recv(1024).decode('utf-8', errors='ignore').strip()
                except Exception:
                    pass
                return True, banner
    except Exception:
        pass
    return False, ""

def test_ftp(ip):
    print(f"\n[*] Attempting anonymous FTP login on {ip}:21...")
    try:
        ftp = FTP()
        ftp.connect(ip, 21, timeout=5)
        # iCatch cameras typically use 'anonymous' and 'anonymous@icatchtek.com'
        ftp.login(user='anonymous', passwd='anonymous@icatchtek.com')
        print("[+] FTP Login Successful!")
        print("[*] Directory listing:")
        files = []
        ftp.dir(files.append)
        for f in files[:15]:
            print(f"    {f}")
        if len(files) > 15:
            print(f"    ... and {len(files) - 15} more files/folders")
        
        # Look for DCIM
        n_list = ftp.nlst()
        print(f"[*] Root contents: {n_list}")
        ftp.quit()
        return True
    except Exception as e:
        print(f"[-] FTP connection failed: {e}")
        return False

def test_http(ip, port=80):
    print(f"\n[*] Probing HTTP on http://{ip}:{port}/...")
    try:
        url = f"http://{ip}:{port}/"
        req = urllib.request.Request(url, method='GET')
        with urllib.request.urlopen(req, timeout=3) as response:
            print(f"[+] HTTP GET success: Code {response.status}")
            headers = response.info()
            print(f"    Server Header: {headers.get('Server', 'Unknown')}")
            # print first 200 chars of body
            body = response.read(200).decode('utf-8', errors='ignore')
            print(f"    Body snippet: {repr(body)}")
            return True
    except Exception as e:
        print(f"[-] HTTP connection failed: {e}")
        return False

def main():
    print("=========================================")
    print("Camera Wi-Fi Bypass Diagnostic Tool")
    print("=========================================")
    
    ips_to_test = get_gateway_ip()
    active_ip = None
    
    for ip in ips_to_test:
        print(f"\nPinging/Probing target IP: {ip}...")
        # Check if the IP is reachable by trying to connect to a port or doing a quick ping
        ping_ok = False
        for port in [21, 80, 554, 8080]:
            is_open, _ = probe_port(ip, port)
            if is_open:
                ping_ok = True
                break
        
        if ping_ok:
            print(f"[+] Found active device at {ip}!")
            active_ip = ip
            break
    
    if not active_ip:
        print("\n[!] No active camera found at 192.168.1.1 or 192.168.0.1.")
        print("[!] Please make sure your Mac is connected to the camera's Wi-Fi network.")
        print("[!] Defaulting to 192.168.1.1 for port scanning...")
        active_ip = "192.168.1.1"

    print(f"\n[*] Scanning common camera ports on {active_ip}...")
    open_ports = []
    for port, desc in COMMON_PORTS.items():
        is_open, banner = probe_port(active_ip, port)
        if is_open:
            print(f"  [+] Port {port} is OPEN - {desc}")
            if banner:
                print(f"      Banner: {repr(banner)}")
            open_ports.append(port)
            
    # Also do a quick scan of other ports
    print("\n[*] Running a quick scan of other ports (1 - 1000)...")
    for port in range(1, 1000):
        if port in COMMON_PORTS:
            continue
        is_open, _ = probe_port(active_ip, port)
        if is_open:
            print(f"  [+] Port {port} is OPEN")
            open_ports.append(port)
            
    if 21 in open_ports:
        test_ftp(active_ip)
        
    if 80 in open_ports:
        test_http(active_ip, 80)
        
    if 8080 in open_ports:
        test_http(active_ip, 8080)

    print("\n=========================================")
    print("Scan completed.")
    print("Please share the output above to identify the protocol.")
    print("=========================================")

if __name__ == "__main__":
    main()
