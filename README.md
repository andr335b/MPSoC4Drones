# MPSoC4Drones
Tool chain for building images with custom programmable logic design, Ubuntu 20.04, and ROS2, targeted for the MPSoC platform Ultra96-V2 in UAV (drone) applications which requires ROS2 with hardware acceleration. 

Prerequisites:

- **Host Platform**: [Ubuntu 20.04 LTS](https://releases.ubuntu.com/20.04/)
- **Tools**: [Vivado/Vitis 2021.1](https://www.xilinx.com/support/download.html) + [PetaLinux 2020.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools/2020-2.html)
- At least a 16 GB SD card

The work uses:

- **Target Platform**: [Ubuntu Base 20.04 LTS for Arm64](http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/)
- **Target Middleware**: [ROS2 Foxy](https://docs.ros.org/en/foxy/Installation.html)
- **Target Development Board**: [Ultra96-V2](https://www.avnet.com/shop/us/products/avnet-engineering-services/aes-ultra96-v2-g-3074457345638646173/) with [U96 JTAG/UART to USB adapter](https://www.avnet.com/shop/us/products/avnet-engineering-services/aes-acc-u96-jtag-3074457345635355958/)

Everything in this repository is heavily based on the work of others, especially the guys from [Avnet](https://www.avnet.com/wps/portal/us/products/avnet-boards/avnet-board-families/ultra96-v2/). Additionally, it is a work in progress, so bugs due to different OS or tool versions may arise. We work continuously to upgrade the system to the latest available tools. Please raise an issue if you experience any bugs that are not already reported.

Some additional references we've used to stitch together this work:
- [Wi-Fi Connectivity on the Ultra96-V2 in Vivado+PetaLinux 2019.2](https://www.hackster.io/news/wi-fi-connectivity-on-the-ultra96-v2-in-vivado-petalinux-2019-2-493a709b7f25)
- [Running Ubuntu 18.04 on Ultra96v2 Using Petalinux 2019.2, with Networking](https://highlevel-synthesis.com/2019/12/15/running-ubuntu-on-ultra96v2-using-petalinux-2019-2-with-networking-and-linux-header/)
- [Tips for Integrating WiFi on the Ultra96-V2](https://www.element14.com/community/groups/fpga-group/blog/2020/01/30/lessons-learned-from-debugging-wifi-access-point-on-ultra96-v2)
- [Ultra96-PYNQ](https://github.com/Avnet/Ultra96-PYNQ)
- [ZynqMP-FPGA-Ubuntu20.04-Lima-Ultra96](https://github.com/ikwzm/ZynqMP-FPGA-Ubuntu20.04-Lima-Ultra96)
- [ZynqMP-FPGA-Ubuntu20.04-Ultra96](https://github.com/ikwzm/ZynqMP-FPGA-Ubuntu20.04-Ultra96)
- [ZynqMP-FPGA-Linux](https://github.com/ikwzm/ZynqMP-FPGA-Linux)
- [Ultra96-V2 ultra-hard-story with WiFi of](https://titanwolf.org/Network/Articles/Article?AID=e801481c-6969-425e-8ce2-77c2edf0e63e#gsc.tab=0)
- [u96v2-wilc-driver](https://github.com/Avnet/u96v2-wilc-driver)
- [Patching the Linux Kernel with devshell in PetaLinux 2020.2](https://www.centennialsoftwaresolutions.com/post/patching-the-linux-kernel-with-devshell-in-petalinux-2020-2)

## Getting started

The tool chain has the following primary steps:
- [Synthesis](#programmable-logic-synthesis) of the programmable logic design to obtain an XSA (hardware description) file. If you don't want to customize your programmable logic, but still want to configure the build process, you can get an XSA file with the bare essentials [here](prebuilt/u96v2_sbc_base.xsa).
- [Building the image](#building-the-image) using PetaLinux and the generated XSA file, in order to obtain the boot files. This step takes a while, so if you only care about getting to the Ubuntu-part quickly with bare essential programmable logic, basic build settings, and standard drivers, the prebuilt boot files can be found [here](prebuilt/BOOT/).
- [Preparing the file system](#preparing-the-file-system), which will be the root file system of the OS on the MPSoC. Once again, this step takes a while, so if you are completely fine with the file system setup we propose here with essential tools and ROS2, go ahead and download the [prebuilt file system]() (FIX LINK). In any case, you can install additional software later.
- [Preparing the SD card](#preparing-the-sd-card) using the generated boot files and the prepared file system.

### Repository setup

Clone the repository: 

```bash
git clone https://github.com/DIII-SDU-Group/MPSoC4Drones.git
```

Enter the cloned directory:

```bash
cd MPSoC4Drones/
```

Now, run the setup script. The setup script will first setup the Vivado project structure host independently, and will then change ownership of all nested folders and files to the current user (a workaround for a bug we experienced with the Vivado project), and will thus prompt for *sudo* password:

```bash
chmod +x setup.sh
./setup.sh
```

Done!

### Programmable logic synthesis
In order to generate a hardware specification file (XSA), we use the Vivado project that was initialised in the [previous step](#repository-setup).

Open Vivado 2021.1 and open the project file, e.g.

```bash
vivado vivado_project/U20U96.xpr
```

Press *Open Block Design*.

You now see the **essential** hardware required for hosting the Ubuntu system. You have the option to add you own programmable logic design. We recommend that you package your design(s) as IP(s) and then include it in this block design. We have not had success with combining the blocks in the block design hierarchies, but if you succeed with this, please share your experience in an issue. Finally, if you need additional PL-PS communication, IO, etc., you are free to enable hardware blocks in the *Zynq Processing System* block or to add *AXI* devices to the design. You can of course connect your design to the *BRAM_PORTB* interface for direct shared memory with the processing system. Please also feel free to report any issues you might experience.

Once you design is as you like, press *Generate Bitstream* and configure your run as desired. Warning: Using too many jobs will take up a lot of RAM and swap memory, potentially resulting in Vivado crashing, so lower the number of jobs and take a coffee.

When the run is finished, generate the XSA file by
> 1. Press *File>Export>Export Platform...*
> 2. Press *Next >*
> 3. Make sure *Hardware* is chosen, then press *Next >*
> 4. Make sure *Pre-synthesis* is chosen, then tick *Include bitstream*, then press *Next >*
> 5. Press *Next >*
> 6. Press *Next >*
> 7. Press *Finish*

After a little processing, the XSA file has been generated.

**Attention**:
> If you haven't made any changes to the hardware which involves changed memory addresses or software driver (changes to the *Zynq Processing System* block or changes to or additional *AXI* devices), and you have previously built the image, you don't need to generate an XSA file and build the image from scratch again. You can simply use the boot files you have previously built and jump straight to [packaging](#packaging).

### Building the image
After obtaining the XSA file, it is time to build the image.

Make sure you're in the MPSoC4Drones directory. Source the PetaLinux environment settings script for the needed command set, e.g.

```bash
source <petalinux-2020.2-dir>/settings.sh
```
Then we create the PetaLinux project:

```bash
petalinux-create --type project --template zynqMP --name U20U96_petalinux
cd U20U96_petalinux
```

Configure the build with your XSA hardware definition file:

```bash
petalinux-config --get-hw-description ../vivado_project/u96v2_sbc_base_wrapper.xsa
```

This command will bring up the hardware system configuration editor. Apply the following settings (all of which are important - neglect might cause failure to boot):

> - In *Subsystem AUTO Hardware Settings > Serial Settings*, all *stdin/stdout* is `PSU_UART1` and the baudrate is 115200 
> - *Subsystem AUTO Hardware Settings > Advanced bootable images storage Settings > boot image settings > image name* is `BOOT.BIN`
> - *Subsystem AUTO Hardware Settings > Advanced bootable images storage Settings > boot image settings > image storage media* is `primary sd`
> - *Subsystem AUTO Hardware Settings > Advanced bootable images storage Settings > u-boot env partition settings > image storage media* is `primary sd`
> - *Subsystem AUTO Hardware Settings > Advanced bootable images storage Settings > kernel image settings > image storage media* is `primary sd`
> - *Subsystem AUTO Hardware Settings > Advanced bootable images storage Settings > dtb image settings > image storage media* is `primary sd`
> - *Subsystem AUTO Hardware Settings > SD/SDIO > Primary SD/SDIO* is `psu_sd_0`
> - *DTG Settings > MACHINE_NAME* is `avnet-ultra96-rev1`
> - *Image Packaging Configuration > Root filesystem type* is `EXT4 (SD/eMMC/SATA/USB)`
> - *Image Packaging Configuration > Copy final images to tftpboot* is unchecked (press n)

WIFI STUFF GOES HERE!


Then we are ready to build a bare minimum device tree for the Zynq MPSoC system. Run:

```
petalinux-build
```

This will take quite a while (few hours). :)

#### Packaging
Once the build is done, a boot image binary (BOOT.BIN) needs to be created from the first stage bootloader, FPGA bitstream, PMU firmware, and u-boot environment. Using the `petalinux-package` command, specify the paths to the bitstream and ELF files. The boot image binary file will be generated in this same directory. This step can be done if the programmable logic design has been changed without changing address specific parts. One simply needs to replace `images/linux/system.bit` with the new bitstream generated from Vivado.

Make sure you're in the PetaLinux project directory, e.g.

```bash
cd MPSoC4Drones/U20U96_petalinux/
```

Then, issue the following command:

```bash
petalinux-package --boot --fsbl images/linux/zynqmp_fsbl.elf --fpga images/linux/system.bit --pmufw images/linux/pmufw.elf --u-boot
```

Finally, create a BOOT folder to contain the generated boot files: TODO: Check this!!

```bash
mkdir BOOT
cp images/linux/boot.scr BOOT/
cp images/linux/image.ub BOOT/
cp images/linux/BOOT.BIN BOOT/
```

Done!

### Preparing the file system
Now we prepare the Ubuntu file system. This step is independent of the build process and can be done separately. Additionally, you can reuse this file system for other builds, as will be obvious.

Make sure you're in the PetaLinux project directory, e.g.

```bash
cd MPSoC4Drones/U20U96_petalinux/
```

Create the rootfs directory, get the Ubuntu base image, and extract it:

```bash
mkdir rootfs

wget http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.1-base-arm64.tar.gz -O - | tar xpz -C rootfs/

sudo chown -R root rootfs/
sudo chgrp -R root rootfs/
```

We then proceed to add libraries to the rootfs from the host PC. 

Install the qemu tool if you don't already have it:

```bash
sudo apt install qemu-user-static
```

Copy these config files into the rootfs:

```bash
sudo cp -av /usr/bin/qemu-aarch64-static ./rootfs/usr/bin/

sudo cp -av /run/systemd/resolve/stub-resolv.conf ./rootfs/etc/resolv.conf
```

Create these mount points:

```bash
sudo mount --bind /dev/ ./rootfs/dev
sudo mount --bind /proc/ ./rootfs/proc
sudo mount --bind /sys/ ./rootfs/sys
```

`chroot` into the rootfs:

```bash
sudo chroot ./rootfs/
```

Update and upgrade (don't mind about an error saying that logs can't be written):
```bash
apt update
apt upgrade -y
```

Install `sudo`, as this is not installed (really scraped Ubuntu version) and you will definitely need it:

```bash
apt install sudo
```

Add a new user (here `u96`), create a password (here `u96`), and give sudo access to the user:

```bash
useradd -G sudo -m -s /bin/bash u96
echo u96:u96 | chpasswd

usermod -aG sudo u96
chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo
```

We then login as the new user in order to not install everything as root:

```bash
su - u96
```

> If you as user `u96` experience issues with using the `sudo` command, specifically if you see 
> ```bash
> sudo: effective uid is not 0, is /usr/bin/sudo on a file system with the 'nosuid' option set or an NFS file system without root privileges?
> ```
> Write `exit` to go back to root user, then execute
> ```bash
> mount
> mount -n -o remount,suid /
> ```
> Then change to `u96` user again:
> ```bash
> su - u96
> ```
> Then you should be good with the `sudo` command again! Let's continue...


Now, let's install some software on rootfs:

```bash
sudo apt -y install \
  locales \
  dialog \
  perl \
  ifupdown \
  net-tools \
  ethtool \
  udev \
  wireless-tools \
  iputils-ping \
  resolvconf \
  wget \
  apt-utils \
  wpasupplicant \
  devmem2 \
  nano \
  vim \
  kmod \
  openssh-client \
  openssh-server \
  build-essential \
  cmake \
  git \
  build-essential \
  libbullet-dev \
  curl \
  gnupg2 \
  lsb-release
```

Set some locale settings (needed for ROS2 repository):

```bash
sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

Authorize the GPG key with apt like this:

```bash
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
```

Then add the repository to your sources list:

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
```

Install ROS2 related Python packages:

```bash
sudo apt update && sudo apt install -y \
  python3-colcon-common-extensions \
  python3-flake8 \
  python3-pip \
  python3-pytest-cov \
  python3-rosdep \
  python3-setuptools \
  python3-vcstool
```
Install some pip packages needed for testing:

```bash
python3 -m pip install -U \
  argcomplete \
  flake8-blind-except \
  flake8-builtins \
  flake8-class-newline \
  flake8-comprehensions \
  flake8-deprecated \
  flake8-docstrings \
  flake8-import-order \
  flake8-quotes \
  pytest-repeat \
  pytest-rerunfailures \
  pytest
```

Install Fast-RTPS dependencies:

```bash
sudo apt install --no-install-recommends -y \
  libasio-dev \
  libtinyxml2-dev
```

Install Cyclone DDS dependencies:

```bash
sudo apt install --no-install-recommends -y \
  libcunit1-dev
```

Finally, we install ROS2 Foxy base:

```bash
sudo apt install ros-foxy-ros-base
```

Add the ROS2 source script to `.bashrc`:

```bash
echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc
```

Create a workspace:

```bash
mkdir -p ~/ros2/src
```

And that's the furthest we can do with `chroot`. Now, the file system is ready.

Quit the qemu session by issuing the `exit` command twice:

```bash
exit
exit
```

Perform the following umount commads (very important!):

```
sudo umount  ./rootfs/dev
sudo umount  ./rootfs/proc
sudo umount  ./rootfs/sys
```

Now, we're ready to put things on the SD card.

### Preparing the SD card
You will need an SD card with at least 16 GB of memory.

The SD card needs to be partitioned. The partition map needs to be as following: First there must be 100 MiB of free space. Next, there needs to be a FAT32 partition labeled *BOOT* of size 1000 MiB. Finally, with no free space in between, the rest of the space must be formated as an EXT4 partition labeled *rootfs*. One can use the Ubuntu **gparted** app.

Mount the SD card to the host system (your PC), e.g. such that the partitions can be seen as `/mnt/BOOT/` and `/mnt/rootfs/`.

Make sure you're in the PetaLinux project directory, e.g.

```bash
cd MPSoC4Drones/U20U96_petalinux
```

Now, copy the boot files into the *BOOT* partition:

```bash
sudo cp -r BOOT/* /mnt/BOOT/
```

And then, copy the file system onto the *rootfs* partition:

```bash
sudo cp -r rootfs/* /mnt/rootfs
```

You're moving a few GBs of data onto the SD card, so have patience. We will theen syncronize the system memory buffer in order to make sure that all data is written properly to the card. Issue

```bash
sync & watch -n 1 grep -e Dirty: /proc/meminfo
```

and wait until the buffer is (nearly) empty. Then `ctrl+c` the operation.

Finally, unmount the SD partitions, e.g.

```bash
sudo umount /mnt/BOOT /mnt/rootfs
```

Remove the SD card from your PC and insert it into the Ultra96V2. Connect to your PC using the serial port with the JTAG connector (baudrate 115200), e.g.

```bash
screen /dev/ttyUSB1 115200
```

Power the board, press the reset button, and the Linux system should start booting. Login with your user name and password (`u96`). 

Go into your ROS2 directory and build:

```bash
cd ~/ros2/
colcon build --symlink-install
```

Set up your environment by sourcing the following file.

```
source ~/ros2/install/local_setup.bash
```
