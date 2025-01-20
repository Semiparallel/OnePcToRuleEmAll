# One Personal Computer to Rull Em all

Goal: Versatile platforms on one machine that is interchangeable, efficient and energy-saving.

::: warn
This project is under heavy development changes and bugs are part of it

:::

# What is it about?

With this approach, you can flexibly manage your resources to run different workloads efficiently on a single Proxmox host.

# What are we gonna do?

This project involves setting up a Proxmox hypervisor to enable GPU resource sharing across multiple virtual machines (VMs) and containers using an NVIDIA RTX 2080 Ti. By implementing the vGPU Unlock v3 script, the GPU’s VRAM is dynamically allocated to different profiles for gaming, office work, and AI workloads.

The setup includes custom scripts for switching between profiles and ensures optimal GPU usage based on active tasks. Each VM is tailored with specific GPU profiles to balance performance and compatibility.

Optional integrations like Looking Glass enhance usability by providing seamless I/O between guest (mainVM) and guest systems.

::: info
**Currently not in this Doc (Comming soon).**

Looking Glass setup and guest to guest functionality.

:::

# Wanna do's

| c                                                                                                                         |    |
|---------------------------------------------------------------------------------------------------------------------------|----|
| A Script for better VRam Calculation and entry based on your needs.                                                       | ✔️ |
| Optional integrations like Looking Glass enhance usability by providing seamless I/O between Main guest and guest system. | ✔️  |
| Not only change GPU VRam based on that script.                                                                            |    |

Thinking about where this project coud go the Feature Rabbit Hole:

- Add a better interface to it than cmd.
- Add Add Wake-on-lan
- Add more Energy efficient protocols: like 
  - GPU status to idle or unbind not consuming 40W
  - mini redundant Backup Server 
    - Maybee whit a optional Feature of providing a vm live migrations.

# Setup

## 1. Hardware Supports

---

### Supported cards

The following consumer/not-vGPU-qualified NVIDIA GPUs can be used with vGPU:

- Most GPUs from the Maxwell 2.0 generation (GTX 9xx, Quadro Mxxxx, Tesla Mxx) EXCEPT the GTX 970
- All GPUs from the Pascal generation (GTX 10xx, Quadro Pxxxx, Tesla Pxx)
- All GPUs from the Turing generation (GTX 16xx, RTX 20xx, Txxxx)

Starting from driver version 17.0, Pascal and earlier require additional patches, see below for more!

If you have GPUs from the Ampere and Ada Lovelace generation, you are out of luck, unless you have a vGPU qualified card from this list like the A5000 or RTX 6000 Ada. If you have one of those cards, please consult the NVIDIA documentation for help with setting it up.

> !!! THIS MEANS THAT YOUR RTX 30XX or 40XX WILL NOT WORK !!!

This guide and all my tests were done on a RTX 2080 Ti which is based on the Turing architechture.

### Supported Cpu's

> !!! THE CPU needs Virtualistation support  AMD-V, Vanderpool, VT-X or SVM !!!

## 2. Preperation

---

You need .ISO files from <https://Proxmox.com>, Windows and your prefered Linux distribution like Ubunut or mint and virtIO Drivers <https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers>.

> You only need to flash Proxmox to an usb stick as this will be the main PC Software (Hypervisor), as today working whit Version 8.3.

install the basic PROXMOX on a PC of your \[\[Supportet Hardware\]\].  
If you need help take a look at your favourite tech guy there are plenty Videos and sources how to do that like Craft Computing.

#### Enable virtualisation of you CPU in BIOS

> Virtualistation  AMD-V, Vanderpool, VT-X or SVM

## 3. Installation of depencies

---

Installing the vGpu Unlock v3 script from wvthoog. Best tutorial is in the <https://wvthoog.nl/proxmox-vgpu-v3/> makers its own homepage.

Optional: Based on your needs i prefer making Whiteboards for managing what i need for virtual machines and containers (lxc's) and how i need it something like this. If you need a drawing tool <https://excalidraw.com/> is a good one.

After setting all your Vm's and containers up i woud recommend test <https://wvthoog.nl/proxmox-vgpu-v3/> vGPU unlock script out whit setting a basic vRAM for eatch VirtualMachine/Container. I Have 3 Profiles and one more fore AI testing that shoud use all VRAM thats left over when one of the other profiles not running. So i go whit 3 for testing. thats your GPU vRam / Profiles = Vram.

> Whitch "GPU Type" you shoud use A , B, C or Q is good described in <https://gitlab.com/polloloco/vgpu-proxmox#vgpu-overrides>
>
> his Cheatsheat:
>
> Q profiles can give you horrible performance in OpenGL applications/games (if you have a consumer GPU). To fix that, either add vgpu_type = "NVS" to your profile overrides (see below), or switch to an equivalent A or B profile (for example GRID RTX6000-4B)
>
> C profiles dont exist anymore, just use Q profiles. C profiles (for example GRID RTX6000-4C) only work on Linux, don't try using those on Windows, it will not work - at all.
>
> A profiles (for example GRID RTX6000-4A) will NOT work on Linux, they only work on Windows.

So i wanna have a total of 3 Gaming/Office Virtual Machine so i use Q or (optimal) B for this testing Profile  i wanna do some ai model on Linux whit my GPU so A is nothing for me.  
Because i dont have a standart B profile for now out of the box i go whit nvidia-259 a Q profile. If you wanna make your own Type profile later pollolco has also a good guide for a config file.

> Iam Using a RTX2080 ti so i have 11GB VRAM to use 3 Profiles i have to run one profile whit less VRAM so i needed to make a custom framebuffer size for the last whit only 3GB instead of 4GB Type nvidia-259 Q standart profile.

Also after installing the vGPU drivers on windows or linux and you have a blank screen over the console try switching the Display in Proxmox Hardware Settings to "VirtiO-GPU (virtio)".

## (Optional) Looking Glass on proxmox

Guide on how to setup looking glass on proxmox

This guide assumes you have a working VFIO setup for both win10 and your linux guest.   

On the Proxmox Host, Passing the following shared blurb to both the Linux and Windows guests   

```
qm set <LINUXVM-ID> --args '-device ivshmem-plain,memdev=ivshmem,bus=pcie.0 -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M'
```

```
qm set  <WINDWOS-VMID> --args '-device ivshmem-plain,memdev=ivshmem,bus=pcie.0 -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M -device virtio-mouse-pci -device virtio-keyboard-pci -spice 'addr=0.0.0.0,port=<YOURSPICEPORT>,disable-ticketing=on''
```

::: info
DONT FORGET TO CHANGE <WINDWOS-VMID> and <LINUXVM-ID> and <YOURSPICEPORT>

:::

::: warn
Also The Vm has to be machine: q35

:::

```
apt-get install build-essential

apt-get install binutils-dev cmake fonts-freefont-ttf libsdl2-dev libsdl2-ttf-dev libspice-protocol-dev libfontconfig1-dev libx11-dev nettle-dev 

[download looking glass from website] and open a shell to the folder.

unzip LookingGlass-Release-B1.zip
cd LookingGlass-Release-B1
mkdir client/build
cd client/build
cmake ../
make
```

```
sudo apt-get install flex bison dkms
```

  If you try to compile here, it'll error with a "no rule to make  target /arch/x86/tools/relocs_32.c" you need to:

edit the Makefile with  vi or nano, and change M=$(PWD) to M=$(shell pwd) on both lines.   

Now run through the rest of the install script found in the README in the module folder.   

```
sudo apt-get install linux-headers-$(uname -r)
sudo make
sudo modprobe uio
sudo modprobe kvmfr
sudo chown user:user /dev/kvmfr0
cd ..
cd client
cd build
 ./looking-glass-client -f /dev/kvmfr0 -c **Your_Proxmox_Host_IP** -p **spice port specified** 
```

     At this point it will likely fail with  "failed to connect to spice  server." So so rerun the command without spice with the -s option.   -s For no input! liek usb or pheriperie

```
./looking-glass-client -f /dev/kvmfr0 -c 192.168.1.29 -p 5900 -s -
```

     If you want to make it permanent on reboot, add the modules to startup   

     vi /etc/modules   

```
uio
kvmfr
```

     After a reboot, sudo chown user:user /dev/uio0  then launch the ./looking-glass-client -f /dev/uio0 -L 32 -s   

     Success!  

<https://technonagib.com/configure-spice-proxmox-ve/> from it

## 1-ActivatingSpice and USB INPUT

Start by enabling your virtual machine's SPICE options.

In Hardware\\Display\\Graphic card, select SPICE in "Graphic card".

![](https://technonagib.fr/content/images/2022/06/image-49.png)

Then,  in "Options", go to "spice_enhancement" and enable file sharing (drag'  drop) as well as video encoding by setting it to "all".

![](https://technonagib.fr/content/images/2022/06/image-25.png)

Finally,  add the audio device. I choose "ich9-intel-hda" (hda for High  Definition Audio), which is the motherboard's audio driver.

![](https://technonagib.fr/content/images/2022/06/image-166.png)

![](https://technonagib.fr/content/images/2022/06/image-167.png)

Leave SPICE as the default backend.

![](https://technonagib.fr/content/images/2022/06/image-168.png)

Finally, go to "USB Device" and add the "SPICE Port" option.

![](https://technonagib.fr/content/images/2022/06/image-169.png)

![](https://technonagib.fr/content/images/2022/06/image-170.png)

We've finished configuring the options.

## (Optional) Dynamic VM vGPU ressource framebuffer relocation script.

::: info
Currently the scripts calculates based on **PRIO**

:::

```
./handlerRessource.bash <vmid>
```

Calculates based on ***proxmox_ids.txt*** and ***running vm's***

***Example***

100,VM,1,
110,VM,0,2
111,VM,0,10
121,VM,0,5
130,VM,0,

VMID, TYPE, Priority0-4, vRAM(GB)

::: info
You coud add Profiles based on your needs whit more *TYPE*s but thats in development.

If you wanna have a VM reservate VRAM use *TYPE* 2 and edit in the  ***proxmox_ids.txt*** directly for now.

:::

![ExamplePRIO.png](.attachments.136004/grafik%20%282%29.png)


## bypass the your running on a VM game error by:   

1.      Fill in the BIOS information (VM -> Options -> SMIBIOS Setting)   
2.      Don't use virtio driver. Detached the SCSI drive, edit and change it to SATA drive   
3.      Change the boot order and enable the SATA drive   
4.      Network card MAC address change to INTEL type   

     I created a new VM with these steps above this way there are no EAC  entries, you can see your BIOS information via the commend `dmidecode --type 1` when typing it into the pve shell.   

     Also my cpu type is set to host, when creating the vm.   

     The config file in "/etc/pve/qemu-server/<vmid>.conf" also contains

 `args: -cpu host,-hypervisor,kvm=off`.   

`cpu: host,hidden=1`

## Sources:

---

<https://forum.proxmox.com/threads/enable-spice-qxl-with-video-type-none-so-that-looking-glass-can-use-host-spice-server.85190/> for how to Looking glass on Proxmox.

### Credits

Big thanks to everyone involved in developing and maintaining this neat piece of software.

- [DualCoder](https://github.com/DualCoder) for the original [vgpu_unlock](https://github.com/DualCoder/vgpu_unlock)
- [mbilker](https://github.com/mbilker) for the fast Rust version of [vgpu_unlock](https://github.com/mbilker/vgpu_unlock-rs)
- [PolloLoco](https://gitlab.com/polloloco) for hosting all the patches and his [excellent guide](https://gitlab.com/polloloco/vgpu-proxmox)
- [Oscar Krause](https://git.collinwebdesigns.de/oscar.krause) for setting up [licensing](https://git.collinwebdesigns.de/oscar.krause/fastapi-dls)
