@echo off
title HysilensSR 发布包制作工具
color 0a

echo ========================================
echo   HysilensSR 发布包制作工具
echo ========================================
echo.

:: 设置发布目录
set RELEASE_DIR=HysilensSR_Release
set CURRENT_DIR=%CD%

echo [1/6] 准备发布目录...
if exist "%RELEASE_DIR%" (
    echo 清理旧的发布目录...
    rmdir /s /q "%RELEASE_DIR%"
)
mkdir "%RELEASE_DIR%"

echo [2/6] 检查并构建项目...
zig build
if %errorlevel% neq 0 (
    echo [错误] 项目构建失败，无法创建发布包
    pause
    exit /b 1
)

echo [3/6] 复制必要文件...
:: 复制启动脚本
copy "start.bat" "%RELEASE_DIR%\"
copy "server-manager.bat" "%RELEASE_DIR%\"

:: 复制配置文件
copy "config.json" "%RELEASE_DIR%\"
copy "hotfix.json" "%RELEASE_DIR%\"
copy "build.zig" "%RELEASE_DIR%\"
copy "build.zig.zon" "%RELEASE_DIR%\"

:: 复制说明文档
copy "README_运行说明.md" "%RELEASE_DIR%\"
if exist "README.md" copy "README.md" "%RELEASE_DIR%\README_开发说明.md"

echo [4/6] 复制源码和资源...
:: 复制源码目录
xcopy "dispatch" "%RELEASE_DIR%\dispatch" /E /I /H /Y
xcopy "gameserver" "%RELEASE_DIR%\gameserver" /E /I /H /Y
xcopy "protocol" "%RELEASE_DIR%\protocol" /E /I /H /Y

:: 复制资源目录
if exist "resources" (
    xcopy "resources" "%RELEASE_DIR%\resources" /E /I /H /Y
) else (
    echo [警告] 未找到 resources 目录
)

:: 复制编译输出（如果存在）
if exist "zig-out" (
    xcopy "zig-out" "%RELEASE_DIR%\zig-out" /E /I /H /Y
)

echo [5/6] 创建发布信息...
:: 创建版本信息文件
echo HysilensSR Server Release Package > "%RELEASE_DIR%\VERSION.txt"
echo Build Date: %date% %time% >> "%RELEASE_DIR%\VERSION.txt"
echo. >> "%RELEASE_DIR%\VERSION.txt"
echo This package contains everything needed to run HysilensSR server. >> "%RELEASE_DIR%\VERSION.txt"
echo Please read README_运行说明.md for setup instructions. >> "%RELEASE_DIR%\VERSION.txt"

:: 创建快速启动说明
echo @echo off > "%RELEASE_DIR%\快速启动.bat"
echo echo 欢迎使用 HysilensSR Server！ >> "%RELEASE_DIR%\快速启动.bat"
echo echo. >> "%RELEASE_DIR%\快速启动.bat"
echo echo 请选择启动方式： >> "%RELEASE_DIR%\快速启动.bat"
echo echo [1] 一键启动 ^(自动启动所有服务器^) >> "%RELEASE_DIR%\快速启动.bat"
echo echo [2] 管理器模式 ^(推荐，提供完整管理功能^) >> "%RELEASE_DIR%\快速启动.bat"
echo echo. >> "%RELEASE_DIR%\快速启动.bat"
echo set /p choice="请选择 (1/2): " >> "%RELEASE_DIR%\快速启动.bat"
echo if "%%choice%%"=="1" start.bat >> "%RELEASE_DIR%\快速启动.bat"
echo if "%%choice%%"=="2" server-manager.bat >> "%RELEASE_DIR%\快速启动.bat"

echo [6/6] 打包完成！
echo.
echo ========================================
echo 发布包已创建在: %RELEASE_DIR%
echo.
echo 发布包包含：
echo - 完整的源代码
echo - 配置文件
echo - 一键启动脚本
echo - 服务器管理器
echo - 详细的使用说明
echo.
echo 用户只需要：
echo 1. 安装 Zig 编译器
echo 2. 运行 快速启动.bat 或 server-manager.bat
echo ========================================
echo.
set /p opendir="是否打开发布目录? (y/n): "
if /i "%opendir%"=="y" explorer "%RELEASE_DIR%"

echo.
echo 发布包制作完成！
pause
