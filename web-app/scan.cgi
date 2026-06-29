#!/bin/sh
echo "Content-type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Scan the SD card for files and rebuild the index
find /mnt/mmc/DCIM -type f | sed 's|/mnt/mmc/DCIM|/DCIM|' > /customer/wifi/webserver/www/files.txt

# Print the list of files as a JSON array
echo -n "["
first=1
while read -r line; do
    # Skip empty lines
    if [ -n "$line" ]; then
        if [ $first -eq 0 ]; then
            echo -n ","
        fi
        echo -n "\"$line\""
        first=0
    fi
done < /customer/wifi/webserver/www/files.txt
echo -n "]"
