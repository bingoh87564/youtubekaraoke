Option Explicit

Dim WShell, fso, scriptDir
Set WShell = CreateObject("WScript.Shell")
Set fso    = CreateObject("Scripting.FileSystemObject")
scriptDir  = fso.GetParentFolderName(WScript.ScriptFullName)

' ── Verify setup has been run ─────────────────────────────────────────────
Dim pythonExe
pythonExe = scriptDir & "\venv\Scripts\python.exe"

If Not fso.FileExists(pythonExe) Then
    MsgBox "Karaoke Maker needs to be set up first." & vbCrLf & vbCrLf & _
           "Please double-click  setup.bat  in the Karaoke Maker folder, " & _
           "wait for it to finish, then try this again.", _
           vbInformation, "Karaoke Maker"
    WScript.Quit 1
End If

' ── Start server if not already running ───────────────────────────────────
If Not IsServerUp() Then
    ' Run python.exe via hidden cmd window; errors go to karaoke.log
    Dim logFile
    logFile = scriptDir & "\karaoke.log"
    WShell.Run "cmd /c """ & pythonExe & """ """ & scriptDir & "\app.py"" >> """ & logFile & """ 2>&1", _
               0, False   ' 0 = hidden window, False = don't wait
End If

' ── Open the loading page immediately so the user sees something ──────────
Dim splash
splash = "file:///" & Replace(scriptDir & "\loading.html", "\", "/")
WShell.Run splash

' ── Helper: ping the health endpoint ─────────────────────────────────────
Function IsServerUp()
    Dim h
    Set h = CreateObject("MSXML2.ServerXMLHTTP")
    On Error Resume Next
        h.Open "GET", "http://localhost:5000/health", False
        h.setTimeouts 800, 800, 800, 800
        h.Send
        IsServerUp = (Err.Number = 0 And h.Status = 200)
        Err.Clear
    On Error GoTo 0
End Function
