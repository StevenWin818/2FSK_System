# 项目设置说明

## 路径配置

本项目使用通用路径占位符，使用前请替换为您的实际路径：

- `<PROJECT_ROOT>` - 替换为项目根目录的完整路径
- `<USER_ONEDRIVE>` - 替换为您的OneDrive文件夹名称
- `<USER>` - 替换为您的用户名

### 示例

如果您的项目位于：`D:/MyProjects/2FSK_System`

则将所有 `<PROJECT_ROOT>` 替换为：`D:/MyProjects`

### 快速设置

在MWORKS Julia REPL中：

```julia
# 设置项目根目录（请根据实际情况修改）
PROJECT_ROOT = "D:/MyProjects/2FSK_System"  # 修改此路径

# 切换到项目目录
cd(PROJECT_ROOT)

# 运行程序
include("main.jl")
```

### Windows路径格式

Julia支持两种路径格式：
- 正斜杠：`"D:/MyProjects/2FSK_System"`（推荐）
- 反斜杠（需转义）：`"D:\\MyProjects\\2FSK_System"`

## Git历史记录

注意：本项目的git提交历史中可能仍包含原始开发路径。如果需要完全清除历史中的路径信息，请使用git filter-repo工具。

## 首次运行检查清单

- [ ] 将所有 `<PROJECT_ROOT>` 替换为实际项目路径
- [ ] 确认Julia版本 ≥ 1.6
- [ ] 确认MWORKS Syslab已安装
- [ ] 运行 `install_pyplot.jl` 安装依赖包
- [ ] 运行 `main.jl` 测试系统
