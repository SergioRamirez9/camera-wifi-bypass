import socket
import time

# Telnet negotiation commands (RFC 854)
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
    print(f"[*] Executing: {cmd}")
    s.sendall(f"{cmd}\n".encode('utf-8'))
    # Wait for the command to finish and return the prompt
    result, _ = read_until(s, ["/ #", "# ", "$ "], timeout=wait_time)
    lines = result.splitlines()
    if len(lines) > 1:
        # The first line is usually the echoed command, the last line is the prompt
        output = "\n".join(lines[1:-1])
        return output
    return result

def main():
    print("=========================================")
    print("Camera Filesystem Explorer (via Telnet)")
    print("=========================================")
    
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("192.168.1.1", 23))
        
        # Read until login
        text, matched = read_until(s, ["login:", "Username:"], timeout=3.0)
        if not matched:
            s.sendall(b"\n")
            text, matched = read_until(s, ["login:", "Username:"], timeout=2.0)
            if not matched:
                print("[-] No login prompt found!")
                s.close()
                return
        
        # Send username 'root'
        s.sendall(b"root\n")
        
        # Read until password prompt or shell prompt
        text, matched = read_until(s, ["Password:", "password:", "/ #", "#", "$"], timeout=2.0)
        
        if matched in ["Password:", "password:"]:
            # Send empty password (newline)
            s.sendall(b"\n")
            # Wait for prompt
            text, matched = read_until(s, ["/ #", "#", "$"], timeout=3.0)
            
        if matched in ["/ #", "#", "$"] or "/ #" in text:
            print("[+] Logged in successfully!")
        else:
            print(f"[-] Login failed. Buffer: {repr(text)}")
            s.close()
            return
        
        # List of exploration commands to run
        commands = [
            "mount",
            "df",
            "ps w",
            "ls -la /",
            "find / -name \"*goahead*\" -o -name \"*http*\" -o -name \"*web*\"",
            "find / -name \"*.cgi\" -o -name \"*.asp\" -o -name \"*.js\" -o -name \"*.html\"",
            "ls -la /P",
            "ls -la /config",
            "ls -la /var",
        ]
        
        outputs = {}
        for cmd in commands:
            output = run_command(s, cmd, wait_time=5.0)
            outputs[cmd] = output
            
        s.close()
        
        # Save results to a file for easy reading
        log_file = "/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass/camera_info.txt"
        with open(log_file, "w") as f:
            f.write("=========================================\n")
            f.write("Camera Diagnostic Dump\n")
            f.write("=========================================\n\n")
            for cmd, out in outputs.items():
                f.write(f"=== Command: {cmd} ===\n")
                f.write(out)
                f.write("\n\n")
        print(f"\n[+] Diagnostic results successfully saved to: {log_file}")
        
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
