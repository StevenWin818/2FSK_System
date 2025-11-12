"""
2FSK调制模块
功能：实现2FSK信号的调制和文本-二进制转换
"""

module Modulation

export text_to_binary, binary_to_text, fsk_modulate

using Printf

"""
将文本转换为二进制序列
输入: text - 字符串
输出: binary_array - 二进制数组 (0和1)
"""
function text_to_binary(text::String)
    binary_str = ""
    for char in text
        # 获取字符的Unicode编码
        code = Int(char)
        # 转换为16位二进制（支持中文等Unicode字符）
        binary_str *= string(code, base=2, pad=16)
    end
    # 转换为数组
    return [parse(Int, bit) for bit in binary_str]
end

"""
将二进制序列转换回文本
输入: binary_array - 二进制数组
输出: text - 恢复的字符串
"""
function binary_to_text(binary_array::Vector{Int})
    # 确保长度是16的倍数
    n_chars = length(binary_array) ÷ 16
    text = ""
    
    for i in 1:n_chars
        # 提取16位
        start_idx = (i-1) * 16 + 1
        end_idx = i * 16
        binary_chunk = binary_array[start_idx:end_idx]
        
        # 转换为字符
        binary_str = join(string.(binary_chunk))
        code = parse(Int, binary_str, base=2)
        text *= Char(code)
    end
    
    return text
end

"""
2FSK调制
输入:
  - binary_data: 二进制数组 [0, 1, 0, 1, ...]
  - f0: 载波频率0 (Hz) - 表示比特'0'
  - f1: 载波频率1 (Hz) - 表示比特'1'
  - symbol_rate: 码元速率 (Hz)
  - fs: 采样频率 (Hz)
输出:
  - t: 时间轴
  - signal: 调制后的信号
"""
function fsk_modulate(binary_data::Vector{Int}, f0::Float64, f1::Float64, 
                     symbol_rate::Float64, fs::Float64)
    # 每个码元的采样点数
    samples_per_symbol = Int(fs / symbol_rate)
    
    # 总采样点数
    total_samples = length(binary_data) * samples_per_symbol
    
    # 时间轴
    t = (0:total_samples-1) / fs
    
    # 初始化信号
    signal = zeros(Float64, total_samples)
    
    # 对每个比特进行调制
    for (i, bit) in enumerate(binary_data)
        # 当前比特的时间范围
        start_idx = (i-1) * samples_per_symbol + 1
        end_idx = i * samples_per_symbol
        t_symbol = t[start_idx:end_idx]
        
        # 根据比特值选择载波频率
        freq = bit == 0 ? f0 : f1
        
        # 生成载波信号
        signal[start_idx:end_idx] = cos.(2π * freq * t_symbol)
    end
    
    return t, signal
end

"""
打印调制信息（调试用）
"""
function print_modulation_info(binary_data::Vector{Int}, f0::Float64, f1::Float64)
    println("调制信息:")
    println("  二进制序列长度: $(length(binary_data))")
    println("  载波频率 f0 (比特0): $(f0/1000) kHz")
    println("  载波频率 f1 (比特1): $(f1/1000) kHz")
    
    # 统计0和1的数量
    n_zeros = sum(binary_data .== 0)
    n_ones = sum(binary_data .== 1)
    println("  比特0数量: $n_zeros")
    println("  比特1数量: $n_ones")
end

end # module
