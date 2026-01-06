#NoEnv
#SingleInstance Force

sellKey := "e"          ; Self Explanatory

holdTime := 350         ; How long to hold the key/click (ms)

useMouse := false       ; Set to true to use Left Click instead of 'E'

waitDelay := 3000       ; Regular delay used if random delay is false

randomDelay := true     ; Set to true to enable random intervals

randomDelayMin := 2000  ; Minimum ms

randomDelayMax := 10000  ; Maximum ms

running := false

RShift::
    running := true
    
    if (randomDelay) {
        Random, firstDelay, %randomDelayMin%, %randomDelayMax%
    } else {
        firstDelay := waitDelay
    }
    
    displayMin := firstDelay // 60000
    displayMs := Mod(firstDelay, 60000)
    
    MsgBox, 64, GlobalAutoSell, Auto Sell Started Make Sure The Interaction UI Is Shown`n`nThe Next Sell Will Be In %displayMin% Minutes %displayMs% Milliseconds
    
    GoSub, SellLoop
return

SellLoop:
    if (!running)
        return

    if (useMouse) {
        Click, Down
        Sleep, %holdTime%
        Click, Up
    } else {
        Send, {%sellKey% down}
        Sleep, %holdTime%
        Send, {%sellKey% up}
    }
    
    if (randomDelay) {
        Random, nextDelay, %randomDelayMin%, %randomDelayMax%
    } else {
        nextDelay := waitDelay
    }
    
    Sleep, %nextDelay%
    
    if (running)
        SetTimer, SellLoop, -10
return

LShift::
    running := false
    MsgBox, 48, GlobalAutoSell, Auto Sell Stopped, 2
    ExitApp
return