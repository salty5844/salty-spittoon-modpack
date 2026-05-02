!define MODPACK_VERSION "26.1.2.1"
!define MODPACK_NAME "Salty-Spittoon-Minecraft-Modpack"

InstallDir  "$APPDATA\.minecraft"
Name        "${MODPACK_NAME} ${MODPACK_VERSION}"
OutFile     "${__FILEDIR__}\${MODPACK_NAME}-${MODPACK_VERSION}.exe"
Icon        "icon.ico"
UninstallIcon "icon.ico"

VIProductVersion                 "${MODPACK_VERSION}"
VIAddVersionKey ProductName      "${MODPACK_NAME}"
VIAddVersionKey CompanyName      "Taylor Kerr"
VIAddVersionKey LegalCopyright   "(c) 2026 Taylor Kerr"
VIAddVersionKey FileDescription  "Minecraft modpack installer for the Salty Spittoon"
VIAddVersionKey FileVersion      "${MODPACK_VERSION}"

!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\SaltySpittoonModpack"

ShowInstDetails show
ShowUninstDetails show

RequestExecutionLevel user

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"
!include "WordFunc.nsh"

!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"

Page custom ChoicePage ChoicePageLeave

!define MUI_PAGE_CUSTOMFUNCTION_SHOW InstFilesShow
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Var Dialog
Var InfoLabel
Var InstallButton
Var UninstallButton
Var Choice
Var BackupFolder
Var YY
Var YYYY
Var MM
Var DD
Var HH
Var Min
Var HasPrevManifest
Var InstalledVersion
Var CompareResult
Var PrimaryAction
Var SecondaryAction
Var HideTimer
Var LocalTimePtr
Var ResourcePackFaithful
Var ResourcePackDarkMode
Var ResourcePackLine
Var OptionsInHandle
Var OptionsOutHandle
Var OptionsLine
Var OptionsTempFile
Var ResourcePacksLineFound
Var ShaderPackName
Var IrisInHandle
Var IrisOutHandle
Var IrisLine
Var IrisTempFile
Var ShaderPackLineFound

Var LauncherVersionId
Var LauncherProfileName
Var LauncherProfilesTempFile
Var LauncherProfilesInHandle
Var LauncherProfilesOutHandle
Var LauncherProfilesLine
Var LauncherProfilesLine2
Var LauncherProfilesLine3

Function .onInit
  SetShellVarContext current

  ; =========================
  ; CHECK IF MINECRAFT IS RUNNING
  ; =========================

  check_mc:

  ; Check javaw.exe
  nsExec::ExecToStack 'cmd /C tasklist /FI "IMAGENAME eq javaw.exe" | find /I "javaw.exe" >nul'
  Pop $0 ; exit code

  StrCmp $0 0 mc_running

  ; Check MinecraftLauncher.exe
  nsExec::ExecToStack 'cmd /C tasklist /FI "IMAGENAME eq MinecraftLauncher.exe" | find /I "MinecraftLauncher.exe" >nul'
  Pop $0 ; exit code

  StrCmp $0 0 mc_running

  Goto mc_not_running

  mc_running:
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
    "Minecraft or the Minecraft Launcher is currently running.$\r$\n$\r$\nPlease close it before continuing." \
    IDRETRY check_mc IDCANCEL cancel_mc

  cancel_mc:
    Abort

  mc_not_running:

  ; SINGLE INSTANCE CHECK
  System::Call 'kernel32::CreateMutex(i 0, i 0, t "SaltySpittoonInstallerMutex") p .r1 ?e'
  Pop $0

  StrCmp $0 0 +3
    MessageBox MB_ICONSTOP|MB_OK "Please close any other installers before running the Salty Spittoon Modpack Installer"
    Abort

  ; Check if .minecraft exists
  IfFileExists "$APPDATA\.minecraft\*.*" continue not_found

  not_found:
    MessageBox MB_ICONSTOP|MB_OK "Please install and launch Minecraft before running the Salty Spittoon Modpack Installer"
    Abort

  continue:
    ; Safe to proceed
    StrCpy $INSTDIR "$APPDATA\.minecraft"
    Call DetectInstalledState
FunctionEnd

Function InstFilesShow
  GetDlgItem $0 $HWNDPARENT 1
  SendMessage $0 ${BM_CLICK} 0 0
FunctionEnd

Function HideNavButtons
  GetDlgItem $0 $HWNDPARENT 1
  ShowWindow $0 ${SW_HIDE}
  EnableWindow $0 0

  GetDlgItem $1 $HWNDPARENT 3
  ShowWindow $1 ${SW_HIDE}
  EnableWindow $1 0
FunctionEnd

Function ShowNavButtons
  GetDlgItem $0 $HWNDPARENT 1
  ShowWindow $0 ${SW_SHOW}
  EnableWindow $0 1

  GetDlgItem $1 $HWNDPARENT 3
  ShowWindow $1 ${SW_SHOW}
  EnableWindow $1 1
FunctionEnd

Function TrimCRLF
  Exch $0
  Push $1

  StrCpy $1 $0 1 -1
  StrCmp $1 "$\n" 0 +2
    StrCpy $0 $0 -1

  StrCpy $1 $0 1 -1
  StrCmp $1 "$\r" 0 +2
    StrCpy $0 $0 -1

  Pop $1
  Exch $0
FunctionEnd

Function un.TrimCRLF
  Exch $0
  Push $1

  StrCpy $1 $0 1 -1
  StrCmp $1 "$\n" 0 +2
    StrCpy $0 $0 -1

  StrCpy $1 $0 1 -1
  StrCmp $1 "$\r" 0 +2
    StrCpy $0 $0 -1

  Pop $1
  Exch $0
FunctionEnd

Function ReadManifestVersion
  Push $0
  Push $1
  Push $2
  Push $3

  StrCpy $0 "0.0.0.0"

  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 done

  ClearErrors
  FileOpen $1 "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" r
  IfErrors done

  loop:
    ClearErrors
    FileRead $1 $2
    IfErrors end

    Push $2
    Call TrimCRLF
    Pop $2

    StrCmp $2 "" loop

    StrCpy $3 $2 8
    StrCmp $3 "Version=" 0 end
      StrCpy $0 $2 "" 8
      Goto end

  end:
    FileClose $1

  done:
    Pop $3
    Pop $2
    Pop $1
    Exch $0
FunctionEnd

Function DetectInstalledState
  StrCpy $HasPrevManifest "0"
  StrCpy $InstalledVersion "0.0.0.0"
  StrCpy $CompareResult "1"

  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 done
    StrCpy $HasPrevManifest "1"
    Call ReadManifestVersion
    Pop $InstalledVersion
    ${VersionCompare} "${MODPACK_VERSION}" "$InstalledVersion" $CompareResult

  done:
FunctionEnd

Function BuildInstalledResourcePackLine
  Push $0
  Push $1
  Push $2
  Push $3

  StrCpy $ResourcePackFaithful ""
  StrCpy $ResourcePackDarkMode ""
  StrCpy $ResourcePackLine 'resourcePacks:[]'

  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 done

  ClearErrors
  FileOpen $0 "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" r
  IfErrors done

  loop:
    ClearErrors
    FileRead $0 $1
    IfErrors end

    Push $1
    Call TrimCRLF
    Pop $1

    StrCmp $1 "" loop

    StrCpy $2 $1 14
    StrCmp $2 "resourcepacks\" 0 loop

    StrCpy $3 $1 22
    StrCmp $3 "resourcepacks\Faithful" 0 check_dark
      StrCpy $ResourcePackFaithful $1 "" 14
      Goto loop

    check_dark:
    StrCpy $3 $1 26
    StrCmp $3 "resourcepacks\Default-Dark" 0 loop
      StrCpy $ResourcePackDarkMode $1 "" 14
      Goto loop

  end:
    FileClose $0

  done:
    StrCpy $ResourcePackLine 'resourcePacks:["vanilla"'

    StrCmp $ResourcePackFaithful "" +3
      StrCpy $ResourcePackLine '$ResourcePackLine,"file/$ResourcePackFaithful"'

    StrCmp $ResourcePackDarkMode "" +3
      StrCpy $ResourcePackLine '$ResourcePackLine,"file/$ResourcePackDarkMode"'

    StrCpy $ResourcePackLine '$ResourcePackLine,"black_icons"'

    StrCpy $ResourcePackLine '$ResourcePackLine]'

    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function BuildLauncherProfileInfo
  Push $0
  Push $1
  Push $2
  Push $3

  ; Hardcode version ID (your new design)
  StrCpy $LauncherVersionId "salty-spittoon-modpack"

  ; Default fallback
  StrCpy $LauncherProfileName "Salty Spittoon"

  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 done

  ClearErrors
  FileOpen $0 "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" r
  IfErrors done

  loop:
    ClearErrors
    FileRead $0 $1
    IfErrors end

    Push $1
    Call TrimCRLF
    Pop $1

    StrCmp $1 "" loop

    ; Look for Version=
    StrCpy $2 $1 8
    StrCmp $2 "Version=" 0 loop

      ; Extract version string after "Version="
      StrCpy $3 $1 "" 8

      ; Build final profile name
      StrCpy $LauncherProfileName "Salty Spittoon $3"
      Goto end

  end:
    FileClose $0

  done:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function WriteLauncherProfileBlock
  Exch $0

  ; Close previous profile entry
  FileWrite $0 "},$\r$\n"

  ; Begin new profile
  FileWrite $0 '    "Salty Spittoon" : {$\r$\n'

  ; Icon (single uninterrupted line, properly closed + newline)
  FileWrite $0 '      "icon" : "data:image/png;base64,'

  FileWrite $0 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAN4SURBVFhH7VddSJNRGH76oYugoGRXu5jhZjLtQpggDjQF0fk3ltokxV3ojU5sjA2aJELiz3T+ETk0RC8VhUAjkfCfgVb+bEi3XRQEQTdRdPnGe/CTdVq6OTUCH3jYx/ed8z3Pec/7vt8ZcI74oAVwW755FrgOwAXgM4AvADwAbsiDTgMXANwD8C4/P5/GxsZoYmKCTCYTAQgCsAK4JE86KRgAvEhOTqauri5aW1ujUCgkuL6+Tr29vZSamspGXgLIlCfHAzWAPgDfHA4Hzc/P0+7uruD29rYgXweDQVpYWCCXy8UmvgN4CkAjvywWXAVgB/ChqqqKJicnaWtrSwgpwjKVZ9PT01RTU8NGPgJwALgmv/wwXARgAhDIycmh4eFh2tjYEKHe2dn5Q1Qmj+Gxm5ubNDIyQnl5eWzkDQBztPnBq6ba2lpaWVmhvb2938IdLdkIz+Vcqa+vZxNMtywWCX0qlYoyMjKos7NTmODQRrP6cHGOwurqqkjYrKws0mq1bMAvi0WCt7S0lDweD2VmZpLRaCS/3x/VNvAzNquEn+daLBZRqk1NTWyAE/NIeM1mMw0NDZHP5yO73U4ajYasVitNTU0JoUiJGJ6APNZgMFB/f7+oDI5Ec3Nz9Ab'
  
  FileWrite $0 'KyspoYGBAkI1wGKurqykhIYHkUgwvQafTSYmJidTS0kKzs7Ni+5aWlgSPZYBXwOTrwcFBamtro4KCAtLpdNTd3S0aUCAQoJ6eHkpJSaG6ujpRrsvLy4KLi4uCcRtQyCb4l5tNeno6FRYWUlFRkeDo6KgQ41UrwiduQCFvC7fe3Nxc0XB4S5Rwy+KnYkAxUVFRIaIRadWnboC3o7y8XCRe+H5H4v9ngPvAvzTgKy4uPig9WThWA0pJNjY2Rt2KH/K3gBtPR0eHSLZI0TjKAK+ak3Nubo5aW1spKSmJDfDR7UhcBmAB8Fav11NDQ4MoOTYSjQFFmDsjG+dPOoBdAPf1ev0VWeww8MHTCeBTdnY2ud3uA+G/GVB6wfj4OPEhZv/Q+ijeA+stAM8A/ODk5HbM4hwRxQB/bFh8ZmZGSbafAJ4D0MkviwdGAK/UajXZbDbyer1UWVkpIsOdsL29ndLS0lj8NYC78uSTAufHAwAhPrDwJ5eP5CUlJSz8HoANQEz7fFzcBPB4/0/JVwBPAKjkQWcBPYA78s1zxIJf9He0EFy3bx8AAAAASUVORK5CYII='

  FileWrite $0 '",$\r$\n'

  ; Remaining fields
  FileWrite $0 '      "javaArgs" : "-Xmx6G -XX:+UseZGC -XX:+ZGenerational",$\r$\n'
  FileWrite $0 '      "lastVersionId" : "$LauncherVersionId",$\r$\n'
  FileWrite $0 '      "name" : "$LauncherProfileName",$\r$\n'
  FileWrite $0 '      "type" : "custom"$\r$\n'

  ; Close profile + restore structure
  FileWrite $0 '    }$\r$\n'
  FileWrite $0 '  },$\r$\n'

  Exch $0
FunctionEnd

Function UpdateLauncherProfiles
  Push $0
  Push $1
  Push $2

  Call BuildLauncherProfileInfo
  StrCmp $LauncherVersionId "" done

  IfFileExists "$INSTDIR\launcher_profiles.json" 0 done

  GetTempFileName $LauncherProfilesTempFile

  ClearErrors
  FileOpen $LauncherProfilesInHandle "$INSTDIR\launcher_profiles.json" r
  IfErrors done

  ClearErrors
  FileOpen $LauncherProfilesOutHandle "$LauncherProfilesTempFile" w
  IfErrors close_in

  loop:
    ClearErrors
    FileRead $LauncherProfilesInHandle $LauncherProfilesLine
    IfErrors end

    Push $LauncherProfilesLine
    Call TrimCRLF
    Pop $0

    StrCmp $0 "}" check_line2
    StrCmp $0 "  }" check_line2
    StrCmp $0 "    }" check_line2
    StrCmp $0 "      }" check_line2
    Goto write_line1

  check_line2:
    ClearErrors
    FileRead $LauncherProfilesInHandle $LauncherProfilesLine2
    IfErrors write_line1_end

    Push $LauncherProfilesLine2
    Call TrimCRLF
    Pop $1

    StrCmp $1 "}," check_line3
    StrCmp $1 "  }," check_line3
    StrCmp $1 "    }," check_line3
    Goto write_line1_line2

  check_line3:
    ClearErrors
    FileRead $LauncherProfilesInHandle $LauncherProfilesLine3
    IfErrors write_line1_line2_end

    Push $LauncherProfilesLine3
    Call TrimCRLF
    Pop $2

    StrCmp $2 '  "settings" : {' inject_profile write_line1_line2_line3

  inject_profile:
    Push $LauncherProfilesOutHandle
    Call WriteLauncherProfileBlock
    FileWrite $LauncherProfilesOutHandle "$2$\r$\n"
    Goto loop

  write_line1_end:
    FileWrite $LauncherProfilesOutHandle "$0$\r$\n"
    Goto end

  write_line1_line2:
    FileWrite $LauncherProfilesOutHandle "$0$\r$\n"
    FileWrite $LauncherProfilesOutHandle "$1$\r$\n"
    Goto loop

  write_line1_line2_end:
    FileWrite $LauncherProfilesOutHandle "$0$\r$\n"
    FileWrite $LauncherProfilesOutHandle "$1$\r$\n"
    Goto end

  write_line1_line2_line3:
    FileWrite $LauncherProfilesOutHandle "$0$\r$\n"
    FileWrite $LauncherProfilesOutHandle "$1$\r$\n"
    FileWrite $LauncherProfilesOutHandle "$2$\r$\n"
    Goto loop

  write_line1:
    FileWrite $LauncherProfilesOutHandle "$0$\r$\n"
    Goto loop

  end:
    FileClose $LauncherProfilesOutHandle
    FileClose $LauncherProfilesInHandle

    SetDetailsPrint none
    Delete "$INSTDIR\launcher_profiles.json"
    Rename "$LauncherProfilesTempFile" "$INSTDIR\launcher_profiles.json"
    SetDetailsPrint both
    Goto done

  close_in:
    FileClose $LauncherProfilesInHandle

  done:
    SetDetailsPrint none
    Delete "$LauncherProfilesTempFile"
    SetDetailsPrint both
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function UpdateLauncherProfilesRemove
  Push $0
  Push $1
  Push $2
  Push $3

  StrCpy $0 "$INSTDIR\launcher_profiles.tmp"
  StrCpy $1 "$INSTDIR\launcher_profiles.json"

  IfFileExists "$1" 0 done

  Delete "$0"

  ClearErrors
  FileOpen $2 "$1" r
  IfErrors done

  ClearErrors
  FileOpen $3 "$0" w
  IfErrors close_in

  StrCpy $R0 0 ; skipping flag
  StrCpy $R6 "" ; previous line buffer

  loop:
    ClearErrors
    FileRead $2 $R1
    IfErrors end

    Push $R1
    Call TrimCRLF
    Pop $R1

    ; detect start of profile
    StrCmp $R1 '    "Salty Spittoon" : {' 0 continue
      StrCpy $R0 1
      Goto loop

  continue:
    ; if skipping, look for end of block
    StrCmp $R0 1 check_end write_normal

  check_end:
    StrCmp $R1 "    }," end_skip
    StrCmp $R1 "  }," end_skip
    StrCmp $R1 "    }" end_skip
    StrCmp $R1 "  }" end_skip
    Goto loop

  end_skip:
    StrCpy $R0 0

    ; Peek next line
    ClearErrors
    FileRead $2 $R2
    IfErrors flush_prev_and_end

    Push $R2
    Call TrimCRLF
    Pop $R2

    ; If next line is end of profiles -> REMOVE comma from previous
    StrCmp $R2 "  }," fix_prev
    StrCmp $R2 "    }," fix_prev
    StrCmp $R2 "    }" fix_prev
    StrCmp $R2 "}," fix_prev

    ; otherwise keep previous as-is
    Goto restore_next

  fix_prev:
    ; remove comma from previous line
    StrLen $R7 $R6
    IntOp $R7 $R7 - 1
    StrCpy $R6 $R6 $R7
    Goto restore_next

  restore_next:
    ; write previous (fixed or not)
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"

    ; move next line into buffer
    StrCpy $R6 $R2
    Goto loop

  write_normal:
    ; write previous first
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"

    StrCpy $R6 $R1
    Goto loop

  flush_prev_and_end:
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"
    Goto end

  end:
    ; flush last line
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"

    FileClose $2
    FileClose $3

    Delete "$1"
    Rename "$0" "$1"
    Goto done

  close_in:
    FileClose $2

  done:
    Delete "$0"
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function un.UpdateLauncherProfilesRemove
  Push $0
  Push $1
  Push $2
  Push $3

  StrCpy $0 "$INSTDIR\launcher_profiles.tmp"
  StrCpy $1 "$INSTDIR\launcher_profiles.json"

  IfFileExists "$1" 0 done

  Delete "$0"

  ClearErrors
  FileOpen $2 "$1" r
  IfErrors done

  ClearErrors
  FileOpen $3 "$0" w
  IfErrors close_in

  StrCpy $R0 0 ; skipping flag
  StrCpy $R6 "" ; previous line buffer

  loop:
    ClearErrors
    FileRead $2 $R1
    IfErrors end

    Push $R1
    Call un.TrimCRLF
    Pop $R1

    ; detect start of profile
    StrCmp $R1 '    "Salty Spittoon" : {' 0 continue
      StrCpy $R0 1
      Goto loop

  continue:
    ; if skipping, look for end of block
    StrCmp $R0 1 check_end write_normal

  check_end:
    StrCmp $R1 "    }," end_skip
    StrCmp $R1 "  }," end_skip
    StrCmp $R1 "    }" end_skip
    StrCmp $R1 "  }" end_skip
    Goto loop

  end_skip:
    StrCpy $R0 0

    ; Peek next line
    ClearErrors
    FileRead $2 $R2
    IfErrors flush_prev_and_end

    Push $R2
    Call un.TrimCRLF
    Pop $R2

    ; If next line is end of profiles -> REMOVE comma from previous
    StrCmp $R2 "  }," fix_prev
    StrCmp $R2 "    }," fix_prev
    StrCmp $R2 "    }" fix_prev
    StrCmp $R2 "}," fix_prev

    ; otherwise keep previous as-is
    Goto restore_next

  fix_prev:
    ; remove comma from previous line
    StrLen $R7 $R6
    IntOp $R7 $R7 - 1
    StrCpy $R6 $R6 $R7
    Goto restore_next

  restore_next:
    ; write previous (fixed or not)
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"

    ; move next line into buffer
    StrCpy $R6 $R2
    Goto loop

  write_normal:
    ; write previous first
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"

    StrCpy $R6 $R1
    Goto loop

  flush_prev_and_end:
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"
    Goto end

  end:
    ; flush last line
    StrCmp $R6 "" +2
      FileWrite $3 "$R6$\r$\n"

    FileClose $2
    FileClose $3

    Delete "$1"
    Rename "$0" "$1"
    Goto done

  close_in:
    FileClose $2

  done:
    Delete "$0"
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function UpdateMinecraftResourcePacks
  Push $0
  Push $1
  Push $2

  Call BuildInstalledResourcePackLine

  IfFileExists "$INSTDIR\options.txt" 0 done

  GetTempFileName $OptionsTempFile

  ClearErrors
  FileOpen $OptionsInHandle "$INSTDIR\options.txt" r
  IfErrors done

  ClearErrors
  FileOpen $OptionsOutHandle "$OptionsTempFile" w
  IfErrors close_in

  StrCpy $ResourcePacksLineFound "0"

  loop:
    ClearErrors
    FileRead $OptionsInHandle $OptionsLine
    IfErrors end

    Push $OptionsLine
    Call TrimCRLF
    Pop $0

    StrCpy $1 $0 14
    StrCmp $1 "resourcePacks:" 0 check_render_distance

      FileWrite $OptionsOutHandle "$ResourcePackLine$\r$\n"
      StrCpy $ResourcePacksLineFound "1"
      Goto loop

    check_render_distance:
    StrCpy $1 $0 15
    StrCmp $1 "renderDistance:" 0 check_simulation_distance

      FileWrite $OptionsOutHandle "renderDistance:10$\r$\n"
      Goto loop

    check_simulation_distance:
    StrCpy $1 $0 19
    StrCmp $1 "simulationDistance:" 0 write_original

      FileWrite $OptionsOutHandle "simulationDistance:10$\r$\n"
      Goto loop

    write_original:
      FileWrite $OptionsOutHandle "$0$\r$\n"
      Goto loop

  end:
    StrCmp $ResourcePacksLineFound "1" +2
      FileWrite $OptionsOutHandle "$ResourcePackLine$\r$\n"

    FileClose $OptionsOutHandle
    FileClose $OptionsInHandle

    SetDetailsPrint none
    Delete "$INSTDIR\options.txt"
    Rename "$OptionsTempFile" "$INSTDIR\options.txt"
    SetDetailsPrint both
    Goto done

  close_in:
    FileClose $OptionsInHandle

  done:
    SetDetailsPrint none
    Delete "$OptionsTempFile"
    SetDetailsPrint both
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function BuildInstalledShaderPackName
  Push $0
  Push $1
  Push $2

  StrCpy $ShaderPackName ""

  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 done

  ClearErrors
  FileOpen $0 "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" r
  IfErrors done

  loop:
    ClearErrors
    FileRead $0 $1
    IfErrors end

    Push $1
    Call TrimCRLF
    Pop $1

    StrCmp $1 "" loop

    StrCpy $2 $1 12
    StrCmp $2 "shaderpacks\" 0 loop
      StrCpy $ShaderPackName $1 "" 12
      Goto end

  end:
    FileClose $0

  done:
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function UpdateIrisProperties
  Push $0
  Push $1

  Call BuildInstalledShaderPackName
  StrCmp $ShaderPackName "" done

  SetDetailsPrint none
  CreateDirectory "$INSTDIR\config"
  SetDetailsPrint both

  IfFileExists "$INSTDIR\config\iris.properties" 0 create_new

  GetTempFileName $IrisTempFile

  ClearErrors
  FileOpen $IrisInHandle "$INSTDIR\config\iris.properties" r
  IfErrors done

  ClearErrors
  FileOpen $IrisOutHandle "$IrisTempFile" w
  IfErrors close_in

  StrCpy $ShaderPackLineFound "0"

  loop:
    ClearErrors
    FileRead $IrisInHandle $IrisLine
    IfErrors end

    Push $IrisLine
    Call TrimCRLF
    Pop $0

    StrCpy $1 $0 11
    StrCmp $1 "shaderPack=" 0 write_original

      FileWrite $IrisOutHandle "shaderPack=$ShaderPackName$\r$\n"
      StrCpy $ShaderPackLineFound "1"
      Goto loop

    write_original:
      FileWrite $IrisOutHandle "$0$\r$\n"
      Goto loop

  end:
    StrCmp $ShaderPackLineFound "1" +2
      FileWrite $IrisOutHandle "shaderPack=$ShaderPackName$\r$\n"

    FileClose $IrisOutHandle
    FileClose $IrisInHandle

    SetDetailsPrint none
    Delete "$INSTDIR\config\iris.properties"
    Rename "$IrisTempFile" "$INSTDIR\config\iris.properties"
    SetDetailsPrint both
    Goto done

  close_in:
    FileClose $IrisInHandle

  create_new:
    ClearErrors
    FileOpen $IrisOutHandle "$INSTDIR\config\iris.properties" w
    IfErrors done
    FileWrite $IrisOutHandle "shaderPack=$ShaderPackName$\r$\n"
    FileClose $IrisOutHandle

  done:
    SetDetailsPrint none
    Delete "$IrisTempFile"
    SetDetailsPrint both
    Pop $1
    Pop $0
FunctionEnd

; =========================
; INSTALLER HELPER
; =========================
Function DeleteManifestListedFile
  Exch $0
  Push $1
  Push $2

  ; strip leading ".\" if present
  StrCpy $2 $0 2
  StrCmp $2 ".\" 0 +2
    StrCpy $0 $0 "" 2

  ; strip leading "\" if present
  StrCpy $2 $0 1
  StrCmp $2 "\" 0 +2
    StrCpy $0 $0 "" 1

  StrCpy $1 "$INSTDIR\$0"

  IfFileExists "$1" 0 done
  SetFileAttributes "$1" NORMAL
  Delete "$1"

  done:
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

; =========================
; INSTALLER-SIDE SHARED DELETE
; =========================
Function RemoveFilesFromManifest
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4

  IfFileExists "$0" 0 done

  ClearErrors
  FileOpen $1 "$0" r
  IfErrors done

  loop:
    ClearErrors
    FileRead $1 $2
    IfErrors end

    Push $2
    Call TrimCRLF
    Pop $3

    StrCmp $3 "" loop

    StrCpy $4 $3 8
    StrCmp $4 "Version=" loop

    StrCpy $4 $3 5
    StrCmp $4 "mods\" check_jar check_versions

  check_versions:
    StrCpy $4 $3 9
    StrCmp $4 "versions\" check_versions_handler check_config

  check_config:
    StrCpy $4 $3 7
    StrCmp $4 "config\" check_properties check_resourcepacks

  check_properties:
    StrCpy $4 $3 11 -11
    StrCmp $4 ".properties" 0 loop
    Push $3
    Call DeleteManifestListedFile
    Goto loop

  check_resourcepacks:
    StrCpy $4 $3 14
    StrCmp $4 "resourcepacks\" check_zip check_shaderpacks

  check_shaderpacks:
    StrCpy $4 $3 12
    StrCmp $4 "shaderpacks\" check_zip loop

  check_versions_handler:
    StrCpy $4 $3 4 -4
    StrCmp $4 ".jar" 0 check_versions_json
    Push $3
    Call DeleteManifestListedFile
    Goto loop

  check_versions_json:
    StrCpy $4 $3 5 -5
    StrCmp $4 ".json" 0 loop
    Push $3
    Call DeleteManifestListedFile
    Goto loop

  check_jar:
    StrCpy $4 $3 4 -4
    StrCmp $4 ".jar" 0 loop
    Push $3
    Call DeleteManifestListedFile
    Goto loop

  check_zip:
    StrCpy $4 $3 4 -4
    StrCmp $4 ".zip" 0 loop
    Push $3
    Call DeleteManifestListedFile
    Goto loop

  end:
    FileClose $1

  done:
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

; =========================
; UNINSTALLER HELPER
; =========================
Function un.DeleteManifestListedFile
  Exch $0
  Push $1
  Push $2

  StrCpy $2 $0 2
  StrCmp $2 ".\" 0 +2
    StrCpy $0 $0 "" 2

  StrCpy $2 $0 1
  StrCmp $2 "\" 0 +2
    StrCpy $0 $0 "" 1

  StrCpy $1 "$INSTDIR\$0"

  IfFileExists "$1" 0 done
  SetFileAttributes "$1" NORMAL
  Delete "$1"

  done:
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

; =========================
; UNINSTALLER-SIDE SHARED DELETE
; =========================
Function un.RemoveFilesFromManifest
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4

  IfFileExists "$0" 0 done

  ClearErrors
  FileOpen $1 "$0" r
  IfErrors done

  loop:
    ClearErrors
    FileRead $1 $2
    IfErrors end

    Push $2
    Call un.TrimCRLF
    Pop $3

    StrCmp $3 "" loop

    StrCpy $4 $3 8
    StrCmp $4 "Version=" loop

    StrCpy $4 $3 5
    StrCmp $4 "mods\" check_jar check_versions

  check_versions:
    StrCpy $4 $3 9
    StrCmp $4 "versions\" check_versions_handler check_config

  check_config:
    StrCpy $4 $3 7
    StrCmp $4 "config\" check_properties check_resourcepacks

  check_properties:
    StrCpy $4 $3 11 -11
    StrCmp $4 ".properties" 0 loop
    Push $3
    Call un.DeleteManifestListedFile
    Goto loop

  check_resourcepacks:
    StrCpy $4 $3 14
    StrCmp $4 "resourcepacks\" check_zip check_shaderpacks

  check_shaderpacks:
    StrCpy $4 $3 12
    StrCmp $4 "shaderpacks\" check_zip loop

  check_versions_handler:
    StrCpy $4 $3 4 -4
    StrCmp $4 ".jar" 0 check_versions_json
    Push $3
    Call un.DeleteManifestListedFile
    Goto loop

  check_versions_json:
    StrCpy $4 $3 5 -5
    StrCmp $4 ".json" 0 loop
    Push $3
    Call un.DeleteManifestListedFile
    Goto loop

  check_jar:
    StrCpy $4 $3 4 -4
    StrCmp $4 ".jar" 0 loop
    Push $3
    Call un.DeleteManifestListedFile
    Goto loop

  check_zip:
    StrCpy $4 $3 4 -4
    StrCmp $4 ".zip" 0 loop
    Push $3
    Call un.DeleteManifestListedFile
    Goto loop

  end:
    FileClose $1

  done:
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function MakeBackupFolders
  System::Alloc 16
  Pop $LocalTimePtr
  StrCpy $8 $LocalTimePtr
  System::Call "kernel32::GetLocalTime(p r8)"
  System::Call "*$8(&i2.r0,&i2.r1,&i2.r2,&i2.r3,&i2.r4,&i2.r5,&i2.r6,&i2.r7)"
  System::Free $8

  IntFmt $YYYY "%04u" $0
  IntFmt $MM   "%02u" $1
  IntFmt $DD   "%02u" $3
  IntFmt $HH   "%02u" $4
  IntFmt $Min  "%02u" $5
  IntFmt $6    "%02u" $6

  StrCpy $YY $YYYY 2 2
  StrCpy $BackupFolder "backup_$MM-$DD-$YY-$HH$Min$6"

  CreateDirectory "$INSTDIR\$BackupFolder"
  CreateDirectory "$INSTDIR\$BackupFolder\config"
  CreateDirectory "$INSTDIR\$BackupFolder\mods"
  CreateDirectory "$INSTDIR\$BackupFolder\resourcepacks"
  CreateDirectory "$INSTDIR\$BackupFolder\shaderpacks"

  CreateDirectory "$INSTDIR\config"
  CreateDirectory "$INSTDIR\mods"
  CreateDirectory "$INSTDIR\resourcepacks"
  CreateDirectory "$INSTDIR\shaderpacks"

  nsExec::ExecToLog 'cmd /C xcopy /E /I /Y /H "$INSTDIR\config" "$INSTDIR\$BackupFolder\config"'
  Pop $0

  nsExec::ExecToLog 'cmd /C xcopy /E /I /Y /H "$INSTDIR\mods" "$INSTDIR\$BackupFolder\mods"'
  Pop $0

  nsExec::ExecToLog 'cmd /C xcopy /Y /H "$INSTDIR\options.txt" "$INSTDIR\$BackupFolder\"'
  Pop $0

  nsExec::ExecToLog 'cmd /C xcopy /E /I /Y /H "$INSTDIR\resourcepacks" "$INSTDIR\$BackupFolder\resourcepacks"'
  Pop $0

  nsExec::ExecToLog 'cmd /C xcopy /E /I /Y /H "$INSTDIR\shaderpacks" "$INSTDIR\$BackupFolder\shaderpacks"'
  Pop $0

  Delete "$INSTDIR\mods\*.jar"
  Delete "$INSTDIR\resourcepacks\*.zip"
  Delete "$INSTDIR\shaderpacks\*.zip"

FunctionEnd

Function ModrinthDownload
  IfFileExists "$INSTDIR\salty-spittoon-modpack\modrinth-download.ps1" 0 script_missing

  DetailPrint "Downloading Modrinth projects..."

  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\salty-spittoon-modpack\modrinth-download.ps1"'
  Pop $0 ; exit code

  StrCmp $0 0 success
    MessageBox MB_ICONSTOP "Modrinth download failed."
    Abort

success:
  SetDetailsPrint none
  Delete "$INSTDIR\salty-spittoon-modpack\modrinth-download.ps1"
  SetDetailsPrint both
  Return

script_missing:
  MessageBox MB_ICONSTOP "Modrinth download script not found. Installation cannot continue."
  Abort
FunctionEnd

Function PromptForPowerShell7
  ; Check for PowerShell 7 (pwsh). If missing, offer to open install page.
  nsExec::ExecToStack 'cmd /C where pwsh >nul 2>nul'
  Pop $0 ; exit code

  StrCmp $0 0 done

  MessageBox MB_YESNO|MB_ICONEXCLAMATION "PowerShell 7 not detected. The installer will be significantly slower with previous versions of PowerShell.$\r$\n$\r$\nWould you like to close the installer and open the PowerShell 7 installation page?" IDYES open_ps7_link IDNO done

  open_ps7_link:
    ExecShell "open" "https://apps.microsoft.com/detail/9mz1snwt0n5d?hl=en-US&gl=US"
    Quit

  done:
FunctionEnd

Function RemoveInstalledModpack
  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 done

  Push "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt"
  Call RemoveFilesFromManifest
  Call UpdateLauncherProfilesRemove

  RMDir /r "$INSTDIR\salty-spittoon-modpack"
  RMDir /r "$INSTDIR\versions\salty-spittoon-modpack"

  Delete "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt"
  Delete "$INSTDIR\uninstall_salty_spittoon.exe"
  DeleteRegKey HKCU "${UNINST_KEY}"

  done:
FunctionEnd

; =========================
; UI Page
; =========================
Function ChoicePage
  nsDialogs::Create 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}

  Call HideNavButtons
  nsDialogs::CreateTimer HideNavButtons 25
  Pop $HideTimer

  StrCpy $PrimaryAction ""
  StrCpy $SecondaryAction ""

  ${If} $HasPrevManifest == "0"
    ${NSD_CreateLabel} 0 0 100% 30u "No Salty Spittoon installation was detected.$\r$\n$\r$\nWould you like to install version ${MODPACK_VERSION}?"
    Pop $InfoLabel

    ${NSD_CreateButton} 125u 40u 80u 20u "Install"
    Pop $InstallButton
    ${NSD_OnClick} $InstallButton PrimaryButtonClick

    StrCpy $PrimaryAction "install"

  ${Else}
    ${If} $CompareResult == "1"
      ${NSD_CreateLabel} 0 0 100% 36u "Older version detected: $InstalledVersion$\r$\n$\r$\nWould you like to upgrade to version ${MODPACK_VERSION} or uninstall the existing version?"
      Pop $InfoLabel

      ${NSD_CreateButton} 80u 48u 80u 20u "Upgrade"
      Pop $InstallButton
      ${NSD_OnClick} $InstallButton PrimaryButtonClick

      ${NSD_CreateButton} 170u 48u 80u 20u "Uninstall"
      Pop $UninstallButton
      ${NSD_OnClick} $UninstallButton SecondaryButtonClick

      StrCpy $PrimaryAction "update"
      StrCpy $SecondaryAction "uninstall"

    ${ElseIf} $CompareResult == "0"
      ${NSD_CreateLabel} 0 0 100% 36u "Version $InstalledVersion is already installed.$\r$\n$\r$\nWould you like to reinstall version ${MODPACK_VERSION} or uninstall the existing version?"
      Pop $InfoLabel

      ${NSD_CreateButton} 80u 48u 80u 20u "Reinstall"
      Pop $InstallButton
      ${NSD_OnClick} $InstallButton PrimaryButtonClick

      ${NSD_CreateButton} 170u 48u 80u 20u "Uninstall"
      Pop $UninstallButton
      ${NSD_OnClick} $UninstallButton SecondaryButtonClick

      StrCpy $PrimaryAction "reinstall"
      StrCpy $SecondaryAction "uninstall"

    ${Else}
      ${NSD_CreateLabel} 0 0 100% 36u "Newer version detected: $InstalledVersion$\r$\n$\r$\nWould you like to downgrade to version ${MODPACK_VERSION} or uninstall the existing version?"
      Pop $InfoLabel

      ${NSD_CreateButton} 80u 48u 80u 20u "Downgrade"
      Pop $InstallButton
      ${NSD_OnClick} $InstallButton PrimaryButtonClick

      ${NSD_CreateButton} 170u 48u 80u 20u "Uninstall"
      Pop $UninstallButton
      ${NSD_OnClick} $UninstallButton SecondaryButtonClick

      StrCpy $PrimaryAction "downgrade"
      StrCpy $SecondaryAction "uninstall"
    ${EndIf}
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function PrimaryButtonClick
  StrCpy $Choice $PrimaryAction
  SendMessage $HWNDPARENT 0x408 1 0
FunctionEnd

Function SecondaryButtonClick
  StrCpy $Choice $SecondaryAction
  SendMessage $HWNDPARENT 0x408 1 0
FunctionEnd

Function ChoicePageLeave
  StrCmp $HideTimer "" +2
    nsDialogs::KillTimer $HideTimer

  Call ShowNavButtons

  ${If} $Choice == ""
    Abort
  ${EndIf}
FunctionEnd

; =========================
; Install / Update / Uninstall decision
; =========================
Section "DecideInstallUpdateUninstall"
  SetShellVarContext current
  StrCpy $INSTDIR "$APPDATA\.minecraft"

  ${If} $Choice == "uninstall"
    IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 uninstall_no_manifest

    MessageBox MB_OK "Uninstalling ${MODPACK_NAME}.$\r$\n$\r$\nConfiguration files and backup folders will remain."
    Call RemoveInstalledModpack
    MessageBox MB_OK "${MODPACK_NAME} has been uninstalled successfully."
    Quit

    uninstall_no_manifest:
      MessageBox MB_OK "No installed manifest was found. Nothing was removed."
      Quit
  ${EndIf}

  ${If} $Choice == "update"
    MessageBox MB_YESNO "This will upgrade ${MODPACK_NAME} to version ${MODPACK_VERSION}.$\r$\n$\r$\nContinue?" IDYES do_update IDNO cancel_update

    do_update:
      Call PromptForPowerShell7
      Call RemoveInstalledModpack
      Goto done_decide

    cancel_update:
      Quit
  ${EndIf}

  ${If} $Choice == "reinstall"
    MessageBox MB_YESNO "This will reinstall ${MODPACK_NAME} version ${MODPACK_VERSION}.$\r$\n$\r$\nContinue?" IDYES do_reinstall IDNO cancel_reinstall

    do_reinstall:
      Call PromptForPowerShell7
      Call RemoveInstalledModpack
      Goto done_decide

    cancel_reinstall:
      Quit
  ${EndIf}

  ${If} $Choice == "downgrade"
    MessageBox MB_YESNO "This will downgrade ${MODPACK_NAME} to version ${MODPACK_VERSION}.$\r$\n$\r$\nContinue?" IDYES do_downgrade IDNO cancel_downgrade

    do_downgrade:
      Call PromptForPowerShell7
      Call RemoveInstalledModpack
      Goto done_decide

    cancel_downgrade:
      Quit
  ${EndIf}

  ${If} $Choice == "install"
    Call PromptForPowerShell7

    MessageBox MB_YESNO|MB_ICONQUESTION \
    "Any current mods, resourcepacks, or shaderpacks will be removed and configuration files will be altered.$\r$\n$\r$\nWould you like to create a backup?" \
    IDYES do_backup IDNO skip_backup

    do_backup:
      Call MakeBackupFolders
      Goto done_decide

    skip_backup:
      CreateDirectory "$INSTDIR\mods"
      CreateDirectory "$INSTDIR\resourcepacks"
      CreateDirectory "$INSTDIR\shaderpacks"
  
      Delete "$INSTDIR\mods\*.jar"
      Delete "$INSTDIR\resourcepacks\*.zip"
      Delete "$INSTDIR\shaderpacks\*.zip"
      Goto done_decide
      ${EndIf}

      done_decide:
SectionEnd

Section "CopyModpackFiles"
  SetOutPath "$INSTDIR\config"
  File /nonfatal /a /r "config\*.*"

  SetOutPath "$INSTDIR\salty-spittoon-modpack"
  File /nonfatal /a /r "salty-spittoon-modpack\*.*"

  SetOutPath "$INSTDIR\shaderpacks"
  File /nonfatal /a /r "shaderpacks\*.*"

  SetOutPath "$INSTDIR\versions"
  File /nonfatal /a /r "versions\*.*"
  Call ModrinthDownload
SectionEnd


Section "FinalizeInstall"
  DetailPrint "Configuring iris.properties"
  Call UpdateIrisProperties
  DetailPrint "Configuring options.txt"
  Call UpdateMinecraftResourcePacks
  Call UpdateLauncherProfiles

  WriteUninstaller "$INSTDIR\uninstall_salty_spittoon.exe"

  WriteRegStr HKCU "${UNINST_KEY}" "DisplayName" "${MODPACK_NAME}"
  WriteRegStr HKCU "${UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall_salty_spittoon.exe"'
  WriteRegStr HKCU "${UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\uninstall_salty_spittoon.exe" /S'
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayVersion" "${MODPACK_VERSION}"
  WriteRegStr HKCU "${UNINST_KEY}" "Publisher" "Taylor Kerr"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\uninstall_salty_spittoon.exe"
  WriteRegStr HKCU "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1

  MessageBox MB_OK "${MODPACK_NAME} has been successfully installed.$\r$\n$\r$\nA modpack profile has been added to the Minecraft Launcher."
SectionEnd

; =========================
; Uninstaller EXE / Programs and Features
; =========================
Section "un.Uninstall"
  SetShellVarContext current
  StrCpy $INSTDIR "$APPDATA\.minecraft"

  IfFileExists "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt" 0 no_manifest

  MessageBox MB_OK "Uninstalling ${MODPACK_NAME}.$\r$\n$\r$\nConfiguration files and backup folders will remain."

  Push "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt"
  Call un.RemoveFilesFromManifest
  Call un.UpdateLauncherProfilesRemove

  RMDir /r "$INSTDIR\salty-spittoon-modpack"
  RMDir /r "$INSTDIR\versions\salty-spittoon-modpack"

  Delete "$INSTDIR\salty-spittoon-modpack\modpack-manifest.txt"
  Delete "$INSTDIR\uninstall_salty_spittoon.exe"
  DeleteRegKey HKCU "${UNINST_KEY}"

  MessageBox MB_OK "${MODPACK_NAME} has been uninstalled successfully."
  Goto done

  no_manifest:
    MessageBox MB_OK "No installed manifest was found. Nothing was removed."

  done:
SectionEnd

Function un.onInit
  SetShellVarContext current
  StrCpy $INSTDIR "$APPDATA\.minecraft"
  
check_mc_un:

  ; Check javaw.exe
  nsExec::ExecToStack 'cmd /C tasklist /FI "IMAGENAME eq javaw.exe" | find /I "javaw.exe" >nul'
  Pop $0

  StrCmp $0 0 mc_running_un

  ; Check MinecraftLauncher.exe
  nsExec::ExecToStack 'cmd /C tasklist /FI "IMAGENAME eq MinecraftLauncher.exe" | find /I "MinecraftLauncher.exe" >nul'
  Pop $0

  StrCmp $0 0 mc_running_un

  Goto mc_not_running_un

mc_running_un:
  MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
  "Minecraft or the Minecraft Launcher is currently running.$\r$\n$\r$\nPlease close it before uninstalling." \
  IDRETRY check_mc_un IDCANCEL cancel_mc_un

cancel_mc_un:
  Abort

mc_not_running_un:
FunctionEnd