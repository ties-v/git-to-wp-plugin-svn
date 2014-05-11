::Git to WordPress Plugin SVN deployment script, written by TV productions (c) 2014.
:: : : : : : :
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
:: : : : : : :
@echo off
setlocal

title Git to WordPress Plugin SVN

::::::::::::
:: The configuration vars
::::::::::::
::The slug of your plugin
set pluginslug=wp-test-plugin
::The file with the plugin header
set mainfile=plugin.php
::Your WordPress SVN username
set svnuser=TV productions

echo.
echo ************************************************************
echo.
call :c 0f "Git to WordPress Plugin SVN deployment script" /n
echo.
echo.
call :c 0f "Written by: TV productions (http://tv-productions.org) GPLv3" /n
call :c 0f "Based on the shell scripts of: " /n
call :c 0f "Dean Clatworthy's deploy script " /n
call :c 0f "    (https://github.com/deanc/wordpress-plugin-git-svn)" /n
call :c 0f "Brent Shepherds' modification of it. " /n
call :c 0f "    (https://github.com/thenbrent/multisite-user-management/" /n
call :c 0f "       blob/master/deploy.sh)" /n
echo.
echo ************************************************************
echo.

set svnurl=http://plugins.svn.wordpress.org/%pluginslug%
set svnpath=%~dp0tmp

:: The filename of this file.
for %%F in (%0) do set thisfile=%%~nxF

:: NOTE

call :c 09 "[Note]" & call :c 0f " This script commits ONLY files that are already under git version control!" /n
echo.

::::::::::::
:: SVN check
::::::::::::
svn status 1>nul 2>nul && goto svn_ok

:: SVN not found

call :c 0c "[Error]" & call :c 0f " SVN not found. Is SVN installed and added to the PATH variable?" /n
call :c 0f "Exit..."
pause >nul
exit /B 1

:svn_ok
call :c 0a "[OK]" & call :c 0f " SVN is available." /n

::::::::::::
:: Git check
::::::::::::

:: Check if this is a git repo
git status 1>nul 2>nul && goto git_ok

:: This is not a git repo
call :c 0c "[Error]" & call :c 0f " This script should run from the plugins root directory." /n
call :c 0f "This directory should also be the git repository." /n
call :c 0f "Please fix it." /n
call :c 0f "Exit..." 
pause >nul
exit /B 2

:git_ok
call :c 0a "[OK]" & call :c 0f " This directory is a git repository." /n

::::::::::::
:: Config check
::::::::::::

if exist %mainfile% goto config_ok
::mainfile doesn't exists.
call :c 0c "[Error]" & call :c 0f " This script should run from the plugins root directory." /n
call :c 0f "Check if that is the case and check the following data:" /n
call :c 0f "Plugin:                  %pluginslug%" /n
call :c 0f "Plugin file:             %mainfile%" /n
call :c 0f "WordPress SVN Username:  %svnuser%" /n
call :c 0f "WordPress SVN URL:       %svnurl%" /n
call :c 0f "Is the data incorrect? Edit this script." /n
call :c 0f "Exit..."
pause >nul
exit /B 3

:config_ok
call :c 0a "[OK]" & call :c 0f " Configuration ok" /n

::::::::::::
:: Version check
::::::::::::

:: Plugin file header version
for /F "delims=" %%i in ('findstr  /R /C:"Version:[ ][0-9].*$" %mainfile%') do (
    for /F "tokens=2 delims=ersion:" %%a in ("%%i") do set version1=%%a
)

:: Readme.txt version
for /F "tokens=1 delims=" %%i in ('findstr  /R /C:"[sS]table[ ][tT]ag:" readme.txt') do (
    for /F "tokens=3 delims= " %%a in ("%%i") do @set version2=%%a
)

:: Strip spaces
set version1=%version1: =%
set version2=%version2: =%

if %version1%==%version2% goto version_ok
::versions do not match
call :c 0c "[Error]" & call :c 0f " The versions of the plugin file header and readme.txt stable tag do not match." /n
call :c 0f "Please match them before you continue. " /n
call :c 0f "Exit..."
pause >nul 
exit /B 4

:version_ok
call :c 0a "[OK]" & call :c 0f " Versions in the plugin files match." /n

::::::::::::
:: Tag Check
::::::::::::

git show-ref --quiet --tags --verify -- "refs/tags/%version1%" || goto :tag_ok
:: Tag already exists
call :c 0c "[Error]" & call :c 0f " Version "%version1%" already exists as git tag." /n
call :c 0f "Please change the version number of the plugin before you continue." /n
call :c 0f "Exit..."
pause >nul
exit /B 5

:tag_ok
call :c 0a "[OK]" & call :c 0f " Tag with the version "%version1%" doesn't exists. Let's proceed..." /n

::::::::::::
:: Git commit, tag and push
::::::::::::
set /p commitmsg=Enter a commit message for this new version: 
git commit -am "%commitmsg%"

call :c 0f "Tagging the new version in git" /n
git tag -a "%version1%" -m "Tag version %version1%"

call :c 0f "Pushing latest commit to origin, with tags" /n
git push origin master --tags

echo.

::::::::::::
:: SVN create commit and tag
::::::::::::

call :c 0f "Creating temporary local copy of SVN repo" /n
if not exist %svnpath% mkdir "%svnpath%"
cd %svnpath%
svn co %svnurl% "%svnpath%"

call :c 0f "Exporting the HEAD of master from git to the trunk of SVN" /n
git checkout-index -a -f --prefix=%svnpath%/trunk/

call :c 0f "Ignoring github specific files and deployment script" /n
cd %svnpath%
:: Create tmp file for ignore settings
(
  echo %thisfile%
  echo .git
  echo .gitignore
  echo .gitattributes
  echo README.md
) > svn-ignore.tmp
:: Add the ignore property
svn propset svn:ignore -qRF svn-ignore.tmp .
:: Remove the tmp file.
erase svn-ignore.tmp


call :c 0f "Changing directory to SVN and committing to trunk" /n
cd %svnpath%/trunk/
:: add all the files that are not ignored
svn add --force --quiet .
svn commit --username %svnuser% -m "%commitmsg%"

call :c 0f "Creating new SVN tag and committing it" /n
cd %svnpath%
svn copy trunk/ tags/%version1%
cd %svnpath%/tags/%version1%
svn commit --username %svnuser% -m "Tag version %version1%"

cd %~dp0

call :c 0f "Removing temporary local copy of SVN repo" /n
rmdir /S /Q "%svnpath%" 2>nul && goto end
call :c 0c "[Error]" & call :c 0f " The script wasn't able to remove the temporary SVN repo. Please remove it manually." /n

:end

echo.
echo ************************************************************
echo.
call :c 0f "      End of Git to WordPress Plugin SVN deploy script" /n
echo.
echo ************************************************************

exit /B

:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::
:: Color functions
:: By dbenham
:: See http://stackoverflow.com/a/10407642
:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::

:c
setlocal enableDelayedExpansion
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:colorPrint Color  Str  [/n]
setlocal
set "s=%~2"
call :colorPrintVar %1 s %3
exit /b

:colorPrintVar  Color  StrVar  [/n]
if not defined DEL call :initColorPrint
setlocal enableDelayedExpansion
pushd .
':
cd \
set "s=!%~2!"
:: The single blank line within the following IN() clause is critical - DO NOT REMOVE
for %%n in (^"^

^") do (
  set "s=!s:\=%%~n\%%~n!"
  set "s=!s:/=%%~n/%%~n!"
  set "s=!s::=%%~n:%%~n!"
)
for /f delims^=^ eol^= %%s in ("!s!") do (
  if "!" equ "" setlocal disableDelayedExpansion
  if %%s==\ (
    findstr /a:%~1 "." "\'" nul
    <nul set /p "=%DEL%%DEL%%DEL%"
  ) else if %%s==/ (
    findstr /a:%~1 "." "/.\'" nul
    <nul set /p "=%DEL%%DEL%%DEL%%DEL%%DEL%"
  ) else (
    >colorPrint.txt (echo %%s\..\')
    findstr /a:%~1 /f:colorPrint.txt "."
    <nul set /p "=%DEL%%DEL%%DEL%%DEL%%DEL%%DEL%%DEL%"
  )
)
if /i "%~3"=="/n" echo(
popd
exit /b


:initColorPrint
for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "DEL=%%A %%A"
<nul >"%temp%\'" set /p "=."
subst ': "%temp%" >nul
exit /b


:cleanupColorPrint
2>nul del "%temp%\'"
2>nul del "%temp%\colorPrint.txt"
>nul subst ': /d
exit /b