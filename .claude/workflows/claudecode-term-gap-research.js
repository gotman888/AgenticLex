export const meta = {
  name: 'claudecode-term-gap-research',
  description: 'Research current Claude Code terminology vs the live app dictionary; produce a categorized, prioritized gap report of terms to add. Re-runnable every 2-4 weeks (see docs/TERM_REFRESH_SOP.md).',
  phases: [
    { title: 'Research', detail: '8 Claude Code doc areas, WebSearch+WebFetch live docs' },
    { title: 'Verify', detail: 'confirm each candidate is real/current and not already covered' },
    { title: 'Synthesize', detail: 'categorized + prioritized gap report' },
  ],
}

const DICT = '/Users/hotman/Code/ClaudeCodeLex/ClaudeCodeLex/Resources/terms.en.json'

const PRE =
  'You are researching CURRENT Claude Code terminology to keep a vocabulary-learning iOS app (AgenticLex) up to date. ' +
  'The app teaches non-native-English speakers the English terms of agentic coding, focused on Claude Code. ' +
  'FIRST: Read ' + DICT + ' (the master dict) and note every terms[].english + the categories[] — that is what is ALREADY COVERED. ' +
  'Only surface GAPS (terms NOT already in that file). Today the dict may be partial; prioritise (a) missing terms and (b) terms NEW since the dict metadata.updated date.\n\n' +
  'Research the LIVE official docs (Claude Code docs moved to code.claude.com/docs): WebSearch for "Claude Code <area>" and WebFetch the code.claude.com/docs/* + docs.claude.com pages + the changelog/release-notes. If a page is JS-blocked, rely on multiple WebSearch snippets and cross-check.\n' +
  'For each gap term give: exact English term as users see it; category (existing: cli/hooks/mcp/sub-agent/plugins/skills/artifacts/tools/context/prompting/misc/commands/settings — or propose new); one-line plain definition; isEnglishOnly (true if it should stay English like MCP/JSON/hook); difficulty 1-3; source URL; isNew=true if it landed around/after the dict updated date. ' +
  'Be accurate — do NOT invent terms/features; if unsure it is real/current, omit or mark confidence low. Note any EXISTING term that is now renamed/deprecated (e.g. Task->Agent tool, removed /vim).'

const CAND = { type:'object', properties:{ candidates:{ type:'array', items:{ type:'object', properties:{
  term:{type:'string'}, category:{type:'string'}, whatItIs:{type:'string'},
  isEnglishOnly:{type:'boolean'}, difficulty:{type:'integer'}, sourceUrl:{type:'string'}, isNew:{type:'boolean'}
}, required:['term','category','whatItIs','sourceUrl'] } } }, required:['candidates'] }

const VERD = { type:'object', properties:{ confirmed:{ type:'array', items:{ type:'object', properties:{
  term:{type:'string'}, category:{type:'string'}, whatItIs:{type:'string'},
  isEnglishOnly:{type:'boolean'}, difficulty:{type:'integer'}, sourceUrl:{type:'string'},
  isNew:{type:'boolean'}, confidence:{type:'string', enum:['high','med','low']}
}, required:['term','category','whatItIs','confidence'] } } }, required:['confirmed'] }

const DIMS = [
  { key:'commands', prompt: PRE + '\n\nAREA: Slash commands + CLI flags/modes. Built-in slash commands, CLI flags (--print/-p, --resume, --model, --output-format, --permission-mode, --dangerously-skip-permissions, --append-system-prompt, --mcp-config...), and modes (interactive/print/headless).' },
  { key:'hooks', prompt: PRE + '\n\nAREA: Hooks. All hook events (incl. SessionStart/SessionEnd/PreCompact and newer), matchers, hook input/output JSON, exit codes, permissionDecision.' },
  { key:'mcp', prompt: PRE + '\n\nAREA: MCP in Claude Code. transports (stdio/Streamable HTTP/SSE), .mcp.json, claude mcp add/list, OAuth, scopes (local/project/user), MCP tools, MCP Tool Search, connectors.' },
  { key:'agents', prompt: PRE + '\n\nAREA: Subagents / custom Agents. custom subagents, .claude/agents/, /agents, the Agent tool (renamed from Task), subagent_type, built-in agents (Explore/Plan/general-purpose), background agents, agent memory/teams.' },
  { key:'skills-plugins', prompt: PRE + '\n\nAREA: Agent Skills + Plugins. SKILL.md frontmatter (allowed-tools, disable-model-invocation), .claude/skills/, bundled/personal skills, $ARGUMENTS, /plugin, plugin components, marketplaces, plugin.json/.claude-plugin.' },
  { key:'settings', prompt: PRE + '\n\nAREA: Settings / config / permissions. settings.json hierarchy (user/project/local/managed), .claude/ dir, permission modes (default/acceptEdits/plan/bypassPermissions), allow/ask/deny rules, allowedTools/disallowedTools, sandboxing, output styles, statusLine, env, additionalDirectories.' },
  { key:'tools', prompt: PRE + '\n\nAREA: Built-in tools. Write, Glob, WebFetch, TodoWrite/TaskCreate/TaskUpdate, NotebookEdit, AskUserQuestion, ExitPlanMode/EnterPlanMode, ToolSearch/deferred tools, Monitor, CronCreate, BashOutput/KillShell, and any new ones.' },
  { key:'context-sdk-new', prompt: PRE + '\n\nAREA: Context/memory, Agent SDK, and NEW features. context editing, auto-compact/microcompact, checkpoints/rewind, output styles, adaptive/interleaved thinking, effort level, MEMORY.md, Claude Agent SDK (renamed from Claude Code SDK), IDE integrations, Claude Code on web/desktop, background tasks, routines, AND anything in the recent changelog/release-notes.' },
]

phase('Research')
const results = await pipeline(
  DIMS,
  (d) => agent(d.prompt, { label:'research:' + d.key, phase:'Research', schema:CAND }),
  (r, d) => agent(
    PRE + '\n\nVERIFY these candidate gap-terms for area ' + d.key + '. For EACH: confirm it is a REAL, CURRENT Claude Code term (WebSearch if unsure), drop hallucinated/outdated/already-covered, dedup, set confidence, keep the source URL.\n\nCANDIDATES:\n' + JSON.stringify((r && r.candidates) || [], null, 2),
    { label:'verify:' + d.key, phase:'Verify', schema:VERD }
  ).then((v) => ({ key:d.key, confirmed:(v && v.confirmed) || [] })).catch(() => ({ key:d.key, confirmed:[] }))
)

const confirmed = (results.flat ? results.flat() : results).filter(Boolean)
  .flatMap((x) => (x.confirmed || []).map((c) => ({ ...c, area:x.key })))
log('Research: ' + confirmed.length + ' confirmed gap terms')

phase('Synthesize')
const report = await agent(
  PRE + '\n\nSynthesis lead. Below are adversarially-CONFIRMED gap terms. Produce a gap report: (1) summary of how complete the dict is + gap shape; (2) dedup + group by category (propose new categories if needed); (3) per term: whatItIs, priority P0/P1/P2, isNew, isEnglishOnly; (4) recommendedFirstBatch (~20 highest-value); (5) outdatedOrRename in the existing dict; (6) totalGapCount + refresh-cadence note. Be concrete; no generic non-Claude-Code terms.\n\nCONFIRMED (' + confirmed.length + '):\n' + JSON.stringify(confirmed, null, 2),
  { label:'synthesize-gap-report', phase:'Synthesize' }
)
return { confirmedCount: confirmed.length, confirmed, report }
