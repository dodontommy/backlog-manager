# Agent Guidelines for Backlog Manager

## Project Overview

**Backlog Manager** is a Rails 8.1.2 application that helps gamers manage their gaming backlogs across multiple platforms (Steam, GOG, Epic Games) with AI-powered recommendations.

### Tech Stack
- **Backend**: Ruby on Rails 8.1.2, Ruby 3.2.3
- **Database**: PostgreSQL 13+
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Testing**: Minitest, Capybara + Selenium
- **Quality**: RuboCop (rails-omakase), Brakeman, Bundler-Audit
- **Deployment**: Docker, Kamal, GitHub Actions CI/CD
- **AI**: IGDB API integration, planned Claude/OpenAI recommendations

### Key Directories
```
app/
├── controllers/     # RESTful controllers, SessionsController handles OAuth
├── models/          # User, Game, UserGame, Identity, Recommendation
├── services/
│   ├── ai_services/         # RecommendationService (TODO: implement)
│   └── game_platforms/      # Steam, GOG, Epic integrations (stubs)
├── views/           # ERB templates with Hotwire
agents/              # Python IGDB gaming curator agent
.claude/             # Claude Code configuration
│   ├── commands/    # Custom slash commands
│   └── settings.local.json
```

---

## MCP Servers Available

This project has configured MCP servers in `.mcp.json`. Use them:

| Server | Purpose | Example Usage |
|--------|---------|---------------|
| `postgres` | Query database, inspect schema | "Show me all users with status 'playing'" |
| `github` | Manage issues, PRs, branches | "Create an issue for the auth bug" |
| `memory-bank` | Persist context across sessions | "Remember that we decided to use JWT" |
| `context7` | Fetch up-to-date documentation | "Look up Rails 8 Turbo Stream docs" |
| `sequential-thinking` | Complex multi-step reasoning | "Plan the recommendation algorithm" |
| `filesystem` | Advanced file operations | "Find all files modified today" |

**To enable**: Run `claude mcp add` for each server or approve when prompted.

---

## Subagent Roles

When spawning subagents, assign appropriate roles:

### Rails Backend Expert
- **Focus**: Models, controllers, services, migrations, API design
- **Patterns**: Service objects, concerns, STI, polymorphic associations
- **Commands**: `bin/rails`, `bundle exec`, database operations

### Hotwire Frontend Expert
- **Focus**: Turbo Frames, Turbo Streams, Stimulus controllers
- **Patterns**: Broadcasts, morphing, lazy loading, form handling
- **Files**: `app/javascript/controllers/`, `app/views/`

### Testing Expert
- **Focus**: Unit tests, integration tests, system tests
- **Patterns**: Fixtures, factories, Capybara DSL, test isolation
- **Commands**: `bin/rails test`, `bin/rails test:system`

### AI/ML Integration Expert
- **Focus**: Recommendation engine, IGDB API, embeddings
- **Files**: `app/services/ai_services/`, `agents/`
- **Integrations**: Python gaming curator, Claude API, OpenAI API

### Database Expert
- **Focus**: Migrations, queries, indexes, performance
- **Tools**: Use `postgres` MCP server for direct queries
- **Patterns**: N+1 prevention, eager loading, query optimization

### Security Expert
- **Focus**: OAuth flows, CSRF, XSS, SQL injection, secrets
- **Commands**: `bundle exec brakeman`, `bundle exec bundler-audit`
- **Files**: `config/credentials.yml.enc`, initializers

---

## Coding Standards

### Ruby/Rails
- Follow rails-omakase RuboCop configuration
- Use service objects for complex business logic (`app/services/`)
- Prefer `has_many :through` over `has_and_belongs_to_many`
- Use strong parameters in controllers
- Keep controllers thin, models focused

### JavaScript/Stimulus
- One controller per behavior
- Use data attributes for configuration
- Prefer Turbo over custom JS where possible

### Testing
- Every model needs unit tests
- Every controller action needs request tests
- Complex flows need system tests
- Use fixtures (Rails default), not factories

### Git
- Branch format: `feature/short-description` or `fix/issue-description`
- Commit messages: imperative mood, 50 char subject, body explains why
- Always run tests before pushing

---

## Destructive Operation Protocol

**CRITICAL - Never do destructive actions without explicit user approval:**

Destructive actions include:
- Dropping/truncating database tables
- Deleting files or directories
- Force pushing to branches
- Modifying production credentials
- Running irreversible migrations

If about to do a destructive action:
1. **STOP** immediately
2. Explain what you were about to do
3. Wait for explicit user approval
4. Log the action in your response

---

## Multi-Agent Coordination

### Activation
Add to prompt: `parallelize: true`

### Protocol
1. Read `AGENT_COORDINATION_PROTOCOL.md` for full details
2. Initialize git worktree: `.agent_comms/` directory
3. Communicate via `.agent_comms/AGENT_DISCUSSION.md`
4. **NO code until consensus reached**

### Quick Commands
See `AGENT_QUICKREF.md` for essential commands.

### Message Types
- `JOINED` - Announce presence
- `PROPOSAL` - Suggest task breakdown
- `CLAIM` - Take specific subtask
- `AGREEMENT` - Confirm and start
- `UPDATE` - Progress report (every ~5 min)
- `COMPLETE` - Task finished
- `ABORT` - Emergency stop

---

## Python Gaming Curator Integration

The `agents/` directory contains a Python agent for IGDB integration:

```bash
# Activate and test
cd agents
source venv/bin/activate
python test_agent.py
```

### Environment Setup
Copy `agents/env.example` to `agents/.env` and add:
- `IGDB_CLIENT_ID`
- `IGDB_CLIENT_SECRET`

### Future Integration
This agent will evolve to:
1. MCP server for game data lookups
2. AWS Bedrock AgentCore deployment
3. Direct integration with Rails RecommendationService

---

## Common Tasks

### Running the App
```bash
bin/dev                    # Start development server
bin/rails db:migrate       # Run migrations
bin/rails db:seed          # Seed sample data
```

### Testing
```bash
bin/rails test             # Run all unit/integration tests
bin/rails test:system      # Run system tests (requires Chrome)
bin/rails test test/models  # Run specific directory
```

### Code Quality
```bash
bundle exec rubocop        # Linting
bundle exec brakeman       # Security scan
bundle exec bundler-audit  # Dependency vulnerabilities
```

### Database
```bash
bin/rails db:create        # Create databases
bin/rails db:migrate       # Run pending migrations
bin/rails db:rollback      # Undo last migration
bin/rails dbconsole        # Open psql console
```

---

## Environment Variables

Required in `.env` (see `.env.example`):
- `DATABASE_URL` - PostgreSQL connection
- `GOOGLE_CLIENT_ID/SECRET` - Google OAuth
- `FACEBOOK_APP_ID/SECRET` - Facebook OAuth
- `STEAM_API_KEY` - Steam integration
- `ANTHROPIC_API_KEY` - Claude API (optional)
- `OPENAI_API_KEY` - OpenAI API (optional)

---

## Implementation Status

### Completed
- Rails 8.1.2 app structure
- Database models and migrations
- OAuth foundation (User, Identity models)
- Service architecture scaffolding
- CI/CD pipeline
- IGDB Python agent (Phase 1)

### In Progress
- Platform integrations (Steam, GOG, Epic)
- AI recommendation engine
- Frontend views

### Planned
- MCP server for gaming data
- Real-time sync with gaming platforms
- Social features

---

## Quick Reference

| Task | Command |
|------|---------|
| Start server | `bin/dev` |
| Run tests | `bin/rails test` |
| Lint code | `bundle exec rubocop` |
| Security scan | `bundle exec brakeman` |
| DB console | `bin/rails dbconsole` |
| Create migration | `bin/rails g migration AddFieldToTable field:type` |
| Open Rails console | `bin/rails console` |
