@echo off
echo Installing ArmA 2 DayZ server
REM By Gachl

echo.
echo Please specify the directories to use to install DayZ.
echo Only use absolute paths (C:\...). Please keep all paths on the same drive
echo as the batch file and its dependencies. Don't use spaces in names.
echo.

set /p dayz_path="Install DayZ into: [C:\games\dayz] "
if /I "%dayz_path%"=="" set dayz_path=C:\games\dayz
echo Will install DayZ into %dayz_path%
set /p temp_path="Temp folder: [C:\temp] "
if /I "%temp_path%"=="" set temp_path=C:\temp
echo Will use %temp_path% to download dependencies

REM Remember current directory
set pwd=%~dp0

if not exist %temp_path% (
	echo Creating temporary folder at %temp_path%
	setlocal enableextensions
	md %temp_path%
	endlocal
)

mkdir %temp_path%\steamcmd
cd %temp_path%\steamcmd\
echo Downloading SteamCMD
echo.
%pwd%wget.exe --no-check-certificate https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
%pwd%\7za.exe x steamcmd.zip
del /F /Q steamcmd.zip
REM steamcmd url taken from https://developer.valvesoftware.com/wiki/SteamCMD#Windows

echo.
echo Updating SteamCMD
steamcmd.exe +exit
echo.

cd %pwd%
echo Downloading ArmA 2 and OA
echo To download ArmA 2 you will require a Steam account with a valid license of the
echo game and the Operations Arrowhead addon.
echo SteamCMD will ask you for your password and, if applicable, your Steam Guard code.
echo.
set /p steam_username="Steam Username: "
%temp_path%\steamcmd\steamcmd.exe +login "%steam_username%" +force_install_dir "%dayz_path%" +app_update "33930 validate -beta beta" +exit
%temp_path%\steamcmd\steamcmd.exe +login "%steam_username%" +force_install_dir "%temp_path%\arma2" +app_update 33910 validate +exit
%temp_path%\steamcmd\steamcmd.exe +login "%steam_username%" +force_install_dir "%temp_path%\arma2" +app_update 33910 validate +exit
REM for whatever retarded reason, the first download fails with 0x106 and needs to be started again to properly work.
%temp_path%\steamcmd\steamcmd.exe +login "%steam_username%" +force_install_dir "%temp_path%\arma2oabeta" +app_update 219540 validate +exit
set steam_username=

echo.
echo Moving ArmA 2 AddOns
move %temp_path%\arma2\AddOns %dayz_path%\AddOns

echo Removing ArmA 2
rmdir /S /Q %temp_path%\arma2

echo Moving DayZ Mod
move %temp_path%\arma2oabeta\Expansion\beta %dayz_path%\Expansion\
rmdir /S /Q %temp_path%\arma2oabeta

cd %temp_path%
echo Downloading DayZ 1.8.6.1 server files
%pwd%wget.exe http://se1.dayz.nu/latest/1.8.6.1/@Server-V1.8.6.1-Full.rar
echo.
echo Unpacking...
%pwd%\unrar.exe x @Server-V1.8.6.1-Full.rar dayz_server\
echo Removing archive...
del /F /Q @Server-V1.8.6.1-Full.rar

echo.
echo Downloading BattlEye filters
%pwd%wget.exe --no-check-certificate https://github.com/DayZMod/Battleye-Filters/archive/Release_1.8.6.1.zip
echo Unpacking
%pwd%\7za.exe x -obattleye_filters Release_1.8.6.1.zip
echo Removing archive
del /F /Q Release_1.8.6.1.zip

echo.
echo Downloading SQL files
%pwd%wget.exe "http://se1.dayz.nu/latest/1.8.6/SQL%%201.8.6.rar"
echo Unpacking
%pwd%\unrar.exe x "SQL 1.8.6.rar" sql\
move "sql\1.8.6\3h updates.sql" sql\1.8.6\3h_updates.sql
echo Removing archive
del /F /Q "SQL 1.8.6.rar"

REM server files urls taken from https://forums.dayzgame.com/index.php?/topic/225450-dayz-mod-1861/

echo.
echo Downloading MySQL server
%pwd%wget.exe --no-check-certificate https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.10-winx64.zip
echo Unpacking
%pwd%\7za.exe x -omysql mysql-5.7.10-winx64.zip
echo Removing archive
del /F /Q mysql-5.7.10-winx64.zip

REM mysql server url taken from https://dev.mysql.com/downloads/mysql/

cd %pwd%

echo.
echo Moving DayZ server files
move %temp_path%\dayz_server\* %dayz_path%\
move %temp_path%\dayz_server\@DayZ %dayz_path%\
move %temp_path%\dayz_server\@Hive %dayz_path%\
move %temp_path%\dayz_server\cfgdayz %dayz_path%\
move %temp_path%\dayz_server\Keys\* %dayz_path%\Keys\
rmdir /S /Q %temp_path%\dayz_server

echo Moving BattlEye filters
move %temp_path%\battleye_filters\Battleye-Filters-Release_1.8.6.1\* %dayz_path%\cfgdayz\BattlEye\
rmdir /S /Q %temp_path%\battleye_filters

echo Moving MySQL server
move %temp_path%\mysql\mysql-5.7.10-winx64 %dayz_path%\mysql_server
rmdir /S /Q %temp_path%\mysql

echo Initialising MySQL database
cd %dayz_path%\mysql_server
.\bin\mysqld --initialize-insecure --user=dayz --console --log_syslog=0
@echo [mysqld]> my.ini
@echo port=3306>> my.ini
@echo bind-address=127.0.0.1>> my.ini
start .\bin\mysqld --console --log_syslog=0
echo Waiting 5s for SQL server to boot...
timeout /t 5 /nobreak > NUL
set /p root_pw="Please specify an SQL root password: "
set /p user_pw="Please specify an SQL user password: "
echo Setting up users
.\bin\mysql.exe --host=127.0.0.1 --port=3306 -uroot --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '%root_pw%';"
.\bin\mysql.exe --host=127.0.0.1 --port=3306 -uroot -p%root_pw% --execute="CREATE DATABASE dayz;"
.\bin\mysql.exe --host=127.0.0.1 --port=3306 -uroot -p%root_pw% --execute="CREATE USER 'dayz'@'localhost' IDENTIFIED BY '%user_pw%';"
.\bin\mysql.exe --host=127.0.0.1 --port=3306 -uroot -p%root_pw% --execute="GRANT ALL PRIVILEGES ON dayz.* TO 'dayz'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
echo Importing SQL files
cd %pwd%
for /f %%f in ('dir /b %temp_path%\sql\1.8.6\') do %dayz_path%\mysql_server\bin\mysql.exe --host=127.0.0.1 --port=3306 -uroot -p%root_pw% -Ddayz < "%temp_path%\sql\1.8.6\%%f"
rmdir /S /Q %temp_path%\sql
%dayz_path%\mysql_server\bin\mysqladmin.exe --host=127.0.0.1 --port=3306 -uroot -p%root_pw% shutdown
set root_pw=

echo.
echo Creating Mission
cd %dayz_path%\MPMissions
mkdir DayZ_Base.Chernarus
cd DayZ_Base.Chernarus
move %pwd%\description.ext .
move %pwd%\init.sqf .
move %pwd%\keyboard.sqf .
move %pwd%\mission.sqm .

REM mission file (edited) from Pwnoz0r https://github.com/Pwnoz0r/DayZ-Private-Server

echo Cleanup
rmdir /S /Q %temp_path%\steamcmd

cd ..\..\cfgdayz

echo.
echo Configuring server
move %pwd%\server.cfg .
move %pwd%\HiveExt.ini .
@echo Password = %user_pw%>> HiveExt.ini
cd BattlEye
set /p rcon_pw="RCON Password: "
@echo RConPassword %rcon_pw%> BEServer.cfg
@echo MaxPing 200>> BEServer.cfg
cd ..\..
@echo @echo off> _start.bat
@echo start .\mysql_server\bin\mysqld.exe --console --log_syslog=0 >> _start.bat
@echo echo Waiting 5s for MySQL to start>> _start.bat
@echo timeout /t 5 /nobreak ^> NUL>> _start.bat
@echo start .\Expansion\beta\arma2oaserver.exe -mod=Expansion\beta;Expansion\beta\expansion;ca;@dayz;@hive -name=cfgdayz -config=cfgdayz\server.cfg -cfg=cfgdayz\arma2.cfg -profiles=cfgdayz -world=Chernarus -cpuCount=4 -exThreads=7 -maxmem=12288 -noCB>> _start.bat
@echo echo DayZ is starting.>> _start.bat
@echo timeout /t 2 /nobreak ^> NUL>> _start.bat

echo.
echo.
echo Installation finished.
echo Before you can start...
echo.
echo 1. Download and install Microsoft Visual C++ Redistributable from
echo    http://www.microsoft.com/en-us/download/details.aspx?id=8328
echo 2. Edit %dayz_path%\cfgdayz\server.cfg
echo    and change passwords, hostname and gamesettings.
echo 3. Edit %dayz_path%\_start.bat
echo    and change CPU, Thread and Memory settings.
echo You can then start your DayZ server using
echo %dayz_path%\_start.bat
echo.
echo Play fair.
pause

echo CREDITS
echo DayZ Mod 1.8.6.1 Files
echo  R4Z0R49 on forums.dayzgame.com
echo Mission File
echo  Pwnoz0r on github.com
echo wget
echo  https://code.google.com/p/osspack32/downloads/detail?name=wget-1.14.exe
echo unrar
echo  http://www.rarlab.com/
echo 7-zip
echo  http://www.7-zip.org/
echo Also
echo  A million outdated guides
echo  ArmA 2 Documentation
echo  DayZ Documentation
