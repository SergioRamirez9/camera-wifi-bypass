import http.server
import socketserver
import json
import os

PORT = 8000

class MockCameraHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Allow serving index.html from current directory
        return super().translate_path(path)
        
    def do_GET(self):
        # Mock files.txt listing
        if self.path == '/files.txt':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # Generate mock file list
            mock_files = [
                "/DCIM/100MEDIA/.t/IMG-0001-A.jpg",
                "/DCIM/100MEDIA/.t/IMG-0002-A.jpg",
                "/DCIM/100MEDIA/.t/IMG-0003-A.jpg",
                "/DCIM/100MEDIA/.s/REC-0004-A.mp4",
                "/DCIM/100MEDIA/.t/IMG-0005-A.jpg",
            ]
            self.wfile.write("\n".join(mock_files).encode('utf-8'))
            return
            
        # Mock scan.cgi
        elif self.path.startswith('/cgi-bin/scan.cgi'):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            mock_files = [
                "/DCIM/100MEDIA/.t/IMG-0001-A.jpg",
                "/DCIM/100MEDIA/.t/IMG-0002-A.jpg",
                "/DCIM/100MEDIA/.t/IMG-0003-A.jpg",
                "/DCIM/100MEDIA/.s/REC-0004-A.mp4",
                "/DCIM/100MEDIA/.t/IMG-0005-A.jpg",
            ]
            self.wfile.write(json.dumps(mock_files).encode('utf-8'))
            return
            
        # Mock Config.cgi for remote shutter
        elif self.path.startswith('/cgi-bin/Config.cgi'):
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b"OK")
            return
            
        # Serve mock images for thumbnails
        elif self.path.startswith('/DCIM/'):
            self.send_response(200)
            self.send_header('Content-type', 'image/jpeg')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # Serve a simple 1x1 pixel JPEG placeholder
            tiny_jpeg = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x10\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\xff\xda\x00\x08\x01\x01\x00\x00?\x00\xbf\x00\xff\xd9'
            self.wfile.write(tiny_jpeg)
            return

        return super().do_GET()

def main():
    # Change working dir to where index.html is located
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    with socketserver.TCPServer(("", PORT), MockCameraHandler) as httpd:
        print(f"=========================================")
        print(f"[+] Mock Camera Server running at:")
        print(f"    http://localhost:{PORT}/")
        print(f"=========================================")
        print("Keep your home Wi-Fi active. Modify index.html,")
        print("refresh your browser to test. Deploy when done!")
        print("Press Ctrl+C to stop.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")

if __name__ == "__main__":
    main()
