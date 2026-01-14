# Multi-Agent Coordination Protocol

## Activation
When user prompt includes `parallelize: true`, activate multi-agent coordination mode.

## Parameters
- `parallelize: true` - Enable multi-agent mode
- `agent_id: <name>` - Optional agent identifier (default: auto-generated from timestamp)
- `max_agents: <n>` - Maximum concurrent agents (default: 3)
- `sync_interval: <seconds>` - Pull frequency in seconds (default: 30)

## Coordination Branch
All agent communication occurs on branch: `cursor/agent_communication`

**IMPORTANT**: Use git worktree for clean separation. Code changes stay on your working branch; only communication happens in the worktree.

## Workflow

### 1. Initialization (CRITICAL - Do this first!)
```bash
# Create/fetch communication branch
git fetch origin
git branch cursor/agent_communication origin/cursor/agent_communication 2>/dev/null || \
  git branch cursor/agent_communication 2>/dev/null || true

# Set up worktree in .agent_comms/ directory
git worktree add .agent_comms cursor/agent_communication 2>/dev/null || \
  (cd .agent_comms && git pull origin cursor/agent_communication)

# Initialize discussion file
touch .agent_comms/AGENT_DISCUSSION.md
cd .agent_comms
git add AGENT_DISCUSSION.md
git commit -m "Initialize agent coordination" || true
git push -u origin cursor/agent_communication || git push origin cursor/agent_communication
cd ..
```

### 2. Join Discussion
Append to `.agent_comms/AGENT_DISCUSSION.md`:
```
---
AGENT: <agent_id>
TIME: <ISO 8601 timestamp>
STATUS: JOINED
TASK: <original user task>
---
```

**Note**: You remain on your working branch. All communication file operations happen in `.agent_comms/` directory.

### 3. Task Planning Phase
**DO NOT execute code/plans until agreement is reached.**

Agents communicate via `.agent_comms/AGENT_DISCUSSION.md` to:
1. Propose task breakdown
2. Claim specific subtasks
3. Identify dependencies
4. Reach consensus

Message format:
```
---
AGENT: <agent_id>
TIME: <timestamp>
TYPE: PROPOSAL|CLAIM|QUESTION|AGREEMENT|UPDATE|COMPLETE
MESSAGE:
<your message>
---
```

### 4. Synchronization Loop
```bash
# Before each significant action - pull updates:
cd .agent_comms
git pull origin cursor/agent_communication --rebase
cd ..
# Read .agent_comms/AGENT_DISCUSSION.md for updates

# After posting message - push update:
cd .agent_comms
git add AGENT_DISCUSSION.md
git commit -m "Agent <agent_id>: <brief description>"
git push origin cursor/agent_communication
cd ..
```

**You never leave your working branch!** All git operations for communication happen inside `.agent_comms/`.

### 5. Execution Phase
Once consensus reached:
- Work on claimed subtasks **on your current branch** (main or feature branch)
- Post progress updates to `.agent_comms/AGENT_DISCUSSION.md` every ~5 minutes
- Pull communication updates at `sync_interval`
- Report blocking issues immediately
- Push code changes to your working branch
- Coordinate merge conflicts in code (communication is conflict-free)

### 6. Completion
```
---
AGENT: <agent_id>
TIME: <timestamp>
TYPE: COMPLETE
MESSAGE:
Completed: <subtask description>
Files modified: <list>
Tests: <pass/fail>
Ready for: <next steps or handoff>
---
```

## Communication Rules

### DOs
- ✅ Be concise - limit messages to essential info
- ✅ Use structured format for parseability
- ✅ Claim specific, non-overlapping work
- ✅ Report blockers immediately
- ✅ Confirm understanding before executing

### DON'Ts
- ❌ Start work without consensus
- ❌ Overlap with other agents' claimed tasks
- ❌ Make assumptions - ask questions
- ❌ Leave stale status - update regularly
- ❌ Switch branches - use worktree
- ❌ Make code changes in .agent_comms/ - that's communication only!

## Conflict Resolution
If agents disagree:
1. Most recently active agent defers
2. Agent with fewest claimed tasks takes disputed work
3. Split task into smaller units if possible

## Example Session

```
---
AGENT: agent-alpha-20260114T120000
TIME: 2026-01-14T12:00:00Z
STATUS: JOINED
TASK: Add user authentication system
---

---
AGENT: agent-alpha-20260114T120000
TIME: 2026-01-14T12:00:15Z
TYPE: PROPOSAL
MESSAGE:
Task breakdown:
1. Database migrations (User model, sessions)
2. Authentication controller & routes
3. Session management & cookies
4. Login/signup views
5. Tests

Proposing to take: Items 1-2
---

---
AGENT: agent-beta-20260114T120100
TIME: 2026-01-14T12:01:00Z
STATUS: JOINED
TASK: Add user authentication system
---

---
AGENT: agent-beta-20260114T120100
TIME: 2026-01-14T12:01:15Z
TYPE: CLAIM
MESSAGE:
I'll handle:
- Items 3-4 (session management & views)
- Depends on: agent-alpha completing item 2
---

---
AGENT: agent-gamma-20260114T120200
TIME: 2026-01-14T12:02:00Z
STATUS: JOINED
TASK: Add user authentication system
---

---
AGENT: agent-gamma-20260114T120200
TIME: 2026-01-14T12:02:15Z
TYPE: CLAIM
MESSAGE:
I'll handle:
- Item 5 (tests)
- Will wait for items 1-4 completion
---

---
AGENT: agent-alpha-20260114T120000
TIME: 2026-01-14T12:02:30Z
TYPE: AGREEMENT
MESSAGE:
Plan confirmed. Starting work on migrations & controller.
ETA: 10 minutes
---

---
AGENT: agent-alpha-20260114T120000
TIME: 2026-01-14T12:12:00Z
TYPE: COMPLETE
MESSAGE:
Completed: Database migrations & authentication controller
Files modified: 
- db/migrate/20260114_add_authentication.rb
- app/controllers/sessions_controller.rb
- config/routes.rb
Tests: N/A (waiting for agent-gamma)
Ready for: agent-beta to implement session management
---
```

## Emergency Stop
If coordination fails, any agent can post:
```
---
AGENT: <agent_id>
TIME: <timestamp>
TYPE: ABORT
MESSAGE: <reason>
---
```
All agents must stop, reassess, and restart coordination.

## Cleanup
When all work complete:
```bash
# Archive discussion file
cp .agent_comms/AGENT_DISCUSSION.md "archive/AGENT_DISCUSSION_$(date +%Y%m%d_%H%M%S).md"
git add archive/
git commit -m "Archive agent discussion from $(date +%Y-%m-%d)"
git push origin main

# Clear discussion for next session
cd .agent_comms
echo "" > AGENT_DISCUSSION.md
git add AGENT_DISCUSSION.md
git commit -m "Clear discussion for next session"
git push origin cursor/agent_communication
cd ..

# Optional: Remove worktree (will be recreated next session)
# git worktree remove .agent_comms
```

## Git Worktree Benefits

- **No branch switching**: Stay on your working branch the entire time
- **Clean separation**: Communication in `.agent_comms/`, code in working directory
- **Parallel work**: Multiple agents on same branch without conflicts
- **Simple sync**: Just `cd .agent_comms && git pull/push`

## Directory Structure
```
your-repo/                          (main working directory - your branch)
├── .agent_comms/                   (separate worktree - cursor/agent_communication branch)
│   └── AGENT_DISCUSSION.md         (communication file ONLY)
├── app/                            (your code - work here)
├── config/
└── ...
```
