#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Display the created by message
echo "This script was created by a cat. 🐾"
echo "It aims to improve battery life for your laptop by optimizing GPU power settings."
echo ""

# Created by message (normal comment text)
echo "####################################################################"
echo "#                                                                  #"
echo "#                 Created by: https://github.com/theayusharma      #"
echo "#                                                                  #"
echo "####################################################################"
echo ""

# Function to check if a GPU is present
check_gpu() {
    local gpu_type="$1"
    if lspci | grep -i "$gpu_type" &>/dev/null; then
        echo "$gpu_type GPU detected."
        return 0
    else
        echo "$gpu_type GPU not detected."
        return 1
    fi
}

# Function to check if a driver is installed
check_driver() {
    local driver_name="$1"
    if pacman -Qq "$driver_name" &>/dev/null; then
        echo "$driver_name driver is installed."
        return 0
    else
        echo "$driver_name driver is missing."
        return 1
    fi
}

# Check for GPUs
has_amdgpu=0
has_nvidia=0

# Check if AMD GPU is present
check_gpu "AMD" && has_amdgpu=1

# Check if NVIDIA GPU is present
check_gpu "NVIDIA" && has_nvidia=1

# Check if drivers for each GPU are installed
missing_drivers=()

if [ $has_amdgpu -eq 1 ]; then
    if ! check_driver "xf86-video-amdgpu"; then
        missing_drivers+=("xf86-video-amdgpu")
    fi
    if ! check_driver "amdgpu-pro"; then
        missing_drivers+=("amdgpu-pro")
    fi
fi

if [ $has_nvidia -eq 1 ]; then
    if ! check_driver "nvidia"; then
        missing_drivers+=("nvidia")
    fi
    if ! check_driver "nvidia-utils"; then
        missing_drivers+=("nvidia-utils")
    fi
fi

# Notify the user if any drivers are missing
if [ ${#missing_drivers[@]} -gt 0 ]; then
    echo "The following drivers are missing:"
    for driver in "${missing_drivers[@]}"; do
        echo "- $driver"
    done
    read -p "Would you like to install the missing drivers? (y/n): " install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        echo "Installing missing drivers..."
        pacman -Syu --noconfirm "${missing_drivers[@]}"
    fi
else
    echo "All necessary drivers are installed."
fi

# Prompt for which GPU(s) to configure
echo "Which GPU would you like to configure?"
echo "1) AMD GPU"
echo "2) NVIDIA GPU"
echo "3) Both AMD and NVIDIA GPUs"
read -p "Enter your choice (1/2/3): " gpu_choice

# Define configuration file paths
AMDGPU_CONFIG_FILE="/etc/modprobe.d/amdgpu.conf"
NVIDIA_CONFIG_FILE="/etc/modprobe.d/nvidia.conf"

# Function to add AMDGPU configuration
configure_amdgpu() {
    echo "Adding AMDGPU configuration to $AMDGPU_CONFIG_FILE..."
    cat <<EOL > "$AMDGPU_CONFIG_FILE"
# AMDGPU Configuration
options amdgpu dc=1           # Enables Display Core for newer GPUs
options amdgpu dpm=1          # Dynamic Power Management (improves power efficiency)
options amdgpu deep_color=1   # Enable deep color for better visuals
options amdgpu powerplay=1    # Advanced power management features
options amdgpu kernel_modesetting=1  # Kernel Mode Setting (KMS) for better stability
EOL
    echo "AMDGPU configuration added."
}

# Function to add NVIDIA configuration
configure_nvidia() {
    echo "Adding NVIDIA configuration to $NVIDIA_CONFIG_FILE..."
    cat <<EOL > "$NVIDIA_CONFIG_FILE"
# NVIDIA Driver Configuration
options nvidia NVreg_DynamicPowerManagement=0x02  # Aggressive power management
options nvidia NVreg_PreserveVideoMemoryAllocations=1  # Improves suspend/resume handling
options nvidia NVreg_EnableS0ixPowerManagement=1  # Enables modern sleep states
options nvidia NVreg_IgnoreMSI=0  # Ensures proper interrupt handling
EOL
    echo "NVIDIA configuration added."
}

# Detect if both iGPU and dGPU are present
if [ $has_amdgpu -eq 1 ] && [ $has_nvidia -eq 1 ]; then
    echo "Both iGPU (AMD) and dGPU (NVIDIA) are detected."
    read -p "Which GPU is your integrated (iGPU)? (AMD/NVIDIA): " igpu_choice
    if [[ "$igpu_choice" =~ ^[Aa]MD$ ]]; then
        echo "AMD is the iGPU."
        echo "NVIDIA will be the dGPU."
    elif [[ "$igpu_choice" =~ ^[Nn]VIDIA$ ]]; then
        echo "NVIDIA is the iGPU."
        echo "AMD will be the dGPU."
    else
        echo "Invalid choice. Assuming AMD as iGPU and NVIDIA as dGPU."
        igpu_choice="AMD"
    fi

    # Ask if the user wants to disable the dGPU while on battery
    read -p "Would you like to disable the dGPU while on battery to improve battery life? (y/n): " disable_dgpu
    if [[ "$disable_dgpu" =~ ^[Yy]$ ]]; then
        if [[ "$igpu_choice" == "AMD" ]]; then
            echo "Disabling NVIDIA dGPU when on battery."
            echo "options nvidia power_control=1" >> "$NVIDIA_CONFIG_FILE"
        else
            echo "Disabling AMD dGPU when on battery."
            echo "options amdgpu power_control=1" >> "$AMDGPU_CONFIG_FILE"
        fi
    fi
fi

# Based on user choice, configure the appropriate GPU(s)
case "$gpu_choice" in
    1)
        # Configure AMDGPU
        configure_amdgpu
        ;;
    2)
        # Configure NVIDIA
        configure_nvidia
        ;;
    3)
        # Configure both AMDGPU and NVIDIA
        configure_amdgpu
        configure_nvidia
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Prompt the user to rebuild the kernel for AMDGPU or NVIDIA
echo "The changes to the GPU configuration might require rebuilding the kernel to take full effect."

if [ "$gpu_choice" == "1" ] || [ "$gpu_choice" == "3" ]; then
    read -p "Would you like to rebuild the kernel now for AMDGPU? (y/n): " amdgpu_choice
    if [[ "$amdgpu_choice" =~ ^[Yy]$ ]]; then
        echo "Rebuilding the kernel for AMDGPU..."
        if command -v mkinitcpio &>/dev/null; then
            mkinitcpio -P
        else
            echo "mkinitcpio not found. Please manually rebuild the initramfs."
        fi
    fi
fi

if [ "$gpu_choice" == "2" ] || [ "$gpu_choice" == "3" ]; then
    read -p "Would you like to rebuild the kernel now for NVIDIA? (y/n): " nvidia_choice
    if [[ "$nvidia_choice" =~ ^[Yy]$ ]]; then
        echo "Rebuilding the kernel for NVIDIA..."
        if command -v mkinitcpio &>/dev/null; then
            mkinitcpio -P
        else
            echo "mkinitcpio not found. Please manually rebuild the initramfs."
        fi
    fi
fi

echo "Configuration complete. Please reboot your system for changes to take effect."
