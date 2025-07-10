@echo off
title 服务器 预编译发布包制作工具
color 0a

echo ========================================
echo   服务器 预编译发布包制作工具
echo ========================================
echo.

:: 设置发布目录
set RELEASE_DIR=服务器_Portable
set CURRENT_DIR=%CD%

echo [1/7] 准备发布目录...
if exist "%RELEASE_DIR%" (
    echo 清理旧的发布目录...
    rmdir /s /q "%RELEASE_DIR%"
)
mkdir "%RELEASE_DIR%"

echo [2/7] 构建项目（生成可执行文件）...
zig build
if %errorlevel% neq 0 (
    echo [错误] 项目构建失败，无法创建发布包
    pause
    exit /b 1
)

echo [3/7] 检查编译输出...
if not exist "zig-out\bin\dispatch.exe" (
    echo [错误] 找不到 dispatch.exe，请确保编译成功
    pause
    exit /b 1
)

if not exist "zig-out\bin\gameserver.exe" (
    echo [错误] 找不到 gameserver.exe，请确保编译成功
    pause
    exit /b 1
)

echo [4/7] 复制可执行文件...
mkdir "%RELEASE_DIR%\bin"
copy "zig-out\bin\dispatch.exe" "%RELEASE_DIR%\bin\"
if %errorlevel% neq 0 (
    echo [错误] 复制 dispatch.exe 失败
    pause
    exit /b 1
)
if not exist "%RELEASE_DIR%\bin\dispatch.exe" (
    echo [错误] 复制后检查失败: dispatch.exe 不存在于发布目录
    pause
    exit /b 1
)
copy "zig-out\bin\gameserver.exe" "%RELEASE_DIR%\bin\"
if %errorlevel% neq 0 (
    echo [错误] 复制 gameserver.exe 失败
    pause
    exit /b 1
)
if not exist "%RELEASE_DIR%\bin\gameserver.exe" (
    echo [错误] 复制后检查失败: gameserver.exe 不存在于发布目录
    pause
    exit /b 1
)

:: 复制可能的依赖文件
if exist "zig-out\bin\*.dll" copy "zig-out\bin\*.dll" "%RELEASE_DIR%\bin\"

echo [5/7] 复制配置和资源文件...
:: 复制配置文件
copy "config.json" "%RELEASE_DIR%\"
copy "hotfix.json" "%RELEASE_DIR%\"

:: 复制资源目录
if exist "resources" (
    xcopy "resources" "%RELEASE_DIR%\resources" /E /I /H /Y
) else (
    echo [警告] 未找到 resources 目录
)

:: 复制启动器（如果存在）
if exist "launcher" (
    xcopy "launcher" "%RELEASE_DIR%\launcher" /E /I /H /Y
)

:: [6/7] 创建便携版启动脚本 - 修复版本

:: 创建便携版一键启动脚本（修复带空格路径问题）
echo @echo off > "%RELEASE_DIR%\启动服务器.bat"
echo title 海瑟音 Server >> "%RELEASE_DIR%\启动服务器.bat"
echo echo ======================================== >> "%RELEASE_DIR%\启动服务器.bat"
echo echo    海瑟音 Server 便携版 >> "%RELEASE_DIR%\启动服务器.bat"
echo echo ======================================== >> "%RELEASE_DIR%\启动服务器.bat"
echo echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo setlocal enabledelayedexpansion >> "%RELEASE_DIR%\启动服务器.bat"
echo set "ROOT=%%~dp0" >> "%RELEASE_DIR%\启动服务器.bat"
echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo :: 检查必要文件 >> "%RELEASE_DIR%\启动服务器.bat"
echo if not exist "!ROOT!bin\dispatch.exe" ( >> "%RELEASE_DIR%\启动服务器.bat"
echo     echo [错误] 找不到 dispatch.exe >> "%RELEASE_DIR%\启动服务器.bat"
echo     echo 路径: !ROOT!bin\dispatch.exe >> "%RELEASE_DIR%\启动服务器.bat"
echo     pause >> "%RELEASE_DIR%\启动服务器.bat"
echo     exit /b 1 >> "%RELEASE_DIR%\启动服务器.bat"
echo ) >> "%RELEASE_DIR%\启动服务器.bat"
echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo if not exist "!ROOT!bin\gameserver.exe" ( >> "%RELEASE_DIR%\启动服务器.bat"
echo     echo [错误] 找不到 gameserver.exe >> "%RELEASE_DIR%\启动服务器.bat"
echo     echo 路径: !ROOT!bin\gameserver.exe >> "%RELEASE_DIR%\启动服务器.bat"
echo     pause >> "%RELEASE_DIR%\启动服务器.bat"
echo     exit /b 1 >> "%RELEASE_DIR%\启动服务器.bat"
echo ) >> "%RELEASE_DIR%\启动服务器.bat"
echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo echo [1/2] 启动调度服务器... >> "%RELEASE_DIR%\启动服务器.bat"
echo start "海瑟音 Dispatch Server" cmd /k "cd /d "!ROOT!" && echo 调度服务器运行中... && "bin\dispatch.exe"" >> "%RELEASE_DIR%\启动服务器.bat"
echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo timeout /t 3 /nobreak ^>nul >> "%RELEASE_DIR%\启动服务器.bat"
echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo echo [2/2] 启动游戏服务器... >> "%RELEASE_DIR%\启动服务器.bat"
echo start "海瑟音 Game Server" cmd /k "cd /d "!ROOT!" && echo 游戏服务器运行中... && "bin\gameserver.exe"" >> "%RELEASE_DIR%\启动服务器.bat"
echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo echo ======================================== >> "%RELEASE_DIR%\启动服务器.bat"
echo echo 服务器启动完成！ >> "%RELEASE_DIR%\启动服务器.bat"
echo echo 调度服务器: http://127.0.0.1:21000 >> "%RELEASE_DIR%\启动服务器.bat"
echo echo ======================================== >> "%RELEASE_DIR%\启动服务器.bat"
echo echo. >> "%RELEASE_DIR%\启动服务器.bat"
echo echo 按任意键关闭启动器... >> "%RELEASE_DIR%\启动服务器.bat"
echo pause ^>nul >> "%RELEASE_DIR%\启动服务器.bat"

:: 创建便携版管理器（同样修复带空格路径问题）
echo @echo off > "%RELEASE_DIR%\服务器管理器.bat"
echo setlocal enabledelayedexpansion >> "%RELEASE_DIR%\服务器管理器.bat"
echo set "ROOT=%%~dp0" >> "%RELEASE_DIR%\服务器管理器.bat"
echo title 海瑟音 Server 便携版管理器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo color 0b >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo cls >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo ======================================== >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo    海瑟音 Server 便携版管理器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo ======================================== >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [1] 启动所有服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [2] 仅启动调度服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [3] 仅启动游戏服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [4] 查看服务器状态 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [5] 停止所有服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [6] 打开配置文件夹 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo [0] 退出 >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo set /p choice=请选择操作 (0-6): >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="1" goto start_all >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="2" goto start_dispatch >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="3" goto start_gameserver >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="4" goto check_status >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="5" goto stop_all >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="6" goto open_config >> "%RELEASE_DIR%\服务器管理器.bat"
echo if "%%choice%%"=="0" goto exit >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :start_all >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 正在启动所有服务器... >> "%RELEASE_DIR%\服务器管理器.bat"
echo start "海瑟音 Dispatch Server" cmd /k "cd /d "!ROOT!" && bin\dispatch.exe" >> "%RELEASE_DIR%\服务器管理器.bat"
echo timeout /t 2 /nobreak ^>nul >> "%RELEASE_DIR%\服务器管理器.bat"
echo start "海瑟音 Game Server" cmd /k "cd /d "!ROOT!" && bin\gameserver.exe" >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 服务器已启动 >> "%RELEASE_DIR%\服务器管理器.bat"
echo pause >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :start_dispatch >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 正在启动调度服务器... >> "%RELEASE_DIR%\服务器管理器.bat"
echo start "海瑟音 Dispatch Server" cmd /k "cd /d "!ROOT!" && bin\dispatch.exe" >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 调度服务器已启动 >> "%RELEASE_DIR%\服务器管理器.bat"
echo pause >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :start_gameserver >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 正在启动游戏服务器... >> "%RELEASE_DIR%\服务器管理器.bat"
echo start "海瑟音 Game Server" cmd /k "cd /d "!ROOT!" && bin\gameserver.exe" >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 游戏服务器已启动 >> "%RELEASE_DIR%\服务器管理器.bat"
echo pause >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :check_status >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 检查服务器状态... >> "%RELEASE_DIR%\服务器管理器.bat"
echo tasklist /fi "imagename eq dispatch.exe" 2^>nul ^| find /i "dispatch.exe" ^>nul >> "%RELEASE_DIR%\服务器管理器.bat"
echo if %%errorlevel%% equ 0 ( >> "%RELEASE_DIR%\服务器管理器.bat"
echo     echo [运行中] 调度服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo ) else ( >> "%RELEASE_DIR%\服务器管理器.bat"
echo     echo [已停止] 调度服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo ) >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo tasklist /fi "imagename eq gameserver.exe" 2^>nul ^| find /i "gameserver.exe" ^>nul >> "%RELEASE_DIR%\服务器管理器.bat"
echo if %%errorlevel%% equ 0 ( >> "%RELEASE_DIR%\服务器管理器.bat"
echo     echo [运行中] 游戏服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo ) else ( >> "%RELEASE_DIR%\服务器管理器.bat"
echo     echo [已停止] 游戏服务器 >> "%RELEASE_DIR%\服务器管理器.bat"
echo ) >> "%RELEASE_DIR%\服务器管理器.bat"
echo pause >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :stop_all >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 正在停止所有服务器... >> "%RELEASE_DIR%\服务器管理器.bat"
echo taskkill /f /im dispatch.exe 2^>nul >> "%RELEASE_DIR%\服务器管理器.bat"
echo taskkill /f /im gameserver.exe 2^>nul >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 所有服务器已停止 >> "%RELEASE_DIR%\服务器管理器.bat"
echo pause >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :open_config >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 打开配置文件夹... >> "%RELEASE_DIR%\服务器管理器.bat"
echo explorer.exe "!ROOT!" >> "%RELEASE_DIR%\服务器管理器.bat"
echo goto menu >> "%RELEASE_DIR%\服务器管理器.bat"
echo. >> "%RELEASE_DIR%\服务器管理器.bat"
echo :exit >> "%RELEASE_DIR%\服务器管理器.bat"
echo echo 再见！ >> "%RELEASE_DIR%\服务器管理器.bat"
echo exit /b 0 >> "%RELEASE_DIR%\服务器管理器.bat"

:: 创建便携版说明文件
echo 创建说明文件...
echo 海瑟音 Server 便携版 > "%RELEASE_DIR%\README.txt"
echo ================================ >> "%RELEASE_DIR%\README.txt"
echo. >> "%RELEASE_DIR%\README.txt"
echo 使用说明： >> "%RELEASE_DIR%\README.txt"
echo 1. 双击"启动服务器.bat"可以一键启动所有服务器 >> "%RELEASE_DIR%\README.txt"
echo 2. 双击"服务器管理器.bat"可以单独管理各个服务器 >> "%RELEASE_DIR%\README.txt"
echo 3. 此便携版可以移动到任意位置运行 >> "%RELEASE_DIR%\README.txt"
echo 4. 将 launcher.exe 和 hkprg.dll 从launcher 文件夹复制并粘贴到 StarRail 文件夹(崩铁的根目录) >> "%RELEASE_DIR%\README.txt"
echo 5. 然后双击lanucher.exe代替官方启动器启动游戏即可体验 >> "%RELEASE_DIR%\README.txt"
echo. >> "%RELEASE_DIR%\README.txt"
echo 服务器地址： >> "%RELEASE_DIR%\README.txt"
echo - 调度服务器: http://127.0.0.1:21000 >> "%RELEASE_DIR%\README.txt"
echo - 游戏服务器: 127.0.0.1:22000 >> "%RELEASE_DIR%\README.txt"
echo. >> "%RELEASE_DIR%\README.txt"
echo 注意事项： >> "%RELEASE_DIR%\README.txt"
echo - 请确保端口21000和22000未被占用 >> "%RELEASE_DIR%\README.txt"
echo - 如需修改配置，请编辑config.json文件 >> "%RELEASE_DIR%\README.txt"
echo - 资源文件位于resources目录中 >> "%RELEASE_DIR%\README.txt"
echo - 备注：此便携版仅供个人学习和测试使用，请勿用于商业用途 >> "%RELEASE_DIR%\README.txt"
echo - 任何问题请联系开发者 >> "%RELEASE_DIR%\README.txt"
echo - 祝您使用愉快！ >> "%RELEASE_DIR%\README.txt"
echo. >> "%RELEASE_DIR%\README.txt"
echo 开发者： >> "%RELEASE_DIR%\README.txt"
echo - B站Up主原神再起不能动 >> "%RELEASE_DIR%\README.txt"
echo - QQ群：822751143 >> "%RELEASE_DIR%\README.txt"
echo. >> "%RELEASE_DIR%\README.txt"
echo 特别鸣谢： >> "%RELEASE_DIR%\README.txt"
echo - HonkaiSlopRail以及xeondev，Năng Pờ Rào the Sillyism CFO，以及所有为此项目做出贡献的人。 >> "%RELEASE_DIR%\README.txt"
echo - 感谢他们的支持和帮助！ >> "%RELEASE_DIR%\README.txt"
echo - 如果您没有测试服游戏本体，请前往B站或者QQ群找我 >> "%RELEASE_DIR%\README.txt"

echo [7/7] 完成便携版制作...
echo.
echo ========================================
echo 便携版制作完成！
echo 输出目录: %RELEASE_DIR%
echo ========================================
echo.
echo 使用说明：
echo 1. 将 %RELEASE_DIR% 文件夹移动到任意位置
echo 2. 双击"启动服务器.bat"一键启动
echo 3. 或使用"服务器管理器.bat"进行精细管理
echo.
echo 按任意键退出...
pause >nul