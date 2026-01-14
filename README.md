# 🎮 What The Game

> **Your AI-Powered Gaming Companion**  
> Manage your game library, eliminate backlog anxiety, and discover your next favorite game with intelligent AI recommendations.

[![Rails Version](https://img.shields.io/badge/Rails-8.1.2-red.svg)](https://rubyonrails.org/)
[![Ruby Version](https://img.shields.io/badge/Ruby-3.2.3-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [The Problem](#-the-problem)
- [Our Solution](#-our-solution)
- [Key Features](#-key-features)
- [Quick Start](#-quick-start)
- [Documentation](#-documentation)
- [Technology Stack](#-technology-stack)
- [Project Status](#-project-status)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**What The Game** is a forward-thinking, AI-native application that helps gamers manage their ever-growing game libraries across multiple platforms. By leveraging cutting-edge AI technology, we provide intelligent recommendations, natural language game discovery, and insights that help you make the most of your gaming time.

### Why We Built This

Modern gamers face a unique problem: too many games, not enough time. With bundles, sales, and subscription services, game libraries have grown massive. The paradox of choice leaves people staring at hundreds of unplayed games, unable to decide what to play next.

**What The Game** uses AI to solve this problem, providing personalized recommendations that understand your preferences, mood, available time, and gaming patterns.

---

## 🎯 The Problem

- **Library Overload**: Hundreds of unplayed games across multiple platforms
- **Decision Paralysis**: Too many choices make it hard to pick what to play
- **Fragmented Libraries**: Games spread across Steam, GOG, Epic, Xbox, PlayStation, etc.
- **Lost Gems**: Great games buried in your backlog
- **Time Management**: Limited gaming time means every choice matters
- **Generic Recommendations**: Most recommendation systems don't understand YOU

---

## 💡 Our Solution

### Intelligent Library Management
- **Unified View**: All your games from all platforms in one place
- **Smart Deduplication**: Automatically identify games you own multiple times
- **Rich Metadata**: Enhanced game information, reviews, playtime estimates
- **Cross-Platform Tracking**: Track progress regardless of where you play

### AI-Powered Intelligence

#### Natural Language Game Discovery
```
You: "Find me a cozy game like Stardew Valley but with more combat"
AI: "I recommend Rune Factory 5. It combines farming simulation with 
     action RPG combat, similar to Stardew but with dungeon crawling."
```

#### Context-Aware Recommendations
- **Mood-Based**: "What should I play when I'm stressed?"
- **Time-Based**: "I have 30 minutes, what can I play?"
- **Social**: "What games do my friends and I all own?"
- **Pattern Recognition**: Learns your play style and preferences

#### Intelligent Backlog Optimization
- AI-powered priority scoring based on your preferences
- Time-to-beat estimates matched to your play style
- Dynamic reordering based on current mood and trends
- Completion probability predictions

### Advanced Features (Roadmap)
- **Conversational AI**: Ask questions about games, get intelligent answers
- **Review Analysis**: AI-generated summaries of thousands of reviews
- **Price Tracking**: Smart deal alerts for wishlist games
- **Social Features**: Compare libraries, find multiplayer matches
- **Gaming Analytics**: Understand your play patterns and preferences

---

## ✨ Key Features

### Available in MVP (Phase 1)
- ✅ **User Authentication**: Secure account management
- ✅ **Steam Integration**: Connect and sync your Steam library
- ✅ **Game Library Management**: View, sort, filter your games
- ✅ **Backlog Tracking**: Manage game status (backlog, playing, completed)
- ✅ **AI Recommendations**: Get personalized game suggestions
- ✅ **Game Notes & Ratings**: Add personal notes and rate your games

### Coming Soon (Phase 2-3)
- 🔄 **Multi-Platform Support**: GOG, Epic Games, Xbox, PlayStation
- 🔄 **Natural Language Search**: Find games using conversational queries
- 🔄 **Review Intelligence**: AI-powered review analysis
- 🔄 **Social Features**: Friend connections and library comparison
- 🔄 **Price Tracking**: Deal alerts for wishlist games
- 🔄 **Advanced Analytics**: Deep insights into gaming patterns

### Future Vision (Phase 4+)
- 🔮 **Conversational AI Assistant**: Chat about games, get recommendations
- 🔮 **Predictive Analytics**: Play session optimization
- 🔮 **Mobile Apps**: Native iOS and Android apps
- 🔮 **Public API**: Integrate with other services
- 🔮 **Community Features**: Clubs, challenges, leaderboards
- 🔮 **Developer Tools**: Plugin system for community extensions

---

## 🚀 Quick Start

### Prerequisites

- **Ruby** 3.2.3 or higher
- **Rails** 8.1.2
- **PostgreSQL** 13 or higher
- **Redis** (for caching and background jobs)
- **Node.js** (for asset compilation)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dodontommy/what-the-game.git
   cd what-the-game
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys and database credentials
   ```

4. **Create and migrate the database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # Optional: Load sample data
   ```

5. **Start the development server**
   ```bash
   rails server
   ```

6. **Visit the application**
   ```
   http://localhost:3000
   ```

### Getting API Keys

#### Steam API Key
1. Visit [Steam Web API Key](https://steamcommunity.com/dev/apikey)
2. Sign in with your Steam account
3. Register for a key (use `http://localhost:3000` for development)
4. Add to `.env`: `STEAM_API_KEY=your_key_here`

#### OpenAI API Key (for AI features)
1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Create an account and generate an API key
3. Add to `.env`: `OPENAI_API_KEY=your_key_here`

#### Alternative: Anthropic Claude
1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Generate an API key
3. Add to `.env`: `ANTHROPIC_API_KEY=your_key_here`

---

## 📚 Documentation

We've created comprehensive documentation to help you understand and contribute to the project:

### Core Documentation
- **[VISION.md](VISION.md)** - Product vision, innovative features, and long-term goals
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture, system design, and infrastructure
- **[ROADMAP.md](ROADMAP.md)** - Development phases, timeline, and feature prioritization
- **[API.md](API.md)** - API documentation and endpoint specifications
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Detailed development setup and workflows

### Quick Links
- **[Setup Summary](SETUP_SUMMARY.md)** - What's been completed so far
- **[Contributing Guidelines](#-contributing)** - How to contribute to the project
- **[Code of Conduct](#code-of-conduct)** - Community guidelines

---

## 🛠️ Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.1.2
- **Language**: Ruby 3.2.3
- **Database**: PostgreSQL 13+
- **Cache/Queue**: Redis + Solid Queue
- **Background Jobs**: Solid Queue (Rails 8)

### Frontend
- **Framework**: Hotwire (Turbo + Stimulus)
- **Asset Pipeline**: Importmap
- **Styling**: Tailwind CSS (planned)
- **Icons**: Heroicons

### AI & Machine Learning
- **LLM Providers**: OpenAI GPT-4, Anthropic Claude
- **Embeddings**: For semantic search
- **Future**: Custom ML models

### External APIs
- **Gaming Platforms**: Steam, GOG, Epic Games, Xbox, PlayStation
- **Game Data**: IGDB, RAWG, HowLongToBeat
- **Price Tracking**: IsThereAnyDeal

### DevOps
- **Containerization**: Docker
- **Deployment**: Kamal 2.0
- **CI/CD**: GitHub Actions
- **Monitoring**: Sentry (error tracking)
- **Code Quality**: RuboCop, Brakeman, Bundler-Audit

---

## 📊 Project Status

### Current Phase: **Phase 1 - MVP Development**

**Status**: Foundation Complete, Active Development

**Completed**:
- ✅ Rails application structure
- ✅ Database schema and models
- ✅ Service architecture framework
- ✅ Documentation (Vision, Architecture, Roadmap)
- ✅ Development environment setup

**In Progress**:
- 🔄 User authentication system
- 🔄 Steam integration implementation
- 🔄 AI recommendation engine

**Next Up**:
- ⏳ Game library UI
- ⏳ Backlog management features
- ⏳ Basic recommendation display

### Timeline
- **Week 1-2**: Authentication & Steam Integration
- **Week 3**: Game Library Management
- **Week 4**: Basic AI Recommendations
- **Week 5-8**: Multi-platform support
- **Week 9-12**: Advanced AI features

See [ROADMAP.md](ROADMAP.md) for complete timeline.

---

## 🧪 Development

### Running Tests
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/game_test.rb

# Run with coverage
COVERAGE=true rails test
```

### Code Quality
```bash
# Lint code with RuboCop
bin/rubocop

# Auto-fix issues
bin/rubocop -A

# Security audit
bin/brakeman

# Dependency vulnerabilities
bin/bundler-audit
```

### Database Operations
```bash
# Create new migration
rails generate migration AddFieldToModel field:type

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (caution!)
rails db:reset
```

### Background Jobs
```bash
# Start job processor
rails solid_queue:start

# Monitor jobs
rails console
> SolidQueue::Job.pending.count
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Ways to Contribute
1. **Report Bugs**: Open an issue with details and reproduction steps
2. **Suggest Features**: Share your ideas in the discussions
3. **Improve Documentation**: Fix typos, clarify instructions
4. **Write Code**: Pick up an issue and submit a PR
5. **Test Features**: Try the app and provide feedback

### Development Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write/update tests
5. Run test suite and linters
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Standards
- Follow Ruby style guide
- Write tests for new features
- Update documentation
- Keep commits atomic and well-described
- Ensure all tests pass
- Run linters before submitting

---

## 📄 License

Copyright © 2026 What The Game

All rights reserved. This project is proprietary software.

---

## 🙏 Acknowledgments

### Inspiration
- [Backloggd](https://www.backloggd.com/) - Game tracking and reviews
- [HowLongToBeat](https://howlongtobeat.com/) - Game completion times
- [Grouvee](https://www.grouvee.com/) - Game collection management

### Technologies
- [Ruby on Rails](https://rubyonrails.org/) - Web framework
- [PostgreSQL](https://www.postgresql.org/) - Database
- [OpenAI](https://openai.com/) - AI capabilities
- [Anthropic](https://www.anthropic.com/) - Claude AI

### Community
- Steam community for extensive API documentation
- Rails community for excellent frameworks and gems
- Early adopters and testers who provide valuable feedback

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/dodontommy/what-the-game/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dodontommy/what-the-game/discussions)
- **Email**: support@whatthegame.com (coming soon)
- **Twitter**: [@whatthegame](https://twitter.com/whatthegame) (coming soon)

---

## 🗺️ Roadmap Highlights

### Q1 2026 (Current)
- ✅ Foundation and architecture
- 🔄 MVP with Steam integration
- 🔄 Basic AI recommendations

### Q2 2026
- Multi-platform support (GOG, Epic)
- Natural language search
- Enhanced AI features
- Social features

### Q3 2026
- Premium tier launch
- Mobile PWA
- Price tracking
- Advanced analytics

### Q4 2026
- Public API
- Native mobile apps
- Developer tools
- Scale to 10,000+ users

See [ROADMAP.md](ROADMAP.md) for complete details.

---

## ⭐ Star Us!

If you find this project interesting, please consider giving it a star! It helps us understand interest and motivates development.

---

<div align="center">

**Made with ❤️ and 🤖 AI**

*Eliminating backlog anxiety, one game at a time*

[Vision](VISION.md) • [Architecture](ARCHITECTURE.md) • [Roadmap](ROADMAP.md) • [API Docs](API.md)

</div>
