# floats — Architecture

> Auto-generated from `.loom/diagrams/`. Do not edit directly — update loom-spec and regenerate.

## Overview

Service-oriented vertical stack. API Gateway + Feature Services on top, Backend (drill-down for internals) in the middle, models at bottom. Backend reaches out horizontally to external platform APIs.

```
         ┌──────────────┐     ┌──────────────────┐
         │  API Gateway  │     │ Reminder Service  │  ◀── Feature
         └──────┬───────┘     └────────┬─────────┘
                │                        │
         ┌──────▼───────────────────────▼──┐
         │          Backend                 │  ──▶ Platform APIs (horizontal)
         │         (drill down)             │
         └──────────────┬──────────────────┘
                        │
         ┌──────────────▼──────────────────┐
         │          Models                  │  ◀── Shared domain types
         └─────────────────────────────────┘
```

## Components

### API Gateway (`api-gateway`)
- **Status**: planned
- Top-level entry point. Routes UI requests to the backend and feature services. Single access point for all features.
- Endpoints: getPersons, getPerson, getOverduePersons, updateNotes, addTag, removeTag, setReminder, logContact, addManualConversation, triggerSync

### Reminder Service (`reminder-service`)
- **Status**: planned
- Feature service. Cadence + overdue logic. Recomputes next_reminder_at from last_contacted_at + cadence_days. Reads/writes reminders via backend persistent repo.
- Domain: reminders
- Responsibilities: recompute next reminders, query overdue

### Backend (`backend`)
- **Status**: planned
- On-device backend. Sync engine, profile builder, purge service, repositories, and SQLite storage.
- **Drill down**: [backend.flow.json](#backend-internals) for internal architecture
- Domain: data processing + persistence
- Responsibilities: sync from platforms, process raw data into person profiles, purge temp data

### Platform APIs (`external-api`)
- **Status**: planned
- Platform connectors reached horizontally by the backend sync engine. iMessage (Messages framework), WhatsApp (chat export), Instagram (data export), Manual entry.
- URL: on-device: Messages framework, file imports
- Auth: platform-specific

### Domain Models (`model`)
- **Status**: planned
- Shared Sendable structs. Flow between backend and API gateway. Define the data contract across layers.
- Properties: TBD — defined per feature

## Data Flow

```
API Gateway ──trigger sync + read data──▶ Backend
API Gateway ──get overdue persons──▶ Reminder Service
Reminder Service ──read + update reminders──▶ Backend
Backend ──fetch from platforms──▶ Platform APIs
Platform APIs ──raw data to sync pipeline──▶ Backend
Backend ──map to domain structs──▶ Models
API Gateway ──return domain types to UI──▶ Models
```

---

## Backend Internals

> From `.loom/diagrams/backend.flow.json`. Drill down from the `backend` node in the overview.

On-device backend organized into 5 architectural layers (Loom groups). Each container houses related components. Edges show cross-boundary communication. All local, SQLite/GRDB.

```
┌─ Sync Pipeline ──────────────────────┐    ┌─ Platform Connectors ─┐
│  Sync Engine                         │───▶│  iMessage, WhatsApp,   │
│  Profile Builder                     │    │  Instagram, Manual    │
│  Purge Service                       │    └───────────────────────┘
└──┬───────────┬───────────────────────┘
   │           │
   │  ┌────────▼────────────────────────┐
   │  │      Data Access Layer           │
   │  │  Persistent Repo  Raw Data Repo  │
   │  └────────┬─────────────────────────┘
   │           │ dependency
   │  ┌────────▼────────────────────────┐
   │  │      Storage                     │
   │  │  Database Manager (GRDB)         │
   │  └────────┬─────────────────────────┘
   │           │
   │  ┌────────▼────────────────────────┐
   │  │      Domain Models               │
   │  └─────────────────────────────────┘
```

### Backend Components

#### Sync Pipeline (container: `sync-pipeline`)
- **Sync Engine** (`sync-engine`) — Orchestrates the fetch → process → purge cycle. Iterates registered platform connectors, inserts raw data, then triggers ProfileBuilder and PurgeService. Schedule: BGAppRefreshTask (system-managed, 15 min min). Retry: exponential backoff, max 6 attempts.
- **Profile Builder** (`profile-builder`) — Raw → profile transform. Matches raw accounts to persons via platform_handle, groups messages by person + time window into conversation entries, extracts topics, updates last_contacted_at on reminders.
- **Purge Service** (`purge-service`) — Deletes processed raw data after ProfileBuilder completes. Raw data lives only between fetch and processing — typically seconds.

#### Platform Connectors (container: `platform-connectors-group`)
- **Platform Connectors** (`platform-connectors`) — Protocol-based platform fetchers. One protocol, multiple implementations: iMessage (Messages framework), WhatsApp (chat export import), Instagram (data export JSON), Manual entry.

#### Data Access Layer (container: `data-access`)
- **Persistent Repository** (`persistent-repo`) — Data access for persistent tables. Source of truth. Tables: person, platform_handle, conversation_entry, tag, person_tag, reminder. Written by ProfileBuilder, read by API Gateway and feature services.
- **Raw Data Repository** (`raw-data-repo`) — Data access for temporary tables. Tables: raw_message, raw_account. Written by SyncEngine, read by ProfileBuilder, purged by PurgeService. Raw data never reaches the UI layer.

#### Storage (container: `storage`)
- **Database Manager** (`database-manager`) — GRDB wrapper + schema migrations. Provides DatabaseQueue/DatabasePool to repositories. Foundation layer — all repos read/write through this. Engine: sqlite. All tables.

#### Domain Models (container: `domain-models-group`)
- **Domain Models** (`domain-models`) — Sendable structs. Person, PlatformHandle, ConversationEntry, Tag, Reminder (persistent). RawMessage, RawAccount (temporary). PersonCard (aggregate for UI).

### Backend Data Flow

```
Sync Engine ──fetch messages + accounts──▶ Platform Connectors
Sync Engine ──insert raw data──▶ Raw Data Repo
Sync Engine ──trigger processing──▶ Profile Builder
Sync Engine ──trigger purge──▶ Purge Service
Profile Builder ──read unprocessed raw──▶ Raw Data Repo
Profile Builder ──upsert persons + conversations──▶ Persistent Repo
Purge Service ──delete processed rows──▶ Raw Data Repo
Persistent Repo ──GRDB access──▶ Database Manager
Raw Data Repo ──GRDB access──▶ Database Manager
Database Manager ──map records to domain structs──▶ Domain Models
```

## Folder Structure

```
Sources/
├── floatsApp.swift              # @main entry, registers background fetch
├── App/
│   └── AppFactory.swift         # Dependency injection, wires services
├── Core/
│   ├── Database/
│   │   └── DatabaseManager.swift    # Actor, GRDB wrapper + migrations
│   ├── Networking/
│   │   ├── APIClient.swift          # Actor, URLSession + async/await
│   │   └── Connectors/
│   │       ├── PlatformConnector.swift    # Protocol
│   │       ├── IMessageConnector.swift
│   │       ├── WhatsAppConnector.swift
│   │       ├── InstagramConnector.swift
│   │       └── ManualEntryConnector.swift
│   ├── Processing/
│   │   └── ProfileBuilder.swift     # Raw → profile transform
│   ├── Sync/
│   │   ├── SyncEngine.swift         # Actor, fetch + process + purge
│   │   ├── PurgeService.swift       # Deletes processed raw data
│   │   └── BackgroundFetchScheduler.swift  # BGAppRefreshTask registration
│   └── AppRouter.swift              # API gateway, routes UI calls
├── Models/
│   ├── Person.swift
│   ├── PlatformHandle.swift
│   ├── ConversationEntry.swift
│   ├── Tag.swift
│   ├── Reminder.swift
│   ├── RawMessage.swift
│   ├── RawAccount.swift
│   └── PersonCard.swift             # Aggregate for UI
├── Repositories/
│   ├── PersonRepository.swift
│   ├── ConversationRepository.swift
│   ├── TagRepository.swift
│   ├── ReminderRepository.swift
│   └── RawDataRepository.swift
├── Features/
│   └── Reminders/
│       └── ReminderService.swift    # Cadence + overdue logic
└── ViewModels/
    ├── PersonListViewModel.swift
    └── PersonCardViewModel.swift
```

## Key Decisions

- **Service-oriented overview, layered backend** — overview is service-oriented (API Gateway, Feature Services, Backend as peers); backend internals are layered (Sync Pipeline → Data Access → Storage → Domain Models).
- **Vertical stack** — API Gateway + Feature Services → Backend → Models. Top-down dependency flow.
- **Drill-down** — Backend is one node in the overview; its internal complexity is a separate sub-diagram.
- **Horizontal outreach** — backend reaches out sideways to platform APIs without going through the stack.
- **Process-then-purge** — raw data is temporary. SyncEngine fetches → ProfileBuilder processes → PurgeService deletes. Raw tables never accumulate.
- **Two repository layers** — raw (temporary, purged) and persistent (source of truth). Different connectivity, different lifecycle.
- **Platform dedup** — one person can have handles on multiple platforms. Matching by (platform, handle) unique constraint.
- **GRDB.swift** (v7.5.0) — SQLite wrapper, 10-20x faster than SwiftData
- **Actors** for DatabaseManager, SyncEngine, ProfileBuilder, PurgeService — Swift 6 strict concurrency safe
- **BGAppRefreshTask** — system-managed background fetch, 15 min minimum interval
- **Offline-first** — persistent tables are source of truth. Sync engine updates from platform connectors on schedule.
