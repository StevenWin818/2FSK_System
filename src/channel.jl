"""
信道模块
功能：实现高斯白噪声信道
"""

module Channel

export add_awgn_noise

using Random
using Statistics
using FFTW

"""
添加加性高斯白噪声 (AWGN)
输入:
  - signal: 输入信号
  - snr_db: 信噪比 (dB)
输出:
  - noisy_signal: 加噪后的信号
"""
function add_awgn_noise(signal::Vector{Float64}, snr_db::Float64)
    # 计算信号功率
    signal_power = mean(signal.^2)
    
    # 根据信噪比计算噪声功率
    # SNR (dB) = 10 * log10(P_signal / P_noise)
    # P_noise = P_signal / 10^(SNR_dB / 10)
    snr_linear = 10^(snr_db / 10)
    noise_power = signal_power / snr_linear
    
    # 生成高斯白噪声
    # 标准差 = sqrt(noise_power)
    noise_std = sqrt(noise_power)
    noise = randn(length(signal)) * noise_std
    
    # 添加噪声
    noisy_signal = signal + noise
    
    return noisy_signal
end

"""
计算信号的信噪比
输入:
  - signal: 原始信号
  - noisy_signal: 加噪信号
输出:
  - snr_db: 实际信噪比 (dB)
"""
function calculate_snr(signal::Vector{Float64}, noisy_signal::Vector{Float64})
    signal_power = mean(signal.^2)
    noise = noisy_signal - signal
    noise_power = mean(noise.^2)
    
    if noise_power == 0
        return Inf
    end
    
    snr_linear = signal_power / noise_power
    snr_db = 10 * log10(snr_linear)
    
    return snr_db
end

"""
生成带限高斯白噪声
输入:
  - signal_length: 噪声长度
  - noise_power: 噪声功率
  - bandwidth: 带宽 (Hz)
  - fs: 采样频率 (Hz)
输出:
  - noise: 带限高斯白噪声
"""
function generate_bandlimited_noise(signal_length::Int, noise_power::Float64, 
                                   bandwidth::Float64, fs::Float64)
    # 生成白噪声
    noise = randn(signal_length) * sqrt(noise_power)
    
    # 频域滤波
    N = length(noise)
    fft_noise = fft(noise)
    freqs = fftfreq(N, fs)
    
    # 创建带通滤波器
    filter_mask = abs.(freqs) .<= bandwidth/2
    fft_noise .*= filter_mask
    
    # 逆变换回时域
    filtered_noise = real.(ifft(fft_noise))
    
    # 调整功率
    actual_power = mean(filtered_noise.^2)
    if actual_power > 0
        filtered_noise *= sqrt(noise_power / actual_power)
    end
    
    return filtered_noise
end

"""
添加脉冲噪声
输入:
  - signal: 输入信号
  - impulse_prob: 脉冲噪声出现的概率
  - impulse_amplitude: 脉冲幅度
输出:
  - noisy_signal: 加噪后的信号
"""
function add_impulse_noise(signal::Vector{Float64}, impulse_prob::Float64, 
                          impulse_amplitude::Float64)
    noisy_signal = copy(signal)
    
    for i in 1:length(signal)
        if rand() < impulse_prob
            # 添加正或负脉冲
            noisy_signal[i] += rand([-1, 1]) * impulse_amplitude
        end
    end
    
    return noisy_signal
end

"""
打印信道信息
"""
function print_channel_info(signal::Vector{Float64}, noisy_signal::Vector{Float64})
    signal_power = mean(signal.^2)
    noise = noisy_signal - signal
    noise_power = mean(noise.^2)
    snr_db = 10 * log10(signal_power / noise_power)
    
    println("信道信息:")
    println("  信号功率: $(round(signal_power, digits=6))")
    println("  噪声功率: $(round(noise_power, digits=6))")
    println("  实际SNR: $(round(snr_db, digits=2)) dB")
end

end # module
