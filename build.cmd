@echo off
cls

set target=%1
set addon_name=ActionBarSaverReloaded

set addon_folder=C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns
set addon_folder_ptr=C:\Program Files (x86)\World of Warcraft\_classic_era_ptr_\Interface\AddOns

set publish_folder="%addon_folder%\%addon_name%"
set publish_folder_ptr="%addon_folder_ptr%\%addon_name%"

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

if %target% == ptr (
    if exist %publish_folder_ptr% rmdir /Q /S %publish_folder_ptr%
    mkdir %publish_folder_ptr%
    xcopy build %publish_folder_ptr% /E
)

if %target% == release (
    if exist release rmdir /Q /S release
    mkdir release
    mkdir release\%addon_name%
    xcopy build release\%addon_name% /E
)