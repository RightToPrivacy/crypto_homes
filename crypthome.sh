#!/bin/bash
#
# create encrypted sdcard /home dir's, + turn usbstick into their hardware key
#
# Problem? File an issue (Git)
#
# Question? Leave as a comment on one of the pages anywhere
# under 'MY LINKS' listed below:
#
# ***BACK UP FIRST IF YOU DON'T KNOW WHAT YOU ARE DOING ;)***
# -RTP
#
# Especially for Linux devices like Pinephone/Pinetab (should work for other systems as this uses underlying
# Linux infrastructure common to most distros). Back up recommended in case you mess up.
#
# * make_vol leaves original /home directory in case you want to switch back anytime,
#   simply comment out the fstab/crypttab changes to revert back :)
#
# MY LINKS:
#
# WRITINGS/VIDEO:
# BLOG: https://www.buymeacoffee.com/politictech/posts
# BACKUP BLOG: https://politictech.wordpress.com
#
# VIDEOS:
# PEERTUBE CHANNEL: https://tube.tchncs.de/video-channels/privacy__tech_tips/videos
# ODYSEE CHANNEL: https://odysee.com/@RTP
#
#
# SUPPORT CONTENT/DONATIONS:
#
# BMAC: https://www.buymeacoffee.com/politictech
# CASHAPP: https://cash.app/$HumanRightsTech
# MONERO:48qtspi5En44mJZLeiMoHYFEmuJfQYb5DLQxLDr7d1NXc53XaAvoT8PS3wBrhEc3VY1wxu5Rgw6oKBYgahpSAYnpHntbQNM
#
#



# VARIABLES
# * Device locations will be set during running (added this in)
sddev='mmcblk0'                 # *prompt will fill these in for you*
#disklocation='/dev/'$sddev     # SDCARD (for keyfile)! - created in set_vars function
username='user'	                # user directory/name
# crypt_type="vcrypt"           # luks (most kernels)
overwrite='/dev/urandom'        # overwrite data
usbmount='/mnt/usb'             # keyfile location
cryptmount='/mnt/home'		# mount location for unlocked disk
fstype='f2fs'                   # Your choice: ext4, f2fs filesystem (f2fs can be faster on flash)
usbdisk='/dev/sda'              # Your usb disk location (use lsblk)
cipher='aes-xts-plain64'        # aes, twofish, etc (make sure your kernel supports it)
editor='nano -l '		# change this to your preferred editor command (ie: vim)
# not forcing anyone to use vim unless they like to. :-P


# COLORS
export CYAN='\033[1;36m'
export GREEN='\033[1;92m'
export RED='\033[1;91m'
export WHITE='\033[1;37m'
export ENDCOLOR='\033[1;00m'

# PROMPT COLOR
red=$'\e[31m';
grey=$'\e[37m';
purple=$'\e[38;5;0;1;48;5;92m';
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
echo -e "${RED}make_vol ${CYAN}will automate creation of new booting encrypted \$HOME disks and hardware key: for individual workspace disks.${ENDCOLOR}"

logo='''

                 ╔╗         ╔╗                  
                ╔╝╚╗        ║║                  
╔══╗╔═╗╔╗ ╔╗╔══╗╚╗╔╝╔══╗    ║╚═╗╔══╗╔╗╔╗╔══╗╔══╗
║╔═╝║╔╝║║ ║║║╔╗║ ║║ ║╔╗║    ║╔╗║║╔╗║║╚╝║║╔╗║║══╣
║╚═╗║║ ║╚═╝║║╚╝║ ║╚╗║╚╝║    ║║║║║╚╝║║║║║║║═╣╠══║
╚══╝╚╝ ╚═╗╔╝║╔═╝ ╚═╝╚══╝    ╚╝╚╝╚══╝╚╩╩╝╚══╝╚══╝
       ╔═╝║ ║║                                  
       ╚══╝ ╚╝                                  

righttoprivacy[at]tutanota.com
'''

echo -e "${GREEN}$logo${ENDCOLOR}"

# SET VARIABLES
echo -e "\n${CYAN}Let's set some variables...${ENDCOLOR}\n"
echo -e "${CYAN}Please ensure to have sdcard and usbstick plugged in. Reading devices in 5sec...${ENDCOLOR}"
sleep 5
echo -e "${CYAN}\nListing block devices...\n${ENDCOLOR}"
lsblk 
echo -e "\n"
read -p $'\e[36mWhich is your desired keyfile disk?\e[0m (ex: /dev/sda) ' usbdisk
read -p $'\e[36mDesired encrypted storage $HOME device inside /dev/ directory?\e[0m (ex: mmcblk0) ' sddev
read -p $'\e[36mChoose Filesystem Format\e[0m (ex: f2fs or ext4)): ' fstype
read -p $'\e[36mChoose encryption cipher\e[0m (ex: aes-xts-plain64): ' cipher
read -p $'\e[36mWhat user are we creating a new encrypted home for\e[0m: ' username
echo -e "\n"
sleep .5
disklocation='/dev/'$sddev      # Save disklocation + sddev for UUID grab
echo -e "${CYAN}Keyfile stick for unlocking set to ${RED}$usbdisk.${ENDCOLOR}\n" && sleep 1
echo -e "${CYAN}Encrypted storage device desired set to ${RED}$sddev.${ENDCOLOR}\n" && sleep 1
echo -e "${CYAN}Filesystem set to ${RED}$fstype.${ENDCOLOR}\n" && sleep 1
echo -e "${CYAN}Encryption set to ${RED}$cipher.${ENDCOLOR}\n" && sleep 1
echo -e "${CYAN}Set work on encrypted \$HOME for${ENDCOLOR} ${RED}$username${ENDCOLOR}\n" && sleep 1
echo '--------------------------------------------------'

# CHECK / SETUP INITIAL DISK / MOUNT LOCATION

# CHECK IF MOUNT EXISTS, MAKE FILESYSTEM ON DISK
if [ ! -d  "${usbmount}" ]; then
	echo -e "${CYAN}Creating mountpoint for hardware key...${ENDCOLOR}" && sleep 1
	mkdir -p ${usbmount}
	mount ${usbdisk} ${usbmount}
fi

if [ ! -d "${cryptmount}" ]; then
	echo -e "${CYAN}Creating mountpoint for crypto_home...${ENDCOLOR}" && sleep 1
	mkdir -p ${cryptmount}
fi


# MAKE KEY FUNCTION [ CHECKS FOR CURRENT KEYFILE / MOUNT 
# CREATES MOUNTPOINT IF NOT EXIST + MAKE FS FOR KEYDISK
make_key () {

	# CHECK IF MOUNT EXISTS, MAKE FILESYSTEM ON DISK
        if [ ! -f  "$usbmount/unlock" ]; then
                echo -e "${CYAN}Keyfile no exit...${ENDCOLOR}" && sleep 1
                #mkdir $usbmount
                mkfs.$fstype -f $usbdisk || { 
                        echo -e"${RED}mkfs.$fstype failed.${ENDCOLOR}"; 
                        exit 2;
                }
        
		mount $usbdisk -t $fstype $usbmount || { 
                        echo -e "${RED}mounting $usbdisk failed.${ENDCOLOR}\n"; 
                        exit 2;
                }
        
		echo -e "\n"
        fi

	# CHECK FOR KEYFILE CREATE OTHERWISE
	echo "Ensuring keyfile will not be overwritten..."

        if [ -f $usbmount/unlock ]; then
                echo -e "${RED}Keyfile already exists. Exiting.${ENDCOLOR}"
                exit 1
        fi

        echo -e "Ready to create.\n" && sleep 1


        touch $usbmount/unlock || { 
                echo -e "${RED}file creation failed.${ENDCOLOR}"; 
                exit; 
        }
        
	echo "Creating randomized Keyfile at: $usbmount/unlock.\n"
        dd if=$overwrite of=$usbmount/unlock bs=1024 count=4 status=progress || { 
		echo -e "${RED}Failed keyfile creation.${ENDCOLOR}" 
		exit; 
	}
        
	echo "Done."
        echo ' '
        echo -e "Setting permissions...\nSetting chmod 400 on keyfile: $usbmount/unlock..."
        sleep 1
        echo ''
        chmod 400 $usbmount/unlock
        echo "Keyfile finished: "
        echo ' '
        echo -e "Displaying bottom end of Keyfile to confirm existence: \n"
        echo ' '
        tail -5 $usbmount/unlock
        echo ' '

}

## CLEAN SDCARD: OVERWRITE RANDOM DATA # optional- depends on disk type 
## (NOTE: flash memory can require manufacture wipe for full clearance)
##
diskwipe () {

        read -p 'Which disk would you like to overwrite with random data? ' ow_choice
        echo -e "       $usbdisk\n"
        echo -e "       $disklocation\n"
        sleep 2
        echo "Overwriting $ow_choice using $overwrite..." && sleep 2
        dd if=$overwrite of=$ow_choice bs=4M status=progress && { 
		echo -e "{CYAN}OVERWRITE COMPLETE.${ENDCOLOR}\n"
	}
}
################# END DISK WIPE ##################

# CREATE HOME VOLUME ON SDCARD DISK + HARDWARE KEY (OUT OF STANDARD USB STICK OR SDCARD)
make_vol () {

        echo -e "${WHITE}Hit ctrl+c to ${RED}exit${ENDCOLOR} ${WHITE}now (5sec wait).${ENDCOLOR}"
        echo ''
        sleep 5
	echo -e "${CYAN}Time to create a new $username encrypted home dir on our disk...${ENDCOLOR}\n"
        ###echo -e "We will copy home dir to /tmp/$username \nMaking tmp directory backup...\n"
        echo -e "The root dir will still contain the home folder if the sdcard is hashed out on fstab/crypttab.\n"
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
        fi

        # open encrypted volume actions here
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
                        echo -e "${RED}mkfs.$fstype on $usbdisk failed.${ENDCOLOR}";
                        exit 2;
                }
                mount $usbdisk -t $fstype $usbmount || {
                        echo -e "${RED}mounting $usbdisk failed.${ENDCOLOR}\n";
                        exit 2;
                }
                echo -e "\n"
        fi

        touch $usbmount/unlock || {
                echo -e "${RED}touch keyfile creation failed.${ENDCOLOR}"; 
                exit 2;
        }
        echo -e "${CYAN}Writing Keyfile in $usbmount/unlock.${ENDCOLOR}\n"
        dd if=$overwrite of=$usbmount/unlock bs=1024 count=4 status=progress || { 
                echo -e"${RED}Failed keyfile writing.${ENDCOLOR}"; 
                exit; 
        }

	echo -e "${WHITE}Done.${ENDCOLOR}"
###############################################################################

        # TEST IF KEYFILE EXISTS - IF EXISTS ADD KEYFILE AS UNLOCK KEY
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

####### BEGIN ADDING NEW HOME TO BOOT #######
        echo -e "${CYAN}Getting UUID to accomodate crypttab...${ENDCOLOR}\n" && sleep 3
        #UUID=$(blkid -o value -s UUID) # get UUID
        # Grab UUID (sdcard) for use
        UUID=$(lsblk -f | grep $sddev | awk '{print $4}')

        # BACKUP / EDIT CRYPTTAB
        echo -e "${CYAN}Backing up crypttab to crypttab.bak...${ENDCOLOR}\n" && sleep .5
        cp /etc/crypttab /etc/crypttab.bak
        echo -e "${CYAN}Adding new sdcard to crypttab...${ENDCOLOR}\n" && sleep .5
        echo "crypto_home /dev/disk/by-uuid/$UUID $usbmount/unlock luks,timeout=45" >> /etc/crypttab

        # BACKUP FSTAB FIRST
        echo -e "${CYAN}Backing up fstab to fstab.bak...${ENDCOLOR}\n" && sleep .5
        cp /etc/fstab /etc/fstab.bak

        # ADD LINES TO FSTAB
        echo -e "${CYAN}Adding usb stick to boot for mounting keyfile...${ENDCOLOR}\n" && sleep .5
        #echo "$usbdisk  $usbmount  auto" >> /etc/fstab
        echo "$usbdisk $usbmount $fstype auto 0 2" | cat - /etc/fstab > tmp && mv tmp /etc/fstab
        echo -e "${CYAN}Adding sdcard to fstab boot...${ENDCOLOR}\n" && sleep .5
        echo "/dev/mapper/crypto_home /home $fstype defaults 0 2" >> /etc/fstab

        # MOUNT SDCARD TO HOME
        echo -e "${CYAN}Mounting encrypted sdcard to home...${ENDCOLOR}\n" && sleep .5
        sudo mount -t $fstype /dev/mapper/crypto_home /home || {
		echo -e "${RED}Mounting crypto_home on /home FAILED! Exiting.${ENDCOLOR}\n" && sleep .5
		exit;
	}

	# CREATE NEW HOME DIR ON ENCRYPTED DISK
	echo -e "${CYAN}Creating new encrypted HOME for $username...${ENDCOLOR}\n"
	sleep .5
	mkhomedir_helper $username 
        echo -e "${GREEN}Process Finished. Welcome \$HOME. Mounted and ready for use.${ENDCOLOR}\n"
	df -h
}

# OPEN VOLUME FOR VIEWING / EDITING
open_vol () {
        echo "Opening $disklocation..."
        cryptsetup luksOpen --key-file $usbmount/unlock $disklocation crypto_home
	mount /dev/mapper/crypto_home $cryptmount || {
		echo -e "${RED}FAILED TO MOUNT AT $cryptmount${ENDCOLOR}\n"
	}
	echo -e "${CYAN}VIEWING MOUNTED DISKS:${ENDCOLOR}\n"
	df -h
	echo -e "${CYAN}You May Now View / Edit Any Changes You Like To crypto_home Files At: ${cryptmount}${ENDCOLOR}\n"
}

# CLOSE VOLUME
close_vol () {
	umount /dev/mapper/crypto_home
        cryptsetup -v luksClose crypto_home && {
		echo -e "${CYAN}CLOSED crypto_home.${ENDCOLOR}\n"
		echo -e "${CYAN}CURRENTLY MOUNTED DISKS:${ENDCOLOR}\n"
		df -h
	}
}

edit_boot () {
	echo -e "${CYAN}NOW OPENING /etc/fstab IN${ENDCOLOR} ${RED}$editor${ENDCOLOR}\n"
	sleep 1 && echo -e "${CYAN}TO REVERT TO ORIGINAL HOME: PLACE HASH MARK IN FRONT OF DISK YOU DO NOT WANT BOOTING...${ENDCOLOR}\n"
	sleep 1
	echo -e "${CYAN}OR SIMPLY COPY BACKUP FILES: /etc/fstab.bak TO: /etc/fstab AND /etc/crypttab.bak TO: /etc/crypttab${ENDCOLOR}\n" 
	sleep 1
	echo -e "${CYAN}COPYING THE ABOVE BACKUPS TO ORIGINAL LOCATION WILL REVERT TO PREVIOUS \$HOME BOOT...${ENDCOLOR}\n"
	sleep 3
	$editor /etc/fstab
	echo -e "${CYAN}NOW OPENING /etc/crypttab IN${ENDCOLOR} ${RED}$editor${ENDCOLOR}${ENDCOLOR}\n" && sleep 1
	$editor /etc/crypttab
	echo -e "${GREEN}DONE.${ENDCOLOR}\n"
}

revert_boot () {
	echo -e "${CYAN}This option is for reverting boot changes back to prior.${ENDCOLOR}\n"
	sleep 1
	echo -e "${CYAN}HOW: ${GREEN}make_vol ${CYAN}backs up your original \$HOME fstab crypttab files...${ENDCOLOR}\n"
	sleep 1
	echo -e "${CYAN}revert_boot moves those backups back into original place cancelling automatic boot into crypto_homes disk...${ENDCOLOR}\n"
	sleep 1
	read -p "ARE YOU SURE YOU WISH TO CONTINUE (Y/N)? " revertans

	if [ "$revertans" == "y" ] || [ "$revertans" == "Y" ] || [ "$revertans" == "YES" ] || [ "$revertans" == "yes" ]
	then
		echo -e "${CYAN}ANSWERED ${GREEN}YES${ENDCOLOR}\n" && sleep 1
		echo -e "${CYAN}RESTORING BACKUP CONF FILES...${ENDCOLOR}\n"
		cp /etc/fstab.bak /etc/fstab && cp /etc/crypttab.bak /etc/crypttab
		echo -e "${GREEN}DONE.${ENDCOLOR}\n" && sleep .5
		echo -e "${CYAN}IF "	
}

# MAIN MENU
menu () {
	echo ' '
	echo -e "${WHITE}MENU:\n${ENDCOLOR}"
	echo -e "${CYAN}NOTE: make_vol has been tested. Stay updated at Gitea Onion / Blog.${ENDCOLOR}\n"
	echo -e "\n"
	echo -e ">> ${WHITE}diskwipe ${ENDCOLOR}(Overwrite with random data)"
#	echo -e ">> ${WHITE}make_key ${ENDCOLOR}(create hardware key using /dev/urandom & USB stick"
	echo -e ">> ${WHITE}make_vol ${ENDCOLOR}(convert home directory to encrypted sdcard with usbstick as hardware key)"
	echo -e ">> ${WHITE}open_vol ${ENDCOLOR}(OPTION: open crypto_homes volume)"
	echo -e ">> ${WHITE}close_vol ${ENDCOLOR}(OPTION: close open crypto_homes volume)"
	echo -e ">> ${WHITE}edit_boot ${ENDCOLOR}(edit fstab crypttab to revert / change next boot)"
	#echo -e ">> ${WHITE}revert_boot ${ENDCOLOR}revert boot to prior \$HOME"
	echo '________________________________________________________________________________'
	echo -e "\n"
	sleep 1.5

}

# MAIN LOOP
while :
do
        echo -e "${CYAN}Type 'menu' for menu. Type 'exit' to exit.${ENDCOLOR}"
        echo ' '
        read -p "${purple}crypto_homes>${nocolor} " cmd
        $cmd
	sleep .5
done
