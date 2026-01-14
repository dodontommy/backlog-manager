# Contributing to What The Game

Thank you for considering contributing to **What The Game**! This document provides guidelines and best practices for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Issue Guidelines](#issue-guidelines)
8. [Documentation](#documentation)

---

## Code of Conduct

### Our Standards

- **Be Respectful**: Treat all contributors with respect and kindness
- **Be Collaborative**: Work together to solve problems
- **Be Patient**: Remember that everyone was a beginner once
- **Be Constructive**: Provide helpful, actionable feedback
- **Be Inclusive**: Welcome contributors of all backgrounds and experience levels

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling, insulting comments, or personal attacks
- Publishing others' private information
- Any conduct that would be inappropriate in a professional setting

---

## Getting Started

### Prerequisites

Ensure you have the following installed:
- Ruby 3.2.3 or higher
- Rails 8.1.2
- PostgreSQL 13+
- Git

### Initial Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/what-the-game.git
   cd what-the-game
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/dodontommy/what-the-game.git
   ```

4. **Install dependencies**:
   ```bash
   bundle install
   ```

5. **Setup database**:
   ```bash
   rails db:create db:migrate
   ```

6. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys (optional for basic development)
   ```

7. **Run tests**:
   ```bash
   rails test
   ```

8. **Start the server**:
   ```bash
   rails server
   ```

---

## Development Workflow

### Branching Strategy

We use a feature branch workflow:

```
main (production-ready code)
  └── develop (integration branch)
       ├── feature/your-feature-name
       ├── bugfix/issue-description
       ├── enhancement/improvement-name
       └── docs/documentation-update
```

### Creating a Feature Branch

1. **Update your local repository**:
   ```bash
   git checkout develop
   git pull upstream develop
   ```

2. **Create a new branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

   Branch naming conventions:
   - `feature/` - New features
   - `bugfix/` - Bug fixes
   - `enhancement/` - Improvements to existing features
   - `docs/` - Documentation updates
   - `refactor/` - Code refactoring
   - `test/` - Test additions or updates

3. **Make your changes** and commit frequently:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

4. **Keep your branch updated**:
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

---

## Coding Standards

### Ruby Style Guide

We follow the [Ruby Style Guide](https://rubystyle.guide/) with Rails conventions enforced by RuboCop.

**Run linter**:
```bash
bin/rubocop

# Auto-fix issues
bin/rubocop -A
```

### Code Quality Checklist

- [ ] Code follows Ruby and Rails style guides
- [ ] No RuboCop violations
- [ ] No Brakeman security warnings
- [ ] No N+1 queries (use `includes` for associations)
- [ ] Proper error handling
- [ ] Meaningful variable and method names
- [ ] Comments for complex logic
- [ ] No hardcoded credentials or API keys

### Service Object Pattern

Business logic should be in service objects, not controllers or models:

```ruby
# Good
class SyncSteamLibraryService
  def initialize(user)
    @user = user
  end

  def call
    # Business logic here
  end
end

# Usage
SyncSteamLibraryService.new(current_user).call
```

### Database Best Practices

- Always use migrations for schema changes
- Add indexes for foreign keys and frequently queried columns
- Use database constraints where appropriate
- Write reversible migrations

```ruby
# Good migration
class AddIndexToGames < ActiveRecord::Migration[8.0]
  def change
    add_index :games, [:platform, :external_id], unique: true
  end
end
```

---

## Testing Guidelines

### Test Coverage Requirements

- Models: 100% coverage
- Services: 95% coverage
- Controllers: 90% coverage
- Overall: 90%+

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage report
COVERAGE=true rails test
```

### Writing Good Tests

**Model Tests**:
```ruby
class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = User.new(username: "test")
    assert_not user.save, "Saved user without email"
  end

  test "should validate email uniqueness" do
    user1 = User.create!(email: "test@example.com", username: "test1")
    user2 = User.new(email: "test@example.com", username: "test2")
    assert_not user2.save, "Saved user with duplicate email"
  end
end
```

**Service Tests**:
```ruby
class RecommendationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @service = AiServices::RecommendationService.new(@user)
  end

  test "generates recommendations" do
    VCR.use_cassette("ai_recommendations") do
      recommendations = @service.generate_recommendations(limit: 5)
      assert_equal 5, recommendations.length
      assert recommendations.all? { |r| r.score.between?(0, 1) }
    end
  end
end
```

**Mocking External APIs**:

Use VCR to record HTTP interactions:
```ruby
VCR.use_cassette("steam_api_call") do
  # Code that makes API call
end
```

---

## Pull Request Process

### Before Submitting

1. **Run all checks**:
   ```bash
   bin/ci  # Runs linters, security scan, and tests
   ```

2. **Update documentation** if needed:
   - README.md for user-facing changes
   - API.md for API changes
   - ARCHITECTURE.md for architectural changes
   - Code comments for complex logic

3. **Add tests** for new features or bug fixes

4. **Update CHANGELOG** (if applicable)

### Submitting a Pull Request

1. **Push your branch** to your fork

2. **Create a pull request** on GitHub:
   - Base branch: `develop` (not `main`)
   - Title: Clear, descriptive summary
   - Description: Detailed explanation of changes

3. **PR Description Template**:
   ```markdown
   ## Description
   Brief description of what this PR does.

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Changes Made
   - Change 1
   - Change 2
   - Change 3

   ## Testing
   - [ ] Unit tests added/updated
   - [ ] Integration tests added/updated
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] No security vulnerabilities introduced

   ## Screenshots (if applicable)
   <!-- Add screenshots of UI changes -->

   ## Related Issues
   Closes #123
   ```

4. **Wait for review** and address feedback

5. **Merge** once approved (squash merge preferred)

### PR Review Process

**For Reviewers**:
- Review within 48 hours (best effort)
- Provide constructive feedback
- Approve once standards are met
- Use GitHub's suggestion feature for small changes

**For Contributors**:
- Respond to feedback within 48 hours
- Make requested changes
- Resolve conversations once addressed
- Be open to suggestions

---

## Issue Guidelines

### Reporting Bugs

Use the bug report template and include:
- Clear, descriptive title
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, Ruby version, etc.)
- Screenshots or error logs (if applicable)

**Example**:
```markdown
**Description**
Steam library sync fails for users with >1000 games

**Steps to Reproduce**
1. Connect Steam account
2. Click "Sync Library"
3. Wait for sync to complete

**Expected Behavior**
All games should sync successfully

**Actual Behavior**
Sync stops at 1000 games with timeout error

**Environment**
- OS: Ubuntu 22.04
- Ruby: 3.2.3
- Rails: 8.1.2
- Browser: Chrome 120

**Error Log**
```
Timeout::Error: execution expired
  at GamePlatforms::SteamPlatform#fetch_library
```
```

### Requesting Features

Use the feature request template and include:
- Clear use case
- Proposed solution
- Alternative solutions considered
- Additional context

### Asking Questions

- Check existing documentation first
- Search closed issues for similar questions
- Use GitHub Discussions for general questions
- Use Issues for specific technical questions

---

## Documentation

### Code Documentation

Use YARD-style comments for methods:

```ruby
# Generates AI-powered game recommendations for a user
#
# @param limit [Integer] Maximum number of recommendations to generate
# @param context [Hash] Additional context for recommendations
# @option context [String] :mood User's current mood
# @option context [Integer] :available_time Time available in hours
# @return [Array<Recommendation>] Array of recommendation objects
# @raise [APIError] If AI service is unavailable
def generate_recommendations(limit: 5, context: {})
  # Implementation
end
```

### Documentation Files

Keep these files up to date:
- **README.md** - Project overview and quick start
- **ARCHITECTURE.md** - System architecture and design
- **ROADMAP.md** - Development roadmap and features
- **API.md** - API endpoints and usage
- **AI_FEATURES.md** - AI capabilities and implementation
- **DEVELOPMENT.md** - Development setup and guidelines

---

## Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

**Good commits**:
```
feat(ai): add natural language query processing

Implement NaturalQueryService to parse user queries
and return relevant game recommendations.

Closes #123
```

```
fix(steam): handle API rate limiting properly

Add exponential backoff for Steam API requests
and better error messages for rate limit errors.

Fixes #456
```

**Bad commits**:
```
fixed stuff
update code
WIP
asdf
```

---

## AI Integration Guidelines

### Handling AI API Calls

1. **Always cache responses** (24h for recommendations)
2. **Handle errors gracefully** with fallbacks
3. **Log prompts and responses** for debugging (development only)
4. **Set timeouts** to prevent hanging requests
5. **Monitor costs** and implement rate limiting

### Prompt Engineering

- Keep prompts concise and focused
- Provide clear structure and output format
- Include relevant context only
- Test prompts with different user scenarios
- Version prompts for A/B testing

### Example Service Implementation

```ruby
class AiServices::BaseService
  TIMEOUT = 30.seconds

  def call_ai(prompt, model: 'gpt-4')
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      
      response = Timeout.timeout(TIMEOUT) do
        client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.7
          }
        )
      end
      
      response.dig('choices', 0, 'message', 'content')
    end
  rescue Timeout::Error, Faraday::Error => e
    Rails.logger.error("AI API Error: #{e.message}")
    fallback_response
  end

  private

  def cache_key
    # Implement cache key logic
  end

  def fallback_response
    # Implement fallback logic
  end
end
```

---

## Security Guidelines

### Sensitive Data

- **Never commit** API keys, passwords, or secrets
- **Use environment variables** for all credentials
- **Encrypt sensitive data** in the database
- **Sanitize user input** to prevent injection attacks

### Security Checklist

- [ ] No hardcoded credentials
- [ ] Input validation on all user data
- [ ] SQL injection prevention (use parameterized queries)
- [ ] XSS prevention (Rails default escaping)
- [ ] CSRF protection enabled
- [ ] Rate limiting implemented
- [ ] Authentication required for sensitive operations

### Reporting Security Issues

**DO NOT** open a public issue for security vulnerabilities.

Instead, email: security@whatthegame.com (when available)

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if known)

---

## Questions or Need Help?

- **Documentation**: Check README.md, ARCHITECTURE.md, and other docs
- **GitHub Discussions**: For general questions and ideas
- **GitHub Issues**: For specific bugs or feature requests
- **Email**: Contact the maintainers (when available)

---

## License

By contributing to What The Game, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing to What The Game! 🎮**

Together, we're building the future of gaming library management!
