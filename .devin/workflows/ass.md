---
description: Engineering Discipline — SOLID + Caveman + Ponytail
---
Apply these rules to the current task automatically — no confirmation step, no restating.

Communication — Caveman
Terse, high signal-to-noise. Conclusions and blockers first, no throat-clearing.
Cut hedging language and filler transitions.
Code volume — Ponytail decision ladder
Before writing any new code, climb the ladder and stop at the first rung that resolves the need:

Does this need to exist at all? If not, skip it (YAGNI).
Does a native platform/language feature already do this?
Does an existing dependency already do this?
Does an existing internal function or module already do this?
Only then write new code, and write the minimum required.
Security, input validation, accessibility, and correctness are never traded away for brevity.

Structure — SOLID, mapped to this stack
Single responsibility — one job per function, service, or component. Split fat services into single-responsibility builders plus a thin orchestrator. Repos declare only their type-specific queries.
Open/closed — extend through generic CRUD/protocol extensions rather than modifying shared base logic. Extract repeated boilerplate into a shared extension once, not per call site.
Liskov substitution — implementations must be safely interchangeable. Prefer typed Hashable/value-object keys over string-composite keys so a malformed substitute can't even compile.
Interface segregation — expose narrow, purpose-built overloads (e.g., a Database-accepting overload for transactional callers) instead of one bloated interface every caller has to satisfy.
Dependency inversion — pure logic (grouping, sorting, filtering, validation) takes its inputs as arguments and has no DB or network dependency; persistence and I/O are injected, not baked in.
Database layer
Verify counts and claims against the actual schema/data before writing docs or comments about it.
Add processed/status flags to staging tables for incremental processing.
Add unique constraints on natural keys to enable upsert-based dedup.
After an upsert ON CONFLICT, fetch the row to recover the auto-generated id — the insert callback only fires on insert, not on conflict.
Dedup order: check existing FK target → check natural key → only then create new.
Mark rows processed before purging; purge only processed rows, never everything.
Wrap multi-table writes in a single transaction for atomicity.
One owner for purge/cleanup logic — never duplicate it across layers.
Backend / domain logic
Check language and runtime version compatibility before using new language features.
Never force-unwrap values from DB operations — use guarded/optional unwrapping.
Extract pure logic (grouping, sorting, filtering) into functions with no DB dependency, and unit-test those before writing integration tests.
Generic CRUD lives in a protocol/interface extension; concrete repos add only what's type-specific.
Shared setup helpers for repeated boilerplate (migrations, config, fixtures).
Safe-unwrap inside any shared/generic code — a force-unwrap there breaks every caller, not just one.
When a shared protocol/interface changes, trace every consumer that breaks, not just the one that prompted the change.
Verify the cleanup path in tests: confirm the old method is actually gone and the new one is actually called.
Front-end / UI
One component, one responsibility — split a component the moment it's doing layout and data-fetching and business logic together.
Presentational components take props and render; container components hold state and side effects. Don't mix the two in one file.
Apply the same Ponytail ladder before adding a UI abstraction: does the design system already have this component? Does the framework already handle this state?
Prefer composition (children, slots) over configuration props that branch internally — an open/closed component accepts new behavior through composition, not through modifying its internals.
Cross-cutting
Group steps that would break each other's APIs into a single atomic change — don't land a breaking interface change and its fix as separate commits.
Delete dead code you find while touching nearby files; don't leave it for later.
If a repo or module is built ahead of demand, say so in its doc comment — "foundation for X, not yet consumed" — so it doesn't read as dead code.
When work connects to something already built, name that foundation in the docs instead of describing the new work in isolation.
