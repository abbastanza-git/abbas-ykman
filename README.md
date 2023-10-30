# abbas-ykman

### Description
This is a script for MacOS to automatically copy your OATH codes from your YubiKey to the clipboard. It uses the YubiKey Manager CLI [ykman](https://docs.yubico.com/software/yubikey/tools/ykman/).

### Usage
If you execute the script, a dialog window pops up and asks you for the account name you would like to get the code of.
You can set your on shortcuts in the *shortcuts* file as shown in the example file *shortcuts-example*.
If the results of your input are ambivalent or no results are found, a window with an error message occurs.

### OS
Since it uses Apple script for the dialog windows you can currently only use it on MacOS.