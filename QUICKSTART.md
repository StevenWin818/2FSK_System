# 2FSK调制解调系统 - 快速开始指南

## 系统要求

- **MWORKS Syslab 2025b** 或更高版本
- 内置Julia 1.6+
- 必需的Julia包（会自动安装）：
  - DSP.jl
  - FFTW.jl
  - SpecialFunctions.jl

## 快速运行

### 方法1: 使用批处理脚本（推荐）

```batch
.\run.bat
```

### 方法2: 手动运行

```batch
# 1. 安装依赖
"C:\Program Files\MWORKS\Syslab 2025b\julia\bin\julia.exe" --project=. -e "using Pkg; Pkg.instantiate()"

# 2. 运行主程序
"C:\Program Files\MWORKS\Syslab 2025b\julia\bin\julia.exe" --project=. main.jl
```

### 方法3: 在Julia REPL中运行

```julia
# 启动Julia并激活项目
# julia --project=.

# 运行主程序
include("main.jl")
```

## 系统参数

- **传输信息**: "测试624438"
- **码元速率**: 21 KBaud
- **载波频率**:
  - f0 = 84 kHz（表示比特'0'）
  - f1 = 42 kHz（表示比特'1'）
- **采样频率**: 840 kHz
- **信道**: 加性高斯白噪声（AWGN）
- **默认SNR**: 10 dB
- **解调方式**: 非相干包络解调（含BPF）

## 输出文件

运行完成后，会在当前目录生成：

1. **ber_data.csv** - 误码率分析数据
   - 列：SNR_dB, Simulated_BER, Theoretical_BER
   
2. **spectrum_data.csv** - 频谱分析数据
   - 列：Frequency_kHz, Magnitude

## 使用示例

### 示例1: 基本运行

```batch
.\run.bat
```

程序会自动：
- 将文本"测试624438"转换为二进制
- 进行2FSK调制
- 通过AWGN信道（SNR=10dB）
- 包络解调
- 恢复文本
- 分析不同SNR下的误码率
- 生成频谱分析
- 保存数据到CSV

### 示例2: 在Excel中绘制BER曲线

1. 打开 `ber_data.csv`
2. 选择SNR_dB列作为X轴
3. 选择Simulated_BER和Theoretical_BER作为Y轴
4. 插入散点图，设置Y轴为对数刻度

### 示例3: 修改传输信息

编辑 `main.jl` 第15行：

```julia
const MESSAGE = "您的信息"  # 修改这里
```

然后重新运行程序。

### 示例4: 修改信噪比

编辑 `main.jl` 第19行：

```julia
const SNR_TEST = 15.0  # 修改SNR值（单位：dB）
```

## 理论公式

### 2FSK非相干解调的理论误码率

$$P_e = \frac{1}{2} \exp\left(-\frac{E_b}{2N_0}\right)$$

其中：
- $E_b/N_0$ 是每比特能量与噪声功率谱密度之比
- 对于等能量信号，$E_b/N_0 \approx \text{SNR}$

## 预期结果

### 单次传输（SNR=10dB）
- 误码率：约0.003-0.007（0.3%-0.7%）
- 文本恢复：通常能完全正确恢复

### BER曲线
- SNR越高，误码率越低（指数下降）
- 仿真BER与理论BER应该非常接近
- 在高SNR时（>10dB），相对误差应小于10%

### 频谱分析
- 应该能检测到42kHz和84kHz的峰值
- 峰值对应两个载波频率

## 故障排除

### 问题1: 找不到Julia

**错误**: `找不到MWORKS Julia`

**解决方案**: 
- 检查MWORKS Syslab 2025b是否已安装
- 或修改 `run.bat` 中的 `JULIA_PATH` 为正确路径

### 问题2: 依赖包安装失败

**错误**: `LoadError: ArgumentError: Package XXX not found`

**解决方案**:
```julia
# 手动安装依赖
using Pkg
Pkg.add(["DSP", "FFTW", "SpecialFunctions"])
```

### 问题3: 误码率很高

**原因**: 
- SNR设置过低
- 信道噪声太大

**解决方案**:
- 增加SNR值（建议>8dB）
- 检查信道参数设置

### 问题4: 无法恢复文本

**可能原因**:
- 误码数太多
- SNR太低

**解决方案**:
- 使用更高的SNR
- 增加纠错码（未来版本）

## 性能指标

| SNR (dB) | 理论BER | 预期仿真BER | 文本恢复 |
|----------|---------|-------------|----------|
| 0        | 0.303   | ~0.30       | ✗        |
| 4        | 0.135   | ~0.13       | ✗        |
| 8        | 0.018   | ~0.02       | △        |
| 10       | 0.0067  | ~0.007      | ✓        |
| 12       | 0.0025  | ~0.003      | ✓        |
| 14       | 0.0009  | ~0.001      | ✓        |

## 下一步

- 📖 阅读 [README.md](README.md) 了解详细文档
- 📝 查看 [CHANGELOG.md](CHANGELOG.md) 了解版本历史
- 🔧 修改参数进行实验
- 📊 使用Excel分析CSV数据

## 技术支持

如有问题，请检查：
1. MWORKS安装是否完整
2. Julia版本是否>=1.6
3. 依赖包是否成功安装
4. 查看详细文档 README.md

---

**版本**: 1.0.0  
**最后更新**: 2025-11-13  
**许可证**: MIT
