@echo off
title HysilensSR Server Launcher
echo ========================================
echo    HysilensSR Server 一键启动器
echo ========================================
echo.

:: 检查 Zig 是否安装
zig version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Zig 编译器，请先安装 Zig 0.13.0 或更高版本
    echo 下载地址: https://ziglang.org/download/
    pause
    exit /b 1
)

echo [信息] 检测到 Zig 编译器版本:
zig version

echo.
echo [1/4] 正在构建项目...
zig build
if %errorlevel% neq 0 (
    echo [错误] 项目构建失败
    pause
    exit /b 1
)

echo [2/4] 构建完成，准备启动服务器...

:: 检查必要的配置文件
if not exist "config.json" (
    echo [错误] 缺少 config.json 配置文件
    pause
    exit /b 1
)

if not exist "hotfix.json" (
    echo [错误] 缺少 hotfix.json 配置文件
    pause
    exit /b 1
)

echo [3/4] 启动调度服务器...
start "HysilensSR Dispatch Server" cmd /k "echo 调度服务器已启动 && zig build run-dispatch"

timeout /t 3 /nobreak >nul

echo [4/4] 启动游戏服务器...
start "HysilensSR Game Server" cmd /k "echo 游戏服务器已启动 && zig build run-gameserver"

echo.
echo ========================================
echo 服务器启动完成！
echo 调度服务器: http://127.0.0.1:21000
echo 游戏服务器端口: 请查看配置文件
echo ========================================
echo.
echo 按任意键退出启动器...
pause >nul
