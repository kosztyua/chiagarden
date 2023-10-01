#!/bin/bash

# Description: Installer script for ChiaGarden - a set of Linux tools to build and manage a Chia post farm.

# Clear the terminal
clear

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}This script must be run as root${NC}" 
  exit 1
fi

# Print header
echo -e "${GREEN}ChiaGarden Installer${NC}"
echo "----------------------------------"

read -p "This script will install ChiaGarden and its dependencies. Do you want to proceed? [Y/n] " response
if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
  echo -e "${RED}Installation canceled.${NC}"
  exit 1
fi


# Update package list and install dependencies
echo -e "\n${YELLOW}Updating package list and installing dependencies...${NC}"
apt update
apt install -y mergerfs xfsprogs ntfs-3g smartmontools parted

# Copy files
echo -e "\n${YELLOW}Copying ChiaGarden files...${NC}"
files_to_copy=(
  "./chiainit/chiainit"
  "./gardenmount/gardenmount"
  "./plotting/plot_counter"
  "./plotting/plot_mover"
  "./plotting/plot_over"
  "./plotting/plot_starter"
  "./taco_list/taco_list"
)

for file in "${files_to_copy[@]}"; do
  if [[ -e $file ]]; then
    cp $file /usr/local/bin/
    echo -e "${GREEN}Copied${NC} $file ${GREEN}to /usr/local/bin/${NC}"
  else
    echo -e "${RED}Error: File $file not found${NC}"
    exit 1
  fi
done

# Copy the systemd service
if [[ -e "gardenmount/garden-mount.service" ]]; then
  echo -e "\n${YELLOW}Installing garden-mount.service${NC}"
  cp ./gardenmount/garden-mount.service /etc/systemd/system/
else
  echo -e "${RED}Error: garden-mount.service not found${NC}"
  exit 1
fi

# Prompt user to enable the systemd service
#echo -e "\n${YELLOW}The garden-mount.service manages is for automounting during boot.${NC}"
read -p "Do you want to enable the garden-mount service? This will automount your drives on boot? [Y/n] " enable_response
if [[ ! "$enable_response" =~ ^([nN][oO]|[nN])$ ]]; then
  echo -e "\n${YELLOW}Enabling the garden-mount service...${NC}"
  systemctl daemon-reload
  systemctl enable garden-mount.service
fi

echo -e
echo -e "${BOLD}${GREEN}ChiaGarden installation complete!${NC}"
echo -e "Please read the README.md files for more information on how to use ChiaGarden.\n"
echo -e "${YELLOW}You may want to start by using chiainit to initialize your drives.${NC}\n"

/usr/local/bin/chiainit --help
echo

