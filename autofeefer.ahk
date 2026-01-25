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

; how to use
; go up to a mailbox and hold ctrl + 1 and boom

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

; i love how i made the webhook stuff and never tried it
MainLoop:
{
    Sleep, % (searchDelay * 1000)
    Send, {%searchKey% down}
    Sleep, %searchHoldTime%
    Send, {%searchKey% up}
    totalSteals += 1
    if (!startedSent)
    {
        stealStartTime := A_TickCount
        startTime := stealStartTime
        startedSent := true
        if (useWebhook)
            SendWebhookStart()
    }
    if (useWebhook && webhookType = "Const")
        SendWebhookRegular()
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
    fields := []
    if (sendSteals)
        fields.Push({ "name": "Session steals", "value": totalSteals, "inline": false })
    if (sendAlltimeSteals)
        fields.Push({ "name": "All-time steals", "value": alltimeSteals + totalSteals, "inline": false })
    if (sendTimeElapsed && startTime)
    {
        elapsedMs := A_TickCount - startTime
        hours := Floor(elapsedMs / 3600000)
        mins := Floor((elapsedMs - hours*3600000) / 60000)
        secs := Floor((elapsedMs - hours*3600000 - mins*60000) / 1000)
        timestr := Format("{:02}:{:02}:{:02}", hours, mins, secs)
        fields.Push({ "name": "Time elapsed", "value": timestr, "inline": false })
    }
    embed := { "title": "Steal Report", "color": embedColor, "fields": fields }
    payload := { "embeds": [ embed ] }
    json := JsonEncode(payload)
    HttpPostJson(url, json)
}

SendWebhookStart()
{
    global url, alltimeSteals, embedColor
    if (url = "")
        return
    FormatTime, curTime, , h:mm tt
    curTimeStr := curTime " EST"
    fields := []
    fields.Push({ "name": "CURRENT STEALS", "value": alltimeSteals, "inline": false })
    fields.Push({ "name": "Current time", "value": curTimeStr, "inline": false })
    embed := { "title": "STEALING STARTED", "color": embedColor, "fields": fields }
    payload := { "embeds": [ embed ] }
    json := JsonEncode(payload)
    HttpPostJson(url, json)
}

SendWebhookEnd()
{
    global url, alltimeSteals, totalSteals, startTime, embedColor
    if (url = "")
        return
    allBefore := alltimeSteals
    currentAll := alltimeSteals + totalSteals
    newSteals := totalSteals
    if (startTime)
        elapsedMs := A_TickCount - startTime
    else
        elapsedMs := 0
    hours := Floor(elapsedMs / 3600000)
    mins := Floor((elapsedMs - hours*3600000) / 60000)
    secs := Floor((elapsedMs - hours*3600000 - mins*60000) / 1000)
    timestr := Format("{:02}:{:02}:{:02}", hours, mins, secs)
    fields := []
    fields.Push({ "name": "ALLTIME STEALS BEFORE", "value": allBefore, "inline": false })
    fields.Push({ "name": "CURRENT ALLTIME STEALS", "value": currentAll, "inline": false })
    fields.Push({ "name": "STEALS SINCE START", "value": newSteals, "inline": false })
    fields.Push({ "name": "TOTAL STEALING TIME", "value": timestr, "inline": false })
    fields.Push({ "name": "THANKS", "value": "THANKS FOR USING AUTO FEEFER", "inline": false })
    embed := { "title": "STEALING ENDED", "color": embedColor, "fields": fields }
    payload := { "embeds": [ embed ] }
    json := JsonEncode(payload)
    HttpPostJson(url, json)
}

; this is ai
; idk how to send webhooks thru ahk
; this could not work
HttpPostJson(url, json)
{
    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.Open("POST", url, false)
        req.SetRequestHeader("Content-Type", "application/json")
        req.Send(json)
    }
    catch e
    {
        FileAppend, %A_Now% " - Webhook error: " e.Message "`n", %A_ScriptDir%\ahk_webhook_errors.log
    }
}

; json code not mine i borrowed it from another github 
JsonEncode(obj)
{
    if (IsObject(obj))
    {
        isArray := true
        idx := 1
        for k, v in obj
        {
            if (k != idx)
            {
                isArray := false
                break
            }
            idx++
        }
        if (isArray)
        {
            out := "["
            for index, val in obj
                out .= JsonEncode(val) . ","
            StringTrimRight, out, out, 1
            out .= "]"
            return out
        }
        else
        {
            out := "{"
            for key, val in obj
                out .= """" . EscapeJson(key) . """:" . JsonEncode(val) . ","
            StringTrimRight, out, out, 1
            out .= "}"
            return out
        }
    }
    else if (obj is number)
        return obj
    else
        return """" . EscapeJson(obj) . """"
}

EscapeJson(str)
{
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, """", "\""")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`t", "\t")
    return str
}

^1::
{
    if (stealingActive)
    {
        TrayTip, Auto Feefer, Already running, 1
        return
    }
    InputBox, userAll, All-time steals, Enter your current all-time steals (0 if none), , 300, 150
    if ErrorLevel
        alltimeSteals := 0
    else
        alltimeSteals := userAll + 0
    totalSteals := 0
    startedSent := false
    startTime := 0
    stealStartTime := 0
    stealingActive := true
    SetTimer, MainLoop, 1000
    if (useWebhook && webhookType = "Repeat")
    {
        SetTimer, WebhookRepeatTimer, % repeatTime
    }
    startedSent := true
    stealStartTime := A_TickCount
    startTime := stealStartTime
    if (useWebhook)
        SendWebhookStart()
    return
}

^2::
{
    if (!stealingActive)
    {
        return
    }
    SetTimer, MainLoop, Off
    SetTimer, WebhookRepeatTimer, Off
    if (useWebhook)
        SendWebhookEnd()
    stealingActive := false
    return
}

^!r::
{
    if (useWebhook)
        SendWebhookEnd()
    ExitApp
    return
}
