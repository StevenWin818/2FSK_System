# 2FSK调制解调系统

[![Version](https://img.shields.io/badge/version-1.3.2-blue.svg)](https://github.com/StevenWin818/2FSK_System)
[![Julia](https://img.shields.io/badge/Julia-1.6+-purple.svg)](https://julialang.org/)
[![License](https://img.shields.io/badge/license-MPL--2.0-orange.svg)](LICENSE)

> **✨ v1.3.2 更新**: 提供历史清理脚本、输出路径脱敏、文档全面对齐！
> **✨ v1.3.1 更新**: 移除所有隐私信息，使用通用路径占位符，项目更安全！

> **✨ v1.3.0 重大更新**: 交互式图窗功能完全可用，无冻结问题！

> **✨ v1.1.0 突破性更新**: 解调算法完全重写，系统从失败到成功的重大突破！误码率从70%降至0%，文本恢复率100%！

## 项目简介

基于Julia语言实现的2FSK（二进制频移键控）信号调制解调系统，在**MWORKS Syslab 2025b**环境中运行，包含完整的调制、信道仿真、解调和误码率分析功能。

## 系统特性

- ✨ **完整的2FSK通信系统**：调制、信道、解调全流程
- 📊 **误码率分析**：仿真与理论对比
- 🔧 **模块化设计**：易于理解和扩展
- 🎯 **支持中文**：可传输中文字符（UTF-16编码）
- 📈 **数据导出**：CSV格式，便于后续分析

## 系统参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 传输信息 | "测试251113" | 可自定义 |
| 码元速率 | 21 KBaud | 符号传输速率 |
| 载波频率 f0 | 84 kHz | 表示比特'0' (4×21kHz) |
| 载波频率 f1 | 42 kHz | 表示比特'1' (2×21kHz) |
| 采样频率 | 840 kHz | 10倍载波频率 |
| 信道类型 | AWGN | 加性高斯白噪声 |
| 默认SNR | 10 dB | 信噪比 |
| 解调方式 | 包络解调 | 非相干解调 |

## 项目结构

```
2FSK_System/
├── src/                    # 源代码模块
│   ├── modulation.jl       # 调制模块（文本↔二进制，2FSK调制）
│   ├── channel.jl          # 信道模块（AWGN噪声）
│   ├── demodulation.jl     # 解调模块（能量检测解调）
│   └── ber_analysis.jl     # 误码率分析模块
├── main.jl                 # 主程序（图形界面版本）
├── install_pyplot.jl       # PyPlot安装脚本
├── Project.toml            # 项目依赖配置
├── tools/privacy/          # Git历史清理辅助文件
├── docs/                   # 文档集合（除README外）
│   ├── CHANGELOG.md        # 版本更新日志
│   ├── PRIVACY_NOTE.md     # 隐私信息说明
│   └── QUICKSTART.md       # 快速开始与图形指南
├── README.md               # 项目文档（本文件）
├── LICENSE                 # Mozilla Public License 2.0
└── .gitignore              # Git忽略配置
```

## 快速开始

### 环境要求

- **MWORKS Syslab 2025b** 或更高版本（内置Julia 1.9.3）
- 依赖包：DSP, FFTW, SpecialFunctions, Statistics, PyPlot（自动安装）

### 路径配置

首次运行前请确认所有占位符已替换为实际环境信息：

- `<PROJECT_ROOT>`：项目根目录（例：`D:/Projects/2FSK_System`）
- `<USER_ONEDRIVE>`：OneDrive 文件夹名称
- `<USER>`：操作系统用户名

在 Julia REPL 中可通过以下方式完成配置：

```julia
PROJECT_ROOT = "D:/Projects/2FSK_System"  # 修改为你的真实路径
cd(PROJECT_ROOT)
```

Windows 支持 `"D:/..."` 与 `"D:\\..."` 两种写法。建议完成下列检查清单：

- [ ] `<PROJECT_ROOT>` 已更新为真实路径
- [ ] Julia 版本 ≥ 1.6，MWORKS Syslab 已安装
- [ ] `install_pyplot.jl` 成功运行
- [ ] `main.jl` 可无误执行

### 运行程序

**首次运行（安装PyPlot）**：
```julia
# 1. 切换到项目目录（请修改为您的实际路径）
cd("D:/Projects/2FSK_System")  # 修改此路径！

# 2. 安装PyPlot图形库（只需运行一次）
include("install_pyplot.jl")
```

**日常运行**：
```julia
# 切换到项目目录（请修改为您的实际路径）
cd("D:/Projects/2FSK_System")  # 修改此路径！

# 运行主程序
include("main.jl")
```

**输出文件**：
- 📊 **图形文件**：
  - `waveforms.png` - 调制/接收信号波形图
  - `ber_curve.png` - 误码率曲线图
  - `spectrum.png` - 频谱图
- 📝 **数据文件**：
  - `ber_data.csv` - 误码率数据
  - `spectrum_data.csv` - 频谱数据

### 备注

- 如果PyPlot安装困难，程序会自动降级为仅生成CSV数据文件
- **路径说明**：文档中的 `<PROJECT_ROOT>` 需要替换为您的实际项目路径

更多使用示例（含图形模式）可参见 `docs/QUICKSTART.md`。

## 功能模块

### 1. 调制模块 (modulation.jl)

- `text_to_binary(text)` - 文本转二进制（UTF-16编码）
- `binary_to_text(binary)` - 二进制转文本
- `fsk_modulate(bits, f0, f1, symbol_rate, fs)` - 2FSK调制

### 2. 信道模块 (channel.jl)

- `add_awgn_noise(signal, snr_db)` - 添加高斯白噪声
- `calculate_snr(signal, noisy_signal)` - 计算实际信噪比

### 3. 解调模块 (demodulation.jl)

- `bandpass_filter(signal, center_freq, bandwidth, fs)` - 带通滤波
- `envelope_detector(signal)` - 包络检测
- `envelope_demodulation(signal, f0, f1, symbol_rate, fs)` - 完整解调

### 4. 误码率分析模块 (ber_analysis.jl)

- `calculate_ber(original, demodulated)` - 计算误码率
- `theoretical_ber_2fsk(snr_db)` - 理论误码率
- `calculate_ber_vs_snr(...)` - 不同SNR下的误码率曲线

## 输出结果

### 控制台输出
- 系统参数汇总
- 各步骤执行信息
- 传输性能指标
- 误码率分析表格

### 文件输出（无Plots版本）
- `ber_data.csv` - 误码率数据
- `spectrum_data.csv` - 频谱数据

### 图像输出（图形版本）
- `waveforms.png` - 信号波形图
- `ber_curve.png` - 误码率曲线
- `spectrum.png` - 频谱图
- `ber_data.csv` - 误码率数据
- `spectrum_data.csv` - 频谱数据

![波形图示例](waveforms.png)

![误码率曲线示例](ber_curve.png)

![频谱图示例](spectrum.png)

## 理论基础

### 2FSK调制原理

2FSK使用两个不同频率的载波表示二进制信息：

$$s_0(t) = A \cos(2\pi f_0 t), \quad \text{比特'0'}$$
$$s_1(t) = A \cos(2\pi f_1 t), \quad \text{比特'1'}$$

### 包络解调过程

1. **带通滤波**：分离两个频率分量
2. **包络检测**：希尔伯特变换提取幅度
3. **判决**：能量比较恢复比特

### 理论误码率

非相干2FSK的理论误码率：

$$P_e = \frac{1}{2} \exp\left(-\frac{E_b}{2N_0}\right)$$

其中 $E_b/N_0$ 是每比特能量与噪声功率谱密度之比。

## 自定义参数

在 `main.jl` 中修改：

```julia
const MESSAGE = "你的消息"        # 传输内容
const SYMBOL_RATE = 21e3          # 码元速率
const SNR_TEST = 10.0             # 测试信噪比
snr_range = 0:2:14                # SNR分析范围
```

## 性能分析

在不同信噪比下的典型误码率：

| SNR (dB) | 理论BER | 仿真BER |
|----------|---------|---------|
| 0        | ~3.9e-1 | ~4.0e-1 |
| 4        | ~1.4e-1 | ~1.5e-1 |
| 8        | ~1.8e-2 | ~1.9e-2 |
| 12       | ~6.7e-4 | ~7.0e-4 |

## 常见问题

### Q: PyPlot安装失败？
**A**: 参考 `docs/QUICKSTART.md` 中的故障排除步骤，或暂时以CSV数据模式运行（程序会自动降级）。

### Q: 程序运行但没有生成图片？
**A**: PyPlot可能加载失败，程序会自动降级为仅生成CSV数据文件。检查控制台输出。

### Q: 如何修改载波频率？
**A**: 修改 `F0` 和 `F1` 参数，建议保持 f0=4×symbol_rate, f1=2×symbol_rate 的关系。

### Q: 如何增加测试数据量？
**A**: 修改 `test_length` 变量（默认10000）。

### Q: 如何使用无图形版本？
**A**: 不安装PyPlot即可触发降级模式，程序会自动跳过绘图并仅生成CSV数据文件。

## 版本历史

查看 [docs/CHANGELOG.md](docs/CHANGELOG.md) 了解详细更新历史。

### v1.0.0 (2025-11-13)
- 🎉 首次发布
- ✨ 完整的2FSK调制解调功能
- 📊 误码率分析和理论对比
- 🔧 支持MWORKS环境（无Plots版本）
- 📖 完整文档和使用说明

## 技术支持

### 文档
- [快速开始与图形指南](docs/QUICKSTART.md)
- [版本更新日志](docs/CHANGELOG.md)

### 问题反馈
如遇到问题，请提供：
1. Julia版本：`versioninfo()`
2. 错误信息完整截图
3. 使用的参数配置

## 贡献

欢迎贡献代码、报告问题或提出建议！

- 项目维护：[@StevenWin818](https://github.com/StevenWin818)

## 许可证

本项目采用 Mozilla Public License 2.0。详见 [LICENSE](LICENSE) 文件。

## 致谢

- Julia语言社区
- DSP.jl、FFTW.jl、Plots.jl 等开源项目
- MWORKS Syslab开发团队

