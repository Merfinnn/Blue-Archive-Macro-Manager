#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global IniFile := A_ScriptDir "\config.ini"
global GameExe := "ahk_exe BlueArchive.exe" ; <--- Sesuaikan dengan emulator kamu
global DaftarMakro := Map()
global SedangMemilih := false
global TempNama := "", TempKey := "", TempPreKey := ""
global TempMode := "Normal", TempNoRet := 0
global TampilkanTooltip := 1

LoadSettings()

; --- MEMBUAT INTERFACES GUI ---
MyGui := Gui("+AlwaysOnTop", "Blue Archive Macro Manager")
MyGui.SetFont("s9", "Segoe UI")

MyGui.Add("GroupBox", "w260 h215", "Tambah / Edit Makro")
MyGui.Add("Text", "xp+10 yp+20", "Nama Makro:")
EditNama := MyGui.Add("Edit", "w240 vNamaMakro", "Spam Serina Heal")

MyGui.Add("Text", "w110", "Keybind (Pemicu):")
EditKey := MyGui.Add("Edit", "w110 vKeybind", "F3")

MyGui.Add("Text", "x+10 w110", "Pre-Key (Opsional):")
EditPreKey := MyGui.Add("Edit", "w110 vPreKey", "1")

; FITUR BARU: Dropdown Mode Eksekusi (Normal / Hold / Spam)
MyGui.Add("Text", "xm+10 y+15 w90", "Mode Eksekusi:")
DDL_TipeMode := MyGui.Add("DropDownList", "x+5 yp-3 w145 vTipeMode Choose1", ["Normal", "Hold (Aiming)", "Spam (Turbo)"])

ChkNoRet := MyGui.Add("CheckBox", "xm+10 y+10 vNoReturn", "Jangan kembalikan mouse ke titik asal")

BtnPick := MyGui.Add("Button", "xm+10 y+10 w240 h26", "Arahkan & Rekam (/)")
BtnPick.OnEvent("Click", TriggerPick)

MyGui.Add("GroupBox", "xm w260 h90", "Daftar Makro Aktif")
DDL_Makro := MyGui.Add("DropDownList", "xp+10 yp+20 w240 vTerpilih")
UpdateDropdown()

BtnHapus := MyGui.Add("Button", "w240", "Hapus Makro Terpilih")
BtnHapus.OnEvent("Click", HapusMakro)

ChkTooltip := MyGui.Add("CheckBox", "xm y+15 vEnableTooltip Checked" TampilkanTooltip, "Tampilkan Notifikasi Popup (Tooltip)")
ChkTooltip.OnEvent("Click", ToggleTooltipSave)

MyGui.Show("w280")

; --- FUNGSI-FUNGSI PENDUKUNG GUI ---
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
    
    ; Ekstrak kata pertama dari mode (Normal / Hold / Spam)
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
    MsgBox("Makro '" TempNama "' berhasil disimpan pada Mode " ModeMurni "!", "Sukses!", 64)
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

LoadSettings() {
    global IniFile, DaftarMakro, TampilkanTooltip
    if !FileExist(IniFile)
        return
        
    TampilkanTooltip := IniRead(IniFile, "Settings", "ShowTooltip", 1)
        
    try {
        FormatINI := FileRead(IniFile)
        Loop Parse, FormatINI, "`n", "`r" {
            if (RegExMatch(A_LoopField, "^\[(.*)\]$", &Match)) {
                Seksi := Match[1]
                if (Seksi == "" || Seksi == "Settings")
                    continue
                
                k := IniRead(IniFile, Seksi, "Key")
                pk := IniRead(IniFile, Seksi, "PreKey", "")
                x := IniRead(IniFile, Seksi, "X")
                y := IniRead(IniFile, Seksi, "Y")
                bw := IniRead(IniFile, Seksi, "BaseW", 1920)
                bh := IniRead(IniFile, Seksi, "BaseH", 1080)
                md := IniRead(IniFile, Seksi, "ModeExec", "Normal")
                nr := IniRead(IniFile, Seksi, "NoReturn", 0)
                
                ; Adaptasi otomatis jika kamu masih punya file config dari versi 2
                hc := IniRead(IniFile, Seksi, "HoldClick", -1)
                if (hc == 1)
                    md := "Hold"
                    
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

; --- LOGIKA EKSEKUSI ADAPTIF (NORMAL / HOLD / SPAM) ---
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
        
    ; Menghilangkan modifier hotkey (seperti alt, ctrl, shift) untuk dibaca GetKeyState/KeyWait
    BaseKey := RegExReplace(TombolPemicu, "[\^\!\+\#\<\>\~*]", "")

    ; --- LOGIKA MODE SPAM (SKENARIO B) ---
    if (data.Mode == "Spam") {
        ; Pindahkan mouse ke area target TERLEBIH DAHULU agar siap
        MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
        
        ; Lakukan spam selama tombol ditahan
        while GetKeyState(BaseKey, "P") {
            if (data.PreKey != "") {
                SendEvent("{" data.PreKey "}")
                Sleep 15 ; Jeda sejenak agar game membaca kartu terpilih
            }
            Click
            Sleep 25 ; Jeda antar tembakan (Sangat ngebut, sekitar ~25 klik per detik)
        }
    } 
    ; --- LOGIKA MODE HOLD (AIMING) ---
    else if (data.Mode == "Hold") {
        if (data.PreKey != "") {
            SendEvent("{" data.PreKey "}")
            Sleep 50 
        }
        MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
        Sleep 30
        
        Click "Down"
        KeyWait BaseKey ; Menunggu sampai jarimu melepas tombol pemicu
        Click "Up"
    } 
    ; --- LOGIKA MODE NORMAL ---
    else {
        if (data.PreKey != "") {
            SendEvent("{" data.PreKey "}")
            Sleep 50 
        }
        MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
        Sleep 30
        Click
    }
    
    Sleep 30
    
    ; Kembalikan mouse ke asal jika opsi NoReturn tidak dicentang
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