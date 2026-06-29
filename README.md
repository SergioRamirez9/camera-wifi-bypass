# SigmaStar Camera Custom Firmware and Web Dashboard Modifications

Documentation and scripts for customizing and optimizing action/vlogging cameras based on the dual-core ARMv7 SigmaStar Infinity5 SoC (such as the AE-DC4928-D600).

This repository contains the scripts, source files, and web dashboard configuration required to increase Wi-Fi connection limits, optimize CPU frequency settings, customize startup/shutdown splash screens, and host a local web-based camera manager and live gallery wall.

---

## Initial Discovery and Reverse-Engineering

A system analysis and network reconnaissance scan was performed to gain root access to the camera system.

### 1. Network Scan
Connecting to the camera's default Wi-Fi hotspot exposed the gateway at `192.168.1.1`. A TCP port scan revealed three open ports:
*   **Port 80 (HTTP):** GoAhead web server hosting the default control interface.
*   **Port 554 (RTSP):** Real-Time Streaming Protocol endpoint for the video stream.
*   **Port 23 (Telnet):** Command-line terminal access.

### 2. Root Access Exploitation
Connecting to the Telnet server on Port 23 revealed that the user is `root` and requires no password. Pressing Enter bypassed authentication and granted root shell access to the BusyBox Linux environment (Kernel 4.9.227).

### 3. File System Layout
Partition parameters and storage mounts were mapped using `mount` and `df -h`:
*   `/` (Rootfs): Mount point for the primary root files, mounted as read-only.
*   `/customer` (JFFS2 partition): Read-write partition holding the Wi-Fi AP configurations, web server root, and system startup scripts.
*   `/misc` (FUSE partition): Read-write partition holding the boot logo graphics (`bootlogo.jpg`, `poweroff.jpg`). This partition has a 1.0MB size limit with approximately 64KB of free space, requiring replacement graphics to be compressed.
*   `/mnt/mmc` (FAT32 partition): The physical MicroSD card mount containing camera photos and videos under `DCIM/100MEDIA`.

### 4. CGI Command Routing
The web directory at `/customer/wifi/webserver/www/` hosts the CGI configuration handler script. Dynamic requests route to `/cgi-bin/Config.cgi`, which delegates values to the router script `/customer/wifi/webserver/www/CGI_PROCESS.sh`. This script was analyzed to map the NVRAM properties and case-sensitive parameters accepted by the system.

---

## Mod list and Optimizations

### 1. Web Dashboard (`index.html`)
*   **Settings Synchronizer:** An on-load NVRAM query system that fetches current configurations on launch so the UI matches the actual hardware state.
*   **Parameter Control:** Mapped 15+ camera parameters (Focus Mode, Grid Guides, Exposure Values, White Balance, ISO, Backlight, Metering, and Auto Power-Off timers) directly to the camera's case-sensitive `/cgi-bin/Config.cgi` endpoints.
*   **Web Audio Shutter Synth:** Built-in Web Audio API synthesizers that play shutter sounds completely offline (Mechanical snap, DSLR click and motor whir, Polaroid eject whir, and Digital beep).

### 2. Live Slideshow Gallery Wall (`slideshow.html`)
*   A standalone fullscreen dashboard designed for display screens.
*   Pans and zooms existing photos using a Ken Burns transition effect.
*   Active polling of `files.txt`: When a new photo is captured, the slideshow triggers a white screen flash, plays a digital chirp, and displays the new photo fullscreen for 7 seconds.

### 3. CPU Performance Lock
*   Modified `/customer/wifi/run_goahead.sh` to write `performance` to the Linux kernel governor `/sys/devices/system/cpu/cpufreq/policy0/scaling_governor` at boot.
*   Locks the clock speed to maximum frequency, decreasing JPEG compression times and improving responsiveness.

### 4. Wi-Fi Connection Limit and SSID Lock
*   **Multi-Device Access:** Changed `max_num_sta` from `1` to `10` in `/customer/wifi/hostapd.conf`, enabling multiple devices to connect to the camera simultaneously.
*   **Static SSID Patch:** Modified `/customer/wifi/ap.sh` to lock the SSID to a static value and bypass the dynamic MAC address suffix append algorithm.

### 5. Custom Startup and Shutdown Screens
*   **/misc/bootlogo.jpg (Startup):** Resized to 480x640 portrait and rotated 90 degrees in-file to display horizontally on the vertical panel during boot.
*   **/misc/poweroff.jpg (Shutdown):** Formatted as a standard `640x480` landscape image. The OS graphical app (`demo`) runs in landscape, so an unrotated file displays horizontally.

---

## Repository File Structure

### 1. Web Dashboard and Core Assets
*   `web-app/`
    *   [index.html](web-app/index.html) — Single-page dashboard application.
    *   [slideshow.html](web-app/slideshow.html) — Fullscreen live slideshow wall.
    *   [scan.cgi](web-app/scan.cgi) — On-camera media indexing shell script.
    *   [deploy.py](web-app/deploy.py) — Script to upload the web app assets to the camera's `/customer/wifi/webserver/www/` directory via telnet.
*   `bootlogo.jpg` — Custom correctly oriented startup screen.
*   `poweroff.jpg` — Custom correctly oriented shutdown screen.
*   `ap.sh` — The patched AP startup script bypassing MAC suffix appends.

### 2. Modification and Deployment Scripts
*   `apply_all_tweaks.py` — Telnet script to lock CPU performance, increase Wi-Fi limits, and set custom SSID details.
*   `deploy_logo.py` — Local HTTP server and telnet automation script to back up and deploy boot/shutdown logos.
*   `deploy_ap_patch.py` — Telnet script to back up, upload patched `ap.sh`, and reboot the camera.

### 3. Penetration Testing and Exploration Scripts
These scripts were created during the initial reconnaissance and reverse-engineering phases to analyze the camera's internal systems:
*   `probe_camera.py` — Initial script that scanned open ports and tested credentials.
*   `telnet_bruteforce.py` — Automated scanner used to test default credentials for the root account.
*   `check_mount.py` — Connects via telnet and prints partition layouts and storage mount properties.
*   `check_boot_scripts.py` / `check_firmware_tweaks.py` — Scans default system boot configurations and frequency governors.
*   `explore_webserver.py` — Dissects the camera's GoAhead web server structure to locate the default web root.
*   `read_config_ini.py` — Downloads the camera's `/bootconfig/config.ini` screen configurations to the Mac.
*   `dump_nvram.py` / `check_nvconf.py` — Queries and dumps the camera's configuration values inside the NVRAM registry.
*   `find_shutdown_script.py` — Searches the camera files for shutdown handles to isolate the screen display program.
*   `check_ap_script.py` / `fix_wifi_ssid.py` — Pulls down the original `ap.sh` script to diagnose SSID naming algorithms.
*   `check_logos.py` — Verification script to double-check active logo file sizes on the camera's flash partition.
*   `retrieve_files.py` / `bypass_and_download.py` — Helper scripts used to test bulk media downloads.
*   `test_stream_endpoints.py` — Utility that scanned ports looking for active video endpoints.

---

## Installation and Setup

Ensure your computer is connected to the camera's default Wi-Fi hotspot and run these commands:

### Step 1: Lock CPU Performance and Customize Wi-Fi
Edit the `WIFI_SSID` and `WIFI_PASS` variables at the top of `apply_all_tweaks.py`, then run:
```bash
python3 apply_all_tweaks.py
```

### Step 2: Deploy Startup and Shutdown Logos
Upload the custom correctly aligned graphics:
```bash
python3 deploy_logo.py
```

### Step 3: Patch Wi-Fi Name Append Logic
Upload the patched `ap.sh` script to force the static SSID and reboot the camera:
```bash
python3 deploy_ap_patch.py
```

### Step 4: Deploy the Web Dashboard
After the camera restarts, connect to your new Wi-Fi network and deploy the web app:
```bash
cd web-app
python3 deploy.py
```

### Step 5: Access the Dashboard
Open your browser and navigate to:
```
http://192.168.1.1/index.html
```
*   Bookmark the page to use the remote shutter and settings controls.
*   Click the Play button in the header to open the Live Slideshow Wall.
