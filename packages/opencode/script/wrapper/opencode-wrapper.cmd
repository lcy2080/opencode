@echo off
REM Wrapper for opencode that resets terminal state after exit (including SIGKILL/OOM).
REM Place this as 'opencode.cmd' next to 'opencode-core.exe' in the install directory.
REM Works in PowerShell and cmd.exe on Windows.
"%~dp0opencode-core.exe" %*
set OC_EXIT=%ERRORLEVEL%
if %OC_EXIT% neq 0 (
    powershell -NoProfile -Command "$e=[char]27; Write-Host -NoNewline \"$e[?1000l$e[?1002l$e[?1003l$e[?1006l$e[?1049l$e[?25h$e[>4;0m$e[?2004l\"" 2>nul
)
exit /b %OC_EXIT%
