"""
install_pyplot.jl - PyPlot包安装脚本
在MWORKS环境中安装PyPlot图形库
"""

using Pkg

println("="^60)
println("PyPlot图形库安装脚本")
println("="^60)

# 激活项目环境
println("\n[1] 激活项目环境...")
Pkg.activate(".")
println("  ✓ 项目环境已激活")

# 检查PyPlot是否已安装
println("\n[2] 检查PyPlot状态...")
try
    using PyPlot
    println("  ✓ PyPlot已安装")
    
    # 测试PyPlot功能
    println("\n[3] 测试PyPlot功能...")
    try
        figure()
        x = 0:0.1:2π
        plot(x, sin.(x))
        title("Test Plot")
        savefig("test_plot.png")
        close()
        println("  ✓ PyPlot工作正常")
        println("  ✓ 测试图已保存: test_plot.png")
        
        # 删除测试图
        rm("test_plot.png", force=true)
    catch e
        println("  ⚠ PyPlot功能测试失败: $e")
    end
catch
    println("  ⚠ PyPlot未安装，开始安装...")
    
    println("\n[3] 安装PyPlot...")
    try
        Pkg.add("PyPlot")
        println("  ✓ PyPlot安装成功")
        
        # 预编译
        println("\n[4] 预编译PyPlot...")
        Pkg.precompile()
        println("  ✓ 预编译完成")
        
        # 测试安装
        println("\n[5] 测试安装...")
        using PyPlot
        figure()
        x = 0:0.1:2π
        plot(x, sin.(x))
        title("Test Plot")
        savefig("test_plot.png")
        close()
        println("  ✓ PyPlot安装验证成功")
        println("  ✓ 测试图已保存: test_plot.png")
        
        # 删除测试图
        rm("test_plot.png", force=true)
        
    catch e
        println("  ✗ PyPlot安装失败: $e")
        println("\n可能的解决方案:")
        println("  1. 确保已安装Python和matplotlib")
        println("  2. 在MWORKS中手动安装:")
        println("     ENV[\"PYTHON\"] = \"\"  # 使用Conda.jl")
        println("     Pkg.add(\"PyCall\")")
        println("     Pkg.build(\"PyCall\")")
        println("     Pkg.add(\"PyPlot\")")
        return
    end
end

println("\n" * "="^60)
println("PyPlot安装完成！")
println("="^60)
println("\n现在可以运行图形版本的程序:")
println("  include(\"main_gui.jl\")")
println("="^60)
