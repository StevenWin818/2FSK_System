"""
解调模块
功能：实现2FSK包络解调，包括带通滤波器(BPF)和包络检测
"""

module Demodulation

export envelope_demodulation, bandpass_filter, envelope_detector

using DSP
using Statistics

"""
带通滤波器设计
输入:
  - signal: 输入信号
  - center_freq: 中心频率 (Hz)
  - bandwidth: 带宽 (Hz)
  - fs: 采样频率 (Hz)
输出:
  - filtered_signal: 滤波后的信号
"""
function bandpass_filter(signal::Vector{Float64}, center_freq::Float64, 
                        bandwidth::Float64, fs::Float64)
    # 归一化频率
    nyquist = fs / 2
    low_freq = (center_freq - bandwidth/2) / nyquist
    high_freq = (center_freq + bandwidth/2) / nyquist
    
    # 确保频率在有效范围内，并保证low < high
    low_freq = max(0.01, min(0.95, low_freq))
    high_freq = max(low_freq + 0.01, min(0.99, high_freq))
    
    # 设计Butterworth带通滤波器
    responsetype = Bandpass(low_freq, high_freq, fs=1.0)
    designmethod = Butterworth(4)  # 4阶滤波器
    
    # 创建数字滤波器
    zpk_filter = digitalfilter(responsetype, designmethod)
    
    # 应用滤波器
    filtered_signal = filtfilt(zpk_filter, signal)
    
    return filtered_signal
end

"""
包络检测器
输入:
  - signal: 输入信号
  - fs: 采样频率（可选，用于低通滤波）
输出:
  - envelope: 包络信号
"""
function envelope_detector(signal::Vector{Float64}, fs::Float64=1.0)
    # 方法：平方律检测
    # 信号平方后包含直流分量（包络的平方）和高频分量
    squared = signal.^2
    
    # 使用移动平均提取直流分量（包络平方）
    # 关键：窗口大小不能超过码元长度，否则会混淆相邻码元
    # 对于21KBaud，码元周期 = 1/21000 = 47.6us
    # 对于840kHz采样率，每码元40个采样点
    # 窗口应该小于码元长度，取码元长度的1/4
    if fs > 1.0
        # 窗口大小：约10个采样点（约12us）
        # 这样可以平滑载波波动，但不会跨越码元边界
        window_size = max(3, Int(fs / 84000))  # 约载波周期
    else
        window_size = 3
    end
    
    # 移动平均滤波
    envelope_squared = similar(squared)
    half_window = window_size ÷ 2
    
    for i in 1:length(squared)
        start_idx = max(1, i - half_window)
        end_idx = min(length(squared), i + half_window)
        envelope_squared[i] = mean(squared[start_idx:end_idx])
    end
    
    # 开方得到包络
    envelope = sqrt.(abs.(envelope_squared))
    
    return envelope
end

"""
简单包络检测（整流+低通滤波）
输入:
  - signal: 输入信号
  - cutoff_freq: 低通滤波器截止频率 (Hz)
  - fs: 采样频率 (Hz)
输出:
  - envelope: 包络信号
"""
function simple_envelope_detector(signal::Vector{Float64}, cutoff_freq::Float64, fs::Float64)
    # 全波整流
    rectified = abs.(signal)
    
    # 低通滤波
    nyquist = fs / 2
    normalized_cutoff = cutoff_freq / nyquist
    normalized_cutoff = min(0.99, max(0.01, normalized_cutoff))
    
    # 设计低通滤波器
    responsetype = Lowpass(normalized_cutoff, fs=1.0)
    designmethod = Butterworth(4)
    lpf = digitalfilter(responsetype, designmethod)
    
    # 应用滤波器
    envelope = filtfilt(lpf, rectified)
    
    return envelope
end

"""
比特判决（简化版）
输入:
  - envelope0: 频率f0的包络
  - envelope1: 频率f1的包络
  - samples_per_symbol: 每个码元的采样点数
输出:
  - bits: 判决后的比特序列
"""
function bit_decision(envelope0::Vector{Float64}, envelope1::Vector{Float64}, 
                     samples_per_symbol::Int)
    n_symbols = Int(length(envelope0) / samples_per_symbol)
    bits = zeros(Int, n_symbols)
    
    for i in 1:n_symbols
        # 计算当前码元的采样范围
        start_idx = (i-1) * samples_per_symbol + 1
        end_idx = i * samples_per_symbol
        
        # 计算两个包络在当前码元周期内的平均能量
        energy0 = mean(envelope0[start_idx:end_idx].^2)
        energy1 = mean(envelope1[start_idx:end_idx].^2)
        
        # 判决：哪个包络能量大，就判为对应的比特
        # f0对应比特'0'，f1对应比特'1'
        # 所以：energy0大 → 判'0'，energy1大 → 判'1'
        bits[i] = energy1 > energy0 ? 1 : 0
    end
    
    return bits
end

"""
完整的2FSK包络解调
输入:
  - received_signal: 接收信号
  - f0: 载波频率0 (Hz)
  - f1: 载波频率1 (Hz)
  - symbol_rate: 码元速率 (Hz)
  - fs: 采样频率 (Hz)
输出:
  - demodulated_bits: 解调后的比特序列
"""
function envelope_demodulation(received_signal::Vector{Float64}, f0::Float64, 
                              f1::Float64, symbol_rate::Float64, fs::Float64)
    # 计算每个码元的采样点数
    samples_per_symbol = Int(fs / symbol_rate)
    n_symbols = Int(length(received_signal) / samples_per_symbol)
    bits = zeros(Int, n_symbols)
    
    # 方法：非相干包络解调
    # 生成本地载波用于混频
    t = (0:length(received_signal)-1) / fs
    carrier0 = cos.(2π * f0 * t)
    carrier1 = cos.(2π * f1 * t)
    
    # 对每个码元进行包络检测
    for i in 1:n_symbols
        start_idx = (i-1) * samples_per_symbol + 1
        end_idx = i * samples_per_symbol
        
        # 方法：平方律检波（能量检测）
        # 计算在当前码元周期内，与两个频率匹配的能量
        
        # 方法1: 直接能量检测（更简单可靠）
        # 与f0混频后的能量
        mixed0 = received_signal[start_idx:end_idx] .* carrier0[start_idx:end_idx]
        energy0 = sum(mixed0.^2)
        
        # 与f1混频后的能量  
        mixed1 = received_signal[start_idx:end_idx] .* carrier1[start_idx:end_idx]
        energy1 = sum(mixed1.^2)
        
        # 判决：哪个能量大，就判为对应的比特
        bits[i] = energy1 > energy0 ? 1 : 0
    end
    
    return bits
end

"""
相干解调（作为对比）
输入:
  - received_signal: 接收信号
  - f0: 载波频率0 (Hz)
  - f1: 载波频率1 (Hz)
  - symbol_rate: 码元速率 (Hz)
  - fs: 采样频率 (Hz)
输出:
  - demodulated_bits: 解调后的比特序列
"""
function coherent_demodulation(received_signal::Vector{Float64}, f0::Float64, 
                              f1::Float64, symbol_rate::Float64, fs::Float64)
    samples_per_symbol = Int(fs / symbol_rate)
    n_symbols = Int(length(received_signal) / samples_per_symbol)
    bits = zeros(Int, n_symbols)
    
    # 生成本地载波
    t = (0:length(received_signal)-1) / fs
    carrier0 = cos.(2π * f0 * t)
    carrier1 = cos.(2π * f1 * t)
    
    # 相乘并积分判决
    for i in 1:n_symbols
        start_idx = (i-1) * samples_per_symbol + 1
        end_idx = i * samples_per_symbol
        
        # 相关检测
        corr0 = sum(received_signal[start_idx:end_idx] .* carrier0[start_idx:end_idx])
        corr1 = sum(received_signal[start_idx:end_idx] .* carrier1[start_idx:end_idx])
        
        # 判决
        bits[i] = abs(corr1) > abs(corr0) ? 1 : 0
    end
    
    return bits
end

"""
打印解调信息
"""
function print_demodulation_info(received_signal::Vector{Float64}, f0::Float64, 
                                f1::Float64, fs::Float64)
    println("解调信息:")
    println("  接收信号长度: $(length(received_signal)) 采样点")
    println("  BPF中心频率: f0=$(f0/1000) kHz, f1=$(f1/1000) kHz")
    println("  采样频率: $(fs/1000) kHz")
end

end # module
