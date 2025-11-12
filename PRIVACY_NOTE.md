# 隐私信息说明

## 当前状态

✅ **v1.3.1及以后版本**：所有代码和文档中的隐私信息已移除
- 具体路径已替换为 `<PROJECT_ROOT>` 占位符
- 用户标识信息已清理
- 所有文档使用通用路径

## Git历史记录

⚠️ **重要提示**：本项目的git提交历史（v1.3.1之前）中可能包含原始开发路径和用户信息。

### 历史记录中的信息

git历史中可能包含：
- 原始文件路径
- 提交消息中的路径引用
- 早期版本的代码快照

### 建议

如果您需要：

1. **仅使用项目**：
   - 直接使用最新版本（v1.3.1+）
   - 所有当前文件已清理隐私信息
   - 无需担心git历史

2. **分享/发布项目**：
   - **选项A（推荐）**：仅打包源代码文件，不包含.git文件夹
     ```bash
     # 创建不含git历史的分发包
     zip -r 2FSK_System_v1.3.1.zip 2FSK_System/ -x "*.git*"
     ```
   
   - **选项B**：清理git历史（高级用户）
     ```bash
     # 使用git filter-repo清理历史（需先安装）
     # 警告：这会重写整个git历史！
     git filter-repo --replace-text replacements.txt
     ```

3. **完全清理历史**：
   - 使用 `git filter-repo` 工具
   - 或创建新的git仓库：
     ```bash
     # 删除旧的git历史
     rm -rf .git
     
     # 创建新的git仓库
     git init
     git add .
     git commit -m "Initial commit - v1.3.1 (privacy cleaned)"
     ```

## 文件分发建议

分享项目时推荐的方式：

### 方式1：ZIP压缩包（推荐）
```powershell
# PowerShell
Compress-Archive -Path "2FSK_System\*" -DestinationPath "2FSK_System_v1.3.1_clean.zip"
```

### 方式2：新的Git仓库
1. 复制项目到新文件夹
2. 删除 `.git` 文件夹
3. 初始化新仓库
4. 提交清理后的代码

### 方式3：GitHub Release
- 使用GitHub的Release功能
- 上传源代码ZIP（自动排除.git）
- 添加v1.3.1标签

## 已清理的占位符

项目中使用的占位符：

| 占位符 | 含义 | 示例替换 |
|--------|------|---------|
| `<PROJECT_ROOT>` | 项目根目录 | `D:/Projects/2FSK_System` |
| `<USER_ONEDRIVE>` | OneDrive文件夹 | `***REMOVED***