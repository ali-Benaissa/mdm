#!/bin/bash

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

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

  # Bypass MDM from Recovery
  echo -e "${YEL}Bypass MDM from Recovery${NC}"

# Check if "Macintosh HD - Data" exists
  if [ -d "/Volumes/Macintosh HD - Data" ]; then
     diskutil rename "Macintosh HD - Data" "Data"
  fi

# Create Temporary User
echo -e "${NC}Create a Temporary User${NC}"
read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
read -p "Enter Temporary Username (Default is 'Apple'): " username
read -p "Enter Temporary Password (Default is '1234'): " passw

# Create User
dscl_path='/Volumes/Data/private/var/db/dslocal/nodes/Default'
echo -e "${GRN}Creating Temporary User${NC}"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
mkdir "/Volumes/Data/Users/$username"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership $username

# Block MDM domains
echo "0.0.0.0 deviceenrollment.apple.com" >>/Volumes/Macintosh\ HD/etc/hosts
echo "0.0.0.0 mdmenrollment.apple.com" >>/Volumes/Macintosh\ HD/etc/hosts
echo "0.0.0.0 iprofiles.apple.com" >>/Volumes/Macintosh\ HD/etc/hosts
echo -e "${GRN}Successfully blocked MDM & Profile Domains${NC}"

# Remove configuration profiles
touch /Volumes/Data/private/var/db/.AppleSetupDone
rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound

echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
echo -e "${NC}Exit terminal and reboot your Mac.${NC}"
  
else
  echo "Invalid Serial Number: $serial_number. Exiting."
  echo "clean up" 
  diskutil eject "$tmpVolume" > /dev/null 2>&1
  diskutil unmount force "$tmpVolume" > /dev/null 2>&1
  exit 1
fi
