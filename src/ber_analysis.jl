"""
误码率分析模块
功能：计算误码率、理论误码率公式、绘制BER曲线
"""

module BERAnalysis

export calculate_ber, theoretical_ber_2fsk, calculate_ber_vs_snr

using Statistics
using Printf
using SpecialFunctions
using Random

include("channel.jl")
include("demodulation.jl")
include("modulation.jl")
using .Channel
using .Demodulation
using .Modulation

"""
计算误码率
输入:
  - original_bits: 原始比特序列
  - demodulated_bits: 解调后的比特序列
输出:
  - ber: 误码率
  - n_errors: 错误比特数
"""
function calculate_ber(original_bits::Vector{Int}, demodulated_bits::Vector{Int})
    # 确保长度相同
    min_length = min(length(original_bits), length(demodulated_bits))
    
    # 计算错误比特数
    n_errors = sum(original_bits[1:min_length] .!= demodulated_bits[1:min_length])
    
    # 计算误码率
    ber = n_errors / min_length
    
    return ber, n_errors
end

"""
2FSK非相干解调的理论误码率
输入:
  - snr_db: 信噪比 (dB)
输出:
  - ber: 理论误码率
  
理论公式：Pe = 0.5 * exp(-0.5 * Eb/N0)
其中 Eb/N0 = SNR (对于等能量信号)
"""
function theoretical_ber_2fsk(snr_db::Float64)
    # 将SNR从dB转换为线性值
    snr_linear = 10^(snr_db / 10)
    
    # 对于2FSK非相干解调
    # Pe = 0.5 * exp(-Eb/(2*N0))
    # 当信号能量相等时，Eb/N0 近似等于SNR
    ber = 0.5 * exp(-0.5 * snr_linear)
    
    return ber
end

"""
2FSK相干解调的理论误码率
输入:
  - snr_db: 信噪比 (dB)
输出:
  - ber: 理论误码率
  
理论公式：Pe = Q(sqrt(Eb/N0))
其中 Q(x) = 0.5 * erfc(x/sqrt(2))
"""
function theoretical_ber_2fsk_coherent(snr_db::Float64)
    snr_linear = 10^(snr_db / 10)
    
    # Q函数
    q_arg = sqrt(snr_linear)
    ber = 0.5 * erfc(q_arg / sqrt(2))
    
    return ber
end

"""
计算不同SNR下的误码率曲线
输入:
  - original_bits: 原始比特序列
  - modulated_signal: 调制信号
  - snr_range: SNR范围 (dB)
  - f0, f1: 载波频率
  - symbol_rate: 码元速率
  - fs: 采样频率
输出:
  - ber_simulated: 仿真误码率数组
  - ber_theoretical: 理论误码率数组
"""
function calculate_ber_vs_snr(original_bits::Vector{Int}, 
                              modulated_signal::Vector{Float64},
                              snr_range::Union{Vector{Float64}, StepRange},
                              f0::Float64, f1::Float64,
                              symbol_rate::Float64, fs::Float64)
    n_snr = length(snr_range)
    ber_simulated = zeros(Float64, n_snr)
    ber_theoretical = zeros(Float64, n_snr)
    
    println("\n开始误码率分析...")
    for (i, snr) in enumerate(snr_range)
        print("  处理 SNR = $(snr) dB ... ")
        
        # 添加噪声（转换为Float64）
        noisy_signal = add_awgn_noise(modulated_signal, Float64(snr))
        
        # 解调
        demodulated_bits = envelope_demodulation(noisy_signal, f0, f1, symbol_rate, fs)
        
        # 计算误码率
        ber_sim, n_errors = calculate_ber(original_bits, demodulated_bits)
        ber_simulated[i] = ber_sim
        
        # 理论误码率（转换为Float64）
        ber_theoretical[i] = theoretical_ber_2fsk(Float64(snr))
        
        println("完成 (BER = $(round(ber_sim, digits=6)), 误码数 = $n_errors)")
    end
    
    return ber_simulated, ber_theoretical
end

"""
计算Eb/N0与SNR的关系
输入:
  - snr_db: 信噪比 (dB)
  - symbol_rate: 码元速率 (Hz)
  - bandwidth: 信号带宽 (Hz)
输出:
  - eb_n0_db: Eb/N0 (dB)
"""
function snr_to_eb_n0(snr_db::Float64, symbol_rate::Float64, bandwidth::Float64)
    # Eb/N0 = SNR * (Bandwidth / Symbol_rate)
    eb_n0_linear = 10^(snr_db/10) * (bandwidth / symbol_rate)
    eb_n0_db = 10 * log10(eb_n0_linear)
    return eb_n0_db
end

"""
蒙特卡洛误码率仿真
输入:
  - n_bits: 测试比特数
  - snr_db: 信噪比 (dB)
  - f0, f1: 载波频率
  - symbol_rate: 码元速率
  - fs: 采样频率
  - n_trials: 蒙特卡洛试验次数
输出:
  - ber: 平均误码率
  - ber_std: 误码率标准差
"""
function monte_carlo_ber(n_bits::Int, snr_db::Float64,
                        f0::Float64, f1::Float64,
                        symbol_rate::Float64, fs::Float64,
                        n_trials::Int=100)
    bers = zeros(Float64, n_trials)
    
    for trial in 1:n_trials
        # 生成随机比特
        bits = rand(0:1, n_bits)
        
        # 调制
        _, modulated = fsk_modulate(bits, f0, f1, symbol_rate, fs)
        
        # 添加噪声
        noisy = add_awgn_noise(modulated, snr_db)
        
        # 解调
        demod_bits = envelope_demodulation(noisy, f0, f1, symbol_rate, fs)
        
        # 计算误码率
        bers[trial], _ = calculate_ber(bits, demod_bits)
    end
    
    return mean(bers), std(bers)
end

"""
打印误码率分析结果
"""
function print_ber_analysis(snr_range, ber_simulated, ber_theoretical)
    println("\n误码率分析结果:")
    println("="^60)
    println(@sprintf("%-10s | %-15s | %-15s | %-10s", "SNR(dB)", "仿真BER", "理论BER", "相对误差"))
    println("-"^60)
    
    for (i, snr) in enumerate(snr_range)
        rel_error = abs(ber_simulated[i] - ber_theoretical[i]) / ber_theoretical[i] * 100
        println(@sprintf("%-10.1f | %-15.6e | %-15.6e | %-9.2f%%", 
                snr, ber_simulated[i], ber_theoretical[i], rel_error))
    end
    
    println("="^60)
end

"""
计算信道容量
输入:
  - snr_db: 信噪比 (dB)
  - bandwidth: 带宽 (Hz)
输出:
  - capacity: 信道容量 (bits/s)
"""
function channel_capacity(snr_db::Float64, bandwidth::Float64)
    snr_linear = 10^(snr_db / 10)
    capacity = bandwidth * log2(1 + snr_linear)
    return capacity
end

"""
计算频谱效率
输入:
  - data_rate: 数据速率 (bits/s)
  - bandwidth: 带宽 (Hz)
输出:
  - efficiency: 频谱效率 (bits/s/Hz)
"""
function spectral_efficiency(data_rate::Float64, bandwidth::Float64)
    efficiency = data_rate / bandwidth
    return efficiency
end

end # module
