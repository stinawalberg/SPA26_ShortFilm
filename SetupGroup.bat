@echo off
setlocal EnableExtensions
rem ---------------------------------------------------------------------------
rem  SetupGroup.bat - show only YOUR group's folder in this project.
rem
rem  Double-click and enter your group number, or run:  SetupGroup.bat 3
rem  Enter FULL (or run "SetupGroup.bat full") to show all groups again.
rem
rem  Other groups' folders are removed from your disk only. Their work is
rem  still in git, and "git pull" keeps working as normal.
rem ---------------------------------------------------------------------------

cd /d "%~dp0"
set "STUDENT=Content/02_StudentWork"

where git >nul 2>&1 || (
    echo Git was not found. Install Git for Windows and try again.
    goto :fail
)
git rev-parse --is-inside-work-tree >nul 2>&1 || (
    echo This folder is not a git clone of the project.
    goto :fail
)

set "GROUP=%~1"
if not defined GROUP set /p "GROUP=Enter your group number, or FULL to show all groups: "
if not defined GROUP goto :fail

if /i "%GROUP%"=="FULL" (
    git sparse-checkout disable || goto :fail
    echo.
    echo All group folders are visible again.
    goto :done
)

echo %GROUP%| findstr /r "^[0-9][0-9]*$" >nul || (
    echo "%GROUP%" is not a group number.
    goto :fail
)

set "MINE=%STUDENT%/Group%GROUP%"
for /f %%i in ('git ls-tree -d --name-only HEAD "%MINE%"') do set "FOUND=1"
if not defined FOUND (
    echo There is no folder for Group %GROUP%. Available groups:
    for /f "delims=" %%d in ('git ls-tree -d --name-only HEAD "%STUDENT%/" ^| findstr /r /c:"/Group[0-9]"') do echo    %%~nxd
    goto :fail
)

rem Redirect before "echo" so no trailing spaces end up in the patterns.
set "PATTERNS=%TEMP%\sparse-group-%RANDOM%.txt"
 >"%PATTERNS%" echo /*
>>"%PATTERNS%" echo !/%STUDENT%/Group*/
>>"%PATTERNS%" echo /%MINE%/
>>"%PATTERNS%" echo !/Content/__ExternalActors__/02_StudentWork/Group*/
>>"%PATTERNS%" echo /Content/__ExternalActors__/02_StudentWork/Group%GROUP%/
>>"%PATTERNS%" echo !/Content/__ExternalObjects__/02_StudentWork/Group*/
>>"%PATTERNS%" echo /Content/__ExternalObjects__/02_StudentWork/Group%GROUP%/
git sparse-checkout set --no-cone --stdin <"%PATTERNS%" 2>nul
set "RESULT=%ERRORLEVEL%"
del "%PATTERNS%" >nul 2>&1
if not "%RESULT%"=="0" goto :fail

echo.
echo You're set up as Group %GROUP%.
echo Only commit work inside %MINE%
echo (Run this again with FULL to see every group's folder.)
goto :done

:fail
echo.
echo Setup did not complete.
if "%~1"=="" pause
exit /b 1

:done
if "%~1"=="" pause
exit /b 0
