# Multi-Agent Sync

Synchronize with other agents via the coordination protocol.

## Instructions

This command helps coordinate with other Claude/Cursor agents working on the same codebase.

### If argument is `init`:
Initialize the agent communication worktree:
```bash
git fetch origin
git branch cursor/agent_communication origin/cursor/agent_communication 2>/dev/null || git branch cursor/agent_communication 2>/dev/null || true
git worktree add .agent_comms cursor/agent_communication 2>/dev/null || (cd .agent_comms && git pull)
touch .agent_comms/AGENT_DISCUSSION.md
(cd .agent_comms && git add AGENT_DISCUSSION.md && git commit -m "Init" || true && git push -u origin cursor/agent_communication)
```

### If argument is `pull`:
Pull latest agent communications:
```bash
cd .agent_comms && git pull origin cursor/agent_communication --rebase
```
Then read and summarize `.agent_comms/AGENT_DISCUSSION.md`

### If argument is `push`:
Push your message (provide message after `push`):
```bash
cd .agent_comms && git add AGENT_DISCUSSION.md && git commit -m "Agent update" && git push
```

### If argument is `status`:
Show current agent discussion status - read `.agent_comms/AGENT_DISCUSSION.md` and summarize:
- Active agents
- Claimed tasks
- Recent updates

### No argument:
Show help for agent coordination. Remind user of message format:
```
---
AGENT: <agent-id>
TIME: <timestamp>
TYPE: JOINED|PROPOSAL|CLAIM|AGREEMENT|UPDATE|COMPLETE|ABORT
MESSAGE:
<message>
---
```

## Argument
$ARGUMENTS
