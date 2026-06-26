#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global IniFile := A_ScriptDir "\config.ini"
; Berdasarkan Window Spy kamu, nama exe Blue Archive adalah BlueArchive.exe
global GameExe := "ahk_exe BlueArchive.exe" 
global DaftarMakro := Map()
global SedangMemilih := false
global TempNama := "", TempKey := ""

LoadSettings()

; --- INTERFACE GUI ---
MyGui := Gui("+AlwaysOnTop", "Blue Archive Macro Manager")
MyGui.SetFont("s9", "Segoe UI")

MyGui.Add("GroupBox", "w260 h120", "Tambah / Edit Makro")
MyGui.Add("Text", "xp+10 yp+20", "Nama Makro:")
EditNama := MyGui.Add("Edit", "w240 vNamaMakro", "Tombol Gacha")
MyGui.Add("Text", "w100", "Keybind (cth: F3):")
EditKey := MyGui.Add("Edit", "w100 vKeybind", "F3")

BtnPick := MyGui.Add("Button", "x+10 w130 h26", "Arahkan & Rekam (/)")
BtnPick.OnEvent("Click", TriggerPick)

MyGui.Add("GroupBox", "xm w260 h90", "Daftar Makro Aktif")
DDL_Makro := MyGui.Add("DropDownList", "xp+10 yp+20 w240 vTerpilih")
UpdateDropdown()

BtnHapus := MyGui.Add("Button", "w240", "Hapus Makro Terpilih")
BtnHapus.OnEvent("Click", HapusMakro)

MyGui.Show("w280")

TriggerPick(*) {
    global SedangMemilih, TempNama, TempKey
    TempNama := EditNama.Value
    TempKey := EditKey.Value
    
    if (TempNama == "" || TempKey == "") {
        MsgBox("Nama Makro dan Keybind tidak boleh kosong!", "Error", 48)
        return
    }
    
    SedangMemilih := true
    ToolTip("Buka Game! Arahkan mouse ke target, lalu tekan tombol [/] untuk mengunci.")
}

#HotIf SedangMemilih
$/:: {
    global SedangMemilih, TempNama, TempKey, DaftarMakro, GameExe
    SedangMemilih := false
    ToolTip()
    
    ; Ambil posisi mouse saat ini
    MouseGetPos &mx, &my
    
    ; Ambil resolusi jendela tempat user merekam saat ini agar rumusnya akurat
    WinGetClientPos ,, &W_Rekam, &H_Rekam, GameExe
    
    ; Simpan ke Map internal termasuk base resolution saat direkam
    DaftarMakro[TempNama] := {Key: TempKey, X: mx, Y: my, BaseW: W_Rekam, BaseH: H_Rekam}
    
    ; Simpan permanen ke file INI
    IniWrite(TempKey, IniFile, TempNama, "Key")
    IniWrite(mx, IniFile, TempNama, "X")
    IniWrite(my, IniFile, TempNama, "Y")
    IniWrite(W_Rekam, IniFile, TempNama, "BaseW")
    IniWrite(H_Rekam, IniFile, TempNama, "BaseH")
    
    DaftarkanHotkey(TempKey, TempNama)
    UpdateDropdown()
    MsgBox("Makro '" TempNama "' berhasil disimpan!", "Sukses!", 64)
}
#HotIf

UpdateDropdown() {
    global DaftarMakro, DDL_Makro
    ArrList := []
    for nama, data in DaftarMakro {
        ArrList.Push(nama " [" data.Key "] -> (" data.X "," data.Y ")")
    }
    DDL_Makro.Delete()
    if (ArrList.Length > 0)
        DDL_Makro.Add(ArrList)
}

; --- PERBAIKAN FUNGSI DAFTAR HOTKEY ---
DaftarkanHotkey(Tombol, NamaMakro) {
    global GameExe
    try {
        ; 1. Kunci konteks: Hotkey yang dibuat setelah baris ini HANYA aktif saat game menyala
        HotIfWinActive(GameExe)
        
        ; 2. Daftarkan hotkey ke sistem Windows
        Hotkey(Tombol, (TombolName) => EksekusiKlik(NamaMakro), "On")
        
        ; 3. Lepas kunci konteks kembali ke global (mencegah error di fungsi AHK lain)
        HotIfWinActive()
    } catch {
        MsgBox("Format Keybind '" Tombol "' tidak valid!", "Error Hotkey", 48)
    }
}

; --- PERBAIKAN FUNGSI HAPUS MAKRO ---
HapusMakro(*) {
    global DaftarMakro, DDL_Makro, IniFile, GameExe
    if (DDL_Makro.Text == "")
        return
        
    NamaAsli := RegExReplace(DDL_Makro.Text, " \[.*", "")
    
    try {
        ; Untuk mematikan hotkey, kita juga harus masuk ke konteks game yang sama
        HotIfWinActive(GameExe)
        Hotkey(DaftarMakro[NamaAsli].Key, "Off")
        HotIfWinActive()
    }
    
    DaftarMakro.Delete(NamaAsli)
    IniDelete(IniFile, NamaAsli)
    
    UpdateDropdown()
    MsgBox("Makro '" NamaAsli "' berhasil dihapus.", "Sukses", 64)
}

LoadSettings() {
    global IniFile, DaftarMakro
    if !FileExist(IniFile)
        return
        
    try {
        FormatINI := FileRead(IniFile)
        Loop Parse, FormatINI, "`n", "`r" {
            if (RegExMatch(A_LoopField, "^\[(.*)\]$", &Match)) {
                Seksi := Match[1]
                if (Seksi == "" || Seksi == "Koordinat_Aktif" || Seksi == "History")
                    continue
                k := IniRead(IniFile, Seksi, "Key")
                x := IniRead(IniFile, Seksi, "X")
                y := IniRead(IniFile, Seksi, "Y")
                
                ; Gunakan nilai fallback jika key BaseW/BaseH belum ada di config lama
                bw := IniRead(IniFile, Seksi, "BaseW", 1920)
                bh := IniRead(IniFile, Seksi, "BaseH", 1080)
                
                DaftarMakro[Seksi] := {Key: k, X: x, Y: y, BaseW: bw, BaseH: bh}
                DaftarkanHotkey(k, Seksi)
            }
        }
    }
}


; --- PERBAIKAN LOGIKA HITUNG ADAPTIF (DINAMIS BASE) ---
; --- LOGIKA UNITY FIXED VERTICAL FOV (MATCH HEIGHT) ---
EksekusiKlik(Nama) {
    global DaftarMakro, GameExe
    
    if !WinActive(GameExe)
        return
        
    data := DaftarMakro[Nama]
    WinGetClientPos ,, &LebarBaru, &TinggiBaru, GameExe
    
    ; 1. Skala murni berdasarkan TINGGI (Fixed Vertical FOV)
    Skala := TinggiBaru / data.BaseH
    
    ; 2. Kalkulasi Y (Skala langsung terhadap tinggi layar)
    TargetY_Baru := data.Y * Skala
    
    ; 3. Kalkulasi X (Dihitung berdasarkan jarak relatif dari titik tengah layar)
    PusatX_Lama := data.BaseW / 2
    PusatX_Baru := LebarBaru / 2
    JarakX_Dari_Pusat := data.X - PusatX_Lama
    
    TargetX_Baru := PusatX_Baru + (JarakX_Dari_Pusat * Skala)

    ; --- FITUR BARU: SIMPAN & KEMBALIKAN MOUSE ---
    
    ; 1. Simpan koordinat mouse kamu saat ini (sebelum klik)
    MouseGetPos &asalX, &asalY
    
    ; 2. Eksekusi Klik di target yang sudah dihitung
    Click Round(TargetX_Baru), Round(TargetY_Baru)
    Sleep 30
    ; 3. Kembalikan mouse ke posisi asalnya (angka 0 = kecepatan instan)
    MouseMove asalX, asalY, 0
    
    ; Tooltip Indikator
    ToolTip("Memicu Makro: " Nama)
    SetTimer () => ToolTip(), -1500
}

#HotIf WinActive(GameExe)
Space::s
#HotIf

; =====================================================================
; --- FITUR GLOBAL (TETAP AKTIF MESKIPUN MAKRO DI-PAUSE) ---
; =====================================================================
#SuspendExempt  ; (Semua hotkey di bawah ini tidak akan terpengaruh mode Pause)

; Right Shift + Esc : Toggle Pause Makro (Bisa untuk Ngetik Chat)
>+Esc:: {
    Suspend(-1) ; Fungsi bawaan AHK untuk mematikan/menghidupkan semua hotkey
    if (A_IsSuspended)
        ToolTip("Makro: PAUSED (Bebas Ngetik)")
    else
        ToolTip("Makro: RESUMED (Siap Tempur)")
    SetTimer () => ToolTip(), -2000
}

; Right Shift + / (?) : Menampilkan Kembali Jendela GUI Makro
>+/:: {
    MyGui.Show()
}

#SuspendExempt False ; (Menutup batas perlindungan Pause)