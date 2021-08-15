# crypto_homes

See my video tutorial/demo on this here: https://tube.tchncs.de/w/cssAP6Syz9vUduCv99ExLN

Right now you can find crypto_homes for download at: http://gg6zxtreajiijztyy5g6bt5o6l3qu32nrg7eulyemlhxwwl6enk6ghad.onion/RightToPrivacy/crypto_homes

make_vol command creates usb key + encrypted sdcard (/home) (luks) + adds to mount at boot.

After running make_vol, simply insert your crypto_homes created usbstick key and boot with the sdcard.

Made with Pinephone/Pinetab setup in mind but can be used for other Linux device setups as well.

## About: 
Ever thought about the benefits of compartmentalization? Such as additional encrypted "homes" (removable/storable) sdcards in addition to your interal storage home directory (giving you chance to switch back/forth between 'homes')? 

Allowing you to create a "work" home encrypted sdcard environment, a "personal" encrypted home (environment sdcard) where you can make it to your liking possibly used for things like banking, accounts, and maybe a security encrypted home sdcard where compartmentalizing the encrypted sdcard home is a preference? 

How about creating a usb key (out of any blank usbstick) compartmentalized away from your device for additional security (say you are a journalist, if you turn off the phone without usb stick (and have deleted the password key- optional)? Well, without the usb stick the phone is not going to unlock.

NOTE: At this time it still adds a password of your choice and does not delete this password - you can easily do this if you choose. I leave this up to the user as it can be important for some to have that backup password in case anything happened to their usb stick.

That's the idea behind this concept. To allow secure storage and as many compartmentalizable, customized home sdcards as you would like to make, without going through all the work of doing so by hand. In this way you can not only extend your internal storage but also create entirely different Home environments, depending on the occasion/security needs.

### SUGGESTED TO BACK UP FIRST IN CASE YOU ENTER BLOCK/DISC DEVICE NAMES WRONG- If done right your original home will still exist on the internal storage and can easily be switched by commenting out fstab/crypttab

Something in the works (functional- still backup) currently found at: http://gg6zxtreajiijztyy5g6bt5o6l3qu32nrg7eulyemlhxwwl6enk6ghad.onion/RightToPrivacy/crypto_homes

### Will be uploading it here on Github (soon) 

### What does it do?

First asks a few questions to set variables specific to your OS/setup: your format type (ex: ext4, f2fs), usbdisk device, sdcard device, choice of encryption cipher (with examples). 

### It then offers (a menu) a few options:

1) Disk wipe (overwrite disk with /dev/urandom)- note: flash type memory may need manufacture for a 'true' wipe.

2) Make Volume: creates copy of your internal emmc $HOME and encrypts this copy on sdcard + adds mounting to boot and makes your plugged in USB stick into a hardware key for mounting that home sdcard. Giving opportunity to make as many home sdcards as you want for differing purposes.

More coming.
-----------------------------

Learn more with additional tutorials on my public blog: https://www.buymeacoffee.com/politictech/posts

And at my video channel mirrors:

https://odysee.com/@RTP
https://www.youtube.com/c/RTPPrivacyTechTips

