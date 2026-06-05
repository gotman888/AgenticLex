# 詞庫落差 backlog — Claude Code 用語（2026-06-03 研究）

> 來源：8 面向 multi-agent 研究 + 對抗式驗證（live docs，主域 `code.claude.com/docs`）。
> 對照基準：`terms.en.json` v2.0.0（60 詞，2026-05-20）。
> 結論：現有 60 詞約覆蓋現行用語 **1/3**；去重後 **121 個落差**（~55 個 2026-05 後新增）；
> 8 個現有詞需改名/擴充。**CC 每週多版** → 建議每 2–4 週 refresh（錨 `/release-notes`）。
> ⚠️ ship 前對 live docs 再核：`/vim` 已移除（別加）；subagent_type、Claude Agent SDK、
> managed-mcp.json、dontAsk Mode、/insights、Deferred Tool 為中低信心。

P0 = 每個用戶都會遇到的核心 / P1 = 常見 / P2 = niche。EN = isEnglishOnly（保留英文不譯）。

---

## 新分類 1：`commands`（斜線指令）
*理由：斜線指令是獨立可學的表層（`/name` 語法）、超高頻，不該塞進 CLI Basics。現有 `/clear` `/init` 建議遷入此類。*

| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| /compact | 摘要對話釋放 context，可加 focus | P0 | | ✓ |
| /context | 視覺化目前 context window 用量網格 | P0 | | ✓ |
| /model | 切換模型(sonnet/opus)並存為預設 | P0 | | ✓ |
| /agents | 開 sub-agent 管理器 | P0 | | ✓ |
| /mcp | 管理 MCP server 連線 + OAuth | P0 | | ✓ |
| /permissions | 管理 allow/ask/deny 權限規則 | P0 | | ✓ |
| /resume | 依 ID/名稱或選單回到過去對話 | P0 | | ✓ |
| /usage | 顯示成本/方案額度/統計(原 /cost /stats) | P0 | | ✓ |
| /rewind | 回滾對話/程式碼到 checkpoint(/undo) | P0 | ✓ | ✓ |
| /help | 顯示說明與指令清單 | P0 | | ✓ |
| /config | 開設定(主題/模型/output style) | P0 | | ✓ |
| /memory | 編輯 CLAUDE.md、切 auto-memory | P0 | | ✓ |
| /review | 本機審 PR | P1 | | ✓ |
| /hooks | 顯示已註冊 hook 設定 | P1 | | ✓ |
| /doctor | 診斷安裝與設定 | P1 | | ✓ |
| /skills | 列 skills、隱藏 | P1 | | ✓ |
| /plugin | 管理 plugin(裝/列/開關) | P1 | | ✓ |
| /export | 匯出對話成文字 | P1 | | ✓ |
| /add-dir | 加額外工作目錄 | P1 | | ✓ |
| /diff | 互動式看 uncommitted/每回合 diff | P1 | | ✓ |
| /statusline | 設定底部 status line | P1 | | ✓ |
| /security-review | 掃描 pending 變更的安全漏洞 | P1 | | ✓ |
| /effort | 設推理 effort(low…max, ultracode) | P1 | ✓ | ✓ |
| /code-review | bundled skill：審 diff(--fix, ultra) | P1 | ✓ | ✓ |
| /background | 把 session 轉背景 agent(/bg) | P1 | ✓ | ✓ |
| /tasks | 列/管背景任務(/bashes) | P1 | ✓ | ✓ |
| /branch | 分叉對話探索替代路(/fork) | P1 | ✓ | ✓ |
| /teleport | 把 web session 拉進本機終端(/tp) | P2 | ✓ | ✓ |
| /goal | 設定 Claude 跨回合持續追的目標 | P2 | ✓ | ✓ |
| /verify | bundled skill：build+run 驗證改動 | P2 | ✓ | ✓ |
| /run | bundled skill：啟動並驅動 app | P2 | ✓ | ✓ |
| /btw | 不進主歷史的側邊提問 | P2 | ✓ | ✓ |
| /login, /logout | 登入/登出 Anthropic 帳號 | P2 | | ✓ |
| /feedback | 送回饋/報 bug(/bug /share) | P2 | | ✓ |
| /release-notes | 開 changelog 版本選單 | P2 | | ✓ |
| /terminal-setup | 設終端鍵位(Shift+Enter) | P2 | | ✓ |
| /install-github-app | 設定 GitHub Actions app | P2 | | ✓ |
| /insights | 分析你的 session + 摩擦點 | P2 | ✓ | ✓ |

## 新分類 2：`settings`（設定與權限）
*理由：設定檔(`settings.json` `.claude/`)+ 整套權限模型(modes/規則/sandbox)是高價值群、目前無家。最被忽略的一塊。*

| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| settings.json | 控制 CC 行為的 JSON 設定(權限/env/模型/hooks) | P0 | | ✓ |
| Permission Mode | 控制 Claude 行動前多常詢問 | P0 | | |
| Accept Edits (acceptEdits) | 自動核准編輯+常見 FS 指令的模式 | P0 | | |
| Allow Rule | 讓某工具免詢問執行的規則 | P0 | | |
| Deny Rule | 擋某工具的規則(deny 最大) | P0 | | |
| Ask Rule | 某工具一律先問的規則 | P0 | | |
| .claude/ Directory | 放設定/commands/agents/skills/hooks 的資料夾 | P0 | | ✓ |
| settings.local.json | 專案內個人 override(gitignore) | P1 | | ✓ |
| Auto Mode | 自動核准但 classifier 擋危險動作 | P1 | ✓ | |
| Bypass Permissions | 跳過所有提示(僅容器/VM) | P1 | | |
| Sandboxing | Bash 工具的 OS 隔離(Seatbelt/bubblewrap) | P1 | | |
| --dangerously-skip-permissions | 跳過所有權限提示的 flag | P1 | | ✓ |
| allowedTools | 預先核准一組工具 | P1 | | ✓ |
| disallowedTools | session 內封鎖特定工具 | P1 | | ✓ |
| Output Style | 可切換的回應 persona | P1 | | |
| env | 為每個 session 設環境變數的設定塊 | P2 | | ✓ |
| Settings Precedence | managed > CLI > local > project > user | P2 | | |
| Managed Settings | 管理員/MDM 政策、用戶不可覆蓋 | P2 | | |
| additionalDirectories | 啟動資料夾外的持久檔案存取 | P2 | | ✓ |
| dontAsk Mode | 自動拒絕未預核的(CI 用) | P2 | ✓ | ✓ |

## `cli`（呼叫 / flag / 模式）
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Interactive Mode | 預設即時終端聊天(對比 print/headless) | P0 | | |
| --print (-p) | 印一次回應就結束(非互動) | P0 | | ✓ |
| --continue (-c) | 載入此目錄最近一次對話 | P0 | | ✓ |
| --model | 用別名/全名設 session 模型 | P0 | | ✓ |
| --resume (-r) | 依 ID/名稱回特定 session | P1 | | ✓ |
| --permission-mode | 以某權限模式開 session | P1 | | ✓ |
| claude mcp / mcp add | 從 shell 設定 MCP server | P1 | | ✓ |
| --output-format | print 模式格式：text/json/stream-json | P2 | | ✓ |
| stream-json | 行分隔 JSON 事件流(自動化) | P2 | | ✓ |
| --append-system-prompt | 在預設 system prompt 後追加 | P2 | | ✓ |
| --mcp-config | 從 JSON 檔/字串載 MCP servers | P2 | | ✓ |
| --max-turns | print 模式限制 agentic 回合 | P2 | | ✓ |
| --fork-session | resume 時開新 session ID | P2 | ✓ | ✓ |
| claude mcp serve | 把 CC 自己跑成 stdio MCP server | P2 | | ✓ |

## `hooks`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| SessionStart | session 開始/resume 時觸發；stdout=context | P1 | | |
| SessionEnd | session 結束時(僅清理) | P1 | | |
| Matcher | 過濾 hook 何時觸發(name/regex/`*`) | P1 | | |
| Exit Code | 指令 hook 回報結果(0 ok, 2 阻擋) | P1 | | |
| PreCompact | compaction 前(手動/自動) | P2 | | |
| PostCompact | compaction 完成後 | P2 | ✓ | |
| SubagentStart | subagent 生成時(對 SubagentStop) | P2 | ✓ | |
| PostToolUseFailure | 工具呼叫失敗後(錯誤記錄) | P2 | ✓ | |
| permissionDecision | PreToolUse 輸出：allow/deny/ask/defer | P2 | | ✓ |
| additionalContext | hook 輸出注入 context 的字串 | P2 | | ✓ |
| hookSpecificOutput | 裝事件專屬欄位的巢狀 JSON | P2 | | ✓ |
| HTTP Hook | 把事件 JSON POST 到 URL 的 hook | P2 | ✓ | |
| MessageDisplay | 只改畫面顯示文字的 hook | P2 | ✓ | |

## `mcp`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| .mcp.json | 專案根定義共用 MCP servers | P0 | | ✓ |
| MCP Tool | 連上的 MCP server 提供的動作 | P0 | | |
| MCP Scope | server config 位置：local/project/user | P1 | | |
| OAuth | 認證遠端 MCP server 的瀏覽器登入 | P1 | | ✓ |
| Connector | directory 裡審核過的遠端 MCP server | P1 | | |
| stdio | 本地 MCP transport(標準輸入輸出) | P1 | | ✓ |
| Streamable HTTP | 建議的遠端 MCP transport(OAuth) | P2 | | ✓ |
| SSE | 已棄用的遠端 transport | P2 | | ✓ |
| MCP Tool Search | 延遲 MCP 工具定義、用時才載省 context | P1 | ✓ | |
| Elicitation | MCP server 中途要結構化輸入 | P2 | ✓ | ✓ |
| managed-mcp.json | 管理員部署、控哪些 MCP server 載入 | P2 | ✓ | ✓ |

## `sub-agent`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Custom Subagent | 自訂 agent(prompt/工具/模型)給重複任務 | P0 | | |
| Agent Tool | 生 subagent 的工具；v2.1.63 由 Task 改名 | P0 | ✓ | ✓ |
| Explore Agent | 內建唯讀快速搜尋 agent(Haiku) | P1 | | |
| Plan Agent | Plan Mode 的唯讀研究 agent | P1 | | |
| General-purpose Agent | 內建全工具多步 agent | P1 | | |
| Automatic Delegation | Claude 依 description 自選 subagent | P1 | | |
| .claude/agents/ | 專案共用 subagent 定義檔資料夾 | P1 | | ✓ |
| @-mention (Subagent) | 打 @agent-name 強制指定 subagent | P1 | ✓ | |
| Background Agent | 背景執行的脫離 session | P1 | ✓ | |
| --agent | 整個 session 當一個 subagent 跑 | P2 | ✓ | ✓ |
| Agent Memory | 讓 subagent 累積學習的持久目錄 | P2 | ✓ | |
| Agent Teams | 實驗性多 session 協調(共用 task list) | P2 | ✓ | |
| Forked Subagent | 繼承完整當前對話的 subagent | P2 | ✓ | |
| Workflow | 跑腳本編排多背景 subagent 的工具 | P2 | ✓ | ✓ |
| isolation: worktree | frontmatter：在暫存 git worktree 跑 agent | P2 | ✓ | ✓ |

## `skills`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Bundled Skill | CC 內建的 skill(/code-review /debug /run) | P0 | ✓ | |
| Personal Skill | ~/.claude/skills/ 跨專案可用 | P1 | | |
| .claude/skills/ | 專案內每 repo skill 資料夾 | P1 | | ✓ |
| allowed-tools | frontmatter：skill 啟用時免問的工具 | P1 | | ✓ |
| $ARGUMENTS | skill 名後文字替換的 placeholder | P1 | | ✓ |
| Supporting Files | 用時才載的 skill 附檔 | P1 | | |
| disable-model-invocation | frontmatter：只允許用戶手動跑 | P2 | | ✓ |
| context: fork | frontmatter：在隔離 subagent 跑 skill | P2 | ✓ | ✓ |
| Dynamic Context Injection | `` !`cmd` `` 把即時 shell 輸出注入 prompt | P2 | ✓ | |

## `plugins`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Plugin Manifest | .claude-plugin/plugin.json 定義 name/版本 | P0 | | |
| /plugin marketplace add | 從 repo/URL 註冊 marketplace | P1 | | ✓ |
| /plugin install | 裝 plugin-name@marketplace-name | P1 | | ✓ |
| Official Marketplace | Anthropic 內建策展目錄 | P1 | ✓ | |
| Community Marketplace | 公開審核過的第三方 plugin 目錄 | P1 | ✓ | |
| Namespacing | plugin skill 加前綴避免衝突 | P1 | | |
| Installation Scope | plugin 安裝層級 User/Project/Local | P1 | | |
| .claude-plugin | 放 plugin.json 的 plugin 根目錄 | P2 | | ✓ |
| hooks.json | plugin 定義事件處理器的檔 | P2 | | ✓ |
| /reload-plugins | 不重啟套用 plugin 變更 | P2 | ✓ | ✓ |
| --plugin-dir | 載入本地 plugin 目錄開發用 | P2 | ✓ | ✓ |
| LSP Server | plugin 加的 Language Server | P2 | ✓ | ✓ |

## `tools`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Write | 建立/完整覆寫檔(不追加) | P0 | | ✓ |
| Glob | 用 glob pattern 找檔 | P0 | | ✓ |
| WebFetch | 抓 URL 轉 Markdown 抽答案 | P0 | | ✓ |
| TodoWrite | 管 session 清單(v2.1.142+ 停用) | P1 | | ✓ |
| TaskCreate / TaskUpdate | 增改持久 task list | P1 | ✓ | ✓ |
| AskUserQuestion | 暫停問多選澄清題 | P1 | | ✓ |
| ExitPlanMode | 提計畫給核准、開始 coding | P1 | | ✓ |
| ToolSearch | 用時才載 deferred 工具省 context | P1 | ✓ | ✓ |
| Deferred Tool | 用時才取的工具(經 ToolSearch) | P1 | ✓ | |
| EnterPlanMode | 進 plan mode 先設計再寫 | P2 | | ✓ |
| NotebookEdit | 依 cell_id 改 Jupyter notebook | P2 | | ✓ |
| Monitor | 背景跑指令、把行回饋回來 | P2 | ✓ | ✓ |
| LSP | 程式智能：go-to-def/find-refs/type err | P2 | ✓ | ✓ |
| CronCreate | session 內排程重複/一次性 prompt | P2 | ✓ | ✓ |

## `context`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Auto-Compact | 近上限(~95%)自動摘要 | P0 | | |
| Checkpoint | /rewind 可還原的程式碼+對話點 | P0 | ✓ | |
| Microcompact | 只清舊的過時工具呼叫延長 session | P1 | ✓ | ✓ |
| Effort Level | 設 Claude 花多少推理(low–max) | P1 | ✓ | |
| MEMORY.md | Claude 自更新的跨 session 索引檔 | P1 | ✓ | ✓ |
| Context Editing | API 端清掉模型視野中的舊內容 | P2 | ✓ | |

## `prompting`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Adaptive Thinking | 模型自決推理深度(取代手調 budget) | P1 | ✓ | |
| Interleaved Thinking | 工具呼叫間的推理 | P2 | | |
| Thinking Budget | extended thinking 的 token 額度(漸棄) | P2 | | |

## `misc`
| 詞 | 一句話 | Pri | New | EN |
|---|---|---|---|---|
| Claude Code on the Web | 在 Anthropic 雲沙箱跑 CC(claude.ai/code) | P0 | ✓ | |
| Claude Agent SDK | 由 Claude Code SDK 改名(claude-agent-sdk) | P0 | ✓ | ✓ |
| Teleport | 把進行中的雲 session 拉進本機終端 | P1 | ✓ | |
| Sandbox | 範圍受限的隔離執行環境 | P1 | ✓ | |
| VS Code Extension | VS Code 內的原生圖形 CC 介面 | P1 | | |
| Routines | 排程/API/GitHub 事件觸發的存檔 CC 設定 | P1 | ✓ | |
| Ultraplan | 在雲 session 起草計畫、瀏覽器審 | P2 | ✓ | |
| Ultrareview | 深度多代理雲審(/code-review ultra) | P2 | ✓ | |
| Auto-fix PRs | Claude 自動回應 CI 失敗+審查留言 | P2 | ✓ | |
| Desktop App | Mac/Win app(2026-04 改版)平行 session | P2 | ✓ | |
| JetBrains Plugin | IntelliJ 系 IDE 的 CC plugin | P2 | | |

---

## 現有 60 詞需改（rename/擴充，非刪除）
| 現有詞 | 問題 | 動作 |
|---|---|---|
| **Task Tool** | v2.1.63 改名 **Agent Tool**(Task 僅留 alias) | 主名改 Agent Tool、Task 當別名 |
| **Agent SDK** | 官方改名 **Claude Agent SDK**(claude-agent-sdk) | 改名+定義；註原 Claude Code SDK |
| Background Task | 與 Background Agent / /background / /tasks 重疊 | 釐清定義、交叉連結 |
| Headless Mode | 文件多改用 `--print`/print mode | 保留；加 --print 當現代說法 |
| Memory Tool | memory 已成更廣系統(/memory MEMORY.md auto) | 核對定義是否仍符；可擴充 |
| Compaction | 現為三機制之一(+Auto-Compact +Microcompact) | 定義仍可；加兩個 sibling |
| Extended Thinking | 新模型用 Adaptive Thinking+Effort | 保留；旁邊加 Adaptive Thinking |
| /clear, /init | 是斜線指令 | 若開 commands 類則遷入 |

## 建議首批 ~22 詞（第一週就會遇到 + 2026 旗艦）
/compact · /context · /model · /agents · /mcp · /permissions · /resume · /usage · /rewind(NEW) ·
settings.json(NEW 類) · Permission Mode · Accept Edits · Allow Rule · Deny Rule · .claude/ Directory ·
Checkpoint(NEW) · Auto-Compact · **Agent Tool(改名)** · Bundled Skill(NEW) · .mcp.json · MCP Tool ·
Claude Code on the Web(NEW) · **Claude Agent SDK(改名)** · Write/Glob/WebFetch

## 更新節奏
CC 每週多版（資料橫跨 v2.1.32→142+）。**每 2–4 週 refresh**：重跑此研究 workflow（錨 `code.claude.com` `/release-notes` + changelog），每個 minor bump 硬 re-audit。詞庫當 living doc。
