;nQuake2 NSIS Online Installer Script
;By Empezar 2012-12-09; Last modified 2013-09-14

!define VERSION "1.1"
!define SHORTVERSION "11"

Name "nQuake2"
OutFile "nquake2v${SHORTVERSION}_installer.exe"
InstallDir "C:\nQuake2"

!define NQUAKE2_URL "http://nquake2.sourceforge.net" # Note: no trailing slash! - for nquake2.ini downloading
!define INSTALLER_URL "http://nquake2.com" # Note: no trailing slash! - for visiting nQuake2 website
!define DISTFILES_PATH "C:\nquake2-distfiles" # Note: no trailing slash!

# Editing anything below this line is not recommended
;---------------------------------------------------

InstallDirRegKey HKCU "Software\nQuake2" "Install_Dir"

;----------------------------------------------------
;Header Files

!include "MUI.nsh"
!include "FileFunc.nsh"
!insertmacro GetSize
!insertmacro GetTime
!include "LogicLib.nsh"
!include "Time.nsh"
!include "Locate.nsh"
!include "VersionCompare.nsh"
!include "VersionConvert.nsh"
!include "WinMessages.nsh"
!include "MultiUser.nsh"
!include "nquake2-macros.nsh"

;----------------------------------------------------
;Variables

Var CONFIG_NAME
Var CONFIG_INVERT
Var CONFIG_FORWARD
Var CONFIG_BACK
Var CONFIG_MOVELEFT
Var CONFIG_MOVERIGHT
Var CONFIG_JUMP
Var CONFIG_DUCK
Var CONFIGCFG
Var DISTFILES_DELETE
Var DISTFILES_PATH
Var DISTFILES_UPDATE
Var DISTFILES_URL
Var DISTFILES
Var DISTLOG
Var DISTLOGTMP
Var ERRLOG
Var ERRLOGTMP
Var ERRORS
Var FULLVERSION
Var INSTALLED
Var INSTLOG
Var INSTLOGTMP
Var INSTSIZE
Var NQUAKE2_INI
Var PAK_LOCATION
Var OFFLINE
Var REMOVE_ALL_FILES
Var REMOVE_MODIFIED_FILES
Var RETRIES
Var SIZE
Var STARTMENU_FOLDER
#TEXTURESVar TEXTURES

;----------------------------------------------------
;Interface Settings

!define MUI_ICON "nquake2.ico"
!define MUI_UNICON "nquake2.ico"

!define MUI_WELCOMEFINISHPAGE_BITMAP "nquake2-welcomefinish.bmp"

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "nquake2-header.bmp"

!define MULTIUSER_EXECUTIONLEVEL Highest

;----------------------------------------------------
;Installer Pages

!define MUI_PAGE_CUSTOMFUNCTION_PRE "WelcomeShow"
!define MUI_WELCOMEPAGE_TITLE "nQuake2 Installation Wizard"
!insertmacro MUI_PAGE_WELCOME

LicenseForceSelection checkbox "I agree to these terms and conditions"
!insertmacro MUI_PAGE_LICENSE "license.txt"

Page custom FULLVERSION

Page custom DISTFILEFOLDER

Page custom MIRRORSELECT

Page custom CONFIG

#TEXTURESPage custom TEXTURES

!define MUI_PAGE_CUSTOMFUNCTION_PRE UpdateInstallSize
DirText "Setup will install nQuake2 in the following folder. To install in a different folder, click Browse and select another folder. Click Next to continue.$\r$\n$\r$\nIt is NOT ADVISABLE to install in the Program Files folder." "Destination Folder" "Browse" "Select the folder to install nQuake2 in:"
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_STARTMENU "Application" $STARTMENU_FOLDER

ShowInstDetails "nevershow"
!insertmacro MUI_PAGE_INSTFILES

Page custom ERRORS

!define MUI_PAGE_CUSTOMFUNCTION_SHOW "FinishShow"
!define MUI_FINISHPAGE_LINK "Click here to visit the Quake 2 community"
!define MUI_FINISHPAGE_LINK_LOCATION "http://forum.tastyspleen.net/quake/index.php"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR/readme.txt"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Open readme"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

;----------------------------------------------------
;Uninstaller Pages

UninstPage custom un.UNINSTALL

!insertmacro MUI_UNPAGE_INSTFILES

;----------------------------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"

;----------------------------------------------------
;NSIS Manipulation

LangString ^Branding ${LANG_ENGLISH} "nQuake2 Installer v${VERSION}"
LangString ^SetupCaption ${LANG_ENGLISH} "nQuake2 Installer"
LangString ^SpaceRequired ${LANG_ENGLISH} "Download size: "

;----------------------------------------------------
;Reserve Files

ReserveFile "config.ini"
ReserveFile "fullversion.ini"
ReserveFile "distfilefolder.ini"
ReserveFile "mirrorselect.ini"
#TEXTURESReserveFile "textures.ini"
ReserveFile "errors.ini"
ReserveFile "uninstall.ini"

!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;----------------------------------------------------
;Installer Sections

Section "" # Prepare installation

  SetOutPath $INSTDIR

  # Set progress bar
  RealProgress::SetProgress /NOUNLOAD 0

  # Read information from custom pages
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_PATH "distfilefolder.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_UPDATE "distfilefolder.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $DISTFILES_DELETE "distfilefolder.ini" "Field 5" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $PAK_LOCATION "fullversion.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_NAME "config.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_INVERT "config.ini" "Field 6" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_FORWARD "config.ini" "Field 9" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_BACK "config.ini" "Field 11" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_MOVELEFT "config.ini" "Field 13" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_MOVERIGHT "config.ini" "Field 15" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_JUMP "config.ini" "Field 17" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $CONFIG_DUCK "config.ini" "Field 19" "State"
  #TEXTURES!insertmacro MUI_INSTALLOPTIONS_READ $TEXTURES "textures.ini" "Field 2" "State"

  # Create distfiles folder if it doesn't already exist
  ${Unless} ${FileExists} "$DISTFILES_PATH\*.*"
    CreateDirectory $DISTFILES_PATH
  ${EndUnless}

  # Calculate the installation size
  ${Unless} ${FileExists} "$INSTDIR\baseq2\pak0.pak"
    # Add demo zip size if pak0.pak can't be found in installer directory
    ${If} ${FileExists} "$EXEDIR\pak0.pak"
      ${GetSize} $EXEDIR "/M=pak0.pak /S=0B /G=0" $7 $8 $9
      ${If} $7 != "183997730"
        ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "q2-314-demo-x86.zip"
        IntOp $INSTSIZE $INSTSIZE + $0
      ${EndIf}
    ${EndIf}
  ${EndUnless}
  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-gpl.zip"
  IntOp $INSTSIZE $INSTSIZE + $0
  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-non-gpl.zip"
  IntOp $INSTSIZE $INSTSIZE + $0
  #TEXTURES${If} $TEXTURES == 1
  #TEXTURES  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-textures.zip"
  #TEXTURES  IntOp $INSTSIZE $INSTSIZE + $0
  #TEXTURES${EndIf}

  # Find out what mirror was selected
  !insertmacro MUI_INSTALLOPTIONS_READ $R0 "mirrorselect.ini" "Field 3" "State"
  ${If} $R0 == "Randomly selected mirror (Recommended)"
    # Get amount of mirrors ($0 = amount of mirrors)
    StrCpy $0 1
    ReadINIStr $1 $NQUAKE2_INI "mirror_descriptions" $0
    ${DoUntil} $1 == ""
      ReadINIStr $1 $NQUAKE2_INI "mirror_descriptions" $0
      IntOp $0 $0 + 1
    ${LoopUntil} $1 == ""
    IntOp $0 $0 - 2
  
    # Get time (seconds)
    ${time::GetLocalTime} $1
    StrCpy $1 $1 "" -2
    
    # Fix seconds (00 -> 1, 01-09 -> 1-9)
    ${If} $1 == "00"
      StrCpy $1 1
    ${Else}
      StrCpy $2 $1 1 -2
      ${If} $2 == 0
        StrCpy $1 $1 1 -1
      ${EndIf}
    ${EndIf}
  
    # Loop until you get a number that's within the range 0 < x =< $0
    ${DoUntil} $1 <= $0
      IntOp $1 $1 - $0
    ${LoopUntil} $1 <= $0
    ReadINIStr $DISTFILES_URL $NQUAKE2_INI "mirror_addresses" $1
    ReadINIStr $0 $NQUAKE2_INI "mirror_descriptions" $1
  ${Else}
    ${For} $0 1 1000
      ReadINIStr $R1 $NQUAKE2_INI "mirror_descriptions" $0
      ${If} $R0 == $R1
        ReadINIStr $DISTFILES_URL $NQUAKE2_INI "mirror_addresses" $0
        ReadINIStr $0 $NQUAKE2_INI "mirror_descriptions" $0
        ${ExitFor}
      ${EndIf}
    ${Next}
  ${EndIf}

  # Open temporary files
  GetTempFileName $INSTLOGTMP
  GetTempFileName $DISTLOGTMP
  GetTempFileName $ERRLOGTMP
  FileOpen $INSTLOG $INSTLOGTMP w
  FileOpen $DISTLOG $DISTLOGTMP w
  FileOpen $ERRLOG $ERRLOGTMP a

SectionEnd

Section "nQuake2" NQUAKE2

  # Copy pak0.pak if it was found or specified (registered data), and doesn't already exist
  CreateDirectory "$INSTDIR\baseq2"
  ${If} ${FileExists} $PAK_LOCATION
  ${AndUnless} ${FileExists} "$INSTDIR\baseq2\pak0.pak"
    # Copy pak1.pak
    CopyFiles /SILENT $PAK_LOCATION "$INSTDIR\baseq2\pak0.pak"
  ${Else}
    # Download and install pak0.pak (demo data)
    !insertmacro InstallSection q2-314-demo-x86.zip "Quake 2 v3.14 demo"
    # Move pak0.pak from demo folder
    Rename "$INSTDIR\Install\Data\baseq2\pak0.pak" "$INSTDIR\baseq2\pak0.pak"
    # Remove crap files extracted from demo zip
    RMDir /R "$INSTDIR\Install"
    RMDir /R "$INSTDIR\Splash"
    Delete /REBOOTOK "$INSTDIR\license.txt"
    Delete /REBOOTOK "$INSTDIR\Setup.exe"
    Delete /REBOOTOK "$INSTDIR\readme.txt"
    Delete /REBOOTOK "$INSTDIR\ref_gl.dll"
    Delete /REBOOTOK "$INSTDIR\ref_soft.dll"
  ${EndIf}
  # Add to installed size
  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "q2-314-demo-x86.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0
  # Add pak0.pak to install.log
  FileWrite $INSTLOG "baseq2\pak0.pak$\r$\n"

  # Download and install Quake 2 v3.20 point release
  # but only if pak0.pak can't be found in installer directory
  ${If} ${FileExists} "$EXEDIR\pak0.pak"
    ${GetSize} $EXEDIR "/M=pak0.pak /S=0B /G=0" $7 $8 $9
    ${If} $7 == "183997730"
      CopyFiles "$EXEDIR\pak0.pak" "$INSTDIR\baseq2\pak0.pak"
      Goto Skipdemo
    ${EndIf}
  ${EndIf}
  !insertmacro InstallSection q2-3.20-x86-full_3.zip "Quake 2 v3.20 point release"
  # Add to installed size
  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "q2-3.20-x86-full_3.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0
  # Remove crap files extracted from point release zip
  RMDir /R "$INSTDIR\DOCS"
  RMDir /R "$INSTDIR\rogue"
  RMDir /R "$INSTDIR\xatrix"
  Delete /REBOOTOK "$INSTDIR\baseq2\maps.lst"
  Delete /REBOOTOK "$INSTDIR\3.20_Changes.txt"
  Delete /REBOOTOK "$INSTDIR\quake2.exe"
  Delete /REBOOTOK "$INSTDIR\ref_soft.dll"
  Delete /REBOOTOK "$INSTDIR\ref_gl.dll"
  Skipdemo:

  # Backup old configs if such exist
  ${If} ${FileExists} "$INSTDIR\baseq2\config.cfg"
    ${GetTime} "" "LS" $2 $3 $4 $5 $6 $7 $8
    # Fix hour format
    ${If} $6 < 10
      StrCpy $6 "0$6"
    ${EndIf}
    StrCpy $1 "$4$3$2$6$7$8"
    Rename "$INSTDIR\baseq2\config.cfg" "$INSTDIR\baseq2\config-$1.cfg"
  ${EndIf}

  # Download and install GPL files
  !insertmacro InstallSection nquake2-gpl.zip "nQuake2 game files (1 of 2)"
  # Add to installed size
  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-gpl.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0
  Delete /REBOOTOK "$INSTDIR\gpl.txt"

  # Download and install non-GPL files
  !insertmacro InstallSection nquake2-non-gpl.zip "nQuake2 game files (2 of 2)"
  # Copy CTF pak0.pak to Eraser folder
  CopyFiles "$INSTDIR\ctf\pak0.pak" "$INSTDIR\eraser\ctf.pak"
  # Add CTF pak0.pak to install.log
  FileWrite $INSTLOG "eraser\ctf.pak$\r$\n"
  # Add to installed size
  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-non-gpl.zip"
  IntOp $INSTALLED $INSTALLED + $0
  # Set progress bar
  IntOp $0 $INSTALLED * 100
  IntOp $0 $0 / $INSTSIZE
  RealProgress::SetProgress /NOUNLOAD $0

  #TEXTURES# Download and install texture files
  #TEXTURES${If} $TEXTURES == 1
  #TEXTURES  !insertmacro InstallSection nquake2-textures.zip "high resolution textures"
  #TEXTURES  # Add to installed size
  #TEXTURES  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-textures.zip"
  #TEXTURES  IntOp $INSTALLED $INSTALLED + $0
  #TEXTURES  # Set progress bar
  #TEXTURES  IntOp $0 $INSTALLED * 100
  #TEXTURES  IntOp $0 $0 / $INSTSIZE
  #TEXTURES  RealProgress::SetProgress /NOUNLOAD $0
  #TEXTURES  # Add a line about the textures pak file in baseq2\readme.txt
  #TEXTURES  FileOpen $BASEQ2README "$INSTDIR\baseq2\readme.txt" a
  #TEXTURES    FileSeek $BASEQ2README 0 END
  #TEXTURES    FileWrite $BASEQ2README "$\r$\nThe file $\"textures.pkz$\" contains the nQuake2 texture files. It can also be opened using WinRAR.$\r$\n"
  #TEXTURES  FileClose $BASEQ2README
  #TEXTURES${EndIf}

  # Copy pak0.pak if it can be found alongside the installer executable
  ${If} ${FileExists} "$EXEDIR\pak0.pak"
    ${GetSize} $EXEDIR "/M=pak0.pak /S=0B /G=0" $7 $8 $9
    ${If} $7 == "183997730"
      CopyFiles "$EXEDIR\pak0.pak" "$INSTDIR\baseq2\pak0.pak"
    ${EndIf}
  ${EndIf}

SectionEnd

Section "" # StartMenu

  # Copy the first char of the startmenu folder selected during installation
  StrCpy $0 $STARTMENU_FOLDER 1

  ${Unless} $0 == ">"
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"

    # Create links
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER\Links"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Latest News.url" "InternetShortcut" "URL" "http://q2scene.net/scene/index.php?op=news"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Message Board.url" "InternetShortcut" "URL" "http://forum.tastyspleen.net/quake/"
    WriteINIStr "$SMPROGRAMS\$STARTMENU_FOLDER\Links\List of Servers.url" "InternetShortcut" "URL" "http://q2servers.com/"

    # Create shortcuts
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Quake 2.lnk" "$INSTDIR\q2pro.exe" "" "$INSTDIR\q2pro.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Eraser CTF.lnk" "$INSTDIR\q2pro.exe" "+set game eraser +exec ctf.cfg +map q2ctf1" "$INSTDIR\q2pro.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Eraser DM.lnk" "$INSTDIR\q2pro.exe" "+set game eraser +map q2dm1" "$INSTDIR\q2pro.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Server Browser.lnk" "$INSTDIR\qsb.exe" "" "$INSTDIR\qsb.exe" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Readme.lnk" "$INSTDIR\readme.txt" "" "$INSTDIR\readme.txt" 0
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall nQuake2.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

    # Write startmenu folder to registry
    WriteRegStr HKCU "Software\nQuake2\" "StartMenu_Folder" $STARTMENU_FOLDER
  ${EndUnless}

SectionEnd

Section "" # Clean up installation

  # Close open temporary files
  FileClose $INSTLOG
  FileClose $ERRLOG
  FileClose $DISTLOG
  FileClose $CONFIGCFG

  # Write config.cfgs for each mod
  FileOpen $CONFIGCFG "$INSTDIR\baseq2\q2config.cfg" w
    # Write config to baseq2/postexec.cfg
    FileWrite $CONFIGCFG "// This config was auto generated by nQuake2 installer$\r$\n"
    FileWrite $CONFIGCFG "$\r$\n"
    FileWrite $CONFIGCFG "name $\"$CONFIG_NAME$\"$\r$\n"
    FileWrite $CONFIGCFG "$\r$\n"
    ${If} $CONFIG_INVERT == 1
      FileWrite $CONFIGCFG "m_pitch $\"-0.022$\" // invert mouse$\r$\n"
    ${Else}
      FileWrite $CONFIGCFG "m_pitch $\"0.022$\"$\r$\n"
    ${EndIf}
    FileWrite $CONFIGCFG "$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_FORWARD $\"+forward$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_BACK $\"+back$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_MOVELEFT $\"+moveleft$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_MOVERIGHT $\"+moveright$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_JUMP $\"+moveup$\"$\r$\n"
    FileWrite $CONFIGCFG "bind $CONFIG_DUCK $\"+movedown$\"$\r$\n"
  FileClose $CONFIGCFG
  CopyFiles "$INSTDIR\baseq2\q2config.cfg" "$INSTDIR\action\q2config.cfg"
  CopyFiles "$INSTDIR\baseq2\q2config.cfg" "$INSTDIR\ctf\q2config.cfg"
  CopyFiles "$INSTDIR\baseq2\q2config.cfg" "$INSTDIR\eraser\q2config.cfg"

  # Write install.log
  FileOpen $INSTLOG "$INSTDIR\install.log" w
    ${time::GetFileTime} "$INSTDIR\install.log" $0 $1 $2
    FileWrite $INSTLOG "Install date: $1$\r$\n"
    FileOpen $R0 $INSTLOGTMP r
      ClearErrors
      ${DoUntil} ${Errors}
        FileRead $R0 $0
        FileWrite $INSTLOG $0
      ${LoopUntil} ${Errors}
    FileClose $R0
  FileClose $INSTLOG

  # Remove downloaded distfiles
  ${If} $DISTFILES_DELETE == 1
    FileOpen $DISTLOG $DISTLOGTMP r
      ${DoUntil} ${Errors}
        FileRead $DISTLOG $0
        StrCpy $0 $0 -2
        ${If} ${FileExists} "$DISTFILES_PATH\$0"
          Delete /REBOOTOK "$DISTFILES_PATH\$0"
        ${EndIf}
      ${LoopUntil} ${Errors}
    FileClose $DISTLOG
    RMDir /REBOOTOK $DISTFILES_PATH
  # Copy nquake2.ini to the distfiles directory if "update distfiles" and "keep distfiles" was set
  ${ElseIf} $DISTFILES_UPDATE == 1
    FlushINI $NQUAKE2_INI
    CopyFiles $NQUAKE2_INI "$DISTFILES_PATH\nquake2.ini"
  ${EndIf}

  # Write to registry
  WriteRegStr HKCU "Software\nQuake2\" "Install_Dir" "$INSTDIR"
  WriteRegStr HKCU "Software\r1ch.net\Quake II Server Browser\" "Quake II Directory" "$INSTDIR"
  WriteRegStr HKCU "Software\r1ch.net\Quake II Server Browser\" "Quake II Executable" "q2pro.exe"
  WriteRegDWORD HKCU "Software\r1ch.net\Quake II Server Browser\" "Good Ping Threshold" "40"
  WriteRegDWORD HKCU "Software\r1ch.net\Quake II Server Browser\" "Medium Ping Threshold" "80"
  WriteRegDWORD HKCU "Software\r1ch.net\Quake II Server Browser\" "Show Empty Servers" "1"
  WriteRegDWORD HKCU "Software\r1ch.net\Quake II Server Browser\" "Show Full Servers" "0"
  WriteRegDWORD HKCU "Software\r1ch.net\Quake II Server Browser\" "Sort Order" "3"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "DisplayName" "nQuake2"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "DisplayIcon" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "Publisher" "The nQuake Team"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "URLUpdateInfo" "http://sourceforge.net/projects/nquake/files/nQuake2%20%28Win32%29/"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "URLInfoAbout" "http://nquake.com/2/"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "HelpLink" "http://sourceforge.net/forum/forum.php?forum_id=702198"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "NoModify" "1"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2\" "NoRepair" "1"

  # Create uninstaller
  WriteUninstaller "uninstall.exe"

SectionEnd

;----------------------------------------------------
;Uninstaller Section

Section "Uninstall"

  # Set out path to temporary files
  SetOutPath $TEMP

  # Read uninstall settings
  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_MODIFIED_FILES "uninstall.ini" "Field 5" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $REMOVE_ALL_FILES "uninstall.ini" "Field 6" "State"

  # Set progress bar to 0%
  RealProgress::SetProgress /NOUNLOAD 0

  # If install.log exists and user didn't check "remove all files", remove all files listed in install.log
  ${If} ${FileExists} "$INSTDIR\install.log"
  ${AndIf} $REMOVE_ALL_FILES != 1
    # Get line count for install.log
    Push "$INSTDIR\install.log"
    Call un.LineCount
    Pop $R1 # Line count
    IntOp $R1 $R1 - 1 # Remove the timestamp from the line count
    FileOpen $R0 "$INSTDIR\install.log" r
    # Get installation time from install.log
    FileRead $R0 $0
    StrCpy $1 $0 -2 14
    StrCpy $5 1 # Current line
    StrCpy $6 0 # Current % Progress
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      StrCpy $0 $0 -2
      # Only remove file if it has not been altered since install, if the user chose to do so
      ${If} ${FileExists} "$INSTDIR\$0"
      ${AndUnless} $REMOVE_MODIFIED_FILES == 1
        ${time::GetFileTime} "$INSTDIR\$0" $2 $3 $4
        ${time::MathTime} "second($1) - second($3) =" $2
        ${If} $2 >= 0
          Delete /REBOOTOK "$INSTDIR\$0"
        ${EndIf}
      ${ElseIf} $REMOVE_MODIFIED_FILES == 1
      ${AndIf} ${FileExists} "$INSTDIR\$0"
        Delete /REBOOTOK "$INSTDIR\$0"
      ${EndIf}
      # Set progress bar
      IntOp $7 $5 * 100
      IntOp $7 $7 / $R1
      RealProgress::SetProgress /NOUNLOAD $7
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
    FileClose $R0
    Delete /REBOOTOK "$INSTDIR\install.log"
    Delete /REBOOTOK "$INSTDIR\uninstall.exe"
    ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
    DetailPrint "Removed $0 empty directories"
    RMDir /REBOOTOK $INSTDIR
  ${Else}
    # Ask the user if he is sure about removing all the files contained within the nQuake2 directory
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "This will remove all files contained within the nQuake2 directory.$\r$\n$\r$\nAre you sure?" IDNO AbortUninst
    RMDir /r /REBOOTOK $INSTDIR
    RealProgress::SetProgress /NOUNLOAD 100
  ${EndIf}

  # Remove start menu items
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Latest News.url"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Links\Message Board.url"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Links\List of Servers.url"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Quake 2.lnk"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Eraser CTF.lnk"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Eraser DM.lnk"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Readme.lnk"
  Delete /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall nQuake2.lnk"
  RMDir /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER\Links"
  RMDir /REBOOTOK "$SMPROGRAMS\$STARTMENU_FOLDER"

  # Remove registry entries
  ReadRegStr $R0 HKCU "Software\nQuake2" "Install_Dir"
  ${If} $R0 == $INSTDIR
    # Remove start menu items
    ReadRegStr $R0 HKCU "Software\nQuake2" "StartMenu_Folder"
    RMDir /r /REBOOTOK "$SMPROGRAMS\$R0"
    # Remove registry entries
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\nQuake2"
    DeleteRegKey HKCU "Software\nQuake2"
    DeleteRegKey HKCU "Software\r1ch.net\Quake II Server Browser"
    DeleteRegKey HKCU "Software\r1ch.net"
  ${EndIf}

  Goto FinishUninst
  AbortUninst:
  Abort "Uninstallation aborted."
  FinishUninst:

SectionEnd

;----------------------------------------------------
;Custom Pages


Function FULLVERSION


  # Copy pak0.pak if it can be found alongside the installer executable
  ${If} ${FileExists} "$EXEDIR\pak0.pak"
    ${GetSize} $EXEDIR "/M=pak0.pak /S=0B /G=0" $7 $8 $9
    ${If} $7 == "183997730"
      !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 3" "State" "$EXEDIR\pak0.pak"
      Goto SkipFullVersion
    ${EndIf}
  ${EndIf}

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "fullversion.ini"
  !insertmacro MUI_HEADER_TEXT "Full Version Quake 2 Data" "Find pak0.pak for inclusion in nQuake2."

  # See if there is a properly installed version of Quake 2
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\App Paths\Quake2_exe" "RegisteredOwner"
  ${If} ${FileExists} "$0\baseq2\pak0.pak"
    StrCpy $0 "$0\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}

  # Look for pak1.pak in 28 likely locations
  ${If} ${FileExists} "C:\Quake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "D:\Quake2\baseq2\pak0.pak"
    StrCpy $0 "D:\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "E:\Quake2\baseq2\pak0.pak"
    StrCpy $0 "E:\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Games\Quake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Games\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "D:\Games\Quake2\baseq2\pak0.pak"
    StrCpy $0 "D:\Games\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "E:\Games\Quake2\baseq2\pak0.pak"
    StrCpy $0 "E:\Games\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Program Files\Quake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Program Files\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "C:\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "D:\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "D:\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "E:\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "E:\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Games\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Games\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "D:\Games\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "D:\Games\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "E:\Games\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "E:\Games\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Program Files\nQuake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Program Files\nQuake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Valve\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Valve\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "D:\Valve\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "D:\Valve\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "E:\Valve\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "E:\Valve\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "D:\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "D:\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "E:\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "E:\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${EndIf}
  ${If} ${FileExists} "C:\Program Files\Valve\Steam\SteamApps\common\Quake2\baseq2\pak0.pak"
    StrCpy $0 "C:\Program Files\Valve\Steam\SteamApps\common\Quake2\baseq2"
    !insertmacro ValidatePak $0
  ${Else}
    Goto FullVersionEnd
  ${EndIf}

  FullVersion:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 1" "Text" "The full version of Quake is not included in this package. However, setup has found what resembles the full version pak0.pak on your harddrive. If this is not the correct file, click Browse to locate the correct pak0.pak. Click Next to continue."
  !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 3" "State" "$0\pak0.pak"
  StrCpy $FULLVERSION 1
  FullVersionEnd:
  # Remove the purchase link if the installer is in offline mode
  ${If} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_WRITE "fullversion.ini" "Field 4" "Type" ""
  ${EndIf}
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "fullversion.ini"

  SkipFullVersion:

FunctionEnd

Function DISTFILEFOLDER

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "distfilefolder.ini"
  # Change the text on the distfile folder page if the installer is in offline mode
  ${If} $OFFLINE == 1
    !insertmacro MUI_HEADER_TEXT "Distribution Files" "Select where the distribution files are located."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 1" "Text" "Setup will use the distribution files (used to install nQuake2) located in the following folder. To use a different folder, click Browse and select another folder. Click Next to continue."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 4" "Type" ""
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 4" "State" "0"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 5" "Type" ""
    !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 5" "State" "0"
  ${Else}
    !insertmacro MUI_HEADER_TEXT "Distribution Files" "Select where you want the distribution files to be downloaded."
  ${EndIf}
  !insertmacro MUI_INSTALLOPTIONS_WRITE "distfilefolder.ini" "Field 3" "State" ${DISTFILES_PATH}
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "distfilefolder.ini"

FunctionEnd

Function MIRRORSELECT

  # Only display mirror selection if the installer is in online mode
  ${Unless} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "mirrorselect.ini"
    !insertmacro MUI_HEADER_TEXT "Mirror Selection" "Select a mirror from your part of the world."

    # Fix the mirrors for the Preferences page
    StrCpy $0 1
    StrCpy $2 "Randomly selected mirror (Recommended)"
    ReadINIStr $1 $NQUAKE2_INI "mirror_descriptions" $0
    ${DoUntil} $1 == ""
      ReadINIStr $1 $NQUAKE2_INI "mirror_descriptions" $0
      ${Unless} $1 == ""
        StrCpy $2 "$2|$1"
      ${EndUnless}
      IntOp $0 $0 + 1
    ${LoopUntil} $1 == ""

    StrCpy $0 $2 3
    ${If} $0 == "|"
      StrCpy $2 $2 "" 1
    ${EndIf}

    !insertmacro MUI_INSTALLOPTIONS_WRITE "mirrorselect.ini" "Field 3" "ListItems" $2
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "mirrorselect.ini"
  ${EndUnless}

FunctionEnd

#TEXTURESFunction TEXTURES

#TEXTURES  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "textures.ini"
#TEXTURES  # Get texture size and add it to radio button description
#TEXTURES  ReadINIStr $0 $NQUAKE2_INI "distfile_sizes" "nquake2-textures.zip"
#TEXTURES  IntOp $0 $0 / 1024
#TEXTURES  !insertmacro MUI_INSTALLOPTIONS_WRITE "textures.ini" "Field 5" "Text" "$0 mb"
#TEXTURES  !insertmacro MUI_HEADER_TEXT "High resolution textures" "Select whether or not to download high resolution textures."
#TEXTURES  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "textures.ini"

#TEXTURESFunctionEnd

Function CONFIG

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "config.ini"
  !insertmacro MUI_HEADER_TEXT "Configuration" "Setup basic configuration."
  System::Call "advapi32::GetUserName(t .r0, *i ${NSIS_MAX_STRLEN} r1) i.r2"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "config.ini" "Field 4" "State" "$0"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "config.ini"

FunctionEnd

Function ERRORS

  # Only display error page if errors occured during installation
  ${If} $ERRORS > 0
    # Read errors from error log
    StrCpy $1 ""
    FileOpen $R0 $ERRLOGTMP r
      ClearErrors
      FileRead $R0 $0
      StrCpy $1 $0
      ${DoUntil} ${Errors}
        FileRead $R0 $0
        ${Unless} $0 == ""
          StrCpy $1 "$1|$0"
        ${EndUnless}
      ${LoopUntil} ${Errors}
    FileClose $R0

    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "errors.ini"
    ${If} $ERRORS == 1
      !insertmacro MUI_HEADER_TEXT "Error" "An error occurred during the installation of nQuake2."
      !insertmacro MUI_INSTALLOPTIONS_WRITE "errors.ini" "Field 1" "Text" "There was an error during the installation of nQuake2. See below for more information."
    ${Else}
      !insertmacro MUI_HEADER_TEXT "Errors" "Some errors occurred during the installation of nQuake2."
      !insertmacro MUI_INSTALLOPTIONS_WRITE "errors.ini" "Field 1" "Text" "There were some errors during the installation of nQuake2. See below for more information."
    ${EndIf}
    !insertmacro MUI_INSTALLOPTIONS_WRITE "errors.ini" "Field 2" "ListItems" $1
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "errors.ini"
  ${EndIf}

FunctionEnd

Function un.UNINSTALL

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "uninstall.ini"

  # Remove all options on uninstall page except for "remove all files" if install.log is missing
  ${Unless} ${FileExists} "$INSTDIR\install.log"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 4" "State" "0"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 4" "Flags" "DISABLED"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 5" "Flags" "DISABLED"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 6" "Text" "Remove all files contained within the nQuake2 directory (install.log missing)."
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 6" "State" "1"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 6" "Flags" "FOCUS"
  ${EndUnless}
  !insertmacro MUI_HEADER_TEXT "Uninstall nQuake2" "Remove nQuake2 from your computer."
  !insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 3" "State" "$INSTDIR\"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "uninstall.ini"

FunctionEnd

;----------------------------------------------------
;Welcome/Finish page manipulation

Function WelcomeShow
  # Remove the part about nQuake2 being an online installer on welcome page if the installer is in offline mode
  ${Unless} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 3" "Text" "This is the installation wizard of nQuake2, a Quake 2 package made for newcomers, or those who just want to get on with the fragging as soon as possible!\r\n\r\nThis is an online installer and therefore requires a stable internet connection."
  ${Else}
    !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 3" "Text" "This is the installation wizard of nQuake2, a Quake 2 package made for newcomers, or those who just want to get on with the fragging as soon as possible!"
  ${EndUnless}
FunctionEnd

Function UpdateInstallSize
  !insertmacro MUI_INSTALLOPTIONS_READ $PAK_LOCATION "fullversion.ini" "Field 3" "State"
  # This function updates install size depending on whether or not the full Quake 2 pak0.pak was found
  ${GetParent} $PAK_LOCATION $0
  ${GetSize} $0 "/M=pak0.pak /S=0B /G=0" $7 $8 $9
  ${Unless} $FULLVERSION == 1
  ${AndUnless} $7 == "183997730"
    !insertmacro DetermineSectionSize q2-314-demo-x86.zip
    IntOp $1 0 + $SIZE
  ${EndUnless}
  !insertmacro DetermineSectionSize q2-3.20-x86-full_3.zip
  IntOp $1 $1 + $SIZE
  !insertmacro DetermineSectionSize nquake2-gpl.zip
  IntOp $1 $1 + $SIZE
  !insertmacro DetermineSectionSize nquake2-non-gpl.zip
  IntOp $1 $1 + $SIZE
#TEXTURES  !insertmacro MUI_INSTALLOPTIONS_READ $TEXTURES "textures.ini" "Field 2" "State"
#TEXTURES  ${If} $TEXTURES == 1
#TEXTURES    !insertmacro DetermineSectionSize nquake2-textures.zip
#TEXTURES    IntOp $1 $1 + $SIZE
#TEXTURES  ${EndIf}
  SectionSetSize ${NQUAKE2} $1
FunctionEnd

Function FinishShow
  # Hide the Back button on the finish page if there were no errors
  ${Unless} $ERRORS > 0
    GetDlgItem $R0 $HWNDPARENT 3
    EnableWindow $R0 0
  ${EndUnless}
  # Hide the community link if the installer is in offline mode
  ${If} $OFFLINE == 1
    !insertmacro MUI_INSTALLOPTIONS_READ $R0 "ioSpecial.ini" "Field 5" "HWND"
    ShowWindow $R0 ${SW_HIDE}
  ${EndIf}
FunctionEnd

;----------------------------------------------------
;Functions

Function .onInit

  !insertmacro MULTIUSER_INIT
  GetTempFileName $NQUAKE2_INI

  # Download nquake2.ini
  Start:
  inetc::get /NOUNLOAD /CAPTION "Initializing..." /BANNER "nQuake2 is initializing, please wait..." /TIMEOUT 5000 "${NQUAKE2_URL}/nquake2.ini" $NQUAKE2_INI /END
  Pop $0
  ${Unless} $0 == "OK"
    ${If} $0 == "Cancelled"
      MessageBox MB_OK|MB_ICONEXCLAMATION "Installation aborted."
      Abort
    ${Else}
      ${Unless} $RETRIES > 0
        MessageBox MB_YESNO|MB_ICONEXCLAMATION "Are you trying to install nQuake2 offline?" IDNO Online
        StrCpy $OFFLINE 1
        Goto InitEnd
      ${EndUnless}
      Online:
      ${Unless} $RETRIES == 2
        MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Could not download nquake2.ini." IDCANCEL Cancel
        IntOp $RETRIES $RETRIES + 1
        Goto Start
      ${EndUnless}
      MessageBox MB_OK|MB_ICONEXCLAMATION "Could not download nquake2.ini. Please try again later."
      Cancel:
      Abort
    ${EndIf}
  ${EndUnless}

  # Prompt the user if there are newer installer versions available
  ReadINIStr $0 $NQUAKE2_INI "versions" "windows"
  ${VersionConvert} ${VERSION} "" $R0
  ${VersionCompare} $R0 $0 $1
  ${If} $1 == 2
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "A newer version of nQuake2 is available.$\r$\n$\r$\nDo you wish to be taken to the download page?" IDNO ContinueInstall
    ExecShell "open" ${INSTALLER_URL}
    Abort
  ${EndIf}
  ContinueInstall:

  # Determine sizes on all the sections
  !insertmacro DetermineSectionSize q2-314-demo-x86.zip
  IntOp $1 0 + $SIZE
  !insertmacro DetermineSectionSize q2-3.20-x86-full_3.zip
  IntOp $1 $1 + $SIZE
  !insertmacro DetermineSectionSize nquake2-gpl.zip
  IntOp $1 $1 + $SIZE
  !insertmacro DetermineSectionSize nquake2-non-gpl.zip
  IntOp $1 $1 + $SIZE
#TEXTURES  !insertmacro DetermineSectionSize nquake2-textures.zip
#TEXTURES  IntOp $1 $1 + $SIZE
  SectionSetSize ${NQUAKE2} $1

  InitEnd:

FunctionEnd

Function un.onInit

  !insertmacro MULTIUSER_UNINIT

FunctionEnd

Function .abortInstallation

  # Close open temporary files
  FileClose $ERRLOG
  FileClose $INSTLOG
  FileClose $DISTLOG

  # Write install.log
  FileOpen $INSTLOG "$INSTDIR\install.log" w
    ${time::GetFileTime} "$INSTDIR\install.log" $0 $1 $2
    FileWrite $INSTLOG "Install date: $1$\r$\n"
    FileOpen $R0 $INSTLOGTMP r
      ClearErrors
      ${DoUntil} ${Errors}
        FileRead $R0 $0
        FileWrite $INSTLOG $0
      ${LoopUntil} ${Errors}
    FileClose $R0
  FileClose $INSTLOG

  # Ask to remove installed files
  Messagebox MB_YESNO|MB_ICONEXCLAMATION "Installation aborted.$\r$\n$\r$\nDo you wish to remove the installed files?" IDNO SkipInstRemoval
  # Show details window
  SetDetailsView show
  # Get line count for install.log
  Push "$INSTDIR\install.log"
  Call .LineCount
  Pop $R1 # Line count
  IntOp $R1 $R1 - 1 # Remove the timestamp from the line count
  FileOpen $R0 "$INSTDIR\install.log" r
    # Get installation time from install.log
    FileRead $R0 $0
    StrCpy $1 $0 -2 14
    StrCpy $5 1 # Current line
    StrCpy $6 0 # Current % Progress
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      StrCpy $0 $0 -2
      ${If} ${FileExists} "$INSTDIR\$0"
        ${time::GetFileTime} "$INSTDIR\$0" $2 $3 $4
        ${time::MathTime} "second($1) - second($3) =" $2
        ${If} $2 >= 0
          Delete /REBOOTOK "$INSTDIR\$0"
        ${EndIf}
      ${EndIf}
      # Set progress bar
      IntOp $7 $5 * 100
      IntOp $7 $7 / $R1
      RealProgress::SetProgress /NOUNLOAD $7
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
  FileClose $R0
  Delete /REBOOTOK "$INSTDIR\install.log"
  ${locate::RMDirEmpty} $INSTDIR /M=*.* $0
  DetailPrint "Removed $0 empty directories"
  RMDir /REBOOTOK $INSTDIR
  Goto InstEnd
  SkipInstRemoval:
  Delete /REBOOTOK "$INSTDIR\install.log"
  InstEnd:

  # Ask to remove downloaded distfiles
  Messagebox MB_YESNO|MB_ICONEXCLAMATION "Do you wish to keep the downloaded distribution files?" IDYES DistEnd
  # Get line count for distfiles.log
  Push $DISTLOGTMP
  Call .LineCount
  Pop $R1 # Line count
  FileOpen $R0 $DISTLOGTMP r
    StrCpy $5 0 # Current line
    StrCpy $6 0 # Current % Progress
    ${DoUntil} ${Errors}
      FileRead $R0 $0
      StrCpy $0 $0 -2
      ${If} ${FileExists} "$DISTFILES_PATH\$0"
        Delete /REBOOTOK "$DISTFILES_PATH\$0"
      ${EndIf}
      # Set progress bar
      IntOp $7 $5 * 100
      IntOp $7 $7 / $R1
      RealProgress::SetProgress /NOUNLOAD $7
      IntOp $5 $5 + 1
    ${LoopUntil} ${Errors}
  FileClose $R0
  RMDir /REBOOTOK $DISTFILES_PATH
  DistEnd:

  # Set progress bar to 100%
  RealProgress::SetProgress /NOUNLOAD 100

  Abort

FunctionEnd

Function .checkDistfileDate
  StrCpy $R2 0
  ReadINIStr $0 $NQUAKE2_INI "distfile_dates" $R0
  ${If} ${FileExists} "$DISTFILES_PATH\$R0"
    ${GetTime} "$DISTFILES_PATH\$R0" M $2 $3 $4 $5 $6 $7 $8
    # Fix hour format
    ${If} $6 < 10
      StrCpy $6 "0$6"
    ${EndIf}
    StrCpy $1 "$4$3$2$6$7$8"
    ${If} $1 < $0
      StrCpy $R2 1
    ${Else}
      ReadINIStr $1 "$DISTFILES_PATH\nquake2.ini" "distfile_dates" $R0
      ${Unless} $1 == ""
        ${If} $1 < $0
          StrCpy $R2 1
        ${EndIf}
      ${EndUnless}
    ${EndIf}
  ${EndIf}
FunctionEnd

Function .installDistfile
  Retry:
  ${Unless} $R2 == 0 # if $R2 is 1 then distfile needs updating, otherwise not
    inetc::get /NOUNLOAD /CAPTION "Downloading..." /BANNER "Downloading $R1 update, please wait..." /TIMEOUT 5000 "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${Else}
    inetc::get /NOUNLOAD /CAPTION "Downloading..." /BANNER "Downloading $R1, please wait..." /TIMEOUT 5000 "$DISTFILES_URL/$R0" "$DISTFILES_PATH\$R0" /END
  ${EndUnless}
  FileWrite $DISTLOG "$R0$\r$\n"
  Pop $0
  ${Unless} $0 == "OK"
    ${If} $0 == "Cancelled"
      Call .abortInstallation
    ${Else}
      MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION "Error downloading $R0: $0" IDIGNORE Ignore IDRETRY Retry
      Call .abortInstallation
      Ignore:
      FileWrite $ERRLOG 'Error downloading "$R0": $0|'
      IntOp $ERRORS $ERRORS + 1
    ${EndIf}
  ${EndUnless}
  StrCpy $DISTFILES 1
  DetailPrint "Extracting $R1, please wait..."
  nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR

FunctionEnd

Function .installSection
  Pop $R1 # distfile info
  Pop $R0 # distfile filename
  Call .checkDistfileDate
  ${If} ${FileExists} "$DISTFILES_PATH\$R0"
  ${OrIf} $OFFLINE == 1
    ${If} $DISTFILES_UPDATE == 0
    ${OrIf} $R2 == 0
      DetailPrint "Extracting $R1, please wait..."
      nsisunz::UnzipToStack "$DISTFILES_PATH\$R0" $INSTDIR
    ${ElseIf} $R2 == 1
    ${AndIf} $DISTFILES_UPDATE == 1
      Call .installDistfile
    ${EndIf}
  ${ElseUnless} ${FileExists} "$DISTFILES_PATH\$R0"
    Call .installDistfile
  ${EndIf}
  Pop $0
  ${If} $0 == "Error opening ZIP file"
  ${OrIf} $0 == "Error opening output file(s)"
  ${OrIf} $0 == "Error writing output file(s)"
  ${OrIf} $0 == "Error extracting from ZIP file"
  ${OrIf} $0 == "File not found in ZIP file"
    FileWrite $ERRLOG 'Error extracting "$R0": $0|'
    IntOp $ERRORS $ERRORS + 1
  ${Else}
    ${DoUntil} $0 == ""
      ${Unless} $0 == "success"
        FileWrite $INSTLOG "$0$\r$\n"
      ${EndUnless}
      Pop $0
    ${LoopUntil} $0 == ""
  ${EndIf}
FunctionEnd

Function .LineCount
  Exch $R0
  Push $R1
  Push $R2
   FileOpen $R0 $R0 r
  loop:
   ClearErrors
   FileRead $R0 $R1
   IfErrors +3
    IntOp $R2 $R2 + 1
  Goto loop
   FileClose $R0
   StrCpy $R0 $R2
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd

Function un.LineCount
  Exch $R0
  Push $R1
  Push $R2
   FileOpen $R0 $R0 r
  loop:
   ClearErrors
   FileRead $R0 $R1
   IfErrors +3
    IntOp $R2 $R2 + 1
  Goto loop
   FileClose $R0
   StrCpy $R0 $R2
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd