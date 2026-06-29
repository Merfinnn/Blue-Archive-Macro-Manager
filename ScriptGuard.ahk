#Include <ScriptGuard1.ahk>    ; Can adjust for location of ScriptGuard1.ahk
;@Ahk2Exe-Obey U_Bin,= "%A_BasePath~^.+\.%" = "bin" ? "Cont" : "Nop" ; .bin?
;@Ahk2Exe-Obey U_au, = "%A_IsUnicode%" ? 2 : 1 ; Base file ANSI or Unicode?
;@Ahk2Exe-PostExec "BinMod.exe" "%A_WorkFileName%"
;@Ahk2Exe-%U_Bin%  "1%U_au%2.>AUTOHOTKEY SCRIPT<. RANDOM"
;@Ahk2Exe-Cont  "%U_au%.AutoHotkeyGUI.RANDOM"
;@Ahk2Exe-Cont  /ScriptGuard2  ; or /ScriptGuard2pss if required
;@Ahk2Exe-PostExec "BinMod.exe" "%A_WorkFileName%" "11.UPX." "1.UPX!.", 2
;@Ahk2Exe-UpdateManifest 0, .