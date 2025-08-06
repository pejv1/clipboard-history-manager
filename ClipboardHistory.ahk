#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
; Clipboard History Manager
; =============================================================================
; Features:
; - Automatic clipboard monitoring
; - GUI menu with numbered items
; - Hotkey support for quick pasting
; - Configurable settings
; =============================================================================

; Global variables
global clipboardHistory := []
global isMenuVisible := false
global clipGui := Gui()
global lastClip := ""
global watchingEnabled := true

; Configuration settings
global settings := {
    maxItems: 10,
    checkInterval: 300,
    autoHideDelay: 8000,
    maxDisplayLength: 150,
    showTooltips: false,
    soundOnPaste: false
}

; Ensure maxItems doesn't exceed 10 (limited by available number keys)
if (settings.maxItems > 10) {
    settings.maxItems := 10
}

; Initialize and start monitoring
InitializeClipboardHistory()
SetTimer(WatchClipboard, settings.checkInterval)

; =============================================================================
; Core Functions
; =============================================================================

InitializeClipboardHistory() {
    global clipboardHistory, lastClip
    ClearClipboardHistory()
    lastClip := A_Clipboard
}

WatchClipboard() {
    global watchingEnabled, lastClip, clipboardHistory
    
    if (!watchingEnabled) {
        return
    }
    
    try {
        currentClip := A_Clipboard
        if (currentClip != lastClip) {
            if (currentClip != "" && Trim(currentClip) != "") {
                lastClip := currentClip
                AddToClipboardHistory(currentClip)
                ShowTooltip("Added to clipboard history: " . SubStr(currentClip, 1, 30) . "...")
            }
        }
    } catch Error as e {
        ShowTooltip("Clipboard access error: " . e.Message)
    }
}

AddToClipboardHistory(text) {
    ; Remove duplicates
    for index, item in clipboardHistory {
        if (item = text) {
            clipboardHistory.RemoveAt(index)
            break
        }
    }
    
    clipboardHistory.InsertAt(1, text)
    if (clipboardHistory.Length > settings.maxItems)
        clipboardHistory.RemoveAt(settings.maxItems + 1)
}

; =============================================================================
; Hotkeys
; =============================================================================

#v::ToggleClipboardMenu()                    ; Win+V: Open/close clipboard history menu
^#c::ClearClipboardHistory()                 ; Ctrl+Win+C: Clear clipboard history
^#v::ToggleClipboardWatching()               ; Ctrl+Win+V: Pause/resume clipboard watching
^#t::TestClipboardHistory()                  ; Ctrl+Win+T: Add test item to history
^#d::DebugClipboardHistory()                 ; Ctrl+Win+D: Show debug information
^#z::ToggleTooltips()                        ; Ctrl+Win+Z: Toggle tooltips on/off
^#u::ForceUnregisterHotkeys()                ; Ctrl+Win+U: Force unregister all hotkeys

; =============================================================================
; Menu Functions
; =============================================================================

ToggleClipboardMenu() {
    global isMenuVisible, clipboardHistory, clipGui

    if (IsClipboardHistoryEmpty()) {
        ShowTooltip("Clipboard history is empty.")
        return
    }

    if (isMenuVisible) {
        HideClipboardMenu()
        return
    }

    ShowClipboardMenu()
}

ShowClipboardMenu() {
    global isMenuVisible, clipboardHistory, clipGui, settings

    clipGui.Destroy()
    clipGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    clipGui.SetFont("s9", "Segoe UI")
    clipGui.BackColor := "FFFFFF"
    clipGui.Opt("+Resize")

    ; Add title
    clipGui.AddText("w450 cBlue", "📋 Clipboard History")
    
    ; Create separator line
    separator := ""
    Loop 50 {
        separator .= "─"
    }
    clipGui.AddText("w450", separator)

    ; Add clipboard items
    Loop clipboardHistory.Length {
        item := clipboardHistory[A_Index]
        displayText := FormatClipboardText(item, settings.maxDisplayLength)
        clipGui.AddText("w450 +Wrap", Format("{}: {}", A_Index, displayText))
    }

    ; Add instructions
    clipGui.AddText("w450", separator)
    if (settings.maxItems >= 10) {
        instructionText := "Press 1–9, 0 for item 10 to paste"
    } else {
        instructionText := "Press 1–" . settings.maxItems . " to paste"
    }
    instructionText .= " • Ctrl+Win+C to clear • Ctrl+Win+V to pause • Ctrl+Win+Z to toggle tooltips • Esc to close"
    clipGui.AddText("w450 cGray", instructionText)
    
    ; Position menu
    posX := 600
    posY := 200
    
    clipGui.Show("NoActivate AutoSize x" . posX . " y" . posY)
    isMenuVisible := true

    RegisterPasteHotkeys()
    SetTimer(() => HideClipboardMenu(), -settings.autoHideDelay)
}

FormatClipboardText(text, maxLength) {
    ; Remove line breaks and extra spaces
    text := StrReplace(text, "`r`n", " ")
    text := StrReplace(text, "`n", " ")
    text := RegExReplace(text, "\s+", " ")
    
    ; Truncate if too long
    if (StrLen(text) > maxLength) {
        text := SubStr(text, 1, maxLength) . "..."
    }
    
    return text
}

HideClipboardMenu() {
    global isMenuVisible, clipGui
    if (isMenuVisible) {
        clipGui.Hide()
        isMenuVisible := false
        UnregisterPasteHotkeys()
    }
}

; =============================================================================
; Utility Functions
; =============================================================================

ClearClipboardHistory() {
    global clipboardHistory
    clipboardHistory := []
    ShowTooltip("Clipboard history cleared.")
}

IsClipboardHistoryEmpty() {
    global clipboardHistory
    if (clipboardHistory.Length = 0)
        return true
    for item in clipboardHistory {
        if (Trim(item) != "")
            return false
    }
    return true
}

ShowTooltip(message) {
    if (settings.showTooltips) {
        ToolTip message
        SetTimer(() => ToolTip(), -2000)
    }
}

; =============================================================================
; Hotkey Management
; =============================================================================

RegisterPasteHotkeys() {
    ; Register number keys 1-9 and 0
    Hotkey("1", (*) => TryPasteItem(1), "On")
    Hotkey("2", (*) => TryPasteItem(2), "On")
    Hotkey("3", (*) => TryPasteItem(3), "On")
    Hotkey("4", (*) => TryPasteItem(4), "On")
    Hotkey("5", (*) => TryPasteItem(5), "On")
    Hotkey("6", (*) => TryPasteItem(6), "On")
    Hotkey("7", (*) => TryPasteItem(7), "On")
    Hotkey("8", (*) => TryPasteItem(8), "On")
    Hotkey("9", (*) => TryPasteItem(9), "On")
    Hotkey("0", (*) => TryPasteItem(10), "On")
    
    ; Numpad keys
    Hotkey("Numpad1", (*) => TryPasteItem(1), "On")
    Hotkey("Numpad2", (*) => TryPasteItem(2), "On")
    Hotkey("Numpad3", (*) => TryPasteItem(3), "On")
    Hotkey("Numpad4", (*) => TryPasteItem(4), "On")
    Hotkey("Numpad5", (*) => TryPasteItem(5), "On")
    Hotkey("Numpad6", (*) => TryPasteItem(6), "On")
    Hotkey("Numpad7", (*) => TryPasteItem(7), "On")
    Hotkey("Numpad8", (*) => TryPasteItem(8), "On")
    Hotkey("Numpad9", (*) => TryPasteItem(9), "On")
    Hotkey("Numpad0", (*) => TryPasteItem(10), "On")
    
    ; Esc key to hide menu
    Hotkey("Esc", (*) => HideClipboardMenu(), "On")
}

UnregisterPasteHotkeys() {
    ; Unregister all number keys
    Hotkey("1", "Off")
    Hotkey("2", "Off")
    Hotkey("3", "Off")
    Hotkey("4", "Off")
    Hotkey("5", "Off")
    Hotkey("6", "Off")
    Hotkey("7", "Off")
    Hotkey("8", "Off")
    Hotkey("9", "Off")
    Hotkey("0", "Off")
    
    Hotkey("Numpad1", "Off")
    Hotkey("Numpad2", "Off")
    Hotkey("Numpad3", "Off")
    Hotkey("Numpad4", "Off")
    Hotkey("Numpad5", "Off")
    Hotkey("Numpad6", "Off")
    Hotkey("Numpad7", "Off")
    Hotkey("Numpad8", "Off")
    Hotkey("Numpad9", "Off")
    Hotkey("Numpad0", "Off")
    
    ; Esc key
    Hotkey("Esc", "Off")
}

; =============================================================================
; Paste Functions
; =============================================================================

TryPasteItem(index) {
    global clipboardHistory, isMenuVisible, settings, watchingEnabled
    
    ; Only proceed if menu is visible and we have items
    if (!isMenuVisible) {
        return
    }
    
    if (clipboardHistory.Length = 0) {
        return
    }
    
    ; Validate index
    if (index < 1 || index > clipboardHistory.Length) {
        return
    }
    
    target := clipboardHistory[index]
    HideClipboardMenu()
    
    ; Temporarily disable clipboard watching to prevent tooltip
    originalWatching := watchingEnabled
    watchingEnabled := false
    
    ; Play sound if enabled
    if (settings.soundOnPaste) {
        SoundPlay("*16")
    }
    
    ; Use a more reliable paste method
    try {
        ; Store current clipboard
        savedClip := A_Clipboard
        A_Clipboard := target
        
        ; Wait a moment for clipboard to update
        Sleep(50)
        
        ; Send paste command
        Send("^v")
        
        ; Restore original clipboard after a delay
        SetTimer(() => A_Clipboard := savedClip, -100)
        
    } catch Error as e {
        ; Fallback to direct input if clipboard method fails
        SendInput target
    }
    
    ; Re-enable clipboard watching after a short delay
    SetTimer(() => watchingEnabled := originalWatching, -200)
}

; =============================================================================
; System Functions
; =============================================================================

; Safety: Unregister all hotkeys when script exits
OnExit(ExitFunc)
ExitFunc(ExitReason, ExitCode) {
    UnregisterPasteHotkeys()
}

; Handle window focus loss to hide menu
OnMessage(0x0006, WM_ACTIVATE)
WM_ACTIVATE(wParam, lParam, msg, hwnd) {
    if (wParam = 0 && isMenuVisible) {
        HideClipboardMenu()
    }
}

; =============================================================================
; Debug and Test Functions
; =============================================================================

TestClipboardHistory() {
    global clipboardHistory, settings
    testText := "Test clipboard item " . A_TickCount
    AddToClipboardHistory(testText)
    ShowTooltip("Test item added: " . testText)
    ShowTooltip("History length: " . clipboardHistory.Length)
}

ForceUnregisterHotkeys() {
    UnregisterPasteHotkeys()
    ShowTooltip("All hotkeys unregistered")
}

DebugClipboardHistory() {
    global clipboardHistory, isMenuVisible, watchingEnabled
    debugInfo := "History length: " . clipboardHistory.Length . "`n"
    debugInfo .= "Menu visible: " . isMenuVisible . "`n"
    debugInfo .= "Watching enabled: " . watchingEnabled . "`n"
    
    if (clipboardHistory.Length > 0) {
        debugInfo .= "First item: " . SubStr(clipboardHistory[1], 1, 30) . "..."
    }
    
    ShowTooltip(debugInfo)
}

ToggleClipboardWatching() {
    global watchingEnabled
    watchingEnabled := !watchingEnabled
    status := watchingEnabled ? "resumed" : "paused"
    ShowTooltip("Clipboard watching " . status)
}

ToggleTooltips() {
    global settings
    settings.showTooltips := !settings.showTooltips
    status := settings.showTooltips ? "enabled" : "disabled"
    ShowTooltip("Tooltips " . status)
}
