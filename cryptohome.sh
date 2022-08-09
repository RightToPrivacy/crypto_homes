#!/bin/bash
#
# create encrypted sdcard /home dir's, + turn usbstick into their hardware key
#
# Problem? File an issue (Git)
#
# Question? Leave as a comment on one of the pages anywhere
# under 'MY LINKS' listed below:
#
# ***BACK UP FIRST*** (anytime running something making system changes)
# -RTP
#
# Tested on Pinetab/Pinephone Mobian/Arch
#
# * make_vol leaves original /home directory in case you want to switch back anytime,
#   simply comment out the fstab/crypttab changes to revert back :)
#
# MY LINKS:
#
# PUBLIC WRITINGS/VIDEO:
# BLOG: https://www.buymeacoffee.com/politictech/posts
# BACKUP BLOG: https://politictech.wordpress.com
#
# VIDEOS:
#
# PEERTUBE CHANNEL: https://tube.tchncs.de/video-channels/privacy__tech_tips/videos
# ODYSEE CHANNEL: https://odysee.com/@RTP
# YOUTUBE: 
#
#
# SUPPORT:
#
# BMAC: https://www.buymeacoffee.com/politictech
# CASHAPP: https://cash.app/$HumanRightsTech
# XMR:48qtspi5En44mJZLeiMoHYFEmuJfQYb5DLQxLDr7d1NXc53XaAvoT8PS3wBrhEc3VY1wxu5Rgw6oKBYgahpSAYnpHntbQNM
#



# VARIABLES
# * Device locations will be set during running (added this in)
sddev='mmcblk0'                 # *prompt will fill these in for you*
#disklocation='/dev/'$sddev     # SDCARD (for keyfile)! - created in set_vars function
username=$(ls /home)            # user directory/name
# crypt_type="vcrypt"           # luks (most kernels)
overwrite='/dev/urandom'        # overwrite data
usbmount='/mnt/usb'             # keyfile location
fstype='f2fs'                   # Your choice: ext4, f2fs filesystem (f2fs can be faster on flash)
usbdisk='/dev/sda'              # Your usb disk location (use lsblk)
cipher='aes-xts-plain64'        # aes, twofish, etc (make sure your kernel supports it)


# COLORS
export CYAN='\033[1;36m'
export GREEN='\033[1;92m'
export RED='\033[1;91m'
export WHITE='\033[1;37m'
export ENDCOLOR='\033[1;00m'

# PROMPT COLOR
red=$'\e[31m';
grey=$'\e[37m';
nexc=$'\e[33m';
nocolor=$'\e[0m';

# ENSURING ROOT PRIV

if [ $EUID == 0 ]; then
        echo -e "${CYAN}Required privileges ${RED}confirmed. ${CYAN}Continuing...${ENDCOLOR}"
else
        echo -e "${RED}sudo ${CYAN}or ${RED}root ${CYAN}required. Exiting.${ENDCOLOR}"
        exit;
fi

### WARNING ACTIVELY BEING EDITED - QUESTION TO KEEP USERS SAFE -THIS WILL BE REMOVED WHEN READY

#echo -e "${CYAN}THIS IS ${RED}ACTIVELY ${CYAN}BEING EDITED (THIS WARNING WILL BE REMOVED WHEN COMPLETE).${ENDCOLOR}\n\n"
echo -e "${RED}make_vol ${CYAN}has been tested to create copy + encrypted microsdcard mounted as home for individual workspace disks.${ENDCOLOR}"

logo='''

                 ╔╗         ╔╗                  
                ╔╝╚╗        ║║                  
╔══╗╔═╗╔╗ ╔╗╔══╗╚╗╔╝╔══╗    ║╚═╗╔══╗╔╗╔╗╔══╗╔══╗
║╔═╝║╔╝║║ ║║║╔╗║ ║║ ║╔╗║    ║╔╗║║╔╗║║╚╝║║╔╗║║══╣
║╚═╗║║ ║╚═╝║║╚╝║ ║╚╗║╚╝║    ║║║║║╚╝║║║║║║║═╣╠══║
╚══╝╚╝ ╚═╗╔╝║╔═╝ ╚═╝╚══╝    ╚╝╚╝╚══╝╚╩╩╝╚══╝╚══╝
       ╔═╝║ ║║                                  
       ╚══╝ ╚╝                                  
'''

echo -e "${GREEN}$logo${ENDCOLOR}"

# SET VARIABLES
set_vars () {

        echo -e "\n${CYAN}Let's set some variables..."
        echo -e "\n${ENDCOLOR}"
        echo -e "${CYAN}Please ensure to have sdcard and usbstick plugged in. Reading devices in 5sec...${ENDCOLOR}"
        sleep 5
        echo -e "${CYAN}\nListing block devices...\n${ENDCOLOR}"
        lsblk 
        echo -e "\n"
#$'\e[31mFoobar\e[0m: '
        read -p $'\e[36mWhich is your usb stick?\e[0m (ex: /dev/sda) ' usbdisk
        read -p $'\e[36msdcard device inside /dev/ directory?\e[0m (ex: mmcblk0) ' sddev
        read -p $'\e[36mChoose Filesystem Format\e[0m (ex: f2fs or ext4)) ' fstype
        read -p $'\e[36mChoose encryption cipher\e[0m (ex: aes-xts-plain64): ' cipher
        echo -e "\n"

        sleep .5
        disklocation='/dev/'$sddev      # Save disklocation + sddev for UUID grab
        echo -e "${CYAN}USB stick set to ${RED}$usbdisk.${ENDCOLOR}\n" && sleep 1
        echo -e "${CYAN}sdcard device set to ${RED}$sddev.${ENDCOLOR}\n" && sleep 1
        echo -e "${CYAN}Filesystem set to ${RED}$fstype.${ENDCOLOR}\n" && sleep 1
        echo -e "${CYAN}Encryption set to ${RED}$cipher.${ENDCOLOR}\n" && sleep 1
        echo '--------------------------------------------------'

}

make_key () {

        echo "Ensuring a keyfile will not be overwritten..."

        if [ -f $usbmount/unlock ]; then
                echo -e "${RED}Keyfile already exists. Exiting.${ENDCOLOR}"
                exit 1
        fi

        echo -e "Ready to create.\n" && sleep 1

        if [ ! -f  $usbmount ]; then
                echo -e "${CYAN}Creating mountpoint, filesystem...${ENDCOLOR}" && sleep 1
                mkdir $usbmount
                mkfs.$fstype -f $usbdisk || { 
                        echo -e"${RED}mkfs.$fstype failed.${ENDCOLOR}"; 
                        exit 2;
                }
                mount $usbdisk -t $fstype $usbmount || { 
                        echo -e "mkfs failed.\n"; 
                        exit 2;
                }
                echo -e "\n"
        fi

        touch $usbmount/unlock || { 
                echo "file creation failed."; 
                exit; 
        }
        echo "Creating randomized Keyfile at: $usbmount/unlock.\n"
        dd if=$overwrite of=$usbmount/unlock bs=1024 count=4 status=progress || { echo "Failed keyfile creation."; exit; }
        echo "Done."
        echo ' '
        echo -e "Setting permissions...\nSetting chmod 400 on keyfile: $usbmount/unlock..."
        sleep 1
        echo ''
        chmod 400 $usbmount/unlock
        echo "Keyfile finished: "
        echo ' '
        echo "Displaying end of Keyfile to confirm:"
        echo ' '
        tail -5 $usbmount/unlock
        echo ' '

}
## CLEAN SDCARD: OVERWRITE RANDOM DATA # optional- depends on disk type 
## (NOTE: flash memory can require manufacture wipe for full clearance)
## encrypting *from* separate storage to flash is ideal (when flash memory)
##
diskwipe () {

        read -p 'Which disk would you like to overwrite random data ' ow_choice
        echo -e "       $usbdisk\n"
        echo -e "       $disklocation\n"
        sleep 2
        echo "Overwriting $ow_choice using $overwrite..." && sleep 2
        dd if=$overwrite of=$ow_choice bs=8M status=progress

}


# CREATE THE HOME VOLUME ON SDCARD DISK
#create volume: zuluCrypt-cli -c -d /dev/sdc1 -z ext4 -t luks -p xxx
make_vol () {

        echo -e "${WHITE}Hit ctrl+c to ${RED}exit${ENDCOLOR} ${WHITE}now (5sec wait).${ENDCOLOR}"
        echo ''
        sleep 5
        echo -e "We will copy home dir to /tmp/$username \nMaking tmp directory backup...\n"
        echo -e "The root dir will still contain the home folder if the sdcard is hashed out on fstab/crypttab.\n"
        mkdir /tmp/$username
        sudo rsync -azv --progress /home/$username/ /tmp/$username/
        #  Done Directory Backup Of Home

        # One last question to make sure
        echo -e "${CYAN}Making ${RED}$cipher ${CYAN}volume at ${RED}$disklocation ${CYAN}of ${RED}$fstype ${CYAN}assigning $usbmount/unlock keyfile...${ENDCOLOR}"
        sleep 2
        read -p 'Are you sure you want to continue (y/n)? ' mv_ques

        if [ "$mv_ques" == 'YES' ] || [ "$mv_ques" == 'yes' ] || [ "$mv_ques" == 'y' ] 
        then

                echo -e "${CYAN}Answered YES. Continuing...\n${ENDCOLOR}" && sleep .5
                echo -e "${CYAN}The password you set here will also be an option for unlocking sdcard...${ENDCOLOR}" && sleep .5
                echo -e "${CYAN}This password key can be deleted later for usbkey only. Though this is ${RED}not ${CYAN}recommended.${ENDCOLOR}\n"
                cryptsetup --cipher $cipher --key-size 512 --hash sha512 -v luksFormat $disklocation || { 
                        echo -e "${RED}luks create vol failed.${ENDCOLOR}"; 
                        exit; 
                }
                #zuluCrypt-cli -c -d $disklocation -z $fstype -t $crypt_type -f $usbmount/unlock
        fi


        #zuluCrypt-cli -c -d $disklocation -z $fstype -t $crypt_type -f $keyfile - do NOT uncomment. *Line not tested*.
        #open_vol

        # open encrypted volume actions here
        #zuluCrypt-cli -o -d $disklocation -m sda -e ro -f $keyfile
        echo -e "${CYAN}Opening $disklocation...${ENDCOLOR}\n" && sleep 5
        cryptsetup luksOpen $disklocation crypto_home || { 
                echo -e "${RED}luksOpen failed. Exiting.${ENDCOLOR}"; 
                exit;
        }

        # Create filesystem
        echo -e "${CYAN}Creating ${RED}$fstype ${CYAN}filesystem format for sdcard...${ENDCOLOR}\n" && sleep 1
        mkfs.$fstype -f /dev/mapper/crypto_home || { 
                echo -e "${RED}Creating $fstype failed. Exiting.${ENDCOLOR}"; 
                exit; 
        }


################################################################################
        # Make/Add The Keyfile/USB


        if [ ! -f  $usbmount ]; then
                echo -e "${CYAN}Creating mountpoint, filesystem...${ENDCOLOR}" && sleep 1
                mkdir $usbmount
                mkfs.$fstype -f $usbdisk || {
                        echo -e "${RED}mkfs.$fstype failed.${ENDCOLOR}";
                        exit 2;
                }
                mount $usbdisk -t $fstype $usbmount || {
                        echo -e "${RED}mkfs failed.${ENDCOLOR}\n";
                        exit 2;
                }
                echo -e "\n"
        fi

        touch $usbmount/unlock || {
                echo -e "${RED}file creation failed.${ENDCOLOR}"; 
                exit;
        }
        echo -e "${CYAN}Creating Keyfile in $usbmount/unlock.${ENDCOLOR}\n"
        dd if=$overwrite of=$usbmount/unlock bs=1024 count=4 status=progress || { 
                echo -e"${RED}Failed keyfile creation.${ENDCOLOR}"; 
                exit; 
        }
        echo -e "${WHITE}Done.${ENDCOLOR}"

###############################################################################

        # test if keyfile was created/exists; if not, exit.
        if test -f "$usbmount/unlock"; then
                echo -e "${CYAN}$usbmount/unlock exists.${ENDCOLOR}"
                echo -e "${CYAN}Adding key.${ENDCOLOR}\n" && sleep 1
                cryptsetup luksAddKey $disklocation $usbmount/unlock || { 
                        echo -e "${RED}FAILED TO ADD KEYFILE. CHECK FOR EXISTENCE. EXITING.${ENDCOLOR}"; 
                        exit 1; 
                }
        else
                echo -e "${RED}There is no keyfile! Check your USB.${ENDCOLOR}";
                exit;
        fi

####### END OF MAKING KEYFILE #############

        echo -e "${CYAN}Getting UUID to accomodate crypttab...${ENDCOLOR}\n" && sleep 3
        #UUID=$(blkid -o value -s UUID) # get UUID
        # Grab UUID (sdcard) for use
        UUID=$(lsblk -f | grep $sddev | awk '{print $4}')

        # Add to crypttab
        echo -e "${CYAN}Backing up crypttab to crypttab.bak...${ENDCOLOR}\n" && sleep .5
        cp /etc/crypttab /etc/crypttab.bak
        echo -e "${CYAN}Adding new sdcard to crypttab...${ENDCOLOR}\n" && sleep .5
        echo "crypto_home /dev/disk/by-uuid/$UUID $usbmount/unlock luks,timeout=45" >> /etc/crypttab

        # Backup fstab in case
        echo -e "${CYAN}Backing up fstab to fstab.bak...${ENDCOLOR}\n" && sleep .5
        cp /etc/fstab /etc/fstab.bak

        # Add lines to fstab
        echo -e "${CYAN}Adding usb stick to boot for mounting keyfile...${ENDCOLOR}\n" && sleep .5
        #echo "$usbdisk  $usbmount  auto" >> /etc/fstab
        echo "$usbdisk $usbmount $fstype auto 0 2" | cat - /etc/fstab > tmp && mv tmp /etc/fstab
        echo -e "${CYAN}Adding sdcard to fstab boot...${ENDCOLOR}\n" && sleep .5
        echo "/dev/mapper/crypto_home /home $fstype defaults 0 2" >> /etc/fstab

        # Mount sdcard for rsync transfer
        echo -e "${CYAN}Mounting encrypted sdcard to home...${ENDCOLOR}\n" && sleep .5
        sudo mount -t $fstype /dev/mapper/crypto_home /home

        # Transfer Files
        echo -e "${CYAN}Transferring files to encrypted disk...${ENDCOLOR}\n" && sleep 2
        echo -e "${CYAN}You may find original home dir in the root partition.${ENDCOLOR}"
        rsync -azv --progress /tmp/$username /home/
        echo -e "${WHITE}Process Finished.${ENDCOLOR}\n"
}


# OPEN VOLUME

open_vol () {

        # open the volume actions here
        #zuluCrypt-cli -o -d $disklocation -m sda -e ro -f $keyfile
        echo "Opening $disklocation..."
        cryptsetup luksOpen --key-file $usbmount/unlock $disklocation crypto_home

}

# CLOSE VOLUME

close_vol () {

        # Close volume command here
        #zuluCrypt-cli -q -d $disklocation
        cryptsetup -v luksClose crypto_home
}

# MAIN MENU

menu () {

	echo ' '
	echo -e "${WHITE}MENU:\n${ENDCOLOR}"
	echo -e "${CYAN}NOTE: At this time only make_vol has been tested. Stay updated for changes.${ENDCOLOR}\n"
	echo -e "\n"
	echo -e ">> ${WHITE}diskwipe ${ENDCOLOR}(Overwrite with random data)"
#	echo -e ">> ${RED}[SETTING NOT YET READY]${ENDCOLOR} make_key (create hardware key using /dev/urandom & USB stick"
	echo -e ">> ${WHITE}make_vol ${ENDCOLOR}(convert home directory to encrypted sdcard with usbstick as hardware key)"
#	echo -e ">> ${RED}[SETTING NOT YET READY]${ENDCOLOR} open_vol (OPTION: open encrypted volume)"
#	echo -e ">> ${RED}[SETTING NOT YET READY]${ENDCOLOR} close_vol (OPTION: close open encrypted volume)"
#	echo -e ">> ${RED}[SETTING NOT YET READY]${ENDCOLOR} sdcard_mgmt (Manage multiple encrypted cards- coming in future)"
	echo '________________________________________________________________________________'
	echo -e "\n"
	sleep 1.5

}


# SET DISK DEVICE VARIABLES + PRINT CURRENT MENU
set_vars

menu


# MAIN LOOP

while :
do
        echo -e "${CYAN}Type exit to exit.${ENDCOLOR}"
        echo ' '
        read -p "${grey}crypto_homes> ${nocolor}" cmd
        $cmd
	sleep .5
done
