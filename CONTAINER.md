# OCI image for cuda-checkpoint

## Create image 
Testing on CentOS Stream release 9 host

using [podman container checkpoint](https://docs.podman.io/en/latest/markdown/podman-container-checkpoint.1.html#create-image-image) hoping to create an image of the running process
note - since `container checkout` uses `criu` behind the scene and it needs root permissoins - all podman commands are executed using sudo



preliminary steps [README.md](./README.md), [nvidia checkpointing-cuda](https://developer.nvidia.com/blog/checkpointing-cuda-applications-with-criu/#checkpointing_example) required to verify that nvidia-checkpoint works as expected regardless of containers

on host install `nvidia-cuda` [follow runfile local](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=RHEL&target_version=9&target_type=runfile_local)
  a. `curl -o ~/cuda_12.4.1_550.54.15_linux.run  https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda_12.4.1_550.54.15_linux.run`
  b. `sudo sh ~/cuda_12.4.1_550.54.15_linux.run --toolkit --driver`  [`--silent`] runfile_local provides an interactive walkthrough option to install both toolkit and driver
```
Please make sure that
 -   PATH includes /usr/local/cuda-12.4/bin
 -   LD_LIBRARY_PATH includes /usr/local/cuda-12.4/lib64, or, add /usr/local/cuda-12.4/lib64 to /etc/ld.so.conf and run ldconfig as root

To uninstall the CUDA Toolkit, run cuda-uninstaller in /usr/local/cuda-12.4/bin
To uninstall the NVIDIA Driver, run nvidia-uninstall
Logfile is /var/log/cuda-installer.log
```

```
# assuming nvidia drivers are already installed on host machine 
export PATH=$PATH:/usr/local/cuda-12.4/bin/

nvcc counter.cu -o counter
```
more info about `nvcc` [nvidia compiler](https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/) 

#### nvidia-container-toolkit Installation
preliminary requiremets:
1. [install nvidia driver](https://developer.nvidia.com/datacenter-driver-downloads?target_os=Linux&target_arch=x86_64&Distribution=RHEL&target_version=9&target_type=rpm_network)
```
# sudo dnf install pciutils ## instal lspci 
# lspci |grep nvidia ## NOT WORKING ... TODO REMOVE
```
   a. `sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo`
   b. `sudo dnf clean all`
   c. `sudo dnf -y module install nvidia-driver:550-open` (or legacy `sudo dnf -y module install nvidia-driver:565`)
   verify installation by `cat /proc/driver/nvidia/version` and `nvidia-smi`

   
1. on host install `nvidia-container-toolkit` [follow steps](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) see commands for centos / dnf:
	a. curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
	b. `sudo dnf config-manager --set-enabled  nvidia-container-toolkit-experimental` (optional)
	c. `sudo dnf install -y nvidia-container-toolkit`
  d. verify installation using `nvidia-ctk --version`
  e. `sudo nvidia-ctk cdi list` ()
2. [configuration](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#configuration)
  a. install container runtime `sudo dnf install podman`
  b. check status `service podman status` (or `sudo systemctl status podman`) and start if needed `sudo systemctl restart podman` 



4. configure rootless
	a. add to `/usr/share/containers/containers.conf` (or `/etc/containers/containers.conf`) under  [engine] `cdi_device_include=["nvidia.com/gpu"]`

5. start a container that uses GPU:
	a. `sudo podman run --rm --device nvidia.com/gpu=all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi`





#### Enable GPU on containers:
[CDI Conttainer Device Iterface](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html)
`nvidia-ctk cdi list` should output list of devices, if not - execute the following:
`sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`

#### varifications
`nvidia-smi -L`
```
GPU 0: Tesla T4 (UUID: GPU-<UUID>)
```

`nvidia-ctk --version`
```
NVIDIA Container Toolkit CLI version 1.17.0
commit: 5bc031544833253e3ab6a36daec376dc13a4f479
```

`sudo nvidia-ctk cdi list`
```
INFO[0000] Found 2 CDI devices
nvidia.com/gpu=0 2
nvidia.com/gpu=all 22
```




validate:
`podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable ubuntu nvidia-smi -L`


## Test example
1. build image `sudo podman build . -t gpu-test`
2. run image `sudo podman run -d --mount type=glob,src=/usr/lib64/libnvidia\*,ro=true --gpus=all --security-opt=label=disable -p 10000:10000 gpu-test`



## Troubleshooting
-- [verify-you-have-a-cuda-capable-gpu](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#verify-you-have-a-cuda-capable-gpu)
```
sudo dnf install pciutils
lspci |grep nvidia
```

- in case `nvidia-ctk cdi list`  fails (no list is produced `INFO[0000] Found 0 CDI devices`)
fix: `sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`
- running `sudo podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu20.04 nvidia-smi` 
Error: setting up CDI devices: failed to inject devices: failed to stat CDI host device "/dev/nvidia-uvm": no such file or director



sudo systemctl restart podman
/etc/crio/crio.conf
sudo nvidia-ctk runtime configure --runtime=crio
i

sudo nvidia-ctk runtime configure --runtime=docker


mkdir -p /etc/containers
sudo cp /usr/share/containers/containers.conf /etc/containers/containers.conf


Exposing shared libraries inside of container as read-only using a glob
$ podman run --mount type=glob,src=/usr/lib64/libnvidia\*,ro=true
[ekaravani@ekaravani-vm10-centos src]$
Broadcast message from root@ekaravani-vm10-centos on pts/0 (Tue 2024-11-05 13:22:07 UTC):

The system will reboot now!

Connection to 35.232.158.75 closed by remote host.
Connection to 35.232.158.75 closed.

Recommendation: To check for possible causes of SSH connectivity issues and get
recommendations, rerun the ssh command with the --troubleshoot option.

gcloud compute ssh ekaravani-vm10-centos --project=ltx-apps-vms --zone=us-central1-b --troubleshoot

Or, to investigate an IAP tunneling issue:

gcloud compute ssh ekaravani-vm10-centos --project=ltx-apps-vms --zone=us-central1-b --troubleshoot --tunnel-through-iap

ERROR: (gcloud.compute.ssh) [/usr/bin/ssh] exited with return code [255].




## Restore Image
