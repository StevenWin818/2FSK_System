@echo off
REM 2FSK调制解调系统 - 快速运行脚本
REM 适用于MWORKS Syslab 2025b环境

echo ========================================
echo 2FSK调制解调系统 v1.0.0
echo ========================================
echo.

REM 设置MWORKS Julia路径
set JULIA_PATH="C:\Program Files\MWORKS\Syslab 2025b\julia\bin\julia.exe"

REM 检查Julia是否存在
if not exist %JULIA_PATH% (
    echo [错误] 找不到MWORKS Julia: %JULIA_PATH%
    echo 请检查MWORKS Syslab 2025b是否已安装
    pause
    exit /b 1
)

echo [步骤 1/3] 检查依赖包...
%JULIA_PATH% --project=. -e "using Pkg; Pkg.instantiate()"

if %errorlevel% neq 0 (
    echo [错误] 依赖包安装失败
    pause
    exit /b 1
)

echo.
echo [步骤 2/3] 运行主程序...
echo.

%JULIA_PATH% --project=. main.jl

if %errorlevel% neq 0 (
    echo.
    echo [错误] 程序运行失败
    pause
    exit /b 1
)

echo.
echo [步骤 3/3] 完成！
echo ========================================
echo 输出文件:
echo   - ber_data.csv (误码率数据)
echo   - spectrum_data.csv (频谱数据)
echo ========================================
echo.
pause
