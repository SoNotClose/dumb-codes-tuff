; ================================
; AFK script in autohotkey
; pretty neat i use this alot in roblox
; ================================

StartKey := "RShift"          ; this doesnt change the start Key this is just a visual var
PanicKey := "Esc"             ; this doesnt change the Panic Key this is just a visual var
AfkType := "click"            ; click, mouse, key
ClickInterval := 1000         ; Inval in ms for clicks
MouseRadius := 50             ; Radius for mouse movement
MouseMode := "clickndrag"     ; clickndrag, ddrag
MouseWay := "right"           ; left, right, up, down
MouseButton := "left"         ; left, right
AfkKey := "Space"             ; Key to press if AfkType = key
KeyTwice := true              ; Press key twice
KeyDelay := 500               ; Delay between second press in ms
EnableNotifications := true   ; Show tray tips

global afkRunning := false

RShift::
    if (afkRunning) {
        afkRunning := false
        SetTimer, AfkLoop, Off
        if (EnableNotifications)
            TrayTip, AFK Macro, Stopped, 1
    } else {
        afkRunning := true
        SetTimer, AfkLoop, 100
        if (EnableNotifications)
            TrayTip, AFK Macro, Started, 1
    }
return

Esc::
    ExitApp
return

AfkLoop:
    if (!afkRunning) {
        SetTimer, AfkLoop, Off
        return
    }

    if (AfkType = "click") {
        Click, %MouseButton%
        Sleep, %ClickInterval%
    }

    else if (AfkType = "mouse") {
        MouseGetPos, x, y

        ; Move based on direction
        if (MouseWay = "right")
            x += MouseRadius
        else if (MouseWay = "left")
            x -= MouseRadius
        else if (MouseWay = "up")
            y -= MouseRadius
        else if (MouseWay = "down")
            y += MouseRadius

        if (MouseMode = "clickndrag") {
            MouseClickDrag, %MouseButton%, x, y, x+MouseRadius, y, 10
        }
        else if (MouseMode = "ddrag") {
            ; Double drag: drag twice in opposite directions
            MouseClickDrag, %MouseButton%, x, y, x+MouseRadius, y, 10
            Sleep, 200
            MouseClickDrag, %MouseButton%, x, y, x-MouseRadius, y, 10
        }
        else {
            MouseMove, x, y, 10
        }
    }

    else if (AfkType = "key") {
        Send, {%AfkKey%}
        if (KeyTwice) {
            Sleep, %KeyDelay%
            Send, {%AfkKey%}
        }
    }
return
