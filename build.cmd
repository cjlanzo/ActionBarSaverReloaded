@echo off
cls

set target=%1
set addon_name="ActionBarSaverReloaded"
set addon_folder="C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns"
set publish_folder="%addon_folder%\%addon_name%" 

if exist build rmdir /Q /S build
mkdir build

xcopy src build
copy RELEASE_NOTES.md build
copy README.md build

if %target% == publish (
    if exist %publish_folder% rmdir /Q /S %publish_folder%
    mkdir %publish_folder%
    xcopy build %publish_folder% /E
)

if %target% == release (
    if exist release rmdir /Q /S release
    mkdir release
    mkdir release\%addon_name%
    xcopy build release\%addon_name% /E
)