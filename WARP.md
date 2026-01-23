# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Backlog Manager is a Ruby on Rails 8.1.2 application for managing gaming backlogs across multiple platforms (Steam, GOG, Epic Games) with AI-powered recommendations. This is an early-stage project with foundation models and services in place, but core integration features are not yet implemented.

## Technology Stack

- **Ruby**: 3.2.3
- **Rails**: 8.1.2
- **Database**: PostgreSQL 13+
- **Testing**: Minitest (Rails default)
- **Code Quality**: RuboCop (rails-omakase), Brakeman, Bundler-Audit
- **Deployment**: Kamal/Docker support included

## Essential Commands

### Development
```bash
# Start server
rails server

# Run console
rails console

# Run single test file
rails test test/models/user_test.rb

# Run all tests
rails test

# Run CI pipeline (includes linting, security checks, tests)
bin/ci
```

### Database
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback

# Reset database (destructive!)
rails db:reset
```

### Code Quality
```bash
# Run linter
bin/rubocop

# Auto-fix linting issues
bin/rubocop -A

# Security scan
bin/brakeman

# Dependency audit
bin/bundler-audit

# Importmap audit
bin/importmap audit
```

## Architecture

### Data Model Relationships

The application uses a service-oriented architecture with clear separation between models, controllers, and business logic services.

**Core Models:**
- `User` - has_many `user_games`, `game_services`, `recommendations`
- `Game` - has_many `user_games` and `recommendations`
- `UserGame` (join table) - belongs_to `user` and `game`, tracks status (backlog/playing/completed/abandoned/wishlist), hours_played, completion_percentage, priority (1-10)
- `GameService` - belongs_to `user`, stores OAuth tokens for platform integrations (Steam, GOG, Epic)
- `Recommendation` - belongs_to `user` and `game`, stores AI-generated recommendations with score and reasoning

### Service Layer Organization

Services are organized by domain in `app/services/`:

**Game Platform Integrations** (`app/services/game_platforms/`)
- `BasePlatform` - Abstract base class defining interface: `fetch_library`, `fetch_game_details(game_id)`, `configured?`
- `SteamPlatform` - Steam Web API integration (not yet implemented)
- `GogPlatform` - GOG API integration (not yet implemented)
- `EpicPlatform` - Epic Games API integration (not yet implemented)

**AI Services** (`app/services/ai_services/`)
- `RecommendationService` - AI recommendation engine (not yet implemented)

### Controllers & Routes

RESTful routes defined in `config/routes.rb`:
- `GET /` - Home page
- `GET /games`, `GET /games/:id` - Game browsing
- `GET /user_games` - Backlog management
- `GET /recommendations` - AI recommendations

## Critical Development Guidelines

### Database Integrity
**CRITICAL**: Never perform `<destructive>` operations that compromise database integrity or delete code/data without explicit user confirmation. If about to perform such an operation, follow `<stop_protocol>`: undo changes, document what led there, and STOP immediately.

Examples of destructive operations:
- `rails db:reset` or `rails db:drop`
- Deleting models or migrations without understanding impact
- Modifying existing migration files
- Mass data deletions

### Multi-Agent Coordination

This project supports parallel AI agent execution for complex tasks. When a user prompt contains `parallelize: true`:

1. **Read the protocol first**: Check `AGENT_COORDINATION_PROTOCOL.md`
2. **Initialize git worktree**: Communication happens via `cursor/agent_communication` branch in `.agent_comms/` directory
3. **Follow workflow**: Init worktree → Join → Plan → Execute → Complete
4. **NO CODE UNTIL CONSENSUS**: All agents must agree on task breakdown in `.agent_comms/AGENT_DISCUSSION.md` before executing
5. **Quick reference**: See `AGENT_QUICKREF.md` for essential commands

Key principle: Code changes stay on your working branch; only communication files go to `.agent_comms/` worktree.

## Project Context

### Implementation Status
- ✅ Database schema and models with associations
- ✅ Controller structure and RESTful routes
- ✅ Service architecture scaffolded
- ✅ Test structure in place
- ❌ Platform API integrations (Steam, GOG, Epic) - **not implemented**
- ❌ AI recommendation engine - **not implemented**
- ❌ Authentication/authorization - **not implemented**
- ❌ Frontend views beyond basic scaffolding - **not implemented**

### API Keys Required (when implementing integrations)
Set in `.env` file (see `.env.example`):
- `STEAM_API_KEY` - Get from https://steamcommunity.com/dev/apikey
- `GOG_CLIENT_ID` / `GOG_CLIENT_SECRET` - GOG Developer Portal
- `EPIC_CLIENT_ID` / `EPIC_CLIENT_SECRET` - Epic Games Developer Portal
- `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` - For AI recommendations

### Security Notes
- GameService tokens should be encrypted (currently not implemented)
- NEVER commit API keys or tokens to version control
- Use Rails credentials or environment variables for secrets

## Additional Documentation

- `README.md` - Project overview and quick start
- `DEVELOPMENT.md` - Detailed setup instructions, project structure, troubleshooting
- `API.md` - Complete API documentation with planned endpoints and data models
- `SETUP_SUMMARY.md` - Implementation status and next steps
- `AGENTS.md` - Agent coordination guidelines and expertise level
