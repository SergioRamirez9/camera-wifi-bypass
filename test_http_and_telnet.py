import socket
import urllib.request
import urllib.error

PATHS = [
    "",
    "index.html",
    "DCIM/",
    "DCIM/100MEDIA/",
    "DCIM/100COACH/",
    "cgi-bin/",
    "cgi-bin/net_jpeg.cgi",
    "cgi-bin/snapshot.cgi",
    "action/",
    "api/",
    "media/",
    "sd/",
    "sdcard/",
    "web/",
]

def test_telnet():
    print("=========================================")
    print("[*] Probing Telnet (Port 23) for welcome banner...")
    print("=========================================")
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(3.0)
            s.connect(("192.168.1.1", 23))
            # Wait for banner
            banner = s.recv(1024).decode('utf-8', errors='ignore')
            print(f"[+] Connected to Telnet!")
            print(f"[+] Banner / Prompt received:\n{banner}")
            
            # Send an empty newline or generic common username like 'root'
            print("[*] Sending 'root' to test login...")
            s.sendall(b"root\n")
            response = s.recv(1024).decode('utf-8', errors='ignore')
            print(f"[+] Telnet response after 'root':\n{response}")
    except Exception as e:
        print(f"[-] Telnet probe failed/timed out: {e}")

def test_http_paths():
    print("\n=========================================")
    print("[*] Probing HTTP paths on http://192.168.1.1/ ...")
    print("=========================================")
    for path in PATHS:
        url = f"http://192.168.1.1/{path}"
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=3) as res:
                print(f"[+] GET /{path} -> SUCCESS (Code: {res.status})")
                print(f"    Content-Type: {res.headers.get('Content-Type')}")
                body = res.read(150).decode('utf-8', errors='ignore').strip()
                print(f"    Body: {repr(body)}")
        except urllib.error.HTTPError as e:
            # 401, 403, 404, etc.
            print(f"[-] GET /{path} -> HTTP Error {e.code}: {e.reason}")
            # Try to print some of the error headers or body
            try:
                err_body = e.read(150).decode('utf-8', errors='ignore').strip()
                print(f"    Error Body: {repr(err_body)}")
            except Exception:
                pass
        except urllib.error.URLError as e:
            print(f"[-] GET /{path} -> Connection Failed: {e.reason}")
        except Exception as e:
            print(f"[-] GET /{path} -> Error: {e}")

if __name__ == "__main__":
    test_telnet()
    test_http_paths()
