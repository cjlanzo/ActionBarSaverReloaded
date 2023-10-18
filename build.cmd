@echo off
cls

set target=%1
set addon_name=ActionBarSaverReloaded
set addon_folder=C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns
set ptr_addon_folder=C:\Program Files (x86)\World of Warcraft\_classic_ptr_\Interface\AddOns
set publish_folder="%addon_folder%\%addon_name%"
set ptr_publish_folder="%ptr_addon_folder%\%addon_name%"

if exist build rmdir /Q /S build
mkdir build
mkdir build\Libs

xcopy src build
xcopy libs\ace build\Libs /E
copy RELEASE_NOTES.md build
copy README.md build

if %target% == publish (
    if exist %publish_folder% rmdir /Q /S %publish_folder%
    mkdir %publish_folder%
    xcopy build %publish_folder% /E
)

if %target% == ptr_publish (
    if exist %ptr_publish_folder% rmdir /Q /S %ptr_publish_folder%
    mkdir %ptr_publish_folder%
    xcopy build %ptr_publish_folder% /E
)

if %target% == release (
    if exist release rmdir /Q /S release
    mkdir release
    mkdir release\%addon_name%
    xcopy build release\%addon_name% /E
)