#Requires AutoHotkey v2.0
#SingleInstance Force

; Set coordinate mode relative to the active window's client area (ignores title bar/borders)
CoordMode "Mouse", "Client"

; --- GLOBAL VARIABLES DECLARATION ---
global IniFile := A_ScriptDir "\config.ini"
global GameExe := "ahk_exe BlueArchive.exe" ; <--- Change to your specific emulator/game executable
global MacroList := Map()
global QuickCastList := Map()
global IsRecording := false
global TempName := "", TempKey := "", TempPreKey := ""
global TempMode := "Normal", TempNoRet := 0
global EnableTooltip := 1

; --- INITIALIZATION ---
LoadSettings()

; --- GUI INTERFACE CREATION ---
MyGui := Gui("+AlwaysOnTop", "Blue Archive Macro Manager")
MyGui.SetFont("s9", "Segoe UI")

; PANEL 1: Targeted Macro (Coordinate-Locked)
MyGui.Add("GroupBox", "w270 h250", "Targeted Macro (Coordinate-Locked)")
MyGui.Add("Text", "xp+10 yp+20", "Select Profile or Enter New Name:")

ComboName := MyGui.Add("ComboBox", "w250 vMacroName", [])
ComboName.OnEvent("Change", AutoFillMacro)

MyGui.Add("Text", "w115", "Trigger Keybind:")
EditKey := MyGui.Add("Edit", "w115 vKeybind", "F3")

MyGui.Add("Text", "x+10 yp w115", "Pre-Key (Optional):")
EditPreKey := MyGui.Add("Edit", "w115 vPreKey", "")

MyGui.Add("Text", "xm+10 y+15 w90", "Execution Mode:")
DDL_ExecMode := MyGui.Add("DropDownList", "x+5 yp-3 w155 vExecMode Choose1", ["Normal", "Hold (Aiming)", "Spam (Turbo)"])

ChkNoRet := MyGui.Add("CheckBox", "xm+10 y+10 vNoReturn", "Do not restore cursor position (No-Return)")

BtnSaveEdit := MyGui.Add("Button", "xm+10 y+10 w250 h26", "Save Profile Settings (Preserve Coordinates)")
BtnSaveEdit.OnEvent("Click", SaveChanges)

BtnRecord := MyGui.Add("Button", "xm+10 y+5 w250 h26", "Create New / Overwrite Coordinates (/)")
BtnRecord.OnEvent("Click", TriggerRecord)

; PANEL: Active Targeted Macros
MyGui.Add("GroupBox", "xm w270 h90", "Active Targeted Macros")
DDL_Macro := MyGui.Add("DropDownList", "xp+10 yp+20 w250 vSelectedMacro")

BtnDelete := MyGui.Add("Button", "w250", "Delete Selected Macro")
BtnDelete.OnEvent("Click", DeleteMacro)

; PANEL 2: Quick Cast (Cursor-bound Spam)
MyGui.Add("GroupBox", "xm w270 h115", "Quick Cast (Spam at Cursor Position)")
MyGui.Add("Text", "xp+10 yp+20 w60", "Slot 1:")
QCEdit1 := MyGui.Add("Edit", "x+5 yp-2 w55 vQC1", "")
MyGui.Add("Text", "x+10 yp+2 w60", "Slot 2:")
QCEdit2 := MyGui.Add("Edit", "x+5 yp-2 w55 vQC2", "")

MyGui.Add("Text", "xm+10 y+10 w60", "Slot 3:")
QCEdit3 := MyGui.Add("Edit", "x+5 yp-2 w55 vQC3", "")
MyGui.Add("Text", "x+10 yp+2 w60", "Slot 4:")
QCEdit4 := MyGui.Add("Edit", "x+5 yp-2 w55 vQC4", "")

MyGui.Add("Text", "xm+10 y+10 w60", "Slot 5:")
QCEdit5 := MyGui.Add("Edit", "x+5 yp-2 w55 vQC5", "")

BtnSaveQC := MyGui.Add("Button", "x+10 yp-2 w125", "Save QC Keybinds")
BtnSaveQC.OnEvent("Click", SaveQuickCast)

; PANEL 3: Additional Settings
ChkTooltip := MyGui.Add("CheckBox", "xm y+15 vEnableTooltip Checked" EnableTooltip, "Enable OSD Notifications (Tooltips)")
ChkTooltip.OnEvent("Click", ToggleTooltipSave)

UpdateDropdown()
UpdateQCGUI()
MyGui.Show("w290")

; =====================================================================
; --- NEW FUNCTION: KEYBIND CONFLICT CHECKER (ANTI DOUBLE-BIND) ---
; =====================================================================
CheckKeybindConflict(CheckKey, ExcludeMacro := "", ExcludeQC := 0) {
    global MacroList, QuickCastList
    
    ; 1. Check against Targeted Macros (excluding itself if editing)
    for name, data in MacroList {
        if (name != ExcludeMacro && data.Key = CheckKey)
            return "Targeted Macro: " name
    }
    
    ; 2. Check against Quick Cast slots (excluding itself if editing)
    for slot, keybind in QuickCastList {
        if (slot != ExcludeQC && keybind = CheckKey)
            return "Quick Cast Slot: " slot
    }
    
    return "" ; Returns empty if the keybind is free to use
}


; --- GUI SUPPORT FUNCTIONS (TARGETED MACRO) ---

ToggleTooltipSave(*) {
    global EnableTooltip, IniFile
    EnableTooltip := ChkTooltip.Value
    IniWrite(EnableTooltip, IniFile, "Settings", "ShowTooltip")
}

AutoFillMacro(*) {
    global MacroList, ComboName, EditKey, EditPreKey, DDL_ExecMode, ChkNoRet
    name := ComboName.Text
    
    if MacroList.Has(name) {
        data := MacroList[name]
        EditKey.Value := data.Key
        EditPreKey.Value := data.PreKey
        ChkNoRet.Value := data.NoRet
        
        if (data.Mode == "Normal")
            DDL_ExecMode.Choose(1)
        else if (data.Mode == "Hold")
            DDL_ExecMode.Choose(2)
        else if (data.Mode == "Spam")
            DDL_ExecMode.Choose(3)
    }
}

SaveChanges(*) {
    global MacroList, ComboName, EditKey, EditPreKey, DDL_ExecMode, ChkNoRet, IniFile
    name := ComboName.Text
    newKey := EditKey.Value
    
    if (name == "" || newKey == "") {
        MsgBox("Profile name and trigger keybind cannot be empty!", "Validation Error", 48)
        return
    }
    
    if !MacroList.Has(name) {
        MsgBox("Profile '" name "' lacks recorded coordinates!`nPlease use the [Create New / Overwrite Coordinates] button to record the target position first.", "Warning", 48)
        return
    }
    
    ; VALIDATION: Check for duplicate keybinds
    conflict := CheckKeybindConflict(newKey, name)
    if (conflict != "") {
        MsgBox("Keybind '" newKey "' is already in use by [" conflict "]!`nPlease choose a different keybind.", "Duplicate Keybind Detected", 48)
        return
    }
    
    newPreKey := EditPreKey.Value
    newMode := RegExReplace(DDL_ExecMode.Text, " \(.*", "")
    newNoRet := ChkNoRet.Value
    
    oldKey := MacroList[name].Key
    if (oldKey != newKey) {
        try {
            HotIfWinActive(GameExe)
            Hotkey(oldKey, "Off")
            HotIfWinActive()
        }
    }
    
    MacroList[name].Key := newKey
    MacroList[name].PreKey := newPreKey
    MacroList[name].Mode := newMode
    MacroList[name].NoRet := newNoRet
    
    IniWrite(newKey, IniFile, name, "Key")
    IniWrite(newPreKey, IniFile, name, "PreKey")
    IniWrite(newMode, IniFile, name, "ModeExec")
    IniWrite(newNoRet, IniFile, name, "NoReturn")
    
    RegisterHotkey(newKey, name)
    UpdateDropdown()
    MsgBox("Settings for profile '" name "' saved successfully (Coordinates preserved)!", "Success", 64)
}

TriggerRecord(*) {
    global IsRecording, TempName, TempKey, TempPreKey, TempMode, TempNoRet, BtnRecord, ComboName
    if (IsRecording) {
        IsRecording := false
        BtnRecord.Text := "Create New / Overwrite Coordinates (/)" 
        ToolTip("Coordinate recording cancelled.")
        SetTimer () => ToolTip(), -1500
        return
    }
    
    TempName := ComboName.Text
    TempKey := EditKey.Value
    
    if (TempName == "" || TempKey == "") {
        MsgBox("Profile Name and Trigger Keybind cannot be empty!", "Validation Error", 48)
        return
    }
    
    ; VALIDATION: Check for duplicate keybinds before entering record mode
    conflict := CheckKeybindConflict(TempKey, TempName)
    if (conflict != "") {
        MsgBox("Keybind '" TempKey "' is already in use by [" conflict "]!`nPlease choose a different keybind.", "Duplicate Keybind Detected", 48)
        return
    }
    
    TempPreKey := EditPreKey.Value
    TempMode := DDL_ExecMode.Text
    TempNoRet := ChkNoRet.Value
    
    IsRecording := true
    BtnRecord.Text := "Cancel Recording (Click Again)"
    ToolTip("Switch to game! Hover over the target, then press [/] to lock coordinates.")
}

#HotIf IsRecording
$/:: {
    global IsRecording, TempName, TempKey, TempPreKey, TempMode, TempNoRet
    global MacroList, GameExe, IniFile, BtnRecord
    IsRecording := false
    BtnRecord.Text := "Create New / Overwrite Coordinates (/)"
    ToolTip()
    
    MouseGetPos &mx, &my
    WinGetClientPos ,, &BaseW, &BaseH, GameExe
    PureMode := RegExReplace(TempMode, " \(.*", "")
    
    MacroList[TempName] := {Key: TempKey, PreKey: TempPreKey, X: mx, Y: my, BaseW: BaseW, BaseH: BaseH, Mode: PureMode, NoRet: TempNoRet}
    
    IniWrite(TempKey, IniFile, TempName, "Key")
    IniWrite(TempPreKey, IniFile, TempName, "PreKey")
    IniWrite(mx, IniFile, TempName, "X")
    IniWrite(my, IniFile, TempName, "Y")
    IniWrite(BaseW, IniFile, TempName, "BaseW")
    IniWrite(BaseH, IniFile, TempName, "BaseH")
    IniWrite(PureMode, IniFile, TempName, "ModeExec")
    IniWrite(TempNoRet, IniFile, TempName, "NoReturn")
    
    RegisterHotkey(TempKey, TempName)
    UpdateDropdown()
    MsgBox("Profile '" TempName "' saved successfully (Coordinates Locked)!", "Success", 64)
}
#HotIf

UpdateDropdown() {
    global MacroList, DDL_Macro, ComboName
    arrList := []
    nameList := []
    for name, data in MacroList {
        optText := (data.Mode != "Normal" ? "[" data.Mode "] " : "") . (data.NoRet ? "[NO-RET] " : "")
        arrList.Push(optText name " (" data.Key ")")
        nameList.Push(name)
    }
    DDL_Macro.Delete()
    ComboName.Delete()
    if (arrList.Length > 0) {
        DDL_Macro.Add(arrList)
        ComboName.Add(nameList)
    }
}

DeleteMacro(*) {
    global MacroList, DDL_Macro, IniFile, GameExe
    if (DDL_Macro.Text == "")
        return
    
    ActualName := RegExReplace(DDL_Macro.Text, "^(\[.*?\]\s*)*", "")
    ActualName := RegExReplace(ActualName, " \(.*", "")
    
    try {
        HotIfWinActive(GameExe)
        Hotkey(MacroList[ActualName].Key, "Off")
        HotIfWinActive()
    }
    MacroList.Delete(ActualName)
    IniDelete(IniFile, ActualName)
    UpdateDropdown()
}

; --- QUICK CAST SUPPORT FUNCTIONS ---
SaveQuickCast(*) {
    global IniFile, QuickCastList, GameExe
    global QCEdit1, QCEdit2, QCEdit3, QCEdit4, QCEdit5
    
    newData := [QCEdit1.Value, QCEdit2.Value, QCEdit3.Value, QCEdit4.Value, QCEdit5.Value]
    
    ; VALIDATION 1: Check internal duplicates within the 5 Quick Cast inputs
    Loop 5 {
        i := A_Index
        if (newData[i] == "")
            continue
        Loop 5 {
            j := A_Index
            if (i != j && newData[i] == newData[j]) {
                MsgBox("Duplicate keybind '" newData[i] "' found in Quick Cast Slots " i " and " j "!", "Validation Error", 48)
                return
            }
        }
    }
    
    ; VALIDATION 2: Check global conflicts against Targeted Macros and existing QC
    Loop 5 {
        if (newData[A_Index] == "")
            continue
        conflict := CheckKeybindConflict(newData[A_Index], "", A_Index)
        if (conflict != "") {
            MsgBox("Keybind '" newData[A_Index] "' in Quick Cast Slot " A_Index " is already in use by [" conflict "]!", "Duplicate Keybind Detected", 48)
            return
        }
    }
    
    ; Turn off old hotkeys
    for slot, keybind in QuickCastList {
        try {
            HotIfWinActive(GameExe)
            Hotkey(keybind, "Off")
            HotIfWinActive()
        }
    }
    QuickCastList.Clear()
    
    ; Save and Register new hotkeys
    Loop 5 {
        kb := newData[A_Index]
        IniWrite(kb, IniFile, "QuickCast", "Slot" A_Index)
        if (kb != "") {
            QuickCastList[A_Index] := kb
            RegisterQC_Hotkey(kb, A_Index)
        }
    }
    MsgBox("Quick Cast keybinds saved successfully!", "Success", 64)
}

RegisterQC_Hotkey(TriggerKey, Slot) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        Hotkey(TriggerKey, (KeyName) => ExecuteQuickCast(Slot, KeyName), "On")
        HotIfWinActive()
    } catch {
        MsgBox("Invalid keybind format '" TriggerKey "' for Slot " Slot "!", "Hotkey Error", 48)
    }
}

UpdateQCGUI() {
    global QCEdit1, QCEdit2, QCEdit3, QCEdit4, QCEdit5, QuickCastList
    try QCEdit1.Value := QuickCastList.Has(1) ? QuickCastList[1] : ""
    try QCEdit2.Value := QuickCastList.Has(2) ? QuickCastList[2] : ""
    try QCEdit3.Value := QuickCastList.Has(3) ? QuickCastList[3] : ""
    try QCEdit4.Value := QuickCastList.Has(4) ? QuickCastList[4] : ""
    try QCEdit5.Value := QuickCastList.Has(5) ? QuickCastList[5] : ""
}

; --- CONFIGURATION LOADER ---
LoadSettings() {
    global IniFile, MacroList, QuickCastList, EnableTooltip
    if !FileExist(IniFile)
        return
        
    EnableTooltip := IniRead(IniFile, "Settings", "ShowTooltip", 1)
    
    Loop 5 {
        kb := IniRead(IniFile, "QuickCast", "Slot" A_Index, "")
        if (kb != "") {
            QuickCastList[A_Index] := kb
            RegisterQC_Hotkey(kb, A_Index)
        }
    }
        
    try {
        FormatINI := FileRead(IniFile)
        Loop Parse, FormatINI, "`n", "`r" {
            if (RegExMatch(A_LoopField, "^\[(.*)\]$", &Match)) {
                Section := Match[1]
                if (Section == "" || Section == "Settings" || Section == "QuickCast")
                    continue
                
                k := IniRead(IniFile, Section, "Key")
                pk := IniRead(IniFile, Section, "PreKey", "")
                x := IniRead(IniFile, Section, "X")
                y := IniRead(IniFile, Section, "Y")
                bw := IniRead(IniFile, Section, "BaseW", 1920)
                bh := IniRead(IniFile, Section, "BaseH", 1080)
                md := IniRead(IniFile, Section, "ModeExec", "Normal")
                nr := IniRead(IniFile, Section, "NoReturn", 0)
                
                MacroList[Section] := {Key: k, PreKey: pk, X: x, Y: y, BaseW: bw, BaseH: bh, Mode: md, NoRet: nr}
                RegisterHotkey(k, Section)
            }
        }
    }
}

RegisterHotkey(TriggerKey, ProfileName) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        Hotkey(TriggerKey, (KeyName) => ExecuteMacro(ProfileName, KeyName), "On")
        HotIfWinActive()
    }
}

; --- EXECUTION LOGIC: QUICK CAST (CURSOR-BOUND) ---
ExecuteQuickCast(SlotPreKey, TriggerKeyName) {
    global GameExe, EnableTooltip
    if !WinActive(GameExe)
        return
        
    BaseKey := RegExReplace(TriggerKeyName, "[\^\!\+\#\<\>\~*]", "")
    ActualPreKey := String(SlotPreKey)
    
    if (EnableTooltip) {
        ToolTip("Quick Cast Active: Slot " ActualPreKey)
    }
    
    while GetKeyState(BaseKey, "P") {
        SendEvent("{" ActualPreKey "}")
        Sleep 15
        Click
        Sleep 25
    }
    
    if (EnableTooltip) {
        ToolTip() 
    }
}

; --- EXECUTION LOGIC: TARGETED MACRO ---
ExecuteMacro(ProfileName, TriggerKeyName) {
    global MacroList, GameExe, EnableTooltip
    if !WinActive(GameExe)
        return
        
    data := MacroList[ProfileName]
    WinGetClientPos ,, &CurrentW, &CurrentH, GameExe
    
    Scale := CurrentH / data.BaseH
    TargetY := data.Y * Scale
    CenterX := CurrentW / 2
    DistXFromCenter := data.X - (data.BaseW / 2)
    TargetX := CenterX + (DistXFromCenter * Scale)
    
    if (!data.NoRet)
        MouseGetPos &OriginX, &OriginY
        
    BaseKey := RegExReplace(TriggerKeyName, "[\^\!\+\#\<\>\~*]", "")

    if (data.Mode == "Spam") {
        MouseMove Round(TargetX), Round(TargetY), 0
        while GetKeyState(BaseKey, "P") {
            if (data.PreKey != "") {
                SendEvent("{" data.PreKey "}")
                Sleep 15 
            }
            Click
            Sleep 25 
        }
    } else if (data.Mode == "Hold") {
        if (data.PreKey != "") {
            SendEvent("{" data.PreKey "}")
            Sleep 50 
        }
        MouseMove Round(TargetX), Round(TargetY), 0
        Sleep 30
        
        Click "Down"
        KeyWait BaseKey 
        Click "Up"
    } else {
        if (data.PreKey != "") {
            SendEvent("{" data.PreKey "}")
            Sleep 50 
        }
        MouseMove Round(TargetX), Round(TargetY), 0
        Sleep 30
        Click
    }
    
    Sleep 30
    if (!data.NoRet)
        MouseMove OriginX, OriginY, 0
    
    if (EnableTooltip) {
        ToolTip("Macro Executed: " ProfileName)
        SetTimer () => ToolTip(), -1000
    }
}

; =====================================================================
; --- GLOBAL HOTKEYS (ACTIVE EVEN WHEN SUSPENDED) ---
; =====================================================================
#SuspendExempt
>+Esc:: {
    Suspend(-1)
    if (A_IsSuspended)
        ToolTip("Macro System: PAUSED (Safe to type)")
    else
        ToolTip("Macro System: RESUMED (Active)")
    SetTimer () => ToolTip(), -2000
}
>+/:: {
    MyGui.Show()
}
#SuspendExempt False

; =====================================================================
; --- CONTEXT-AWARE KEY REMAPPING (IN-GAME ONLY) ---
; =====================================================================
#HotIf WinActive(GameExe)
Space::s
r::a
#HotIf