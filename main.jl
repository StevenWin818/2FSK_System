"""
main.jl - 2FSK调制解调系统主程序
使用PyPlot进行可视化（图形界面版本）
版本: v1.3.2
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
using Printf

# 尝试加载PyPlot
PLOTTING_AVAILABLE = false

try
    import PyPlot
    
    # 设置GUI后端（必须在第一次绘图前设置）
    try
        PyPlot.matplotlib.use("TkAgg")  # 尝试使用TkAgg
        println("✓ 使用 TkAgg 后端")
    catch
        try
            PyPlot.matplotlib.use("Qt5Agg")  # 尝试Qt5
            println("✓ 使用 Qt5Agg 后端")
        catch
            println("⚠ 无法设置GUI后端，将只保存PNG文件")
        end
    end
    
    # 关闭交互式模式，使用阻塞式显示
    PyPlot.ioff()  # 关闭交互式模式
    
    # 显式导入需要的函数为全局变量
    global figure = PyPlot.figure
    global subplot = PyPlot.subplot
    global plot = PyPlot.plot
    global stem = PyPlot.stem
    global semilogy = PyPlot.semilogy
    global title = PyPlot.title
    global xlabel = PyPlot.xlabel
    global ylabel = PyPlot.ylabel
    global legend = PyPlot.legend
    global grid = PyPlot.grid
    global ylim = PyPlot.ylim
    global xlim = PyPlot.xlim
    global tight_layout = PyPlot.tight_layout
    global savefig = PyPlot.savefig
    global show = PyPlot.show
    global gcf = PyPlot.gcf
    global axvline = PyPlot.axvline
    
    global PLOTTING_AVAILABLE = true
    println("✓ PyPlot图形库已加载")
catch e
    println("⚠ PyPlot未安装，将只生成数据文件")
    println("  安装命令: using Pkg; Pkg.add(\"PyPlot\")")
end

# ==================== 系统参数设置 ====================
# 获取脚本所在目录
SCRIPT_DIR = @__DIR__

# 控制台输出使用相对路径，避免暴露本机绝对目录
show_local_path(path::AbstractString) = try
    relpath(path, SCRIPT_DIR)
catch
    basename(path)
end

MESSAGE = "测试251113"
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

# ==================== 绘制波形图 ====================
if PLOTTING_AVAILABLE
    println("\n[步骤 6] 生成波形图...")
    
    try
        # 只显示前10个码元
        display_symbols = min(10, length(binary_data))
        display_samples = display_symbols * SAMPLES_PER_SYMBOL
        t_display = t[1:display_samples] * 1000  # 转换为毫秒
        
        # 创建3个子图
        figure(figsize=(12, 10))
        
        # 子图1: 调制信号
        subplot(3, 1, 1)
        plot(t_display, modulated_signal[1:display_samples], "b-", linewidth=0.8)
        title("2FSK调制信号（前$(display_symbols)个码元）", fontsize=12, fontproperties="SimHei")
        xlabel("时间 (ms)", fontsize=10, fontproperties="SimHei")
        ylabel("幅度", fontsize=10, fontproperties="SimHei")
        grid(true, alpha=0.3)
        
        # 子图2: 接收信号（含噪声）
        subplot(3, 1, 2)
        plot(t_display, received_signal[1:display_samples], "r-", linewidth=0.8, alpha=0.7)
        title("接收信号（SNR=$(SNR_TEST)dB）", fontsize=12, fontproperties="SimHei")
        xlabel("时间 (ms)", fontsize=10, fontproperties="SimHei")
        ylabel("幅度", fontsize=10, fontproperties="SimHei")
        grid(true, alpha=0.3)
        
        # 子图3: 比特序列对比
        subplot(3, 1, 3)
        bit_indices = 1:display_symbols
        # 原始比特
        stem(bit_indices, binary_data[bit_indices], linefmt="b-", markerfmt="bo", 
             basefmt=" ", label="原始比特")
        # 解调比特
        stem(bit_indices .+ 0.1, demodulated_data[bit_indices], linefmt="r--", 
             markerfmt="rx", basefmt=" ", label="解调比特")
        title("比特序列对比（前$(display_symbols)个比特）", fontsize=12, fontproperties="SimHei")
        xlabel("比特索引", fontsize=10, fontproperties="SimHei")
        ylabel("比特值", fontsize=10, fontproperties="SimHei")
        legend(loc="upper right", prop=Dict("family"=>"SimHei", "size"=>9))
        grid(true, alpha=0.3)
        ylim(-0.5, 1.5)
        
        tight_layout()
        
        # 保存图片
        output_path = joinpath(SCRIPT_DIR, "waveforms.png")
        savefig(output_path, dpi=150, bbox_inches="tight")
        println("  ✓ 波形图已保存: $(show_local_path(output_path))")
        println("  ✓ 图窗1已创建")
        
    catch e
        println("  ⚠ 生成波形图时出错: $e")
    end
end

# ==================== 误码率分析 ====================
println("\n[步骤 7] 误码率分析（不同SNR）...")
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

# ==================== 绘制BER曲线 ====================
if PLOTTING_AVAILABLE
    println("\n[步骤 8] 生成误码率曲线...")
    
    try
        figure(figsize=(10, 7))
        
        semilogy(snr_range, ber_simulated, "bo-", linewidth=2, markersize=8, 
                label="实测BER")
        semilogy(snr_range, ber_theoretical, "r^--", linewidth=2, markersize=8, 
                label="理论BER (非相干FSK)")
        
        title("2FSK系统误码率性能曲线", fontsize=14, fontproperties="SimHei", fontweight="bold")
        xlabel("信噪比 SNR (dB)", fontsize=12, fontproperties="SimHei")
        ylabel("误码率 BER", fontsize=12, fontproperties="SimHei")
        legend(loc="best", prop=Dict("family"=>"SimHei", "size"=>11))
        grid(true, which="both", alpha=0.3)
        ylim(1e-6, 1)
        
        output_path = joinpath(SCRIPT_DIR, "ber_curve.png")
        savefig(output_path, dpi=150, bbox_inches="tight")
        println("  ✓ BER曲线已保存: $(show_local_path(output_path))")
        println("  ✓ 图窗2已创建")
        
    catch e
        println("  ⚠ 生成BER曲线时出错: $e")
    end
end

# ==================== 频谱分析 ====================
println("\n[步骤 9] 频谱分析...")
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

# ==================== 绘制频谱图 ====================
if PLOTTING_AVAILABLE
    println("\n[步骤 10] 生成频谱图...")
    
    try
        # 只绘制感兴趣的频率范围 (0-200 kHz)
        freq_limit = 200e3
        freq_mask = positive_freqs .<= freq_limit
        
        figure(figsize=(10, 6))
        
        plot(positive_freqs[freq_mask] / 1000, magnitude[freq_mask], "b-", linewidth=1.5)
        
        # 标注载波频率
        axvline(x=F0/1000, color="r", linestyle="--", linewidth=2, label=@sprintf("f0 = %.0f kHz", F0/1000))
        axvline(x=F1/1000, color="g", linestyle="--", linewidth=2, label=@sprintf("f1 = %.0f kHz", F1/1000))
        
        title("2FSK调制信号频谱", fontsize=14, fontproperties="SimHei", fontweight="bold")
        xlabel("频率 (kHz)", fontsize=12, fontproperties="SimHei")
        ylabel("幅度", fontsize=12, fontproperties="SimHei")
        legend(loc="best", prop=Dict(raw"family"=>"SimHei", "size"=>11))
        grid(true, alpha=0.3)
        xlim(0, freq_limit/1000)
        
        output_path = joinpath(SCRIPT_DIR, "spectrum.png")
        savefig(output_path, dpi=150, bbox_inches="tight")
        println("  ✓ 频谱图已保存: $(show_local_path(output_path))")
        println("  ✓ 图窗3已创建")
        
    catch e
        println("  ⚠ 生成频谱图时出错: $e")
    end
end

# ==================== 保存数据 ====================
println("\n[步骤 11] 保存数据...")
try
    # 保存误码率数据
    ber_path = joinpath(SCRIPT_DIR, "ber_data.csv")
    open(ber_path, "w") do f
        println(f, "SNR_dB,Simulated_BER,Theoretical_BER")
        for (i, snr) in enumerate(snr_range)
            println(f, "$snr,$(ber_simulated[i]),$(ber_theoretical[i])")
        end
    end
    println("  ✓ BER数据已保存: $(show_local_path(ber_path))")
    
    # 保存频谱数据（部分）
    spectrum_path = joinpath(SCRIPT_DIR, "spectrum_data.csv")
    open(spectrum_path, "w") do f
        println(f, "Frequency_kHz,Magnitude")
        step = max(1, length(positive_freqs) ÷ 1000)
        for i in 1:step:length(positive_freqs)
            println(f, "$(positive_freqs[i]/1000),$(magnitude[i])")
        end
    end
    println("  ✓ 频谱数据已保存: $(show_local_path(spectrum_path))")
catch e
    println("  ⚠ 保存数据时出错: $e")
end

# ==================== 完成 ====================
println("\n" * "="^60)
println("程序运行完成！")
println("="^60)

if PLOTTING_AVAILABLE
    println("\n生成的文件:")
    println("  📊 图形文件:")
    println("    - waveforms.png: 调制/接收信号波形")
    println("    - ber_curve.png: 误码率曲线")
    println("    - spectrum.png: 频谱图")
    println("  📝 数据文件:")
    println("    - ber_data.csv: 误码率数据")
    println("    - spectrum_data.csv: 频谱数据")
    
    println("\n" * "="^60)
    println("  💡 正在显示交互式图窗...")
    println("     - 3个图窗将依次打开")
    println("     - 可以缩放、平移、保存图片")
    println("     - 关闭所有图窗后程序将退出")
    println("="^60)
    println()
    
    # 使用阻塞式显示，这样图窗会正常响应
    try
        show()  # 阻塞显示所有图窗，直到用户关闭
        println("\n所有图窗已关闭")
    catch e
        println("\n检测到中断: ", e)
    end
else
    println("\n说明:")
    println("  ⚠ PyPlot未安装，仅生成了数据文件")
    println("  数据文件:")
    println("    - ber_data.csv: 误码率数据")
    println("    - spectrum_data.csv: 频谱数据")
    println("\n  安装PyPlot以生成图形:")
    println("    using Pkg")
    println("    Pkg.add(\"PyPlot\")")
end
println("\n" * "="^60)
println("程序已退出")
