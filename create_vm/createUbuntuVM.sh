#!/bin/bash
# Create Ubuntu VM
# Thomas, based on jing.ma's job

##########################################################
## Host OS: CentOS 5.5, 5.8
## VM OS: Ubuntu 14.04
#
## Preparation on Host OS: ext4
# sudo modprobe ext4
# yum install e4fsprogs
#
#
#
#
##########################################################


##########################################################
## Because Thomas is a lasy guy, so you have to modify those parameters by yourself.

SERVER_URL=http://bj.faster.mobi:5555/create_vm/
HOSTS_ALLOW_SERVER_URI=http://58.68.224.134/hosts.allow
TEMPLATE_IMG_GZ=ubuntu_14.04_template.img.gz
TEMPLATE_IMG=ubuntu_14.04_template.img
HOSTS_ALLOW=hosts.allow

VMDIR=/data/xen/
HOSTNAME=CNC-BJ-MOP-100
DISPLAY_NAME=$HOSTNAME
PHY_DISK=/dev/sdb
BRIDGE_NAME=xenbr0

ETH0=192.168.100.122
NETMASK=255.255.0.0
GATEWAY=192.168.100.1
NAMESERVERS=8.8.8.8



##########################################################
## Below are static code, please don't modify them

gre_echo()
{
    echo -en "\033[32;49;1m"
    echo -e "$1"
    echo -en "\033[0m"
}


red_echo()
{
    echo -en "\033[31;49;1m"
    echo -e "$1"
    echo -en "\033[0m"
}


function fatal()
{
    red_echo "$1"
    exit 1
}


## Fetch template image and template xml, then unzip them.
function fetch_resources()
{
    if[ ! -f $HOSTS_ALLOW ]; do
        # TODO: md5sum check
        wget -O $TEMPLATE_IMG_GZ $SERVER_URL$TEMPLATE_IMG_GZ  ||   fatal "download fail"
        gzip -dc $TEMPLATE_IMG_GZ > $TEMPLATE_IMG      || fatal "unzip fail"

        wget -O $HOSTS_ALLOW  $HOSTS_ALLOW_SERVER_URI   || fatal "download host.allow fail"

    done

}


## Make sure the host environment are ready
function init_host_machine() {

    /etc/init.d/libvirtd start
    chkconfig --level 35 libvirtd on
}


## copy images from template name to realname
## $1: display name
function copy_images()
{
    cp $TEMPLATE_IMG $1.img
}


## modify config file
## $1: display name
function create_conf()
{
    local vm_xml=$1.xml
    local vm_name=$1

    local disk_str="--disk path=$VMDIR/$1.img "
    disk_str+="--disk path=$PHY_DISK "

    virt-install --connect=xen  \
                 --name=$vm_name \
                 --ram=8096 --vcpus=4 --arch=x86_64  --hvm  \
                 --import  $disk_str     \
                 --network bridge:$BRIDGE_NAME \
                 --noreboot --vnc \
        || fatal "virt-install failed!"

}


## modify files in VM.
## $1: display name
function modify_vm_fs()
{
    local vm_img=$1.img
    local hostname=$HOSTNAME
    local eth0=$ETH0
    local netmask=$NETMASK
    local gateway=$GATEWAY
    local nameservers=$NAMESERVERS

    ## mount images
    mkdir -p /mnt
    local sectorSize=$(parted $vm_img unit s print | awk '/Sector size/{print $4}' | awk -F "B" '{print $1}')
    local sst=$(parted $vm_img unit s print | awk '/ 1  /{print $2}')
    local startSector=${sst:0:${#sst}-1}
    local offSet=$(($startSector*$sectorSize))
    echo "$offSet"
    mount -o loop,offset=$offSet $vm_img /mnt/   || fatal "mount failed"

    ## hostname
    echo $hostname > /mnt/etc/hostname

    ## network
    local ether_str="iface eth0 inet static\n"
    ether_str+="address $eth0\n"
    ether_str+="netmask $netmask\n"
    ether_str+="gateway $gateway\n"
    ether_str+="dns-nameservers $nameservers\n"

    sed -i -e "s/iface eth0 inet dhcp/$ether_str/g" /mnt/etc/network/interfaces

    ## hosts.allow
    cp $HOSTS_ALLOW  /mnt/etc/hosts.allow
    chmod 644 /mnt/etc/hosts.allow
    chattr +i /mnt/etc/hosts.allow

    ## auto-format diskette, and fstab
    # TODO: Thomas don't know how to do it by now.


    ## umount
    umount /mnt
}


function set_autostart()
{
    virsh autostart $1  || fatal "set autostart fail"
}

function start_vm()
{
    virsh start $1      || fatal "start fail"
}

function main()
{
    cd $VMDIR  ||   fatal "you don't have dir $VMDIR"

    fetch_resources;

    #init_host_machine;


    ## TODO: create multi VMs in a for loop.
    copy_images $DISPLAY_NAME
    create_conf $DISPLAY_NAME

    modify_vm_fs $DISPLAY_NAME

    set_autostart $DISPLAY_NAME

    start_vm $DISPLAY_NAME


}

main

