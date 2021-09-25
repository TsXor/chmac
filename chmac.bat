@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
set cdpgreg=HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Nls\CodePage
for /f "tokens=3" %%i in ('reg query !cdpgreg! /v ACP') do (set cdpg=%%i)


rem LOCALE
rem ======

set loc1=正在查找存在的网卡，这可能需要一段时间...

set loc2=请选择正在使用的网卡，将重置其mac地址。

set loc3=请输入网卡前的序号

set loc4=你已选择

set loc5=它现在的mac地址为：

set loc6=新的mac地址是要随机生成(y)还是手动填写(n)

set loc7=注意：有效mac地址的第二位需为"2","6","A","E"中的一个。

set loc8=请输入mac地址：

set loc9=你已选择

set loc10=它现在的mac地址为：

set loc11=网卡的mac地址将被设为：

set loc12=设置过程中网卡将被禁用并重新启用。这个过程中会断网。如果你在使用无线网卡，可能需要重新连接wifi。

set loc13=如果暂时不想断网，你可以等会再确定，或者输入n退出。

set loc14=确定要设置mac地址吗？

set loc15=正在设置mac地址...

set loc16=正在禁用设备...

set loc17=正在启用设备...

rem ======


echo !loc1!
set devs=0
set linenum=0
for /f "tokens=*" %%i in ('ipconfig /all') do (
	set /a linenum+=1
	echo %%i | find "Ethernet adapter" >nul && set /a devs+=1 && set devline!devs!=!linenum!
	echo %%i | find "Wireless LAN adapter" >nul && set /a devs+=1 && set devline!devs!=!linenum!
	echo %%i | find "Description" >nul && for /f "tokens=2* delims=:" %%j in ('echo %%i ^| find "Description"') do (for /f "tokens=*" %%n in ("%%j") do (set desc!devs!=%%n))
	echo %%i | find "Physical Address" >nul && for /f "tokens=2* delims=:" %%j in ('echo %%i ^| find "Physical Address"') do (for /f "tokens=*" %%n in ("%%j") do (set mac!devs!=%%n))
)
chcp !cdpg! >nul
set thisdev=1
set linenum=0
for /f "tokens=*" %%i in ('ipconfig /all') do (
	set /a linenum+=1
	set linecontent=%%i
	for /f "tokens=2* delims==" %%k in ('set devline!thisdev!') do (if !linenum!==%%k (set name!thisdev!=!linecontent:~0,-1! && set /a thisdev+=1))
	if !thisdev! gtr !devs! (goto skip1)
)
:skip1
chcp 65001 >nul

set macreg=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\
set namereg=HKLM\SYSTEM\CurrentControlSet\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}\
for /f "tokens=7 delims=\" %%a in ('reg query !macreg!') do (
	if %%a==Properties (echo 0 > nul) else (if %%a==Configuration (echo 0 > nul) else (
		set curnum=%%a
		for /f "tokens=2*" %%b in ('reg query !macreg!%%a /v DriverDesc ^| find "DriverDesc"') do (
			set curname=%%c
			for /l %%n in (1,1,!devs!) do (
				set thisdev=%%n
				for /f "tokens=2* delims==" %%s in ('set desc!thisdev!') do (set desc=%%s)
				echo !desc! | find "!curname!" >nul && set regnum!thisdev!=!curnum!
			)
		)
	))
)
for /f "tokens=7 delims=\" %%a in ('reg query !namereg!') do (
	if %%a==Descriptions (echo 0 > nul) else (
		for /f "tokens=2*" %%b in ('reg query !namereg!%%a\Connection /v Name ^| find "Name"') do (
			set curcmdname=%%c
			for /l %%n in (1,1,!devs!) do (
				set thisdev=%%n
				for /f "tokens=2* delims==" %%s in ('set name!thisdev!') do (set name=%%s)
				echo !name! | find "!curcmdname!" >nul && set cmdname!thisdev!=!curcmdname!
			)
		)
	)
)
cls

echo !loc2!
for /l %%n in (1,1,!devs!) do (
	for /f "tokens=2* delims==" %%s in ('set name!thisdev!') do (set name=%%s)
	for /f "tokens=2* delims==" %%s in ('set desc!thisdev!') do (set desc=%%s)
	echo [%%n]!name!: !desc!
)

set choicestr=
for /l %%a in (1,1,!devs!) do (set choicestr=!choicestr!%%a)
choice /c:!choicestr! /m:"!loc3!"
set ch=!ERRORLEVEL!
for /l %%n in (1,1,!devs!) do (
	if !ch!==%%n (
		for /f "tokens=2* delims==" %%s in ('set name!thisdev!') do (set chosenname=%%s)
		for /f "tokens=2* delims==" %%s in ('set desc!thisdev!') do (set chosendesc=%%s)
		for /f "tokens=2* delims==" %%s in ('set regnum!thisdev!') do (set chosennum=%%s)
		for /f "tokens=2* delims==" %%s in ('set mac!thisdev!') do (set chosenmac=%%s)
		for /f "tokens=2* delims==" %%s in ('set cmdname!thisdev!') do (set chosencmdname=%%s)
	)
)
cls

echo !loc4![!chosenname!: !chosendesc!]。
reg query !macreg!!chosennum! | find "NetworkAddress" > nul
if !errorlevel!==1 (set def=1)
if !def!==1 (echo !loc5!!chosenmac!*default) else (echo !loc5!!chosenmac!)
choice /c:yn /m:"!loc6!"

if !errorlevel!==1 (
	set min=1
	set max=15
	set /a mod=!max!-!min!+1
	for /l %%i in (1,1,12) do (
		set /a rand1=!random!%%!mod!+!min!
		if %%i equ 1 (
			set rand2=0
		) else (
			if %%i equ 2 (
				if !rand1! equ 1 set rand2=2
				if !rand1! equ 2 set rand2=2
				if !rand1! equ 3 set rand2=2
				if !rand1! equ 4 set rand2=2
				if !rand1! equ 5 set rand2=6
				if !rand1! equ 6 set rand2=6
				if !rand1! equ 7 set rand2=6
				if !rand1! equ 8 set rand2=6
				if !rand1! equ 9 set rand2=A
				if !rand1! equ 10 set rand2=A
				if !rand1! equ 11 set rand2=A
				if !rand1! equ 12 set rand2=A
				if !rand1! equ 13 set rand2=E
				if !rand1! equ 14 set rand2=E
				if !rand1! equ 15 set rand2=E
			) else (
				if !rand1! equ 1 set rand2=1
				if !rand1! equ 2 set rand2=2
				if !rand1! equ 3 set rand2=3
				if !rand1! equ 4 set rand2=4
				if !rand1! equ 5 set rand2=5
				if !rand1! equ 6 set rand2=6
				if !rand1! equ 7 set rand2=7
				if !rand1! equ 8 set rand2=8
				if !rand1! equ 9 set rand2=9
				if !rand1! equ 10 set rand2=A
				if !rand1! equ 11 set rand2=B
				if !rand1! equ 12 set rand2=C
				if !rand1! equ 13 set rand2=D
				if !rand1! equ 14 set rand2=E
				if !rand1! equ 15 set rand2=F
			)
		)
		set randmac=!randmac!!rand2!
	)
) else (
	echo !loc7!
	set /p randmac=!loc8!
)
cls

echo !loc9![!chosenname!: !chosendesc!]。
if !def!==1 (echo !loc10!!chosenmac!*default) else (echo !loc10!!chosenmac!)
echo !loc11!!randmac:~-12,2!-!randmac:~-10,2!-!randmac:~-8,2!-!randmac:~-6,2!-!randmac:~-4,2!-!randmac:~-2,2!
echo !loc12!
echo !loc13!
choice /c:yn /m:"!loc14!"
if !errorlevel!==2 (exit)
cls

echo !loc15!
echo reg add !macreg!!chosennum! /v NetworkAddress /d !randmac! /f > !temp!\chmaccmdtmp.bat
call :adminexec
echo !loc16!
echo netsh interface set interface name="!chosencmdname!" admin=disable > !temp!\chmaccmdtmp.bat
call :adminexec
timeout /t 10 /nobreak > nul
echo !loc17!
echo netsh interface set interface name="!chosencmdname!" admin=enable > !temp!\chmaccmdtmp.bat
call :adminexec
del /f /q !temp!\chmaccmdtmp.bat
pause

:adminexec
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c !temp!\chmaccmdtmp.bat ::","","runas",0)(window.close)