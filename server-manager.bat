@echo off
setlocal enabledelayedexpansion

title HysilensSR Server Manager
color 0b

:menu
cls
echo ========================================
echo    HysilensSR Server 管理器
echo ========================================
echo.
echo [1] 一键启动服务器
echo [2] 仅启动调度服务器
echo [3] 仅启动游戏服务器
echo [4] 重新构建项目
echo [5] 检查环境和配置
echo [6] 查看服务器状态
echo [7] 停止所有服务器
echo [0] 退出
echo.
set /p choice="请选择操作 (0-7): "

if "%choice%"=="1" goto start_all
if "%choice%"=="2" goto start_dispatch
if "%choice%"=="3" goto start_gameserver
if "%choice%"=="4" goto rebuild
if "%choice%"=="5" goto check_env
if "%choice%"=="6" goto check_status
if "%choice%"=="7" goto stop_all
if "%choice%"=="0" goto exit
goto menu

:start_all
echo.
echo [信息] 正在启动所有服务器...
call :check_and_build
if !errorlevel! neq 0 goto menu
call :start_dispatch_only
timeout /t 3 /nobreak >nul
call :start_gameserver_only
echo [完成] 所有服务器已启动
pause
goto menu

:start_dispatch
echo.
echo [信息] 正在启动调度服务器...
call :check_and_build
if !errorlevel! neq 0 goto menu
call :start_dispatch_only
echo [完成] 调度服务器已启动
pause
goto menu

:start_gameserver
echo.
echo [信息] 正在启动游戏服务器...
call :check_and_build
if !errorlevel! neq 0 goto menu
call :start_gameserver_only
echo [完成] 游戏服务器已启动
pause
goto menu

:rebuild
echo.
echo [信息] 正在重新构建项目...
zig build
if !errorlevel! neq 0 (
    echo [错误] 构建失败
    pause
    goto menu
)
echo [完成] 项目构建成功
pause
goto menu

:check_env
echo.
echo [信息] 检查环境和配置...
call :check_environment
pause
goto menu

:check_status
echo.
echo [信息] 检查服务器状态...
echo.
tasklist /fi "windowtitle eq HysilensSR Dispatch Server*" 2>nul | find "cmd.exe" >nul
if !errorlevel! equ 0 (
    echo [运行中] 调度服务器
) else (
    echo [已停止] 调度服务器
)

tasklist /fi "windowtitle eq HysilensSR Game Server*" 2>nul | find "cmd.exe" >nul
if !errorlevel! equ 0 (
    echo [运行中] 游戏服务器
) else (
    echo [已停止] 游戏服务器
)
echo.
pause
goto menu

:stop_all
echo.
echo [信息] 正在停止所有服务器...
taskkill /fi "windowtitle eq HysilensSR Dispatch Server*" /f >nul 2>&1
taskkill /fi "windowtitle eq HysilensSR Game Server*" /f >nul 2>&1
echo [完成] 所有服务器已停止
pause
goto menu

:check_and_build
call :check_environment
if !errorlevel! neq 0 exit /b 1
echo [构建] 正在构建项目...
zig build
if !errorlevel! neq 0 (
    echo [错误] 项目构建失败
    exit /b 1
)
exit /b 0

:check_environment
echo [检查] Zig 编译器...
zig version >nul 2>&1
if !errorlevel! neq 0 (
    echo [错误] 未检测到 Zig 编译器
    echo        请安装 Zig 0.13.0 或更高版本
    echo        下载地址: https://ziglang.org/download/
    exit /b 1
) else (
    echo [正常] Zig 编译器已安装
)

echo [检查] 配置文件...
if not exist "config.json" (
    echo [错误] 缺少 config.json 配置文件
    exit /b 1
) else (
    echo [正常] config.json 存在
)

if not exist "hotfix.json" (
    echo [错误] 缺少 hotfix.json 配置文件
    exit /b 1
) else (
    echo [正常] hotfix.json 存在
)

echo [检查] 资源文件...
if not exist "resources\" (
    echo [警告] 缺少 resources 目录
) else (
    echo [正常] resources 目录存在
)

exit /b 0

:start_dispatch_only
start "HysilensSR Dispatch Server" cmd /k "title HysilensSR Dispatch Server && echo [调度服务器] 启动中... && zig build run-dispatch"
exit /b 0

:start_gameserver_only
start "HysilensSR Game Server" cmd /k "title HysilensSR Game Server && echo [游戏服务器] 启动中... && zig build run-gameserver"
exit /b 0

:exit
echo.
echo 感谢使用 HysilensSR Server 管理器！
timeout /t 2 /nobreak >nul
exit
