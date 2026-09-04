# Antigravity 2.0 語言助手

Windows 一鍵語言切換工具，自動下載並執行 [qqxpee/antigravity2-cn](https://github.com/qqxpee/antigravity2-cn) 上游漢化引擎，無需手動下載或解壓。

漢化相關技術與翻譯內容均由上游專案負責，本專案僅將其整合至 Windows 環境，降低使用者的安裝與使用門檻。

啟動後會先檢測 Node.js、npm 與 npx。若環境缺失或版本過舊，可選擇透過 winget 安裝 Node.js LTS。

## 一行執行

```powershell
iex ((irm https://raw.githubusercontent.com/ni-null/antigravity2-lang-helper/main/antigravity2-lang.ps1).TrimStart([char]0xFEFF))
```

## 需求

- Windows PowerShell 5.1 或 PowerShell 7+
- Node.js 22.12.0+ 與 npm/npx（缺失時可由腳本引導安裝）
- winget（自動安裝 Node.js 時需要）
- 已安裝 Antigravity 2.0
- 可連線至 GitHub

執行前請先儲存工作。漢化引擎可能會關閉正在執行的 Antigravity，完成後會自動重新啟動。
