@echo off
cls

set target=%1
set addon_name=ActionBarSaverReloaded
set addon_folder=C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns
set addon_folder_beta=C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns
set publish_folder="%addon_folder%\%addon_name%"
set publish_folder_beta="%addon_folder_beta%\%addon_name%"
set build=.release\%addon_name%

rem Build with the BigWigs packager, the same way releases are built. It fetches
rem the Ace3 libraries and puts the addon in .release\%addon_name%.
rem Needs bash on the PATH (Git for Windows or WSL).
if not exist .release mkdir .release
if not exist .release\release.sh curl -sfL https://raw.githubusercontent.com/BigWigsMods/packager/v2/release.sh -o .release\release.sh

rem -d: don't upload. -z: don't zip, except for "release", which leaves the zip in .release
if %target% == release (
    bash .release/release.sh -d
) else (
    bash .release/release.sh -d -z
)
if errorlevel 1 exit /b 1

if %target% == publish (
    if exist %publish_folder% rmdir /Q /S %publish_folder%
    mkdir %publish_folder%
    xcopy %build% %publish_folder% /E
)

if %target% == beta (
    if exist %publish_folder_beta% rmdir /Q /S %publish_folder_beta%
    mkdir %publish_folder_beta%
    xcopy %build% %publish_folder_beta% /E
)
