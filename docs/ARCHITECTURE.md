# floats — Architecture

> Auto-generated from `.loom/diagrams/overview.flow.json`. Do not edit directly — update loom-spec and regenerate.

## Overview

Service-oriented vertical stack. API Gateway on top, services stacked vertically, database at bottom. Services reach out horizontally to external APIs.

```
         ┌──────────────┐
         │  API Gateway  │  ◀── UI entry point
         └──────┬───────┘
                │
         ┌──────▼───────┐
         │ Sync Service  │  ──▶ External API (horizontal)
         └──────┬───────┘
                │
         ┌──────▼───────┐
         │   Database    │  ◀── Foundation (SQLite/GRDB)
         └──────┬───────┘
                │
         ┌──────▼───────┐
         │    Models     │  ◀── Shared domain types
         └──────────────┘
```

## Components

### API Gateway (`api-gateway`)
- **Status**: planned
- Top-level entry point. Routes UI requests to appropriate services. Single access point for all features.
- Endpoints: TBD — defined per feature

### Sync Service (`sync-service`)
- **Status**: planned
- Background fetch / cron updater. Runs on BGAppRefreshTask schedule. Reaches out horizontally to external APIs, writes down to database.
- Schedule: BGAppRefreshTask (system-managed, 15 min min)
- Retry policy: exponential backoff, max 6 attempts

### SQLite Database (GRDB) (`database`)
- **Status**: planned
- Foundation layer. On-device persistence via GRDB.swift. All services read/write here. Source of truth for offline-first.
- Engine: sqlite
- Tables: TBD — defined per feature

### External API (`external-api`)
- **Status**: planned
- Remote third-party or backend API. Reached horizontally by API gateway + sync service. URLSession + async/await.
- URL: TBD
- Auth: TBD

### Domain Models (`model`)
- **Status**: planned
- Shared Sendable structs. Flow between database, services, and API gateway. Define the data contract across layers.
- Properties: TBD — defined per feature

## Data Flow

```
API Gateway ──trigger sync──▶ Sync Service
Sync Service ──persist fetched data──▶ Database
Sync Service ──scheduled fetch──▶ External API
API Gateway ──on-demand fetch──▶ External API
API Gateway ──read local data──▶ Database
Database ──map records to domain──▶ Models
External API ──decode response to domain──▶ Models
API Gateway ──return domain types to UI──▶ Models
```

## Folder Structure

```
Sources/
├── floatsApp.swift              # @main entry, registers background fetch
├── App/
│   └── AppFactory.swift         # Dependency injection, wires services
├── Core/
│   ├── Database/
│   │   └── DatabaseManager.swift    # Actor, GRDB wrapper
│   ├── Networking/
│   │   └── APIClient.swift          # Actor, URLSession + async/await
│   └── Sync/
│       ├── SyncEngine.swift         # Actor, fetch + persist with retry
│       └── BackgroundFetchScheduler.swift  # BGAppRefreshTask registration
├── Models/
│   └── Model.swift                  # Domain models (Sendable structs)
└── Services/                        # Service modules (vertical slices)
```

## Key Decisions

- **Service-oriented** — services are primary units, not layers. Each service owns its domain.
- **Vertical stack** — API Gateway → Services → Database. Top-down dependency flow.
- **Horizontal outreach** — services reach out sideways to external APIs without going through the stack.
- **GRDB.swift** (v7.5.0) — SQLite wrapper, 10-20x faster than SwiftData
- **Actors** for DatabaseManager, APIClient, SyncEngine — Swift 6 strict concurrency safe
- **BGAppRefreshTask** — system-managed background fetch, 15 min minimum interval
- **Offline-first** — Database is source of truth. Sync service updates from external APIs on schedule.
