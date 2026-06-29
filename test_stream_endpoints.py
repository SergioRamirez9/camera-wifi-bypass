import urllib.request
import urllib.error

endpoints = [
    "/video.mjpg",
    "/video.mjpeg",
    "/live.mjpg",
    "/live.mjpeg",
    "/video",
    "/live",
    "/stream",
    "/mjpg",
    "/mjpeg",
    "/cgi-bin/video.cgi",
    "/cgi-bin/stream.cgi",
    "/cgi-bin/live.cgi",
    "/cgi-bin/mjpg.cgi",
    "/cgi-bin/mjpeg.cgi",
    "/cgi-bin/preview.cgi",
    "/cgi-bin/net_jpeg.cgi",
    "/cgi-bin/net_mjpg.cgi",
]

def main():
    print("[*] Probing camera HTTP endpoints for MJPEG streams...")
    for ep in endpoints:
        url = f"http://192.168.1.1{ep}"
        try:
            # Send a GET request with a short timeout
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=2.0) as response:
                content_type = response.headers.get('Content-Type', '')
                status = response.status
                print(f"[+] Found {ep} -> Status: {status}, Content-Type: {content_type}")
        except urllib.error.HTTPError as e:
            # Endpoint returned 404, 401, etc.
            pass
        except Exception as e:
            # Connection timeout, etc.
            pass
    print("[*] Probing finished.")

if __name__ == "__main__":
    main()
