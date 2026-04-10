@echo off
REM Wrapper for opencode that resets terminal state after exit (including SIGKILL/OOM).
REM Place this as 'opencode.cmd' next to 'opencode-core.exe' in the install directory.
REM Works in PowerShell and cmd.exe on Windows.
setlocal
"%~dp0opencode-core.exe" %*
set EXIT_CODE=%ERRORLEVEL%

REM Reset terminal state after TUI session (covers SIGKILL/OOM of child process)
REM Skip reset for non-TUI commands
echo %* | findstr /i /r "[\-][\-]version [\-][\-]help \-h \-v ^version$ ^help$" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    for /f %%a in ('echo prompt $E ^| cmd') do (
        <nul set /p "=%%a[?1000l%%a[?1002l%%a[?1003l%%a[?1006l%%a[?1049l%%a[?25h%%a[>4;0m%%a[?2004l"
    )
)

exit /b %EXIT_CODE%
