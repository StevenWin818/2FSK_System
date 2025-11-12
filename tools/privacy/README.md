# Git 历史清理指南

本目录包含用于移除历史提交中敏感路径的辅助文件。

## 所需工具
- Git ≥ 2.30
- Python ≥ 3.8（用于安装 `git-filter-repo`）

## 安装 `git-filter-repo`
```powershell
pip install git-filter-repo
```

若系统使用的是 Microsoft Store 安装的 Python，请改用：
```powershell
py -m pip install git-filter-repo
```

验证安装：
```powershell
git filter-repo --help
```

## 执行清理
在项目根目录运行：
```powershell
cd "<PROJECT_ROOT>\2FSK_System"
git filter-repo --replace-text tools/privacy/replacements.txt
```

> ⚠️ **注意**：该操作会重写整个 git 历史。执行前请先备份仓库或在新克隆上操作。

完成后，建议执行：
```powershell
git for-each-ref refs/original --format="%(refname)" | ForEach-Object { git update-ref -d $_ }
```
以删除 `filter-repo` 创建的备份引用。

## 推送到远程
历史重写后需要强制推送：
```powershell
git push origin main --force --tags
```
若远程仓库已有其他分支，请逐个强制推送。

## 复原工作区
如在重写前有本地改动，可在操作前先 `git stash`，完成后再 `git stash pop`。

---
`replacements.txt` 使用正则表达式自动匹配 `***REMOVED***