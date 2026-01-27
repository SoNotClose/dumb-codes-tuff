#SingleInstance
; ---------- Auto feefer ----------
; made so i can afk feefs (roblox)
; yeah this will get patched so abuse whille ya can

; ---------- Configurable vars ----------
; searchKey ; self explan
; searchHoldTime ; in ms ; how long it will hold down the search key
; searchDelay ; in seconds ; the delay between searches
; useWebhook ; send info to the webhook
; webhookType ; 2 types "Repeat" , "Const" const will send after every steal repeat will send every repeatTime
; repeatTime ; in ms
; sendSteals ; true sends totalSteals
; sendAlltimeSteals ; if true after runnning the ahk it will promt u to enter in ur current steals
; sendTimeElapsed ; sends the time elapsed since startuo
; url ; the url for the webhook

searchKey := "e"
searchHoldTime := 1000
searchDelay := 30

useWebhook := false
webhookType := "Const"
repeatTime := 5000
sendSteals := true
sendAlltimeSteals := true
sendTimeElapsed := true
embedColor := 0x8B4513
url := ""

totalSteals := 0
alltimeSteals := 0
startTime := 0
stealStartTime := 0
startedSent := false
stealingActive := false

SetTimer, MainLoop, Off
SetTimer, WebhookRepeatTimer, Off

MainLoop:
{
    if (!stealingActive)
        return

    Send, {%searchKey% down}
    Sleep, %searchHoldTime%
    Send, {%searchKey% up}
    
    totalSteals += 1
    
    if (useWebhook && webhookType = "Const")
    {
        SendWebhookRegular()
    }

    Sleep, % (searchDelay * 1000)
    return
}

WebhookRepeatTimer:
{
    if (useWebhook && webhookType = "Repeat")
        SendWebhookRegular()
    return
}

SendWebhookRegular()
{
    global url, sendSteals, sendAlltimeSteals, sendTimeElapsed, totalSteals, alltimeSteals, startTime, embedColor
    if (url = "")
        return

    json := "{""embeds"":[{""title"":""Steal Report"",""color"":" . embedColor . ",""fields"":["
    
    if (sendSteals)
        json .= "{""name"":""Session steals"",""value"":""" . totalSteals . """},"
    
    if (sendAlltimeSteals)
    {
        val := (alltimeSteals + totalSteals = 0) ? "None" : (alltimeSteals + totalSteals)
        json .= "{""name"":""All-time steals"",""value"":""" . val . """},"
    }

    if (sendTimeElapsed && startTime)
    {
        elapsedMs := A_TickCount - startTime
        hours := Floor(elapsedMs / 3600000)
        mins := Floor((elapsedMs - hours*3600000) / 60000)
        secs := Floor((elapsedMs - hours*3600000 - mins*60000) / 1000)
        timestr := Format("{:02}:{:02}:{:02}", hours, mins, secs)
        json .= "{""name"":""Time elapsed"",""value"":""" . timestr . """},"
    }

    json := RTrim(json, ",") . "]}]}"
    SendWebhook(url, json)
}

SendWebhookStart()
{
    global url, alltimeSteals, embedColor
    if (url = "")
        return

    FormatTime, curTime, , h:mm tt
    curTimeStr := curTime " EST"
    
    ; If input was 0, display "None"
    displaySteals := (alltimeSteals = 0) ? "None" : alltimeSteals

    json := "{""embeds"":[{""title"":""FEEFING STARTED"",""color"":" . embedColor . ",""fields"":["
    json .= "{""name"":""CURRENT STEALS"",""value"":""" . displaySteals . """},"
    json .= "{""name"":""Current time"",""value"":""" . curTimeStr . """}"
    json .= "]}]}"

    SendWebhook(url, json)
}

SendWebhookEnd()
{
    global url, alltimeSteals, totalSteals, startTime, embedColor
    if (url = "")
        return

    if (startTime)
        elapsedMs := A_TickCount - startTime
    else
        elapsedMs := 0

    hours := Floor(elapsedMs / 3600000)
    mins := Floor((elapsedMs - hours*3600000) / 60000)
    secs := Floor((elapsedMs - hours*3600000 - mins*60000) / 1000)
    timestr := Format("{:02}:{:02}:{:02}", hours, mins, secs)

    json := "{""embeds"":[{""title"":""STEALING ENDED"",""color"":0,""fields"":["
    json .= "{""name"":""ALLTIME STEALS BEFORE"",""value"":""" . (alltimeSteals = 0 ? "None" : alltimeSteals) . """},"
    json .= "{""name"":""CURRENT ALLTIME STEALS"",""value"":""" . (alltimeSteals + totalSteals = 0 ? "None" : alltimeSteals + totalSteals) . """},"
    json .= "{""name"":""STEALS SINCE START"",""value"":""" . totalSteals . """},"
    json .= "{""name"":""TOTAL STEALING TIME"",""value"":""" . timestr . """},"
    json .= "{""name"":""THANKS"",""value"":""THANKS FOR USING AUTO FEEFER""}"
    json .= "]}]}"

    SendWebhook(url, json)
}

; widley used system not moine
SendWebhook(url, json) {
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", url, false)
    http.SetRequestHeader("Content-Type", "application/json")
    try {
        http.Send(json)
    } catch e {
        ; failed
    }
}

^1::
{
    if (stealingActive)
    {
        TrayTip, Auto Feefer, Already running, 3, 1
        return
    }
    
    InputBox, userAll, All-time steals, Enter your current all-time steals (0 if none), , 300, 150
    if (ErrorLevel)
        return
        
    alltimeSteals := (userAll = "" || userAll = "0") ? 0 : userAll + 0
    totalSteals := 0
    startTime := A_TickCount
    stealingActive := true
    
    ; Start the loop
    SetTimer, MainLoop, 10
    
    if (useWebhook)
    {
        SendWebhookStart()
        if (webhookType = "Repeat")
            SetTimer, WebhookRepeatTimer, % repeatTime
    }
    
    TrayTip, Auto Stealer, Stealing started, 3, 1
    return
}

^2::
{
    if (!stealingActive)
    {
        TrayTip, Auto Stealer, Not currently running, 3, 1
        return
    }
    
    stealingActive := false
    SetTimer, MainLoop, Off
    SetTimer, WebhookRepeatTimer, Off
    
    Send, {%searchKey% up}
    
    if (useWebhook)
        SendWebhookEnd()
        
    TrayTip, Auto Stealer, Stealing stopped, 3, 1
    return
}

^!r::
{
    if (useWebhook && stealingActive)
        SendWebhookEnd()
    ExitApp
    return
}
