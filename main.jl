"""
main.jl - 2FSK调制解调系统主程序
适用于MWORKS环境的轻量版本（无Plots依赖）
"""

# 避免重复加载模块的警告
if !@isdefined(Modulation)
    include("src/modulation.jl")
    include("src/channel.jl")
    include("src/demodulation.jl")
    include("src/ber_analysis.jl")
end

using .Modulation
using .Channel
using .Demodulation
using .BERAnalysis
using Statistics
using FFTW

# ==================== 系统参数设置 ====================
MESSAGE = "测试624438"
SYMBOL_RATE = 21e3
F0 = 4 * SYMBOL_RATE
F1 = 2 * SYMBOL_RATE
FS = 10 * F0
SNR_TEST = 10.0
SAMPLES_PER_SYMBOL = Int(FS / SYMBOL_RATE)

println("="^60)
println("2FSK调制解调系统")
println("="^60)
println("\n系统参数：")
println("  传输信息: $MESSAGE")
println("  码元速率: $(SYMBOL_RATE/1000) KBaud")
println("  载波频率 f0 (表示'0'): $(F0/1000) kHz")
println("  载波频率 f1 (表示'1'): $(F1/1000) kHz")
println("  采样频率: $(FS/1000) kHz")
println("  每码元采样点数: $SAMPLES_PER_SYMBOL")
println("  测试信噪比: $SNR_TEST dB")
println("="^60)

# ==================== 单次传输测试 ====================
println("\n[步骤 1] 文本转二进制...")
binary_data = Modulation.text_to_binary(MESSAGE)
println("  原始信息: $MESSAGE")
println("  二进制序列长度: $(length(binary_data)) bits")
n_zeros = sum(binary_data .== 0)
n_ones = sum(binary_data .== 1)
println("  比特分布: 0=$(n_zeros), 1=$(n_ones)")

println("\n[步骤 2] 2FSK调制...")
t, modulated_signal = Modulation.fsk_modulate(binary_data, F0, F1, SYMBOL_RATE, FS)
println("  调制信号长度: $(length(modulated_signal)) 采样点")
println("  信号时长: $(length(t)/FS) 秒")

println("\n[步骤 3] 通过信道（添加噪声 SNR=$(SNR_TEST)dB）...")
received_signal = Channel.add_awgn_noise(modulated_signal, SNR_TEST)
signal_power = mean(modulated_signal.^2)
noise_power = mean((received_signal - modulated_signal).^2)
actual_snr = 10 * log10(signal_power / noise_power)
println("  实际信噪比: $(round(actual_snr, digits=2)) dB")

println("\n[步骤 4] 包络解调...")
# 计算滤波器参数用于显示
freq_separation = abs(F1 - F0)
bandwidth_used = min(1.2 * SYMBOL_RATE, freq_separation * 0.6)
println("  频率间隔: $(freq_separation/1000) kHz")
println("  BPF带宽: $(bandwidth_used/1000) kHz")
println("  BPF1中心: $(F0/1000) kHz, 范围: $((F0-bandwidth_used/2)/1000)-$((F0+bandwidth_used/2)/1000) kHz")
println("  BPF2中心: $(F1/1000) kHz, 范围: $((F1-bandwidth_used/2)/1000)-$((F1+bandwidth_used/2)/1000) kHz")
demodulated_data = Demodulation.envelope_demodulation(received_signal, F0, F1, SYMBOL_RATE, FS)
println("  解调序列长度: $(length(demodulated_data)) bits")

println("\n[步骤 5] 恢复文本...")
recovered_text = Modulation.binary_to_text(demodulated_data)
println("  恢复的信息: $recovered_text")

# 显示解调比特分布
demod_zeros = sum(demodulated_data .== 0)
demod_ones = sum(demodulated_data .== 1)
println("  解调比特分布: 0=$(demod_zeros), 1=$(demod_ones)")

# 计算误码率
errors = sum(binary_data .!= demodulated_data)
ber = errors / length(binary_data)
println("\n[结果] 传输性能：")
println("  误码数: $errors")
println("  误码率: $(round(ber, digits=6))")
println("  传输准确: $(recovered_text == MESSAGE ? "✓ 成功" : "✗ 失败")")

# ==================== 误码率分析 ====================
println("\n[步骤 6] 误码率分析（不同SNR）...")
println("  生成测试序列...")

test_length = 10000
test_binary = rand(0:1, test_length)

println("  调制测试序列...")
t_test, test_modulated = Modulation.fsk_modulate(test_binary, F0, F1, SYMBOL_RATE, FS)

snr_range = 0:2:14
println("  测试SNR范围: $(snr_range) dB")

ber_simulated, ber_theoretical = BERAnalysis.calculate_ber_vs_snr(
    test_binary, test_modulated, snr_range, F0, F1, SYMBOL_RATE, FS
)

println("\n  " * "="^60)
println("  误码率分析结果")
println("  " * "="^60)
println("  SNR (dB)  |  实测BER      |  理论BER      |  相对误差")
println("  " * "-"^60)
for (i, snr) in enumerate(snr_range)
    rel_error = abs(ber_simulated[i] - ber_theoretical[i]) / (ber_theoretical[i] + 1e-10) * 100
    @printf("  %8.1f | %13.6e | %13.6e | %9.2f%%\n", 
            snr, ber_simulated[i], ber_theoretical[i], rel_error)
end
println("  " * "="^60)

# ==================== 频谱分析 ====================
println("\n[步骤 7] 频谱分析...")
N = length(modulated_signal)
fft_result = fft(modulated_signal)
freqs = fftfreq(N, FS)

positive_freqs = freqs[1:N÷2]
magnitude = abs.(fft_result[1:N÷2]) / N

# 找到峰值频率
peak_indices = findall(magnitude .> maximum(magnitude) * 0.5)
if !isempty(peak_indices)
    println("  检测到的主要频率成分:")
    for idx in peak_indices[1:min(5, length(peak_indices))]
        freq = positive_freqs[idx]
        if freq > 1000
            println("    $(round(freq/1000, digits=2)) kHz (幅度: $(round(magnitude[idx], digits=4)))")
        end
    end
end

# 保存数据到CSV文件
println("\n[步骤 8] 保存数据...")
try
    # 保存误码率数据
    open("ber_data.csv", "w") do f
        println(f, "SNR_dB,Simulated_BER,Theoretical_BER")
        for (i, snr) in enumerate(snr_range)
            println(f, "$snr,$(ber_simulated[i]),$(ber_theoretical[i])")
        end
    end
    println("  ✓ BER数据已保存: ber_data.csv")
    
    # 保存频谱数据（部分）
    open("spectrum_data.csv", "w") do f
        println(f, "Frequency_kHz,Magnitude")
        step = max(1, length(positive_freqs) ÷ 1000)
        for i in 1:step:length(positive_freqs)
            println(f, "$(positive_freqs[i]/1000),$(magnitude[i])")
        end
    end
    println("  ✓ 频谱数据已保存: spectrum_data.csv")
catch e
    println("  ⚠ 保存数据时出错: $e")
end

# ==================== 完成 ====================
println("\n" * "="^60)
println("程序运行完成！")
println("="^60)
println("\n说明:")
println("  数据已保存到CSV文件:")
println("    - ber_data.csv: 误码率数据")
println("    - spectrum_data.csv: 频谱数据")
println("  您可以使用Excel或其他工具打开这些文件绘制图表")
println("="^60)
