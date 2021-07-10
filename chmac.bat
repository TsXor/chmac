@echo off
chcp 936 > nul
setlocal enabledelayedexpansion


type nul > %~dp0adapterslist1.txt
type nul > %~dp0adapterslist2.txt
echo 正在查找存在的网卡，这可能需要一段时间...
set sw=0
for /f "tokens=*" %%i in ('ipconfig /all') do (
	if !sw!==0 (
		for /f "tokens=1*" %%j in ('echo %%i ^| find "以太网适配器"') do (
			if "%%k"=="" (echo 0 > nul) else (
				if "%%k"==" " (echo 0 > nul) else (
					set x=%%k
					set sw=1
				)
			)
		)
		for /f "tokens=1*" %%j in ('echo %%i ^| find "无线局域网适配器"') do (
			if "%%k"=="" (echo 0 > nul) else (
				if "%%k"==" " (echo 0 > nul) else (
					set x=%%k
					set sw=1
				)
			)	
		)
	) else (
		for /f "tokens=*" %%j in ('echo %%i ^| find "描述"') do (
			if "%%j"=="" (echo 0 > nul) else (
				echo !x!/%%j >> %~dp0adapterslist1.txt
				set sw=0
			)
		)
	)
)
set /a choicenum=0
set macreg=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\
for /f "tokens=7 delims=\" %%a in ('reg query !macreg!') do (
	if %%a==Properties (echo 0 > nul) else (
		set curnum=%%a
		for /f "tokens=2*" %%b in ('reg query !macreg!%%a /v DriverDesc ^| find "DriverDesc"') do (
			set curname=%%c
			set sw=0
			for /f "tokens=1* delims=/" %%d in (%~dp0adapterslist1.txt) do (
				set name=%%d
				set desc=%%e
				for /f "tokens=*" %%f in ('echo !desc! ^| find "!curname!"') do (
					if "%%f"=="" (echo 0 > nul) else (
						set /a choicenum+=1
						echo !choicenum!/!curnum!/!name!!curname! >> %~dp0adapterslist2.txt
					)
				)
			)
		)
	)
)
cls
echo 请选择正在使用的网卡，将重置其mac地址。
for /f "tokens=1,2,3 delims=/" %%i in (%~dp0adapterslist2.txt) do (
	echo [%%i]%%k
)
set /a choicenump=!choicenum!
set /a choicenumt=!choicenum!
for /l %%a in (1,1,!choicenump!) do (
	set choicestr=!choicenumt!!choicestr!
	set /a choicenumt-=1
)
choice /c:!choicestr! /m:"请输入网卡前的序号"
set ch=!ERRORLEVEL!
for /f "tokens=1,2,3 delims=/:" %%i in (%~dp0adapterslist2.txt) do (
	if !ch!==%%i (
		set chosennum=%%j
		set chosendev=%%k
	)
)
cls
echo 你已选择[!chosendev!]。
for /f "tokens=2*" %%i in ('reg query !macreg!!chosennum! /v NetworkAddress ^| find "NetworkAddress"') do (echo 它现在的mac地址为：%%j)
choice /c:yn /m:"新的mac地址是要随机生成(y)还是手动填写(n)"
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
	echo 注意：有效mac地址的第二位需为"2","6","A","E"中的一个。
	set /p randmac=请输入mac地址：
)
cls
echo 你已选择[!chosendev!]。
for /f "tokens=2*" %%i in ('reg query !macreg!!chosennum! /v NetworkAddress ^| find "NetworkAddress"') do (echo 它现在的mac地址为：%%j)
echo 网卡的mac地址将被设为：!randmac!
echo 设置过程中网卡将被禁用并重新启用。这个过程中会断网。如果你在使用无线网卡，可能需要重新连接wifi。
echo 如果暂时不想断网，你可以等会再确定，或者输入n退出。
del %~dp0adapterslist1.txt
del %~dp0adapterslist2.txt
choice /c:yn /m:"确定要设置mac地址吗？"
if !errorlevel!==2 (exit)
cls
echo 设置mac地址...
%~dp0elevate /c reg add !macreg!!chosennum! /v NetworkAddress /d !randmac! /f
timeout /t 2 /nobreak > nul
echo 禁用设备...
%~dp0elevate /c netsh interface set interface name="!chosendev!" admin=disable
timeout /t 10 /nobreak > nul
echo 启用设备...
%~dp0elevate /c netsh interface set interface name="!chosendev!" admin=enable
pause
