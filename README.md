# Backlog Manager

A Ruby on Rails application to help manage your gaming backlog across multiple platforms using AI recommendations.

## Overview

Backlog Manager helps gamers manage their game libraries from various services including:
- Steam
- GOG (Good Old Games)
- Epic Games Store
- And more...

The application uses AI to provide intelligent game recommendations and help users prioritize their gaming backlog.

## Requirements

* Ruby 3.2.3
* Rails 8.1.2
* PostgreSQL 13+

## Setup

1. Install dependencies:
```bash
bundle install
```

2. Configure your database in `config/database.yml`

3. Create and setup the database:
```bash
rails db:create
rails db:migrate
```

4. Start the server:
```bash
rails server
```

## Features (Planned)

- Multi-platform game library integration
- AI-powered game recommendations
- Backlog management and prioritization
- Game completion tracking
- Library statistics and insights

## Development

Run the test suite:
```bash
rails test
```

### Multi-Agent Coordination

This project supports parallel AI agent execution for complex tasks. See `AGENTS.md` for the complete coordination protocol.

**Quick Start:**
```
# In your prompt, include:
parallelize: true

# Agents will coordinate via the cursor/agent_communication branch
# and communicate through AGENT_DISCUSSION.md
```

**Key Features:**
- Automatic task distribution among multiple agents
- Git worktree-based communication (no branch switching!)
- Conflict-free parallel execution
- Structured message format for coordination
- Code changes stay on your working branch

For detailed instructions, message formats, and examples, see `AGENTS.md`.

## License

Copyright 2026
