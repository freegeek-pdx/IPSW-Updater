# IPSW Updater
*Made by Pico Mitchell of [Free Geek](https://www.freegeek.org) using the [IPSW Downloads API](https://ipsw.me) by Callum Jones.*

### Visit [ipsw.app](https://ipsw.app) to [view release notes](https://ipsw.app/download/updates.php) and [download the latest release of the compiled app](https://ipsw.app/download/).

IPSW Updater can batch download all the latest IPSW Firmware files from Apple and place them in the correct iTunes Software Updates or Apple Configurator Firmware folders so that they are automatically found by iTunes/Finder and/or Apple Configurator.

You can set which IPSW Firmware files to download based on versions as well as product types, such as iPhone, iPad, iPod touch, Apple TV, HomePod mini, T2 Mac (iBridge Firmware), and Apple Silicon Mac. You can also set IPSW Updater to run automatically at a scheduled time so that all of your IPSW Firmware files will always be kept up-to-date.

iPhone, iPad, and iPod touch IPSW Firmware files will be stored within iTunes Software Updates folders at `~/Library/iTunes` since they will be found by both iTunes/Finder and Apple Configurator at that location.

Apple TV, HomePod mini, and T2 and Apple Silicon Mac IPSW Firmware files will be stored within the Apple Configurator Firmware folder at `~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Firmware`. This is because unlike iPhone, iPad, and iPod touch IPSW Firmware files, Apple Configurator will not detect or use IPSW Firmware files for Apple TVs or HomePod minis from the iTunes Software Updates folders. Also, T2 and Apple Silicon Macs cannot be restored by iTunes/Finder and can only be restored by Apple Configurator when they are put into DFU mode.

Any IPSW Firmware files that are already in these folders will become managed by IPSW Updater. That means that IPSW Firmware files in these locations will be moved to the Trash (or deleted, based on your settings) when they become out-of-date after an update for them has been downloaded by IPSW Updater. Also, as described above, any iPhone, iPad, and iPod touch IPSW Firmware files that are currently in the Apple Configurator Firmware folder will be moved into their correct iTunes Software Updates folder and any Apple TV or HomePod IPSW Firmware files in the iTunes Software Updates folders will be moved into the Apple Configurator Firmware folder. Finally, any IPSW Firmware files currently in these folders that are out-of-date but are still signed by Apple will be left alone and any that are no longer signed by Apple will be moved to the Trash (or deleted). IPSW Updater will check for unsigned IPSW Firmware files each time it runs, so existing files may be trashed (or deleted) in the future if and when Apple no longer signs them.
