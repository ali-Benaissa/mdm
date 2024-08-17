#!/bin/bash
serial_number=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $4}')
serial_number=$(echo $serial_number | tr -d '\n')
sw_vers_output=$(sw_vers)
formatted_output=$(echo "$sw_vers_output" | tr -s '	')
product_type=$(sysctl hw.model | awk -F ' ' '{print $2}')
product_type=$(echo $product_type | tr -d '\n')

# Define API endpoint
API_URL="http://192.168.1.14:8080/api/checkKey"

# Check if serial number is valid
response=$(curl -s -w "%{http_code}" -o /dev/null "$API_URL?serial=$serial_number")
echo "$API_URL?key=$serial_number"
# Check if response is successful (200)
if [ "$response" -eq 200 ]; then
  echo "Serial Number: $serial_number is valid. Proceeding with the script..."
  # Run software
  echo "Run software..."
  
else
  echo "Invalid Serial Number: $serial_number. Exiting."
  echo "clean up" 
  diskutil eject "$tmpVolume" > /dev/null 2>&1
  diskutil unmount force "$tmpVolume" > /dev/null 2>&1
  exit 1
fi
