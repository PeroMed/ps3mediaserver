!include "MUI2.nsh"
!include "FileFunc.nsh"

; Include the project header file generated by the nsis-maven-plugin
!include "..\..\..\..\target\project.nsh"
!include "..\..\..\..\target\extra.nsh"

!define REG_KEY_UNINSTALL "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PROJECT_NAME}"
!define REG_KEY_SOFTWARE "SOFTWARE\${PROJECT_NAME}"

RequestExecutionLevel admin

Name "${PROJECT_NAME}"
InstallDir "$PROGRAMFILES\${PROJECT_NAME}"

;Get install folder from registry for updates
InstallDirRegKey HKCU "${REG_KEY_SOFTWARE}" ""

SetCompressor /SOLID lzma
SetCompressorDictSize 32

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\PMS.exe"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"

!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Desktop Shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortcut

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PROJECT_BASEDIR}\LICENSE.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

ShowUninstDetails show

Function .onInit
  ;Check OS for 64-bit installer.
  !insertmacro checkSystemOS
FunctionEnd

Function CreateDesktopShortcut
  CreateShortCut "$DESKTOP\${PROJECT_NAME}.lnk" "$INSTDIR\PMS.exe"
FunctionEnd

Section "Program Files"
  SetOutPath "$INSTDIR"
  SetOverwrite on
  nsSCM::Stop "${PROJECT_NAME}"
  File /r /x "*.conf" /x "*.zip" /x "*.dll" /x "third-party" "${PROJECT_BASEDIR}\src\main\external-resources\plugins"
  File /r "${PROJECT_BASEDIR}\src\main\external-resources\documentation"
  File /r "${PROJECT_BASEDIR}\src\main\external-resources\renderers"
  File /r "${PROJECT_BASEDIR}\target\bin\win32"
  ;Include private JRE folder if needed.
  !insertmacro privateJRE
  File "${PROJECT_BUILD_DIR}\PMS.exe"
  File "${PROJECT_BASEDIR}\src\main\external-resources\PMS.bat"
  File "${PROJECT_BUILD_DIR}\pms.jar"
  File "${PROJECT_BASEDIR}\MediaInfo.dll"
  File "${PROJECT_BASEDIR}\MediaInfo64.dll"
  File "${PROJECT_BASEDIR}\CHANGELOG.txt"
  File "${PROJECT_BASEDIR}\README.md"
  File "${PROJECT_BASEDIR}\LICENSE.txt"
  File "${PROJECT_BASEDIR}\src\main\external-resources\logback.xml"
  File "${PROJECT_BASEDIR}\src\main\external-resources\icon.ico"

  ;the user may have set the installation dir
  ;as the profile dir, so we can't clobber this
  SetOverwrite off
  File "${PROJECT_BASEDIR}\src\main\external-resources\WEB.conf"

  ;Store install folder
  WriteRegStr HKCU "${REG_KEY_SOFTWARE}" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayName" "${PROJECT_NAME}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayVersion" "${PROJECT_VERSION}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "Publisher" "${PROJECT_ORGANIZATION_NAME}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "URLInfoAbout" "${PROJECT_ORGANIZATION_URL}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "UninstallString" '"$INSTDIR\uninst.exe"'

  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${REG_KEY_UNINSTALL}" "EstimatedSize" "$0"

  WriteUnInstaller "uninst.exe"

  ReadENVStr $R0 ALLUSERSPROFILE
  SetOutPath "$R0\PMS"
  AccessControl::GrantOnFile "$R0\PMS" "(S-1-5-32-545)" "FullAccess"
SectionEnd

Section "Start Menu Shortcuts"
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\${PROJECT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME}.lnk" "$INSTDIR\PMS.exe" "" "$INSTDIR\PMS.exe" 0
  CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME} (Select Profile).lnk" "$INSTDIR\PMS.exe" "profiles" "$INSTDIR\PMS.exe" 0
  CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\Uninstall.lnk" "$INSTDIR\uninst.exe" "" "$INSTDIR\uninst.exe" 0
SectionEnd

Section "Uninstall"
  SetShellVarContext all

  nsSCM::Stop "${PROJECT_NAME}"
  nsSCM::Remove "${PROJECT_NAME}"

  Delete /REBOOTOK "$INSTDIR\uninst.exe"
  RMDir /R /REBOOTOK "$INSTDIR\plugins"
  RMDir /R /REBOOTOK "$INSTDIR\renderers"
  RMDir /R /REBOOTOK "$INSTDIR\documentation"
  RMDir /R /REBOOTOK "$INSTDIR\win32"
  RMDir /R /REBOOTOK "$INSTDIR\jre"
  RMDir /R /REBOOTOK "$INSTDIR\jre64"
  Delete /REBOOTOK "$INSTDIR\PMS.exe"
  Delete /REBOOTOK "$INSTDIR\PMS.bat"
  Delete /REBOOTOK "$INSTDIR\pms.jar"
  Delete /REBOOTOK "$INSTDIR\MediaInfo.dll"
  Delete /REBOOTOK "$INSTDIR\MediaInfo64.dll"
  Delete /REBOOTOK "$INSTDIR\CHANGELOG.txt"
  Delete /REBOOTOK "$INSTDIR\WEB.conf"
  Delete /REBOOTOK "$INSTDIR\README.md"
  Delete /REBOOTOK "$INSTDIR\LICENSE.txt"
  Delete /REBOOTOK "$INSTDIR\debug.log"
  Delete /REBOOTOK "$INSTDIR\logback.xml"
  Delete /REBOOTOK "$INSTDIR\icon.ico"
  RMDir /REBOOTOK "$INSTDIR"

  Delete /REBOOTOK "$DESKTOP\${PROJECT_NAME}.lnk"
  RMDir /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}"
  Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME}.lnk"
  Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME} (Select Profile).lnk"
  Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\Uninstall.lnk"

  DeleteRegKey HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}"
  DeleteRegKey HKCU "${REG_KEY_SOFTWARE}"
SectionEnd
