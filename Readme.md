# DSLR Browser for iOS

[![Build Status](https://travis-ci.org/spikehip/dslrbrowser-ios.svg?branch=master)](https://travis-ci.org/spikehip/dslrbrowser-ios)

Use the DSLR Browser app to discover and connect to your Wi-Fi and DLNA enabled camera and download your photos directly into your iPhone or iPad's Camera Roll via Wi-Fi. 
You can connect to and download images from more than one device at a time. 
You can either select your images one-by-one or opt for a mass download of all images from a certain device.
The app supports primarily the Canon EOS DSLR range and the Canon WFT Wireless Transmitter family.
However with a switch you can enable discovering other vendor's devices as well.   
Tested with the Canon EOS 6d and the Canon EOS 7d equipped with the WFT-E5 transmitter.

## Download 

https://itunes.apple.com/de/app/dslr-browser/id1193690451?l=en&mt=8 


# Testing instuctions

- Select "View images on DLNA devices" in your camera's Wi-Fi function settings
- Connect your iPhone or iPad to the same access point as your camera 
- Open the app and check if your camera appears on the list of the first tab
- Tap the item and check the detailed information of your camera (vendor name, local address, camera icon, downloaded item summary and progress bar)
- Change to the photos tab and browse the photo thumbnails provided from your camera
- Check that all photos are listed
- Try to peek into photos using 3D touch
- Download a photo using the menu item provided during 3D touch
- Watch the progress bar under your image to complete as your image downloads
- Switch back to the Cameras tab and check the camera status and progress bar that it reflects the actual downloaded image count 
- Switch to your photo roll and check that your photo appears
- Switch back to the app and tap the Settings tab 
- Move the Show Canon only switch to the "on" position
- Connect a second camera or launch a DLNA service on your network (you may use ushare for Mac)
- Switch to the Cameras tab and pull-refresh the list. Check if your new camera/sevice appears
- Repeat the download steps for your new device on the photos tab. 
- Exit and re-enter the app. Check if the download count is still valid. 
- Exit the app and delete some downloaded items from your photo roll. 
- Enter the app and if necessary pull-refresh the camera list. Check the download count and progress bar to adapt. 
- Tap a camera/device from the list and select Download all Photos
- Check the download progress on the Camera Detail screen as well as the Photos tab under the respective thumbnail images.
- Put the app into background during download
- Open photo roll and check that your photos are getting downloaded
- Open it again after a while and check the download progress on the camera list tab to adapt.

# Testing GPS injection

- navigate to the settings tab 
- allow location access to the app
- toggle the Insert GPS switch on
- download an item you shot without having your on-camera gps turned on
- check in the photos app detail view that a location is appended
- do some other tests with and without granting location access
and with or without camera gps data

## Launch a DLNA service
brew install ushare
ushare -i en0 -q 10000 -w -n "MacBook" -c ushare

## Connection Guide

Locate the Wi-Fi settings on your camera and enable Wi-Fi. Enter the Wi-Fi functions menu.

![screen 1] (dslrbrowser/Assets.xcassets/_wifi_settings.imageset/_wifi_settings_2.png)

Select View images on DLNA devices and complete the wizard. Use the same access point as your phone is connected to.

![screen 2] (dslrbrowser/Assets.xcassets/_dlna_settings.imageset/_dlna_settings_2.png)

