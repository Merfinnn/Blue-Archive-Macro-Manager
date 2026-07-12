#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Event"
SetKeyDelay -1, -1
SetMouseDelay -1
CoordMode "Mouse", "Client"

; --- GLOBAL VARIABLES & FOLDER MANAGEMENT ---
global ConfigDir := A_ScriptDir "\saved binds"

if !DirExist(ConfigDir)
    DirCreate(ConfigDir)

global MasterIni := ConfigDir "\settings.ini"
global GameExe := "ahk_exe BlueArchive.exe"
global MacroList := Map()
global QuickCastList := Map()
global IsRecording := false
global TempName := "", TempKey := "", TempPreKey := ""
global TempMode := "Normal", TempNoRet := 0

; Extra Features Variables
global EnableRapidA := 0
global RapidABind := "a"
global InstPauseBind := ""

; Load global preferences from settings.ini
global EnableTooltip := IniRead(MasterIni, "Preferences", "ShowTooltip", 1)
global EnableLetterbox := IniRead(MasterIni, "Preferences", "EnableLetterbox", 0) 
global LoopDelay := IniRead(MasterIni, "Preferences", "LoopDelay", 25)
global IniFile := IniRead(MasterIni, "System", "LastProfile", ConfigDir "\config.ini")

; --- INITIALIZATION ---
LoadSettings()

; --- GUI INTERFACE CREATION ---
global MainGui := Gui("+AlwaysOnTop", "Blue Archive Macro Manager")
MainGui.SetFont("s9", "Segoe UI")

; PANEL 0: Profile Management
MainGui.Add("GroupBox", "w270 h55", "Configuration Profile")
ComboFiles := MainGui.Add("ComboBox", "xp+10 yp+20 w130", [])
BtnLoadProfile := MainGui.Add("Button", "x+5 yp-1 w55 h25", "Load")
BtnLoadProfile.OnEvent("Click", LoadOrCreateProfile)
BtnImport := MainGui.Add("Button", "x+5 yp w55 h25", "Import")
BtnImport.OnEvent("Click", ImportProfile)

; PANEL 1: Targeted Macro (Coordinate-Locked)
MainGui.Add("GroupBox", "xm w270 h275", "Targeted Macro (Coordinate-Locked)")
MainGui.Add("Text", "xp+10 yp+20", "Select Profile or Enter New Name:")

global ComboName := MainGui.Add("ComboBox", "w250 vMacroName", [])
ComboName.OnEvent("Change", AutoFillMacro)

MainGui.Add("Text", "w115", "Trigger Keybind:")
global EditKey := MainGui.Add("Edit", "w115 vKeybind", "F3")

MainGui.Add("Text", "x+10 yp w115", "Pre-Key (Optional):")
global EditPreKey := MainGui.Add("Edit", "w115 vPreKey", "")

MainGui.Add("Text", "xm+10 y+15 w90", "Execution Mode:")
global DDL_ExecMode := MainGui.Add("DropDownList", "x+5 yp-3 w155 vExecMode Choose1", ["Normal", "Hold (Aiming)", "Rapid (Turbo)"])

global ChkNoRet := MainGui.Add("CheckBox", "xm+10 y+10 vNoReturn", "Do not restore cursor position (No-Return)")
global ChkLetterbox := MainGui.Add("CheckBox", "xm+10 y+8 vIsLetterbox", "Save as vertical letterbox (Combat 2.06:1)")

BtnSaveEdit := MainGui.Add("Button", "xm+10 y+12 w250 h26", "Save Profile Settings (Preserve Coordinates)")
BtnSaveEdit.OnEvent("Click", SaveChanges)

BtnRecord := MainGui.Add("Button", "xm+10 y+5 w250 h26", "Create New / Overwrite Coordinates (/)")
BtnRecord.OnEvent("Click", TriggerRecord)

; PANEL 2: Active Targeted Macros
MainGui.Add("GroupBox", "xm w270 h90", "Active Targeted Macros")
global DDL_Macro := MainGui.Add("DropDownList", "xp+10 yp+20 w250 vSelectedMacro")

BtnDelete := MainGui.Add("Button", "w250", "Delete Selected Macro")
BtnDelete.OnEvent("Click", DeleteMacro)

; PANEL 3: Quick Cast & Extra Features
MainGui.Add("GroupBox", "xm w270 h195", "Quick Cast & Extra Features")
MainGui.Add("Text", "xp+10 yp+20 w60", "Slot 1:")
global QCEdit1 := MainGui.Add("Edit", "x+5 yp-2 w55 vQC1", "")
MainGui.Add("Text", "x+10 yp+2 w60", "Slot 2:")
global QCEdit2 := MainGui.Add("Edit", "x+5 yp-2 w55 vQC2", "")

MainGui.Add("Text", "xm+10 y+10 w60", "Slot 3:")
global QCEdit3 := MainGui.Add("Edit", "x+5 yp-2 w55 vQC3", "")
MainGui.Add("Text", "x+10 yp+2 w60", "Slot 4:")
global QCEdit4 := MainGui.Add("Edit", "x+5 yp-2 w55 vQC4", "")

MainGui.Add("Text", "xm+10 y+10 w60", "Slot 5:")
global QCEdit5 := MainGui.Add("Edit", "x+5 yp-2 w55 vQC5", "")

global ChkRapidA := MainGui.Add("CheckBox", "xm+10 y+15 vEnableRapidA Checked" EnableRapidA, "Enable 'A' Key Rapid. Trigger:")
global EditRapidA := MainGui.Add("Edit", "x+5 yp-2 w45 vRapidABind", RapidABind)

MainGui.Add("Text", "xm+10 y+12 w120", "Instant Pause Bind:")
global EditInstPause := MainGui.Add("Edit", "x+5 yp-2 w45 vInstPauseBind", InstPauseBind)

BtnSaveQC := MainGui.Add("Button", "xm+10 y+15 w250 h26", "Save Quick Cast & Extra Binds")
BtnSaveQC.OnEvent("Click", SaveQuickCast)

; PANEL 4: Global Preferences (settings.ini)
MainGui.Add("GroupBox", "xm w270 h115", "Global Preferences (settings.ini)")
global ChkTooltip := MainGui.Add("CheckBox", "xp+10 yp+20 vEnableTooltip Checked" EnableTooltip, "Enable OSD Notifications (Tooltips)")
ChkTooltip.OnEvent("Click", ToggleTooltipSave)

global ChkGlobalLetterbox := MainGui.Add("CheckBox", "xm+10 y+8 vEnableLetterbox Checked" EnableLetterbox, "Enable vertical letterbox projection")
ChkGlobalLetterbox.OnEvent("Click", ToggleLetterboxSave)

MainGui.Add("Text", "xm+10 y+10 w140", "Loop / Turbo Delay (ms):")
global EditLoopDelay := MainGui.Add("Edit", "x+5 yp-2 w60", LoopDelay)
EditLoopDelay.OnEvent("Change", SaveLoopDelay)
MainGui.Add("UpDown", "Range10-1000", LoopDelay).OnEvent("Change", SaveLoopDelay)

; --- CREDIT SECTION ---
MainGui.SetFont("s7 c888888") ; Small and dim gray font
MainGui.Add("Text", "xm y+10 w255 Right", "Created by Gemini")
MainGui.SetFont("s9 cDefault") ; Revert back to original font

UpdateFileDropdown()
UpdateDropdown()
UpdateQCGUI()
MainGui.Show("w290")


; =====================================================================
; --- PROFILE & FILE MANAGER LOGIC ---
; =====================================================================
UpdateFileDropdown() {
    global ComboFiles, IniFile, ConfigDir
    files := []
    
    Loop Files ConfigDir "\*.ini" {
        if (A_LoopFileName != "settings.ini")
            files.Push(A_LoopFileName)
    }
    
    ComboFiles.Delete()
    if (files.Length > 0)
        ComboFiles.Add(files)
        
    SplitPath(IniFile, &OutFileName)
    ComboFiles.Text := OutFileName
}

ClearAllHotkeys() {
    global MacroList, QuickCastList, GameExe
    global EnableRapidA, RapidABind, InstPauseBind

    for name, data in MacroList {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(data.Key, "Off")
            HotIfWinActive() 
        }
    }
    for slot, keybind in QuickCastList {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(keybind, "Off")
            HotIfWinActive() 
        }
    }
    if (EnableRapidA && RapidABind != "") {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(RapidABind, "Off")
            HotIfWinActive() 
        }
    }
    if (InstPauseBind != "") {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(InstPauseBind, "Off")
            HotIfWinActive() 
        }
    }

    MacroList.Clear()
    QuickCastList.Clear()
    EnableRapidA := 0
    RapidABind := "a"
    InstPauseBind := ""
}

LoadOrCreateProfile(*) {
    global IniFile, MasterIni, ComboFiles, ConfigDir
    global ComboName, EditKey, EditPreKey, ChkNoRet, DDL_ExecMode, ChkLetterbox
    
    selected := ComboFiles.Text
    if (selected == "")
        return
        
    if !RegExMatch(selected, "\.ini$")
        selected .= ".ini"
        
    ClearAllHotkeys()
    
    IniFile := ConfigDir "\" selected
    IniWrite(IniFile, MasterIni, "System", "LastProfile")
    
    LoadSettings()
    UpdateFileDropdown()
    UpdateDropdown()
    UpdateQCGUI()
    
    ComboName.Text := ""
    EditKey.Value := ""
    EditPreKey.Value := ""
    ChkNoRet.Value := 0
    ChkLetterbox.Value := 0
    DDL_ExecMode.Choose(1)
    
    MsgBox("Profile [" selected "] is now active!", "Profile Switched", 64)
}

ImportProfile(*) {
    global ConfigDir, MasterIni, IniFile
    global ComboName, EditKey, EditPreKey, ChkNoRet, DDL_ExecMode, ChkLetterbox

    SelectedFile := FileSelect(3, "", "Select Configuration File to Import", "INI Files (*.ini)")
    if (SelectedFile == "")
        return 

    SplitPath SelectedFile, &OutFileName
    DestPath := ConfigDir "\" OutFileName

    if (SelectedFile != DestPath) {
        try {
            FileCopy SelectedFile, DestPath, 1 
        } catch {
            MsgBox("Failed to import the file. Please check file permissions.", "File Error", 48)
            return
        }
    }

    ClearAllHotkeys()
    
    IniFile := DestPath
    IniWrite(IniFile, MasterIni, "System", "LastProfile")

    LoadSettings()
    UpdateFileDropdown()
    UpdateDropdown()
    UpdateQCGUI()

    ComboName.Text := ""
    EditKey.Value := ""
    EditPreKey.Value := ""
    ChkNoRet.Value := 0
    ChkLetterbox.Value := 0
    DDL_ExecMode.Choose(1)

    MsgBox("Profile [" OutFileName "] successfully imported and activated!", "Import Success", 64)
}


; =====================================================================
; --- KEYBIND CONFLICT CHECKER (ANTI DOUBLE-BIND) ---
; =====================================================================
CheckKeybindConflict(CheckKey, ExcludeMacro := "") {
    global MacroList, QuickCastList, EnableRapidA, RapidABind, InstPauseBind
    
    for name, data in MacroList {
        if (name != ExcludeMacro && data.Key = CheckKey)
            return "Targeted Macro: " name
    }
    for slot, keybind in QuickCastList {
        if (keybind = CheckKey)
            return "Quick Cast Slot: " slot
    }
    if (EnableRapidA && RapidABind = CheckKey)
        return "Extra Feature: Rapid A"
    if (InstPauseBind != "" && InstPauseBind = CheckKey)
        return "Extra Feature: Instant Pause"
        
    return ""
}


; =====================================================================
; --- GUI SUPPORT FUNCTIONS ---
; =====================================================================
ToggleTooltipSave(*) {
    global EnableTooltip, MasterIni, ChkTooltip
    EnableTooltip := ChkTooltip.Value
    IniWrite(EnableTooltip, MasterIni, "Preferences", "ShowTooltip")
}

ToggleLetterboxSave(*) {
    global EnableLetterbox, MasterIni, ChkGlobalLetterbox
    EnableLetterbox := ChkGlobalLetterbox.Value
    IniWrite(EnableLetterbox, MasterIni, "Preferences", "EnableLetterbox")
}

SaveLoopDelay(*) {
    global LoopDelay, MasterIni, EditLoopDelay
    val := EditLoopDelay.Value
    if (val != "" && IsNumber(val)) {
        LoopDelay := Integer(val)
        IniWrite(LoopDelay, MasterIni, "Preferences", "LoopDelay")
    }
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
        else if (data.Mode == "Rapid")
            DDL_ExecMode.Choose(3)
    }
}

SaveChanges(*) {
    global MacroList, ComboName, EditKey, EditPreKey, DDL_ExecMode, ChkNoRet, IniFile, GameExe
    name := ComboName.Text
    newKey := EditKey.Value
    
    if (name == "" || newKey == "") {
        MsgBox("Profile name and trigger keybind cannot be empty!", "Validation Error", 48)
        return
    }
    if !MacroList.Has(name) {
        MsgBox("Profile '" name "' lacks recorded coordinates!`nPlease use the [Create New] button to record the target position first.", "Warning", 48)
        return
    }
    
    conflict := CheckKeybindConflict(newKey, name)
    if (conflict != "") {
        MsgBox("Keybind '" newKey "' is already in use by [" conflict "]!", "Duplicate Keybind", 48)
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
    MsgBox("Settings for profile '" name "' saved successfully!", "Success", 64)
}

TriggerRecord(*) {
    global IsRecording, TempName, TempKey, TempPreKey, TempMode, TempNoRet, BtnRecord, ComboName, EditKey, EditPreKey, DDL_ExecMode, ChkNoRet
    
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
    
    conflict := CheckKeybindConflict(TempKey, TempName)
    if (conflict != "") {
        MsgBox("Keybind '" TempKey "' is already in use by [" conflict "]!", "Duplicate Keybind", 48)
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
    global MacroList, GameExe, IniFile, BtnRecord, ChkLetterbox
    
    if !WinActive(GameExe) {
        MsgBox("Error: Target window not active or not found!`nPlease ensure the game window is in focus before pressing [/].", "Invalid Target", 48)
        return 
    }
    
    IsRecording := false
    BtnRecord.Text := "Create New / Overwrite Coordinates (/)"
    ToolTip()
    
    MouseGetPos &mx, &my
    WinGetClientPos ,, &BaseW, &BaseH, GameExe
    PureMode := RegExReplace(TempMode, " \(.*", "")
    
    ; --- PRECISE MATH LOGIC: NORMALIZATION DURING SAVE ---
    if (ChkLetterbox.Value) {
        CombatH := BaseW / 2.0556
        TopBar := (BaseH - CombatH) / 2
        PureX := mx - (BaseW / 2)
        PureY := my - (TopBar + (CombatH / 2))
        
        NormX := PureX / CombatH
        NormY := PureY / CombatH
    } else {
        PureX := mx - (BaseW / 2)
        PureY := my - (BaseH / 2)
        
        NormX := PureX / BaseH
        NormY := PureY / BaseH
    }
    
    finalX := (1920 / 2) + (NormX * 1080)
    finalY := (1080 / 2) + (NormY * 1080)
    finalBaseW := 1920
    finalBaseH := 1080
    
    MacroList[TempName] := {Key: TempKey, PreKey: TempPreKey, X: finalX, Y: finalY, BaseW: finalBaseW, BaseH: finalBaseH, Mode: PureMode, NoRet: TempNoRet}
    
    IniWrite(TempKey, IniFile, TempName, "Key")
    IniWrite(TempPreKey, IniFile, TempName, "PreKey")
    IniWrite(finalX, IniFile, TempName, "X")
    IniWrite(finalY, IniFile, TempName, "Y")
    IniWrite(finalBaseW, IniFile, TempName, "BaseW")
    IniWrite(finalBaseH, IniFile, TempName, "BaseH")
    IniWrite(PureMode, IniFile, TempName, "ModeExec")
    IniWrite(TempNoRet, IniFile, TempName, "NoReturn")
    
    RegisterHotkey(TempKey, TempName)
    UpdateDropdown()
    MsgBox("Profile '" TempName "' saved successfully (Coordinates Normalized)!", "Success", 64)
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

; =====================================================================
; --- QUICK CAST & EXTRA FEATURES SUPPORT FUNCTIONS ---
; =====================================================================
SaveQuickCast(*) {
    global IniFile, QuickCastList, GameExe, MacroList
    global QCEdit1, QCEdit2, QCEdit3, QCEdit4, QCEdit5
    global ChkRapidA, EditRapidA, EditInstPause
    global EnableRapidA, RapidABind, InstPauseBind
    
    newData := [QCEdit1.Value, QCEdit2.Value, QCEdit3.Value, QCEdit4.Value, QCEdit5.Value]
    newRapidAEnabled := ChkRapidA.Value
    newRapidABind := EditRapidA.Value
    newInstPauseBind := EditInstPause.Value
    
    CheckList := Map()
    
    Loop 5 {
        if (newData[A_Index] != "")
            CheckList["QC Slot " A_Index] := newData[A_Index]
    }
    if (newRapidAEnabled && newRapidABind != "")
        CheckList["Rapid A"] := newRapidABind
    if (newInstPauseBind != "")
        CheckList["Instant Pause"] := newInstPauseBind
        
    for label1, key1 in CheckList {
        for label2, key2 in CheckList {
            if (label1 != label2 && key1 == key2) {
                MsgBox("Duplicate keybind '" key1 "' found between [" label1 "] and [" label2 "]!", "Validation Error", 48)
                return
            }
        }
    }
    
    for label, key in CheckList {
        for name, data in MacroList {
            if (data.Key == key) {
                MsgBox("Keybind '" key "' for [" label "] is already in use by [Targeted Macro: " name "]!", "Duplicate Keybind", 48)
                return
            }
        }
    }
    
    for slot, keybind in QuickCastList {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(keybind, "Off")
            HotIfWinActive() 
        }
    }
    if (EnableRapidA && RapidABind != "") {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(RapidABind, "Off")
            HotIfWinActive() 
        }
    }
    if (InstPauseBind != "") {
        try { 
            HotIfWinActive(GameExe)
            Hotkey(InstPauseBind, "Off")
            HotIfWinActive() 
        }
    }
    
    QuickCastList.Clear()
    
    Loop 5 {
        kb := newData[A_Index]
        IniWrite(kb, IniFile, "QuickCast", "Slot" A_Index)
        if (kb != "") {
            QuickCastList[A_Index] := kb
            RegisterQC_Hotkey(kb, A_Index)
        }
    }
    
    EnableRapidA := newRapidAEnabled
    RapidABind := newRapidABind
    InstPauseBind := newInstPauseBind
    
    IniWrite(EnableRapidA, IniFile, "ExtraFeatures", "EnableRapidA")
    IniWrite(RapidABind, IniFile, "ExtraFeatures", "RapidABind")
    IniWrite(InstPauseBind, IniFile, "ExtraFeatures", "InstPauseBind")
    
    if (EnableRapidA && RapidABind != "")
        RegisterExtra_Hotkey(RapidABind, "RapidA")
    if (InstPauseBind != "")
        RegisterExtra_Hotkey(InstPauseBind, "InstPause")
        
    MsgBox("Quick Cast & Extra keybinds saved successfully!", "Success", 64)
}

RegisterQC_Hotkey(TriggerKey, Slot) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        Hotkey(TriggerKey, (KeyName) => ExecuteQuickCast(Slot, KeyName), "On")
        HotIfWinActive()
    } catch {
        MsgBox("Invalid keybind format '" TriggerKey "' for QC Slot " Slot "!", "Hotkey Error", 48)
    }
}

RegisterExtra_Hotkey(TriggerKey, FeatureType) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        if (FeatureType == "RapidA")
            Hotkey(TriggerKey, (KeyName) => ExecuteRapidA(KeyName), "On")
        else if (FeatureType == "InstPause")
            Hotkey(TriggerKey, (KeyName) => ExecuteInstPause(KeyName), "On")
        HotIfWinActive()
    } catch {
        MsgBox("Invalid keybind format '" TriggerKey "' for Extra Feature: " FeatureType "!", "Hotkey Error", 48)
    }
}

UpdateQCGUI() {
    global QCEdit1, QCEdit2, QCEdit3, QCEdit4, QCEdit5, QuickCastList
    global ChkRapidA, EditRapidA, EditInstPause
    global EnableRapidA, RapidABind, InstPauseBind
    
    try QCEdit1.Value := QuickCastList.Has(1) ? QuickCastList[1] : ""
    try QCEdit2.Value := QuickCastList.Has(2) ? QuickCastList[2] : ""
    try QCEdit3.Value := QuickCastList.Has(3) ? QuickCastList[3] : ""
    try QCEdit4.Value := QuickCastList.Has(4) ? QuickCastList[4] : ""
    try QCEdit5.Value := QuickCastList.Has(5) ? QuickCastList[5] : ""
    
    try ChkRapidA.Value := EnableRapidA
    try EditRapidA.Value := RapidABind
    try EditInstPause.Value := InstPauseBind
}

; =====================================================================
; --- CONFIGURATION LOADER ---
; =====================================================================
LoadSettings() {
    global IniFile, MacroList, QuickCastList
    global EnableRapidA, RapidABind, InstPauseBind
    
    if !FileExist(IniFile)
        return
        
    Loop 5 {
        kb := IniRead(IniFile, "QuickCast", "Slot" A_Index, "")
        if (kb != "") {
            QuickCastList[A_Index] := kb
            RegisterQC_Hotkey(kb, A_Index)
        }
    }
    
    EnableRapidA := IniRead(IniFile, "ExtraFeatures", "EnableRapidA", 0)
    RapidABind := IniRead(IniFile, "ExtraFeatures", "RapidABind", "a")
    InstPauseBind := IniRead(IniFile, "ExtraFeatures", "InstPauseBind", "")
    
    if (EnableRapidA && RapidABind != "")
        RegisterExtra_Hotkey(RapidABind, "RapidA")
    if (InstPauseBind != "")
        RegisterExtra_Hotkey(InstPauseBind, "InstPause")
        
    try {
        FormatINI := FileRead(IniFile)
        Loop Parse, FormatINI, "`n", "`r" {
            if (RegExMatch(A_LoopField, "^\[(.*)\]$", &Match)) {
                Section := Match[1]
                if (Section == "" || Section == "Settings" || Section == "QuickCast" || Section == "ExtraFeatures")
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

; =====================================================================
; --- EXECUTION LOGIC: EXTRA FEATURES ---
; =====================================================================
ExecuteRapidA(TriggerKeyName) {
    global GameExe, EnableTooltip, LoopDelay
    if !WinActive(GameExe)
        return
        
    BaseKey := RegExReplace(TriggerKeyName, "[\^\!\+\#\<\>\~*]", "")
    
    if (EnableTooltip)
        ToolTip("Rapid pressing 'A' Key...")
        
    while GetKeyState(BaseKey, "P") {
        SendEvent("{a}")
        Sleep LoopDelay
    }
    
    if (EnableTooltip)
        ToolTip() 
}

ExecuteInstPause(TriggerKeyName) {
    global GameExe, EnableTooltip
    if !WinActive(GameExe)
        return
        
    if (EnableTooltip)
        ToolTip("Instant Pause Executed")
        
    Click
    Sleep 17
    SendEvent("{Esc}")
    
    if (EnableTooltip)
        SetTimer () => ToolTip(), -1000
}

; =====================================================================
; --- EXECUTION LOGIC: QUICK CAST (CURSOR-BOUND) ---
; =====================================================================
ExecuteQuickCast(SlotPreKey, TriggerKeyName) {
    global GameExe, EnableTooltip, LoopDelay
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
        Sleep LoopDelay 
    }
    
    if (EnableTooltip) {
        ToolTip() 
    }
}

; =====================================================================
; --- EXECUTION LOGIC: TARGETED MACRO ---
; =====================================================================
ExecuteMacro(ProfileName, TriggerKeyName) {
    global MacroList, GameExe, EnableTooltip, LoopDelay, EnableLetterbox
    if !WinActive(GameExe)
        return
        
    data := MacroList[ProfileName]
    WinGetClientPos ,, &CurrentW, &CurrentH, GameExe
    
    ; --- PRECISE MATH LOGIC: PROJECTION DURING EXECUTION ---
    SavedActiveH := data.BaseH
    NormX := (data.X - (data.BaseW / 2)) / SavedActiveH
    NormY := (data.Y - (data.BaseH / 2)) / SavedActiveH
    
    if (EnableLetterbox) {
        CombatH := CurrentW / 2.0556
        TopBar := (CurrentH - CombatH) / 2
        CenterY := TopBar + (CombatH / 2)
        
        TargetX := (CurrentW / 2) + (NormX * CombatH)
        TargetY := CenterY + (NormY * CombatH)
    } else {
        CenterY := CurrentH / 2
        
        TargetX := (CurrentW / 2) + (NormX * CurrentH)
        TargetY := CenterY + (NormY * CurrentH)
    }
    
    if (!data.NoRet)
        MouseGetPos &OriginX, &OriginY
        
    BaseKey := RegExReplace(TriggerKeyName, "[\^\!\+\#\<\>\~*]", "")

    if (data.Mode == "Rapid") {
        MouseMove Round(TargetX), Round(TargetY), 0
        while GetKeyState(BaseKey, "P") {
            if (data.PreKey != "") {
                SendEvent("{" data.PreKey "}")
                Sleep 15 
            }
            Click
            Sleep LoopDelay 
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

RCtrl & RAlt::
RAlt & RCtrl:: {
    Suspend(-1)
    if (A_IsSuspended)
        ToolTip("Macro System: PAUSED (Safe to type)")
    else
        ToolTip("Macro System: RESUMED (Active)")
    SetTimer () => ToolTip(), -2000
}

+/:: {
    DetectHiddenWindows True
    if (WinGetStyle("ahk_id " MainGui.Hwnd) & 0x10000000) ; WS_VISIBLE check
        MainGui.Hide()
    else
        MainGui.Show()
}

+Esc:: {
    ToolTip("Exiting Macro System...")
    Sleep 500
    ExitApp()
}

#SuspendExempt False

; =====================================================================
; --- CONTEXT-AWARE KEY REMAPPING (IN-GAME ONLY) ---
; =====================================================================
#HotIf WinActive(GameExe)
Space::s
r::a
#HotIf