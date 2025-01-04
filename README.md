# OnePcToRuleEmAll
Versatile platforms on one machine that is interchangeable, efficient and energy-saving.
# What is it about?

This project involves setting up a Proxmox hypervisor to enable GPU resource sharing across multiple virtual machines (VMs) and containers using an NVIDIA RTX 2080 Ti. By implementing the vGPU Unlock v3 script, the GPU’s VRAM is dynamically allocated to different profiles for gaming, office work, and AI workloads. The setup includes custom scripts for switching between profiles and ensures optimal GPU usage based on active tasks. Each VM is tailored with specific GPU profiles to balance performance and compatibility. Optional integrations like Looking Glass enhance usability by providing seamless I/O between host and guest systems.

# Currently not in this Doc (Comming soon).

\- The setup includes custom scripts for switching between profiles and ensures optimal GPU usage based on active tasks.

\- Optional integrations like Looking Glass enhance usability by providing seamless I/O between host and guest system.

> If you wanna help some sources are avaiable in Repo. 

## Todo's +

- Add Wake-On-Lan Tutorials and intergate whit Ressource scripts for eatch VM (50% done)
- Add HomeAssistant Tutorials for easier managment and a better interface.

# 1. Hardware Supports

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

# 2. Preperation

---

You need .ISO files from https://Proxmox.com, Windows and your prefered Linux distribution like Ubunut or mint and virtIO Drivers https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers.

> You only need to flash Proxmox to an usb stick as this will be the main PC Software (Hypervisor), as today working whit Version 8.3.

install the basic PROXMOX on a PC of your \[\[Supportet Hardware\]\].  
If you need help take a look at your favourite tech guy there are plenty Videos and sources how to do that like Craft Computing.

# 3. Installation of depencies

---

Installing the vGpu Unlock v3 script from wvthoog. Best tutorial is in the https://wvthoog.nl/proxmox-vgpu-v3/ makers its own homepage.

Optional: Based on your needs i prefer making Whiteboards for managing what i need for virtual machines and containers (lxc's) and how i need it something like this. If you need a drawing tool https://excalidraw.com/ is a good one.

![whiteboardZuschnitt.png](.attachments.132107/image%20%283%29.png)

I tried making Profile 1-4 and how they can be online at the same time in VGPU RAM CONST based on my needs i also made a script that switches the profiles dynamically later.

After setting all your Vm's and containers up i woud recommend test https://wvthoog.nl/proxmox-vgpu-v3/ vGPU unlock script out whit setting a basic vRAM for eatch VirtualMachine/Container. I Have 3 Profiles and one more fore AI testing that shoud use all VRAM thats left over when one of the other profiles not running. So i go whit 3 for testing. thats your GPU vRam / Profiles = Vram.

> Whitch "GPU Type" you shoud use A , B, C or Q is good described in https://gitlab.com/polloloco/vgpu-proxmox#vgpu-overrides
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

## (Optional) Looking Glass
## (Optional) Dynamic VM vGPU ressource framebuffer relocation script
## (Optional) Wake on Lan
## (Optional) Home Assistant

# Sources:

---

https://forum.proxmox.com/threads/enable-spice-qxl-with-video-type-none-so-that-looking-glass-can-use-host-spice-server.85190/ for how to Looking glass on Proxmox.

... for the Wake-on-lan script.

Big thanks to everyone involved in developing and maintaining this neat piece of software.

- DualCoder for the original vgpu_unlock
- mbilker for the fast Rust version of vgpu_unlock
- PolloLoco for hosting all the patches and his excellent guide
- Oscar Krause for setting up licensing
