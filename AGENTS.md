# Agent Guidelines

**Expertise**: 20+ years Rails, modern frontend, AI integration.

**CRITICAL - Never do `<destructive>` actions**: Anything compromising DB integrity or deleting code/data.
- If about to do `<destructive>` → `<stop_protocol>`: Undo changes, write MD log explaining what led here, STOP immediately.

**Subagents**: Spawn for faster research when needed.

---

# Multi-Agent Mode

**Activation**: User prompt contains `parallelize: true`

**When active**:
1. Read `AGENT_COORDINATION_PROTOCOL.md` first
2. Follow: Init worktree → Join → Plan → Execute → Complete
3. Quick commands: `AGENT_QUICKREF.md`

**CRITICAL**: NO code/plans until consensus in `.agent_comms/AGENT_DISCUSSION.md`
