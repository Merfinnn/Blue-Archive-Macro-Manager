#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global IniFile := A_ScriptDir "\config.ini"
global GameExe := "ahk_exe BlueArchive.exe" ; <--- Sesuaikan dengan emulator kamu
global DaftarMakro := Map()
global DaftarQuickCast := Map()
global SedangMemilih := false
global TempNama := "", TempKey := "", TempPreKey := ""
global TempMode := "Normal", TempNoRet := 0
global TampilkanTooltip := 1

LoadSettings()

; --- MEMBUAT INTERFACES GUI ---
MyGui := Gui("+AlwaysOnTop", "Blue Archive Macro Manager")
MyGui.SetFont("s9", "Segoe UI")

; PANEL 1: Makro dengan Target Koordinat
MyGui.Add("GroupBox", "w260 h215", "Target Makro (Punya Koordinat)")
MyGui.Add("Text", "xp+10 yp+20", "Nama Makro:")
EditNama := MyGui.Add("Edit", "w240 vNamaMakro", "Target Heal")

MyGui.Add("Text", "w110", "Keybind (Pemicu):")
EditKey := MyGui.Add("Edit", "w110 vKeybind", "F3")

MyGui.Add("Text", "x+10 w110", "Pre-Key (Opsional):")
EditPreKey := MyGui.Add("Edit", "w110 vPreKey", "1")

MyGui.Add("Text", "xm+10 y+15 w90", "Mode Eksekusi:")
DDL_TipeMode := MyGui.Add("DropDownList", "x+5 yp-3 w145 vTipeMode Choose1", ["Normal", "Hold (Aiming)", "Spam (Turbo)"])

ChkNoRet := MyGui.Add("CheckBox", "xm+10 y+10 vNoReturn", "Jangan kembalikan mouse ke titik asal")

BtnPick := MyGui.Add("Button", "xm+10 y+10 w240 h26", "Arahkan & Rekam (/)")
BtnPick.OnEvent("Click", TriggerPick)

MyGui.Add("GroupBox", "xm w260 h90", "Daftar Makro Target")
DDL_Makro := MyGui.Add("DropDownList", "xp+10 yp+20 w240 vTerpilih")
UpdateDropdown()

BtnHapus := MyGui.Add("Button", "w240", "Hapus Makro Terpilih")
BtnHapus.OnEvent("Click", HapusMakro)

; PANEL 2: Quick Cast (Spam Bebas Tanpa Koordinat)
MyGui.Add("GroupBox", "xm w260 h115", "Quick Cast (Spam di Posisi Kursor)")
MyGui.Add("Text", "xp+10 yp+20 w60", "Slot 1:")
QCEdit1 := MyGui.Add("Edit", "x+5 yp-2 w50 vQC1", "")
MyGui.Add("Text", "x+10 yp+2 w60", "Slot 2:")
QCEdit2 := MyGui.Add("Edit", "x+5 yp-2 w50 vQC2", "")

MyGui.Add("Text", "xm+10 y+10 w60", "Slot 3:")
QCEdit3 := MyGui.Add("Edit", "x+5 yp-2 w50 vQC3", "")
MyGui.Add("Text", "x+10 yp+2 w60", "Slot 4:")
QCEdit4 := MyGui.Add("Edit", "x+5 yp-2 w50 vQC4", "")

MyGui.Add("Text", "xm+10 y+10 w60", "Slot 5:")
QCEdit5 := MyGui.Add("Edit", "x+5 yp-2 w50 vQC5", "")

BtnSaveQC := MyGui.Add("Button", "x+10 yp-2 w115", "Simpan Keybind")
BtnSaveQC.OnEvent("Click", SimpanQuickCast)

; PANEL 3: Settings Tambahan
ChkTooltip := MyGui.Add("CheckBox", "xm y+15 vEnableTooltip Checked" TampilkanTooltip, "Tampilkan Notifikasi Popup (Tooltip)")
ChkTooltip.OnEvent("Click", ToggleTooltipSave)

MyGui.Show("w280")
UpdateQCGui()

; --- FUNGSI-FUNGSI PENDUKUNG GUI (TARGET MAKRO) ---
ToggleTooltipSave(*) {
    global TampilkanTooltip, IniFile
    TampilkanTooltip := ChkTooltip.Value
    IniWrite(TampilkanTooltip, IniFile, "Settings", "ShowTooltip")
}

TriggerPick(*) {
    global SedangMemilih, TempNama, TempKey, TempPreKey, TempMode, TempNoRet, BtnPick
    if (SedangMemilih) {
        SedangMemilih := false
        BtnPick.Text := "Arahkan & Rekam (/)" 
        ToolTip("Perekaman dibatalkan.")
        SetTimer () => ToolTip(), -1500
        return
    }
    TempNama := EditNama.Value
    TempKey := EditKey.Value
    TempPreKey := EditPreKey.Value
    TempMode := DDL_TipeMode.Text
    TempNoRet := ChkNoRet.Value
    
    if (TempNama == "" || TempKey == "") {
        MsgBox("Nama Makro dan Keybind tidak boleh kosong!", "Error", 48)
        return
    }
    
    SedangMemilih := true
    BtnPick.Text := "Batalkan Perekaman (Klik Lagi)"
    ToolTip("Buka Game! Arahkan mouse ke target, lalu tekan tombol [/] untuk mengunci.")
}

#HotIf SedangMemilih
$/:: {
    global SedangMemilih, TempNama, TempKey, TempPreKey, TempMode, TempNoRet
    global DaftarMakro, GameExe, IniFile, BtnPick
    SedangMemilih := false
    BtnPick.Text := "Arahkan & Rekam (/)"
    ToolTip()
    
    MouseGetPos &mx, &my
    WinGetClientPos ,, &W_Rekam, &H_Rekam, GameExe
    ModeMurni := RegExReplace(TempMode, " \(.*", "")
    
    DaftarMakro[TempNama] := {Key: TempKey, PreKey: TempPreKey, X: mx, Y: my, BaseW: W_Rekam, BaseH: H_Rekam, Mode: ModeMurni, NoRet: TempNoRet}
    
    IniWrite(TempKey, IniFile, TempNama, "Key")
    IniWrite(TempPreKey, IniFile, TempNama, "PreKey")
    IniWrite(mx, IniFile, TempNama, "X")
    IniWrite(my, IniFile, TempNama, "Y")
    IniWrite(W_Rekam, IniFile, TempNama, "BaseW")
    IniWrite(H_Rekam, IniFile, TempNama, "BaseH")
    IniWrite(ModeMurni, IniFile, TempNama, "ModeExec")
    IniWrite(TempNoRet, IniFile, TempNama, "NoReturn")
    
    DaftarkanHotkey(TempKey, TempNama)
    UpdateDropdown()
    MsgBox("Makro '" TempNama "' berhasil disimpan!", "Sukses!", 64)
}
#HotIf

UpdateDropdown() {
    global DaftarMakro, DDL_Makro
    ArrList := []
    for nama, data in DaftarMakro {
        teksOpsi := (data.Mode != "Normal" ? "[" data.Mode "] " : "") . (data.NoRet ? "[NO-RET] " : "")
        ArrList.Push(teksOpsi nama " (" data.Key ")")
    }
    DDL_Makro.Delete()
    if (ArrList.Length > 0)
        DDL_Makro.Add(ArrList)
}

HapusMakro(*) {
    global DaftarMakro, DDL_Makro, IniFile, GameExe
    if (DDL_Makro.Text == "")
        return
    NamaAsli := RegExReplace(DDL_Makro.Text, "^(\[.*?\]\s*)*", "")
    NamaAsli := RegExReplace(NamaAsli, " \(.*", "")
    try {
        HotIfWinActive(GameExe)
        Hotkey(DaftarMakro[NamaAsli].Key, "Off")
        HotIfWinActive()
    }
    DaftarMakro.Delete(NamaAsli)
    IniDelete(IniFile, NamaAsli)
    UpdateDropdown()
}

; --- FUNGSI QUICK CAST (SPAM BEBAS) ---
SimpanQuickCast(*) {
    global IniFile, DaftarQuickCast, GameExe
    global QCEdit1, QCEdit2, QCEdit3, QCEdit4, QCEdit5
    
    DataBaru := [QCEdit1.Value, QCEdit2.Value, QCEdit3.Value, QCEdit4.Value, QCEdit5.Value]
    
    ; Matikan hotkey Quick Cast lama sebelum menimpa
    for slot, tombol in DaftarQuickCast {
        try {
            HotIfWinActive(GameExe)
            Hotkey(tombol, "Off")
            HotIfWinActive()
        }
    }
    DaftarQuickCast.Clear()
    
    ; Simpan dan daftarkan yang baru
    Loop 5 {
        kb := DataBaru[A_Index]
        IniWrite(kb, IniFile, "QuickCast", "Slot" A_Index)
        if (kb != "") {
            DaftarQuickCast[A_Index] := kb
            DaftarkanHotkeyQuickCast(kb, A_Index)
        }
    }
    MsgBox("Keybind Quick Cast berhasil disimpan!", "Sukses", 64)
}

DaftarkanHotkeyQuickCast(Tombol, Slot) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        Hotkey(Tombol, (TombolName) => EksekusiSpamBebas(Slot, TombolName), "On")
        HotIfWinActive()
    } catch {
        MsgBox("Format Keybind '" Tombol "' untuk Slot " Slot " tidak valid!", "Error Hotkey", 48)
    }
}

UpdateQCGui() {
    global QCEdit1, QCEdit2, QCEdit3, QCEdit4, QCEdit5, DaftarQuickCast
    try QCEdit1.Value := DaftarQuickCast.Has(1) ? DaftarQuickCast[1] : ""
    try QCEdit2.Value := DaftarQuickCast.Has(2) ? DaftarQuickCast[2] : ""
    try QCEdit3.Value := DaftarQuickCast.Has(3) ? DaftarQuickCast[3] : ""
    try QCEdit4.Value := DaftarQuickCast.Has(4) ? DaftarQuickCast[4] : ""
    try QCEdit5.Value := DaftarQuickCast.Has(5) ? DaftarQuickCast[5] : ""
}

; --- INITIALIZATION (LOAD SETTINGS) ---
LoadSettings() {
    global IniFile, DaftarMakro, DaftarQuickCast, TampilkanTooltip
    if !FileExist(IniFile)
        return
        
    TampilkanTooltip := IniRead(IniFile, "Settings", "ShowTooltip", 1)
    
    ; Load Quick Cast
    Loop 5 {
        kb := IniRead(IniFile, "QuickCast", "Slot" A_Index, "")
        if (kb != "") {
            DaftarQuickCast[A_Index] := kb
            DaftarkanHotkeyQuickCast(kb, A_Index)
        }
    }
        
    ; Load Makro Target
    try {
        FormatINI := FileRead(IniFile)
        Loop Parse, FormatINI, "`n", "`r" {
            if (RegExMatch(A_LoopField, "^\[(.*)\]$", &Match)) {
                Seksi := Match[1]
                if (Seksi == "" || Seksi == "Settings" || Seksi == "QuickCast")
                    continue
                
                k := IniRead(IniFile, Seksi, "Key")
                pk := IniRead(IniFile, Seksi, "PreKey", "")
                x := IniRead(IniFile, Seksi, "X")
                y := IniRead(IniFile, Seksi, "Y")
                bw := IniRead(IniFile, Seksi, "BaseW", 1920)
                bh := IniRead(IniFile, Seksi, "BaseH", 1080)
                md := IniRead(IniFile, Seksi, "ModeExec", "Normal")
                nr := IniRead(IniFile, Seksi, "NoReturn", 0)
                
                DaftarMakro[Seksi] := {Key: k, PreKey: pk, X: x, Y: y, BaseW: bw, BaseH: bh, Mode: md, NoRet: nr}
                DaftarkanHotkey(k, Seksi)
            }
        }
    }
}

DaftarkanHotkey(Tombol, NamaMakro) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        Hotkey(Tombol, (TombolName) => EksekusiKlik(NamaMakro, TombolName), "On")
        HotIfWinActive()
    }
}

; --- LOGIKA EKSEKUSI: SPAM BEBAS (QUICK CAST) ---
EksekusiSpamBebas(SlotPreKey, TombolPemicu) {
    global GameExe, TampilkanTooltip
    if !WinActive(GameExe)
        return
        
    BaseKey := RegExReplace(TombolPemicu, "[\^\!\+\#\<\>\~*]", "")
    PreKeyAktual := String(SlotPreKey) ; Slot 1 = kirim tombol "1"
    
    if (TampilkanTooltip) {
        ToolTip("Quick Cast Spam: Slot " PreKeyAktual)
    }
    
    ; Langsung lakukan loop klik di posisi kursor SAAT INI
    while GetKeyState(BaseKey, "P") {
        SendEvent("{" PreKeyAktual "}")
        Sleep 15
        Click
        Sleep 25
    }
    
    if (TampilkanTooltip) {
        ToolTip() ; Hilangkan langsung setelah tombol dilepas
    }
}

; --- LOGIKA EKSEKUSI: MAKRO TARGET KORDINAT (NORMAL / HOLD / SPAM) ---
EksekusiKlik(Nama, TombolPemicu) {
    global DaftarMakro, GameExe, TampilkanTooltip
    if !WinActive(GameExe)
        return
        
    data := DaftarMakro[Nama]
    WinGetClientPos ,, &LebarBaru, &TinggiBaru, GameExe
    
    Skala := TinggiBaru / data.BaseH
    TargetY_Baru := data.Y * Skala
    PusatX_Baru := LebarBaru / 2
    JarakX_Dari_Pusat := data.X - (data.BaseW / 2)
    TargetX_Baru := PusatX_Baru + (JarakX_Dari_Pusat * Skala)
    
    if (!data.NoRet)
        MouseGetPos &asalX, &asalY
        
    BaseKey := RegExReplace(TombolPemicu, "[\^\!\+\#\<\>\~*]", "")

    if (data.Mode == "Spam") {
        MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
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
        MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
        Sleep 30
        
        Click "Down"
        KeyWait BaseKey 
        Click "Up"
    } else {
        if (data.PreKey != "") {
            SendEvent("{" data.PreKey "}")
            Sleep 50 
        }
        MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
        Sleep 30
        Click
    }
    
    Sleep 30
    if (!data.NoRet)
        MouseMove asalX, asalY, 0
    
    if (TampilkanTooltip) {
        ToolTip("Makro Selesai: " Nama)
        SetTimer () => ToolTip(), -1000
    }
}

; =====================================================================
; --- FITUR GLOBAL (TETAP AKTIF MESKIPUN MAKRO DI-PAUSE) ---
; =====================================================================
#SuspendExempt
>+Esc:: {
    Suspend(-1)
    if (A_IsSuspended)
        ToolTip("Makro: PAUSED (Bebas Ngetik)")
    else
        ToolTip("Makro: RESUMED (Siap Tempur)")
    SetTimer () => ToolTip(), -2000
}
>+/:: {
    MyGui.Show()
}
#SuspendExempt False

; =====================================================================
; --- REMAP TOMBOL KEYBOARD KHUSUS DI DALAM BLUE ARCHIVE ---
; =====================================================================
#HotIf WinActive(GameExe)
Space::s
r::a
#HotIf