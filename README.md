# GPU Power Management Script for Better Battery Life

This script was created to optimize GPU power settings on laptops with AMD and NVIDIA graphics cards. It aims to improve battery life by enabling power-saving features and managing GPU usage, especially when on battery.

**Tested for Arch Linux laptops only.**

## Features

- **GPU Detection**: Automatically detects if your system has an AMD iGPU (integrated GPU) and/or an NVIDIA dGPU (discrete GPU).
- **Driver Check**: Verifies if the required drivers for AMD and NVIDIA GPUs are installed. If not, it will prompt you to install them.
- **Power Management**: 
    - Enables power-saving features like Dynamic Power Management (DPM) and kernel modesetting.
    - Disables the discrete GPU when on battery (if both GPUs are present), reducing power consumption.
- **Kernel Rebuild Prompt**: After making changes, the script will prompt you to rebuild the kernel (using `mkinitcpio`) to apply the new GPU settings.

## How It Works

The script checks for the presence of AMD and NVIDIA GPUs and their corresponding drivers. It then allows you to:
- Configure the AMD and/or NVIDIA GPU power settings.
- Choose whether to disable the discrete GPU (dGPU) when on battery to improve battery life.

## Installation

1. Clone this repository to your local machine:
    ```bash
    git clone https://github.com/theayusharma/gpu-power-management.git
    ```

2. Navigate to the project directory:
    ```bash
    cd gpu-power-management
    ```

3. Make the script executable:
    ```bash
    chmod +x gpu_power_management.sh
    ```

4. Run the script as root:
    ```bash
    sudo ./gpu_power_management.sh
    ```

## Script Usage

- The script will automatically check for AMD and NVIDIA GPUs.
- It will then guide you through configuring power-saving options based on your GPU setup.
- It will also ask if you'd like to disable the dGPU while on battery to improve battery life.

## Dependencies

- **Tested for Arch Linux only**: This script is optimized for Arch Linux systems, and the package manager used is `pacman`.
- `pacman` (for installing packages on Arch-based systems)
- `mkinitcpio` (for rebuilding the initramfs)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Created by

- **Ayush Sharma** (https://github.com/theayusharma)
- **Created with love by a cat 🐾**
