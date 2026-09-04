# Antigravity 2.0 語言助手

Windows 一鍵語言切換工具，自動下載並執行 [qqxpee/antigravity2-cn](https://github.com/qqxpee/antigravity2-cn) 上游漢化引擎，無需手動下載或解壓。

漢化相關技術與翻譯內容均由上游專案負責，本專案僅將其整合至 Windows 環境，降低使用者的安裝與使用門檻。

## 一行執行

```powershell
irm https://raw.githubusercontent.com/ni-null/antigravity2-lang-helper/main/antigravity2-lang.ps1 | iex
```

## 需求

- Windows PowerShell 5.1 或 PowerShell 7+
- 已安裝 Node.js 與 npm/npx
- 已安裝 Antigravity 2.0
- 可連線至 GitHub

執行前請先儲存工作。漢化引擎可能會關閉正在執行的 Antigravity，完成後會自動重新啟動。
