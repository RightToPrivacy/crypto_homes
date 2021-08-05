# crypto_homes
Made for adding/creating encrypted sdcard /home (luks) + turns usb stick into hardware key.

With Pinephone/Pinetab setups in mind.

## About: 
Ever thought about the benefits of compartmentalization? Such as encrypted "homes" (removable/storable) sdcards separate from your interal storage? Allowing you to create a "work" home encrypted sdcard, maybe a security one where compartmentalizing the encrypted sdcard home is a preference? 

How about a usb key compartmentalized away from your device for additional security? 

This is the idea behind this. To allow secure storage and as many customized home sdcards as you would like to make, without going through all the work by hand.

### SUGGESTED TO BACK UP FIRST IN CASE YOU ENTER BLOCK/DISC DEVICE NAMES WRONG- If done right your original home will still exist on the internal storage and can easily be switched by commenting out fstab/crypttab

Something in the works (functional- still backup) currently found at: http://gg6zxtreajiijztyy5g6bt5o6l3qu32nrg7eulyemlhxwwl6enk6ghad.onion/RightToPrivacy/crypto_homes

### Will be uploading it here on Github (soon) once I finishing more testing/editing.

### What does it do?

First asks a few questions to set variables specific to your OS/setup: your format type (ex: ext4, f2fs), usbdisk device, sdcard device, choice of encryption cipher (with examples). 

### It then offers (a menu) a few options:

1) Disk wipe (overwrite disk with /dev/urandom)- note: flash type memory may need manufacture for a 'true' wipe.

2) Make Key (Makes (currently) plugged in USB stick into a hardware keyfile storage disk using format of choice).

3) Make Volume: backs up your $HOME user directory to /tmp/$username (NOTE: was made for a Pinephone/pinetab and atm variable depends on single username under /home)

 After coping home user dir to /tmp make_vol then creates a LUKS home dir, adding the hardware keyfile for unlocking.
 
 After this it adds to the boot (crypttab/fstab) to allow unlocking of $HOME directory with the usb stick.
 
 It mounts and copies home dir back onto the newly created home directory sdcard.
 
 At this point booting to mount the sdcard home directory will require the usb key (password for a backup- you can delete this but not suggested).
 
 4) Open Volume: Opens the volume (optional addition)
 
 5) Close volume: closes open volume (optional setting)

-----------------------------

Learn more with additional tutorials on my public blog: https://www.buymeacoffee.com/posts

And at my video channel mirrors:

https://odysee.com/@RTP
https://www.youtube.com/c/RTPPrivacyTechTips

