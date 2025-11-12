# 2FSK调制解调系统 - 图形界面快速指南

## 📊 两种运行模式

### 模式对比

| 特性 | 命令行版本 (main.jl) | 图形版本 (main_gui.jl) |
|------|---------------------|----------------------|
| 速度 | ⚡ 快速 | 🐢 较慢 |
| 输出 | CSV数据文件 | PNG图片 + CSV数据 |
| 依赖 | 少（4个包） | 多（需PyPlot+Python） |
| 推荐场景 | 快速验证、批量测试 | 论文报告、详细分析 |

---

## 🚀 快速运行（命令行版本）

### 适合：日常使用、快速验证

```julia
cd("***REMOVED***")
include("main.jl")
```

**输出**：
- ✅ 控制台显示完整结果
- ✅ `ber_data.csv` - 误码率数据
- ✅ `spectrum_data.csv` - 频谱数据

**后续**：用Excel、Origin等工具绘图

---

## 📊 图形界面版本

### 适合：论文、报告、演示

### 步骤1：安装PyPlot（只需一次）

```julia
# 1. 切换到项目目录
cd("***REMOVED***")

# 2. 运行安装脚本
include("install_pyplot.jl")
```

**预计时间**：5-10分钟（首次安装会下载Python和matplotlib）

### 步骤2：运行图形版本

```julia
cd("***REMOVED***")
include("main_gui.jl")
```

**输出文件**：
- 📊 `waveforms.png` - 信号波形图（3个子图）
  - 调制信号波形
  - 接收信号波形（含噪声）
  - 比特序列对比（原始 vs 解调）
- 📈 `ber_curve.png` - 误码率曲线（对数坐标）
  - 实测BER曲线（蓝色实线）
  - 理论BER曲线（红色虚线）
- 🌈 `spectrum.png` - 频谱分析图
  - 标注f0=84kHz, f1=42kHz
- 📝 `ber_data.csv` - 误码率数据
- 📝 `spectrum_data.csv` - 频谱数据

---

## ⚙️ 首次运行（完整步骤）

### 命令行版本

```julia
# 1. 切换目录
cd("***REMOVED***")

# 2. 安装依赖（首次）
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# 3. 运行
include("main.jl")
```

### 图形版本

```julia
# 1. 切换目录
cd("***REMOVED***")

# 2. 安装基础依赖（首次）
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# 3. 安装PyPlot（首次）
include("install_pyplot.jl")

# 4. 运行图形版本
include("main_gui.jl")
```

---

## 🎨 生成的图片示例

### waveforms.png（波形图）
```
┌─────────────────────────────────────────┐
│ 2FSK调制信号（前10个码元）                │
│ [蓝色正弦波，频率在42kHz和84kHz间切换]     │
├─────────────────────────────────────────┤
│ 接收信号（SNR=10dB）                     │
│ [红色波形，有噪声干扰]                    │
├─────────────────────────────────────────┤
│ 比特序列对比（前10个比特）                │
│ ○ 蓝色：原始比特                         │
│ × 红色：解调比特                         │
└─────────────────────────────────────────┘
```

### ber_curve.png（误码率曲线）
```
10⁰  ┐
     │    ○＼
10⁻² │       ＼○
     │          ＼○   ○ 实测BER
10⁻⁴ │             ＼○ △ 理论BER
     │                ＼△
10⁻⁶ └─────┬─────┬─────┬─────┬
           0     4     8    12    14
              SNR (dB)
```

### spectrum.png（频谱图）
```
幅度 ┐
     │        ┃
     │   ┃    ┃
     │   ┃    ┃
     └───┴────┴────────→ 频率
        42   84  (kHz)
        f₁   f₀
```

---

## 🔧 自定义参数

在 `main.jl` 或 `main_gui.jl` 开头修改：

```julia
# 传输信息
const MESSAGE = "您的测试文本"

# 信噪比
const SNR_TEST = 12.0  # 默认10dB

# BER分析范围
snr_range = 0:1:16  # 默认0:2:14
```

---

## ⚠️ 故障排除

### 1. PyPlot安装失败

**错误信息**：
```
ERROR: PyError ... No module named 'matplotlib'
```

**解决方案A**（推荐）：使用Conda.jl自动安装
```julia
ENV["PYTHON"] = ""  # 让PyCall使用自己的Python
using Pkg
Pkg.add("PyCall")
Pkg.build("PyCall")  # 会自动安装Miniconda
Pkg.add("PyPlot")
```

**解决方案B**：使用系统Python
```bash
# 1. 在系统中安装Python（3.7+）
# 2. 安装matplotlib
pip install matplotlib

# 3. 在Julia中指定Python路径
```
```julia
ENV["PYTHON"] = "C:/Python39/python.exe"  # 改为实际路径
using Pkg
Pkg.build("PyCall")
Pkg.add("PyPlot")
```

**解决方案C**：回退到命令行版本
```julia
# PyPlot安装困难时，使用无图形版本
include("main.jl")
# 然后用Excel/Origin绘制ber_data.csv
```

### 2. 图片中文乱码

**原因**：PyPlot默认字体不支持中文

**解决**：在 `main_gui.jl` 开头添加：
```julia
using PyPlot
PyPlot.matplotlib.rc("font", family="SimHei")  # Windows
# 或
PyPlot.matplotlib.rc("font", family="Arial Unicode MS")  # macOS
```

### 3. 图片显示不出来

**检查**：
```julia
# 查看图片是否生成
readdir(".")  # 应该能看到.png文件
```

**打开图片**：
- Windows: 用图片查看器或浏览器打开
- 在MWORKS中：使用系统命令打开
  ```julia
  run(`explorer waveforms.png`)  # Windows
  ```

### 4. 程序运行很慢

**正常现象**：
- 首次运行需要预编译（1-2分钟）
- PyPlot绘图较慢（每张图5-10秒）

**加速方案**：
- 使用命令行版本（`main.jl`）
- 减少BER测试点数
- 减少频谱采样点数

### 5. 找不到模块

**错误**：
```
ERROR: LoadError: could not open file "src/xxx.jl"
```

**解决**：确保在正确目录
```julia
pwd()  # 检查当前目录
cd("***REMOVED***")
```

### 6. 包版本冲突

**错误**：
```
Unsatisfiable requirements detected for package XXX
```

**解决**：清理环境重新安装
```julia
using Pkg
Pkg.activate(".")
Pkg.resolve()
Pkg.update()
```

---

## 📋 性能指标

### 运行时间对比（参考）

| 版本 | 首次运行 | 后续运行 |
|------|---------|---------|
| 命令行版 | ~30秒 | ~5秒 |
| 图形版 | ~2分钟 | ~20秒 |

### 输出文件大小（参考）

| 文件 | 大小 |
|------|------|
| ber_data.csv | ~1 KB |
| spectrum_data.csv | ~50 KB |
| waveforms.png | ~200 KB |
| ber_curve.png | ~100 KB |
| spectrum.png | ~100 KB |

---

## 📖 下一步

1. **学习原理**：阅读 [README.md](README.md)
2. **查看源码**：理解算法实现
3. **修改参数**：进行自定义实验
4. **版本历史**：查看 [CHANGELOG.md](CHANGELOG.md)

---

## 💡 使用建议

### 论文/报告
✅ 使用图形版本 (`main_gui.jl`)  
✅ 生成高质量PNG图片  
✅ 直接插入文档

### 日常调试
✅ 使用命令行版本 (`main.jl`)  
✅ 快速验证算法  
✅ CSV数据便于处理

### 批量测试
✅ 命令行版本  
✅ 修改参数后快速重跑  
✅ 自动化脚本友好

---

**版本**: 1.1.0  
**更新日期**: 2025-11-13  
**图形支持**: PyPlot.jl  
**许可**: MIT License
