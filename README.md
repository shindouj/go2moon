# go2moon

Find a quick installation tutorial here: https://guides.jeikobu.net/go2rtc/

This project aims to make updating go2rtc painfully easy on 3D printers. This project **does not** 
offer any new features for go2rtc and does not supersede any existing installations. 

The automated action here:

- downloads the newest available release of go2rtc,
- adds a manifest file with the version number,
- packs it up into a ZIP and uploads a release.

With all that, updating go2rtc is as easy as clicking "Update" in your Mainsail or Fluidd instance.

On top of that, the install.sh script automates downloading the newest release, unpacks it, 
sets up a system service, and adds a record to moonraker.conf.


## Why not the 'executable' updater type in Moonraker?

Easy. It seems to be completely unsupported by both Mainsail and Fluidd. Moonraker updates it just fine 
when manually making a REST call for update, but you won't see the version in your frontend.

## Copyright notice

Licensed under GPLv3. 

Uses portions of code from [klippain-shaketune](https://github.com/Frix-x/klippain-shaketune/blob/main/install.sh) install script.
Uses portions of code from [klipper](https://github.com/Klipper3d/klipper/blob/master/scripts/install-debian.sh) install script.
