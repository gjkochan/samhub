# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SAMHub** is a monorepo containing two Git submodules:
- `sam_api` - Rails 7 API backend with Grape API framework
- `sam_ui` - Vue 3 + TypeScript frontend with Vuetify UI framework

This is a marketing analytics platform that integrates with multiple advertising platforms (Google Ads, Meta, LinkedIn, Pinterest, TikTok, Adform, etc.) and provides dashboards, reports, and marketplace functionality.

## Architecture

### Repository Structure
- **Monorepo with Git Submodules**: The main repository contains `sam_api` and `sam_ui` as submodules
- **Separate Development**: Each submodule has its own dependencies, build process, and can be developed independently
- **Docker Support**: Backend runs in Docker; frontend typically runs locally

### Backend (`sam_api`)
- **Framework**: Rails 7.0.4+ with Ruby 3.2.2
- **API**: Grape API framework mounted at `/api/v1/`, using JSON:API format
- **Database**: PostgreSQL with multiple databases (`primary` and `admin`)
- **Authentication**: OAuth2 with JWT tokens, supports multiple providers (Google, LinkedIn)
- **Admin Panel**: ActiveAdmin mounted at `/admin`
- **Background Jobs**: Sidekiq with Redis
- **Storage**: AWS S3 (MinIO for local development)
- **Documentation**: Swagger at `/swagger`

### Frontend (`sam_ui`)
- **Framework**: Vue 3 with TypeScript
- **Build Tool**: Vite
- **UI Library**: Vuetify 3
- **State Management**: Pinia with persistence
- **Routing**: Vue Router with route guards
- **Testing**: Vitest (unit), Playwright (e2e)
- **Analytics**: CubeJS integration for data visualization
- **Internationalization**: vue-i18n with backend-managed translations

### Key Architectural Patterns

**Backend:**
- **Grape API Mounting**: All API endpoints are Grape APIs mounted under `Api::V1::` namespace
- **Multi-Database Setup**: Uses Rails 7+ multiple database features with separate `primary` and `admin` databases
- **Service Objects**: Business logic in `app/services/`
- **Form Objects**: Reform for form validation in `app/forms/`
- **Pundit Authorization**: Policy-based authorization in `app/policies/`
- **Dry-rb Libraries**: Heavy use of dry-monads, dry-types, dry-struct for functional patterns
- **API Versioning**: All endpoints under `/api/v1/` namespace

**Frontend:**
- **Feature-Based Organization**: Views organized by feature (dashboard, marketplace, library, etc.)
- **Composables Pattern**: Reusable logic in `src/composables/`
- **Store Per Feature**: Each major feature has its own Pinia store
- **Layout System**: Multiple layouts (default, workspace) defined in router meta
- **Route Guards**: Authentication and workspace checks via `beforeEnter` guards
- **API Client**: Axios with retry logic in `src/api/`

## Development Setup

### Backend Setup (Docker)

```bash
cd sam_api

# Copy environment file
cp .env.docker .env
cp docker-compose.dev.yml docker-compose.yml

# Build and start services
docker-compose build
docker-compose up

# In another terminal, setup database
docker-compose exec app rails db:setup
docker-compose exec app rails db:populate  # optional seed data

# Access points:
# API: http://localhost:3000
# Admin Panel: http://localhost:3000/admin (admin@example.com / password)
# Swagger: http://localhost:3000/swagger
# Letter Opener (dev only): http://localhost:3000/letter_opener
```

**Key Backend Services:**
- `app` - Rails API (port 3000)
- `db.local` - PostgreSQL 15
- `redisapi` - Redis 7.2
- `minio` - S3-compatible storage (ports 9000, 9001)
- `playwright` - Playwright server (port 8080)

### Frontend Setup

```bash
cd sam_ui

# Setup environment
cp .env.example .env
cp .env.example .env.development.local
# Edit .env.development.local with your values

# Install dependencies
npm install
npm run prepare  # setup Husky hooks

# Generate system design files (Figma tokens → SCSS)
npm run generate-system-design

# Start development server
npm run dev  # runs on port 5173 by default
```

## Common Development Commands

### Backend (Rails API)

```bash
# Start server (Docker)
docker-compose up

# Rails console
docker-compose exec app rails c

# Run migrations
docker-compose exec app rails db:migrate

# Run specific migration
docker-compose exec app rails db:migrate:up VERSION=20240101120000

# Rollback migration
docker-compose exec app rails db:rollback

# Reset database
docker-compose exec app rails db:reset

# Run seeds
docker-compose exec app rails db:seed

# Translations management
docker-compose exec app rails seeds:import_translations    # Import from YAML
docker-compose exec app rails seeds:export_translations    # Export to YAML
docker-compose exec app rails seeds:export_frontend_translations  # Generate JSON for UI

# Production console access
bin/console                    # Rails console
bin/console bash              # Bash in container
bin/console rake db:version   # Run rake commands

# Staging console access
bin/staging_console
bin/staging_console bash
```

### Frontend (Vue)

```bash
# Development
npm run dev                    # Start dev server

# Build
npm run build                  # Type-check + build
npm run build-only             # Build only (no type-check)
npm run build-only:staging     # Build for staging
npm run build-only:production  # Build for production

# Testing
npm run test:unit              # Run unit tests
npm run test:unit-dev          # Run unit tests in watch mode
npm run test:e2e               # Run e2e tests (readonly only)
npm run test:e2e:all           # Run all e2e tests including @write tagged
npm run test:e2e:record        # Record API responses for mocking
npm run test:e2e:ui            # Open Playwright UI
npm run test:e2e:codegen       # Generate tests with Playwright

# Linting
npm run lint                   # Run ESLint with auto-fix

# System Design (Figma tokens)
npm run generate-system-design # Full pipeline: download → transform → build → fix
```

### Testing Notes

**Unit Tests:**
- Test files in `helpers/` (except `helpers/guard.ts` - use e2e)
- Test files in `composables/` (except `composables/use-snackbar.ts` - use e2e)

**E2E Tests:**
- Default user: `user@example.com` / `password`
- Set custom user: `SAMHUB_TEST_USERNAME` and `SAMHUB_TEST_PASSWORD` env vars
- Default target: `http://localhost:5173`
- Set custom target: `SAMHUB_TEST_UI_URL` env var
- API mocking enabled by default via recordings
- Disable mocking: `USE_API_RECORDINGS=false`

**Example - Run tests against production:**
```bash
USE_API_RECORDINGS=false \
SAMHUB_TEST_UI_URL=https://app.samhub.io \
SAMHUB_TEST_USERNAME=your@email.com \
SAMHUB_TEST_PASSWORD=yourpassword \
npm run test:e2e
```

## Critical Routing Conventions

**IMPORTANT: Rails uses UNDERSCORES in route paths, NOT hyphens.**

### Route Path Rules
- Rails API routes ALWAYS use underscores: `/tag_manager/shared_tags`
- Frontend URLs MUST match Rails routes exactly with underscores
- Directory names can use hyphens (e.g., `src/views/tag-manager/`)
- API paths must use underscores (e.g., `/api/v1/tag_manager/`)

### Common Routing Mistakes
```
✅ CORRECT:
/api/samhub/:org_slug/tag_manager/shared_tags
/api/samhub/:org_slug/context_app/domains

❌ WRONG (causes 500 errors):
/api/samhub/:org_slug/tag-manager/shared-tags
/api/samhub/:org_slug/context-app/domains
```

**Before creating new routes:**
1. Check Rails routes: `rails routes | grep [resource_name]`
2. Match the exact format from Rails (underscores!)
3. Update frontend API calls to match Rails format

## Multi-Database Architecture

The application uses Rails 7+ multiple database features:

### Databases
- **Primary**: Main application database with user data, workspaces, campaigns, reports
- **Admin**: Separate database for ActiveAdmin tables and admin-specific features

### Migration Commands
```bash
# Run all migrations
rails db:migrate

# Migrate specific database
rails db:migrate:primary
rails db:migrate:admin

# Check migration status
rails db:migrate:status
rails db:migrate:status:admin

# Migration files locations:
# - Primary: db/migrate/
# - Admin: db/migrate_admin/
```

## External Dependencies

### CubeJS Integration
Some features depend on running `samhub-cube` instance:
- Set `CUBEJS_API_URL` to point to running cube instance
- Docker config connects to `cubejs:4000` host by default
- Repository: https://github.com/brainnordic/samhub-cube

### Required Environment Variables

**Backend (.env):**
- `DATABASE_URL` - Primary database connection
- `ADMIN_DATABASE_URL` - Admin database connection
- `REDIS_URL` - Redis connection
- `BACKEND_URL` - For Active Storage disk server
- `FRONTEND_URL` - For CORS and redirects
- `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_SIGNING_SECRET`
- `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- `CUBEJS_API_URL` - CubeJS API endpoint

**Frontend (.env.development.local):**
- `VITE_API_URL` - Backend API URL
- System announcement variables (optional):
  - `VITE_SYSTEM_ANNOUNCEMENT_ENABLED`
  - `VITE_SYSTEM_ANNOUNCEMENT_ID`
  - `VITE_SYSTEM_ANNOUNCEMENT_TEXT`
  - `VITE_SYSTEM_ANNOUNCEMENT_SEVERITY`

## Deployment

### Versioning
- Based on Git tags using semantic versioning (e.g., `v1.0.1`, `v1.3.0-beta.1`)
- Create and push tag to trigger deployment

### Staging Deployment
```bash
git tag staging
git push origin staging
# CI/CD automatically deploys to staging environment
```

### Production Deployment
```bash
# 1. Create version tag
git tag v1.2.3
git push origin v1.2.3

# 2. Create GitHub release from tag
# CI/CD automatically deploys to production

# Docker image pushed to: 315002035614.dkr.ecr.eu-west-1.amazonaws.com/sam-api
```

### Production Access
```bash
# SSH to production
eb ssh sam-api-production

# SSH to staging
eb ssh samapi-staging
```

## Frontend Constants & Requirements

### Required Admin Panel Links
These constant links must exist in the admin panel:
- `/service-agreement` - Service agreement page
- `/cookie-policy` - Cookie policy page
- `/privacy-policy` - Privacy policy page
- `/how-remove-sam-script` - Script removal instructions

### Special Routes
- Add item to cart: `/marketplace/order/add-to-cart/<PRODUCT_ID>`

## System Announcements

Configure system-wide announcements via environment variables for maintenance notices or alerts:

```bash
VITE_SYSTEM_ANNOUNCEMENT_ENABLED=true
VITE_SYSTEM_ANNOUNCEMENT_ID=unique-announcement-id
VITE_SYSTEM_ANNOUNCEMENT_TEXT=Your announcement message
VITE_SYSTEM_ANNOUNCEMENT_SEVERITY=warning  # info | warning | error | success
VITE_SYSTEM_ANNOUNCEMENT_DISMISSIBLE=true
VITE_SYSTEM_ANNOUNCEMENT_LINK_TEXT=Learn More
VITE_SYSTEM_ANNOUNCEMENT_MODAL_TITLE=Detailed Title
VITE_SYSTEM_ANNOUNCEMENT_MODAL_CONTENT=<p>HTML content</p>
```

## Authentication Flow

1. **OAuth Providers**: Google, LinkedIn supported via OmniAuth
2. **Token-Based**: JWT tokens via Grape OAuth2
3. **Frontend Storage**: Tokens stored in Pinia with persistence
4. **Route Guards**: `mustBeLogged()` and `mustBeWorkspace()` guards in router
5. **Callback Routes**: Each provider has callback route (e.g., `/google-ads/callback`)

## Key Technologies

### Backend Stack
- Ruby 3.2.2 / Rails 7.0.4+
- Grape API (RESTful APIs with JSON:API format)
- PostgreSQL 15
- Redis 7.2
- Sidekiq (background jobs)
- ActiveAdmin (admin panel)
- Reform (form objects)
- Pundit (authorization)
- Dry-rb suite (functional patterns)
- Stripe (payments)
- AWS S3 / MinIO (storage)

### Frontend Stack
- Vue 3 (Composition API)
- TypeScript 4.7+
- Vite (build tool)
- Vuetify 3 (UI components)
- Pinia (state management)
- Vue Router (routing)
- Vitest (unit testing)
- Playwright (e2e testing)
- Axios (HTTP client)
- CubeJS (analytics)
- vue-i18n (internationalization)
- Chart.js / ECharts (visualization)

## Vendor Gems

### active_admin-sortable_tree
- Located in `vendor/gems/active_admin-sortable_tree`
- Modified because original uses CoffeeScript (not supported)
- Rewritten to JavaScript

## Grape API Structure

APIs are organized under `app/api/api/v1/` with feature-based modules:
- `auth/` - Authentication endpoints
- `current_user_route.rb` - Current user operations
- `current_workspace_route.rb` - Workspace context operations
- `integration_route.rb` - Integration management
- Feature-specific modules: `campaigns/`, `dashboards/`, `marketplace/`, etc.

All APIs mounted via `Api::Root` which includes OAuth2 middleware and error handling.

## Husky Git Hooks

- **commit-msg**: Runs commitlint (conventional commits)
- **pre-commit**: Runs ESLint
- **pre-push**: Runs unit tests

If hooks fail, run: `chmod ug+x .husky/*`

## Commit Convention

Uses conventional commits format:
```
type(scope): description

Examples:
feat(marketplace): add product filtering
fix(auth): resolve token refresh issue
refactor(dashboard): extract chart component
docs(readme): update setup instructions
```
