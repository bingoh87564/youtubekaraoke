Option Explicit

Dim WShell, fso, scriptDir
Set WShell = CreateObject("WScript.Shell")
Set fso    = CreateObject("Scripting.FileSystemObject")
scriptDir  = fso.GetParentFolderName(WScript.ScriptFullName)

' ── Find the right Python (embedded first, then venv) ─────────────────────
Dim pythonExe
If fso.FileExists(scriptDir & "\python\python.exe") Then
    pythonExe = scriptDir & "\python\python.exe"          ' portable / no-install
ElseIf fso.FileExists(scriptDir & "\venv\Scripts\python.exe") Then
    pythonExe = scriptDir & "\venv\Scripts\python.exe"    ' old venv setup
Else
    MsgBox "Karaoke Maker needs to be set up first." & vbCrLf & vbCrLf & _
           "Please double-click  setup.bat  in the Karaoke Maker folder, " & _
           "wait for it to finish, then try again.", _
           vbInformation, "Karaoke Maker"
    WScript.Quit 1
End If

' ── Start server if not already running ────────────────────────────────────
If Not IsServerUp() Then
    Dim starter
    starter = scriptDir & "\server_start.bat"
    WShell.Run "cmd /c """ & starter & """", 0, False

    ' Show friendly popup while the server starts (auto-closes in 30 s)
    WShell.Popup "Karaoke Maker is starting up." & vbCrLf & vbCrLf & _
                 "Your browser will open automatically in a few seconds." & vbCrLf & _
                 "(This message closes on its own)", _
                 30, "Karaoke Maker", 64

    ' Continue polling after popup closes
    Dim i
    For i = 1 To 60
        If IsServerUp() Then Exit For
        WScript.Sleep 1000
    Next
End If

' ── Open the app ───────────────────────────────────────────────────────────
If IsServerUp() Then
    WShell.Run "http://127.0.0.1:5000"
Else
    MsgBox "Karaoke Maker could not start." & vbCrLf & vbCrLf & _
           "Please try again. If it keeps failing, run  setup.bat  once more.", _
           vbExclamation, "Karaoke Maker"
End If

Function IsServerUp()
    Dim h
    Set h = CreateObject("MSXML2.ServerXMLHTTP")
    On Error Resume Next
        h.Open "GET", "http://127.0.0.1:5000/health", False
        h.setTimeouts 1000, 1000, 1000, 1000
        h.Send
        IsServerUp = (Err.Number = 0 And h.Status = 200)
        Err.Clear
    On Error GoTo 0
End Function
