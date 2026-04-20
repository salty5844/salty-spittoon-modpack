!include "WinMessages.nsh"

!define VERSION "26.1.0.0"

Name "Salty-Signer-${VERSION}"
Caption "Salty-Signer"
OutFile "Salty-Signer-${VERSION}.exe"
Icon        "sign-icon.ico"
RequestExecutionLevel user
InstProgressFlags smooth

VIProductVersion "${VERSION}"
VIAddVersionKey "ProductName" "Salty-Signer"
VIAddVersionKey "FileDescription" "Salty-Signer"
VIAddVersionKey "CompanyName" "Taylor Kerr"
VIAddVersionKey "LegalCopyright" "(c) 2026 Taylor Kerr"
VIAddVersionKey "FileVersion" "${VERSION}"

!define SIGNTOOL '"C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"'

Var Compiler_ScriptPath
Var Compiler_ExePath
Var Compiler_Retries
Var Compiler_CompileExit
Var Compiler_SignExit

ShowInstDetails show

PageEx instfiles
    PageCallbacks "" InstFilesShow
PageExEnd

; ----------------------------
; Button Control Functions
; ----------------------------

Function HideNavButtons
    GetDlgItem $0 $HWNDPARENT 1
    ShowWindow $0 ${SW_HIDE}
    EnableWindow $0 0

    GetDlgItem $1 $HWNDPARENT 2
    ShowWindow $1 ${SW_HIDE}
    EnableWindow $1 0

    GetDlgItem $2 $HWNDPARENT 3
    ShowWindow $2 ${SW_HIDE}
    EnableWindow $2 0
FunctionEnd

Function ForceTitle
    SendMessage $HWNDPARENT ${WM_SETTEXT} 0 "STR:Salty-Signer"
FunctionEnd

Function .onGUIInit
    Call HideNavButtons
FunctionEnd

Function InstFilesShow
    Call ForceTitle
FunctionEnd

; ----------------------------
; Main Section
; ----------------------------

Section

    SetAutoClose false

    DetailPrint "=== Salty-Signer ==="
    DetailPrint ""

    ; ----------------------------
    ; Working Directory
    ; ----------------------------
    DetailPrint "Working directory:"
    DetailPrint "$EXEDIR"
    DetailPrint ""

    ; ----------------------------
    ; Find NSIS script
    ; ----------------------------
    DetailPrint "Searching for NSIS script..."

    FindFirst $0 $1 "$EXEDIR\installer.nsi"
    StrCmp $1 "" notfound

    StrCpy $Compiler_ScriptPath "$EXEDIR\$1"

    DetailPrint "Found script:"
    DetailPrint "$Compiler_ScriptPath"
    DetailPrint ""

    ; ----------------------------
    ; Compile (FIXED)
    ; ----------------------------
    DetailPrint "Compiling..."

    DetailPrint "Starting makensis..."

    nsExec::ExecToStack '"$PROGRAMFILES\NSIS\makensis.exe" /V4 "$Compiler_ScriptPath"'
    Pop $Compiler_CompileExit
    Pop $0

    DetailPrint "makensis output (last line):"
    DetailPrint "$0"

    DetailPrint "Compile finished."
    DetailPrint "makensis exit code: $Compiler_CompileExit"

    StrCmp $Compiler_CompileExit "0" 0 compile_fail

    ; ----------------------------
    ; Locate EXE
    ; ----------------------------
    DetailPrint ""
    DetailPrint "Locating compiled EXE..."

    FindFirst $0 $1 "$EXEDIR\Salty-Spittoon-Minecraft-Modpack*.exe"
    StrCmp $1 "" exe_not_found

    StrCpy $Compiler_ExePath "$EXEDIR\$1"

loop_exe:
    FindNext $0 $1
    StrCmp $1 "" done_exe
    StrCpy $Compiler_ExePath "$EXEDIR\$1"
    Goto loop_exe

done_exe:
    FindClose $0

    DetailPrint "Detected EXE:"
    DetailPrint "$Compiler_ExePath"
    Goto exe_done

exe_not_found:
    DetailPrint "ERROR: No EXE found after compilation."
    Call ForceTitle
    Goto done

exe_done:

    ; ----------------------------
    ; Metadata check
    ; ----------------------------
    DetailPrint ""
    DetailPrint "Checking for metadata.json..."

    IfFileExists "$EXEDIR\metadata.json" metadata_found metadata_missing

metadata_found:
    DetailPrint "Metadata found:"
    DetailPrint "$EXEDIR\metadata.json"
    Goto sign_start

metadata_missing:
    DetailPrint "ERROR: metadata.json not found in:"
    DetailPrint "$EXEDIR"
    Goto done

sign_start:

    ; ----------------------------
    ; Signing
    ; ----------------------------
    DetailPrint ""
    DetailPrint "=== Signing ==="

    StrCpy $Compiler_Retries 0

retry_sign:
    IntOp $Compiler_Retries $Compiler_Retries + 1

    DetailPrint ""
    DetailPrint "Signing attempt $Compiler_Retries..."

    nsExec::ExecToStack '${SIGNTOOL} sign /v /fd SHA256 /td SHA256 /tr http://timestamp.acs.microsoft.com /d "Salty Spittoon Minecraft Modpack" /dlib "$LOCALAPPDATA\Microsoft\MicrosoftArtifactSigningClientTools\Azure.CodeSigning.Dlib.dll" /dmdf "$EXEDIR\metadata.json" "$Compiler_ExePath"'
    Pop $Compiler_SignExit
    Pop $0

    DetailPrint "SignTool output (last line):"
    DetailPrint "$0"

    DetailPrint "SignTool exit code: $Compiler_SignExit"

    StrCmp $Compiler_SignExit "0" sign_success
    StrCmp $Compiler_Retries "5" sign_fail

    DetailPrint "Signing failed, retrying..."
    Sleep 2000
    Goto retry_sign

sign_success:
    DetailPrint ""
    DetailPrint "Signing completed successfully."
    Goto done

compile_fail:
    DetailPrint ""
    DetailPrint "ERROR: Compilation failed."
    Call ForceTitle
    Goto done

sign_fail:
    DetailPrint ""
    DetailPrint "ERROR: Signing failed after 5 attempts."
    Call ForceTitle
    Goto done

notfound:
    DetailPrint ""
    DetailPrint "ERROR: No NSIS script found."
    Call ForceTitle
    Goto done

done:
    DetailPrint ""
    DetailPrint "=== DONE ==="
    Call ForceTitle

    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 1
    ShowWindow $0 ${SW_SHOW}

    GetDlgItem $1 $HWNDPARENT 2
    ShowWindow $1 ${SW_HIDE}

    GetDlgItem $2 $HWNDPARENT 3
    ShowWindow $2 ${SW_HIDE}

    BringToFront

SectionEnd