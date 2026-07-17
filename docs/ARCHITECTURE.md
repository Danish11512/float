# floats — Architecture

> Auto-generated from `.loom/diagrams/overview.flow.json`. Do not edit directly — update loom-spec and regenerate.

## Overview

MVVM + Repository pattern. SQLite (GRDB) local DB. Background sync engine for cron updates.

## Layers

### SwiftUI Views (`view`)
- **Status**: planned
- Presentation layer. Renders state from ViewModel, sends user intents back.
- Screen: ContentView + feature views

### ViewModels (`viewmodel`)
- **Status**: planned
- @Observable view models. Hold UI state, call repository, never touch network/DB directly.
- State: @Observable, @MainActor

### Repository Layer (`repository`)
- **Status**: planned
- Data access abstraction. Decides local vs remote. Writes local first (offline-first).
- Entities: Feature-specific repositories

### SQLite Database (GRDB) (`database`)
- **Status**: planned
- On-device persistence via GRDB.swift. Source of truth for offline-first.
- Engine: sqlite
- Tables: TBD — defined per feature

### Sync Engine (`sync-engine`)
- **Status**: planned
- Background fetch task (BGAppRefreshTask). Pulls remote data on schedule, writes to local DB. Exponential backoff retry.
- Schedule: BGAppRefreshTask (system-managed)
- Retry policy: exponential backoff, max 6 attempts

### API Client (`api-client`)
- **Status**: planned
- URLSession + async/await. Handles remote fetch for sync engine + repository.
- Base URL: TBD

### Domain Models (`model`)
- **Status**: planned
- Sendable structs. Shared across layers. DB records map to these.
- Properties: TBD — defined per feature

## Data Flow

```
View ──user intent──▶ ViewModel
View ◀─observed state── ViewModel
ViewModel ──fetch/save──▶ Repository
Repository ──local read/write──▶ SQLite Database (GRDB)
Repository ──remote fetch (on-demand)──▶ API Client
Sync Engine ──scheduled fetch──▶ API Client
Sync Engine ──persist update──▶ SQLite Database (GRDB)
API Client ──decode response──▶ Domain Models
SQLite Database (GRDB) ──map records──▶ Domain Models
Repository ──return domain types──▶ Domain Models
```

## Folder Structure

```
Sources/
├── floatsApp.swift              # @main entry, registers background fetch
├── App/
│   └── AppFactory.swift         # Dependency injection container
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
├── Features/                        # Feature modules
├── Repositories/                    # Repository implementations
└── ViewModels/                      # View models
```

## Key Decisions

- **GRDB.swift** (v7.5.0) — SQLite wrapper, 10-20x faster than SwiftData
- **Actors** for DatabaseManager, APIClient, SyncEngine — Swift 6 strict concurrency safe
- **BGAppRefreshTask** — system-managed background fetch, 15 min minimum interval
- **Offline-first** — Repository writes local DB first, sync engine handles remote updates
- **@Observable** macro — Swift 5.9+, replaces ObservableObject
