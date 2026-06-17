Option Explicit

Dim WShell, fso, scriptDir, http
Set WShell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")
scriptDir  = fso.GetParentFolderName(WScript.ScriptFullName)

' ── Make sure setup has been run ─────────────────────────────────────────
Dim pythonExe
pythonExe = scriptDir & "\venv\Scripts\pythonw.exe"

If Not fso.FileExists(pythonExe) Then
    MsgBox "Karaoke Maker needs to be set up first." & vbCrLf & vbCrLf & _
           "Please double-click  setup.bat  in the same folder, " & _
           "wait for it to finish, then try this again.", _
           vbInformation, "Karaoke Maker"
    WScript.Quit 1
End If

' ── Check whether the server is already running ───────────────────────────
Dim running
running = False
Set http = CreateObject("MSXML2.ServerXMLHTTP")
On Error Resume Next
    http.Open "GET", "http://localhost:5000/health", False
    http.setTimeouts 800, 800, 800, 800
    http.Send
    If Err.Number = 0 And http.Status = 200 Then running = True
    Err.Clear
On Error GoTo 0

' ── Start Flask silently (pythonw = no console window) ───────────────────
If Not running Then
    WShell.Run """" & pythonExe & """ """ & scriptDir & "\app.py""", 0, False
End If

' ── Open the loading page — it polls until the server is ready ────────────
Dim splash
splash = "file:///" & Replace(scriptDir & "\loading.html", "\", "/")

' Try Chrome, then fall back to the system default browser
On Error Resume Next
WShell.Run "chrome.exe --new-window """ & splash & """", 1, False
If Err.Number <> 0 Then
    Err.Clear
    WShell.Run """" & splash & """", 1, False
End If
On Error GoTo 0
