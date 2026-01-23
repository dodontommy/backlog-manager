# Development Setup Guide

## Prerequisites

- Ruby 3.2.3 or higher
- Rails 8.1.2
- PostgreSQL 13 or higher
- Bundler

## Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/dodontommy/backlog-manager.git
cd backlog-manager
```

2. Install Ruby dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
# Create the database
rails db:create

# Run migrations
rails db:migrate

# Seed the database (optional)
rails db:seed
```

4. Configure environment variables:
Create a `.env` file in the root directory with the following:
```bash
# Database
DATABASE_URL=postgresql://localhost/backlog_manager_development

# Steam API (optional, for Steam integration)
STEAM_API_KEY=your_steam_api_key_here

# GOG API (optional, for GOG integration)
GOG_CLIENT_ID=your_gog_client_id_here
GOG_CLIENT_SECRET=your_gog_client_secret_here

# Epic Games API (optional, for Epic integration)
EPIC_CLIENT_ID=your_epic_client_id_here
EPIC_CLIENT_SECRET=your_epic_client_secret_here

# AI Service API (optional, for AI recommendations)
# OPENAI_API_KEY=your_openai_key_here
# or
# ANTHROPIC_API_KEY=your_anthropic_key_here
```

## Running the Application

Start the Rails server:
```bash
rails server
```

The application will be available at http://localhost:3000

## Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage (if configured)
COVERAGE=true rails test
```

## Database Management

```bash
# Create a new migration
rails generate migration AddFieldToModel field:type

# Run pending migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (caution: destroys all data)
rails db:reset

# View database schema
rails db:schema:dump
```

## Code Quality

```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -A

# Run Brakeman security scanner
bin/brakeman

# Run bundler-audit for dependency vulnerabilities
bin/bundler-audit
```

## Project Structure

```
app/
├── controllers/     # Request handlers
├── models/          # Database models
├── services/        # Business logic
│   ├── ai_services/          # AI-related services
│   └── game_platforms/       # Game platform integrations
├── views/           # HTML templates
└── helpers/         # View helpers

db/
├── migrate/         # Database migrations
└── seeds.rb         # Seed data

test/
├── controllers/     # Controller tests
├── models/          # Model tests
└── fixtures/        # Test data
```

## API Integration Setup

### Steam
1. Get API key from https://steamcommunity.com/dev/apikey
2. Add to environment variables
3. Documentation: https://developer.valvesoftware.com/wiki/Steam_Web_API

### GOG
1. Register application at GOG Developer Portal
2. Obtain client credentials
3. Documentation: https://docs.gog.com/

### Epic Games
1. Register at Epic Games Developer Portal
2. Create application and get credentials
3. Documentation: https://dev.epicgames.com/

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running: `sudo service postgresql status`
- Check database credentials in `config/database.yml`
- Verify database exists: `psql -l`

### Gem Installation Issues
- Update bundler: `gem update bundler`
- Clear bundle cache: `bundle clean --force`
- Reinstall: `bundle install`

### Test Failures
- Ensure test database is set up: `rails db:test:prepare`
- Check for pending migrations: `rails db:migrate RAILS_ENV=test`

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linters
4. Submit a pull request

## Additional Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Ruby Style Guide](https://rubystyle.guide/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
