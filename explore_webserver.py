import socket
import time

# Telnet negotiation commands
IAC  = b'\xff'
DONT = b'\xfe'
DO   = b'\xfd'
WONT = b'\xff' # WONT is actually \xfc, typo in comment
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

def run_command(s, cmd, wait_time=5.0):
    print(f"[*] Executing: {cmd}")
    s.sendall(f"{cmd}\n".encode('utf-8'))
    result, _ = read_until(s, ["/ #", "# ", "$ "], timeout=wait_time)
    lines = result.splitlines()
    if len(lines) > 1:
        output = "\n".join(lines[1:-1])
        return output
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
            
        print("[+] Connected to Shell!")
        
        # Read the Webserver home / document root configuration
        # goahead is running command: goahead -v --home /customer/wifi/webserver/conf/ /customer/wifi/webserver/www/ 80
        # Let's inspect the files in /customer/wifi/webserver/
        commands = [
            "ls -la /customer/wifi/webserver",
            "ls -la /customer/wifi/webserver/www",
            "ls -la /customer/wifi/webserver/www/cgi-bin",
            "ls -la /customer/wifi/webserver/conf",
            "cat /customer/wifi/webserver/conf/route.txt",
            "cat /customer/wifi/webserver/conf/web.properties",
            "strings /customer/wifi/webserver/www/cgi-bin/Config.cgi | head -n 100",
            "strings /customer/wifi/goahead | grep -i cgi"
        ]
        
        outputs = {}
        for cmd in commands:
            output = run_command(s, cmd, wait_time=5.0)
            outputs[cmd] = output
            print(output)
            
        s.close()
        
        log_file = "/Users/icode/.gemini/antigravity/scratch/camera-wifi-bypass/webserver_info.txt"
        with open(log_file, "w") as f:
            for cmd, out in outputs.items():
                f.write(f"=== Command: {cmd} ===\n")
                f.write(out)
                f.write("\n\n")
        print(f"\n[+] Results saved to {log_file}")
        
    except Exception as e:
        print(f"[-] Error: {e}")

if __name__ == "__main__":
    main()
