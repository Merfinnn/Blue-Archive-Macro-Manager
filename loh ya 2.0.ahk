#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global IniFile := A_ScriptDir "\config.ini"
global GameExe := "ahk_exe BlueArchive.exe" ; <--- Ganti dengan Exe emulator kamu
global DaftarMakro := Map()
global SedangMemilih := false
global TempNama := "", TempKey := "", TempPreKey := ""
global TempHold := 0, TempNoRet := 0
global TampilkanTooltip := 1

LoadSettings()

; --- MEMBUAT INTERFACES GUI ---
MyGui := Gui("+AlwaysOnTop", "Blue Archive Macro Manager")
MyGui.SetFont("s9", "Segoe UI")

; GroupBox diperbesar untuk menampung fitur baru
MyGui.Add("GroupBox", "w260 h210", "Tambah / Edit Makro")
MyGui.Add("Text", "xp+10 yp+20", "Nama Makro:")
EditNama := MyGui.Add("Edit", "w240 vNamaMakro", "Skill EX Hibiki")

MyGui.Add("Text", "w110", "Keybind (Pemicu):")
EditKey := MyGui.Add("Edit", "w110 vKeybind", "F3")

MyGui.Add("Text", "x+10 w110", "Pre-Key (Opsional):")
EditPreKey := MyGui.Add("Edit", "w110 vPreKey", "")

; FITUR BARU: Opsi Mode Hold dan Return Mouse
ChkHold := MyGui.Add("CheckBox", "xm+10 y+10 vHoldClick", "Mode Hold (Tahan Klik sampai pemicu dilepas)")
ChkNoRet := MyGui.Add("CheckBox", "xp y+5 vNoReturn", "Jangan kembalikan mouse ke titik asal")

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
    global SedangMemilih, TempNama, TempKey, TempPreKey, TempHold, TempNoRet
    TempNama := EditNama.Value
    TempKey := EditKey.Value
    TempPreKey := EditPreKey.Value
    TempHold := ChkHold.Value
    TempNoRet := ChkNoRet.Value
    
    if (TempNama == "" || TempKey == "") {
        MsgBox("Nama Makro dan Keybind tidak boleh kosong!", "Error", 48)
        return
    }
    
    SedangMemilih := true
    ToolTip("Buka Game! Arahkan mouse ke target, lalu tekan tombol [/] untuk mengunci.")
}

; --- MODE PEREKAMAN AKTIF ---
#HotIf SedangMemilih

; 1. Tombol [/] untuk MENGONFIRMASI / MENYIMPAN koordinat
$/:: {
    global SedangMemilih, TempNama, TempKey, TempPreKey, TempHold, TempNoRet
    global DaftarMakro, GameExe, IniFile
    SedangMemilih := false
    ToolTip() ; Hilangkan tooltip
    
    MouseGetPos &mx, &my
    WinGetClientPos ,, &W_Rekam, &H_Rekam, GameExe
    
    DaftarMakro[TempNama] := {Key: TempKey, PreKey: TempPreKey, X: mx, Y: my, BaseW: W_Rekam, BaseH: H_Rekam, Hold: TempHold, NoRet: TempNoRet}
    
    IniWrite(TempKey, IniFile, TempNama, "Key")
    IniWrite(TempPreKey, IniFile, TempNama, "PreKey")
    IniWrite(mx, IniFile, TempNama, "X")
    IniWrite(my, IniFile, TempNama, "Y")
    IniWrite(W_Rekam, IniFile, TempNama, "BaseW")
    IniWrite(H_Rekam, IniFile, TempNama, "BaseH")
    IniWrite(TempHold, IniFile, TempNama, "HoldClick")
    IniWrite(TempNoRet, IniFile, TempNama, "NoReturn")
    
    DaftarkanHotkey(TempKey, TempNama)
    UpdateDropdown()
    MsgBox("Makro '" TempNama "' berhasil disimpan!", "Sukses!", 64)
}

; 2. FITUR BARU: Tombol [Esc] untuk MEMBATALKAN perekaman
$Esc:: {
    global SedangMemilih
    SedangMemilih := false
    
    ; Tampilkan notifikasi batal sejenak, lalu hilangkan
    ToolTip("Perekaman dibatalkan.")
    SetTimer () => ToolTip(), -1500
}

#HotIf
; --- BATAS MODE PEREKAMAN ---

UpdateDropdown() {
    global DaftarMakro, DDL_Makro
    ArrList := []
    for nama, data in DaftarMakro {
        teksOpsi := (data.Hold ? "[HOLD] " : "") . (data.NoRet ? "[NO-RET] " : "")
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
        
    ; Ekstrak nama asli (menghilangkan teks awalan seperti [HOLD] jika ada)
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
                hc := IniRead(IniFile, Seksi, "HoldClick", 0)
                nr := IniRead(IniFile, Seksi, "NoReturn", 0)
                
                DaftarMakro[Seksi] := {Key: k, PreKey: pk, X: x, Y: y, BaseW: bw, BaseH: bh, Hold: hc, NoRet: nr}
                DaftarkanHotkey(k, Seksi)
            }
        }
    }
}

DaftarkanHotkey(Tombol, NamaMakro) {
    global GameExe
    try {
        HotIfWinActive(GameExe)
        ; Menyuntikkan nama tombol ke dalam fungsi agar bisa dicek saat dilepas (KeyWait)
        Hotkey(Tombol, (TombolName) => EksekusiKlik(NamaMakro, TombolName), "On")
        HotIfWinActive()
    }
}

; --- LOGIKA EKSEKUSI ADAPTIF, HOLD, & RETURN ---
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
    
    ; Simpan asal mouse jika opsi NoReturn mati
    if (!data.NoRet) {
        MouseGetPos &asalX, &asalY
    }
    
    if (data.PreKey != "") {
        SendEvent("{" data.PreKey "}")
    ;    Sleep 50 
    }
    
    MouseMove Round(TargetX_Baru), Round(TargetY_Baru), 0
    ;   Sleep 30
    
    if (data.Hold) {
        Click "Down" ; Tahan klik kiri
        
        ; Membersihkan nama tombol dari modifier (seperti ^, !, +) agar KeyWait berfungsi
        BaseKey := RegExReplace(TombolPemicu, "[\^\!\+\#\<\>\~*]", "")
        KeyWait BaseKey ; Menunggu jarimu melepas tombol di keyboard
        
        Click "Up"   ; Lepaskan klik kiri (menembak skill)
    } else {
        Click        ; Klik instan biasa
    }
    
    Sleep 30
    
    ; Kembalikan mouse hanya jika kotak NoReturn tidak dicentang
    if (!data.NoRet) {
        MouseMove asalX, asalY, 0
    }
    
    if (TampilkanTooltip) {
        ToolTip("Makro: " Nama)
        SetTimer () => ToolTip(), -1500
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