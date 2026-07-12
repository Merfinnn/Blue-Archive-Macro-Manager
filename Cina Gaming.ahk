#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1
InstallKeybdHook
#UseHook
Persistent

; ================== 全局输入模式 ==================
SendMode "Event"
SetKeyDelay -1, -1
SetMouseDelay -1
; ==============================================================

WIDTH  := 1920
HEIGHT := 1200

global ActiveSpamKey := ""
global SpamTimer := ""

; ================== 窗口处理 ==================

hwnd := WinGetID("ahk_exe bluearchive.exe")
if WinExist("ahk_id " hwnd) {
    SetWindowClientSize(hwnd, WIDTH, HEIGHT)
}

SetWindowClientSize(hwnd, desiredW, desiredH) {
    if !WinExist("ahk_id " hwnd)
        return

    if WinGetMinMax("ahk_id " hwnd)
        WinRestore("ahk_id " hwnd)

    WinGetPos &wx, &wy, &ww, &wh, "ahk_id " hwnd
    WinGetClientPos &cx, &cy, &cw, &ch, "ahk_id " hwnd

    left   := cx - wx
    top    := cy - wy
    right  := (wx + ww) - (cx + cw)
    bottom := (wy + wh) - (cy + ch)

    newW := desiredW + left + right
    newH := desiredH + top + bottom

    WinMove wx, wy, newW, newH, "ahk_id " hwnd
}

WinGetClientPos &X, &Y, &W, &H, "ahk_id " hwnd

RelativeClick(x, y) {
    global W, H, WIDTH, HEIGHT
    rx := x / WIDTH * W
    ry := y / HEIGHT * H
    SendEvent Format("{{Click {} {}}}", rx, ry)
}

; ================== 连发控制 ==================

SpamAction(actionFunc) {
    actionFunc.Call()
}

StartSpam(actionFunc, key) {
    global ActiveSpamKey, SpamTimer

    if IsObject(SpamTimer) {
        SetTimer SpamTimer, 0
        SpamTimer := ""
    }

    ActiveSpamKey := key
    SpamTimer := SpamAction.Bind(actionFunc)
    SetTimer SpamTimer, 2
}

StopSpam() {
    global ActiveSpamKey, SpamTimer

    if IsObject(SpamTimer) {
        SetTimer SpamTimer, 0
        SpamTimer := ""
    }
    ActiveSpamKey := ""
}

#HotIf WinActive("ahk_exe bluearchive.exe")

; ================== Q / W / E：鼠标当前位置连发 ==================

$*q:: {
    StartSpam(RepeatTick.Bind("1"), "q")
    KeyWait "q"
    StopSpam()
}

$*w:: {
    StartSpam(RepeatTick.Bind("2"), "w")
    KeyWait "w"
    StopSpam()
}

$*e:: {
    StartSpam(RepeatTick.Bind("3"), "e")
    KeyWait "e"
    StopSpam()
}

$*r:: {
    StartSpam(RepeatTick.Bind("4"), "r")
    KeyWait "r"
    StopSpam()
}

$*t:: {
    StartSpam(RepeatTick.Bind("5"), "t")
    KeyWait "t"
    StopSpam()
}

; ================== Z / X / C：固定坐标连发 ==================

$*z:: {
    StartSpam(RepeatClick.Bind("1", 786, 410), "z")
    KeyWait "z"
    StopSpam()
}

$*x:: {
    StartSpam(RepeatClick.Bind("2", 786, 410), "x")
    KeyWait "x"
    StopSpam()
}

$*c:: {
    StartSpam(RepeatClick.Bind("3", 786, 410), "c")
    KeyWait "c"
    StopSpam()
}

; ================== 点位 ==================

$D:: SendEvent "{Click 341, 623 Down}"
$D up:: SendEvent "{Click Up}"

$F:: SendEvent "{Click 576, 594 Down}"
$F up:: SendEvent "{Click Up}"

$G:: SendEvent "{Click 487, 540 Down}"
$G up:: SendEvent "{Click Up}"

; ================== 波浪键：帧暂停 ==================

$`:: {
    SendEvent "{Click}"
    Sleep 25
    SendEvent "{Esc}"
}

; ================== V 键：连发Auto  ==================

SendA() {
    SendEvent "a"
}

$*v:: {
    SetTimer SendA, 2
    KeyWait "v"
    SetTimer SendA, 0
}

; ================== P 键：记录坐标 ==================

$p:: {
    global W, H, WIDTH, HEIGHT
    MouseGetPos &mx, &my

    relX := Round(mx / W * WIDTH)
    relY := Round(my / H * HEIGHT)

    file := A_Desktop "\坐标.txt"
    time := FormatTime("", "yyyy-MM-dd HH:mm:ss")
    FileAppend "时间: " time " | 坐标: (" relX ", " relY ") | 实际: (" mx ", " my ")" "`n", file

    ToolTip "记录: (" relX ", " relY ")", mx+20, my+20
    SetTimer () => ToolTip(), -1500
}

#HotIf

; ================== 动作函数 ==================

RepeatTick(key) {
    SendEvent key
    SendEvent "{Click}"
}

RepeatClick(key, x, y) {
    global W, H, WIDTH, HEIGHT

    SendEvent key

    rx := x / WIDTH * W
    ry := y / HEIGHT * H

    MouseMove rx, ry, 0
    SendEvent "{Click Down}"
    SendEvent "{Click Up}"
}
