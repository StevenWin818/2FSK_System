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
    
    # 确保频率在有效范围内
    low_freq = max(0.01, min(0.99, low_freq))
    high_freq = max(0.01, min(0.99, high_freq))
    
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
输出:
  - envelope: 包络信号
"""
function envelope_detector(signal::Vector{Float64})
    # 方法1：希尔伯特变换法
    # 计算解析信号，其幅度即为包络
    analytic_signal = hilbert(signal)
    envelope = abs.(analytic_signal)
    
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
比特判决
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
    
    # 滤波器带宽（根据码元速率设置）
    # 带宽约为码元速率的2倍（考虑主瓣）
    bandwidth = 2 * symbol_rate
    
    # 步骤1: 通过两个带通滤波器分离两个频率分量
    signal_f0 = bandpass_filter(received_signal, f0, bandwidth, fs)
    signal_f1 = bandpass_filter(received_signal, f1, bandwidth, fs)
    
    # 步骤2: 包络检测
    envelope0 = envelope_detector(signal_f0)
    envelope1 = envelope_detector(signal_f1)
    
    # 步骤3: 比特判决
    demodulated_bits = bit_decision(envelope0, envelope1, samples_per_symbol)
    
    return demodulated_bits
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
