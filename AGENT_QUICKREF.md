# Agent Coordination Quick Reference

## Activation
Add to prompt: `parallelize: true`

## Essential Commands

### Initialize (creates separate worktree)
```bash
git fetch origin
git branch cursor/agent_communication origin/cursor/agent_communication 2>/dev/null || git branch cursor/agent_communication 2>/dev/null || true
git worktree add .agent_comms cursor/agent_communication 2>/dev/null || (cd .agent_comms && git pull)
touch .agent_comms/AGENT_DISCUSSION.md
(cd .agent_comms && git add AGENT_DISCUSSION.md && git commit -m "Init" || true && git push -u origin cursor/agent_communication)
```

### Sync (do this frequently!)
```bash
# Pull updates
(cd .agent_comms && git pull origin cursor/agent_communication --rebase)
# Read .agent_comms/AGENT_DISCUSSION.md
# ... do work on YOUR branch ...
# Post update
(cd .agent_comms && git add AGENT_DISCUSSION.md && git commit -m "Agent update" && git push)
```

## Message Format
```
---
AGENT: <your-id>
TIME: <timestamp>
TYPE: JOINED|PROPOSAL|CLAIM|QUESTION|AGREEMENT|UPDATE|COMPLETE|ABORT
MESSAGE:
<message text>
---
```

## Workflow
1. **JOIN** → Announce presence
2. **PROPOSE** → Suggest task breakdown  
3. **CLAIM** → Take specific subtask
4. **AGREE** → Confirm & start work
5. **UPDATE** → Report progress every ~5 min
6. **COMPLETE** → Finish & handoff

## Rules
- ⚠️ NO CODE until consensus reached
- ⚠️ ONE task per agent (no overlap)
- ⚠️ PULL communication before every action
- ⚠️ PUSH message after every update
- ⚠️ NEVER switch branches - use worktree
- ⚠️ Code changes on working branch, communication in `.agent_comms/`

## Generate Agent ID
```bash
echo "agent-$(whoami)-$(date -u +%Y%m%dT%H%M%S)"
```

## Full docs
See `AGENTS.md` for complete protocol.
