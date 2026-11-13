# Dashboard tickets

This repository contains the first extracted data-access and validation layer for the [CCI Django dashboard](https://github.com/CCI-GU-Sweden/Dashboard-django). It is an early extraction, not a standalone application: the core still owns the ticket views, routes, templates, access checks, overview card and Django models.

The package currently uses the core's `accounts` models and the existing PostgreSQL ticket tables. Some SQL intentionally refers to existing `accounts_*` tables by name. Their data, Django migration history, transaction behavior and relationships must be preserved when moving the models; do not create, rename or delete tables as part of this code-only extraction. The core enforces access before calling these functions; they must not be exposed directly without authorization.

The ticket schema and integrations currently live in the existing deployment and collector repositories; setup, schema collision checks and any needed integration workloads will be brought into this repository in a later step. The image validation code uses Pillow. Existing code copyright is retained in [CORE_LICENSE](CORE_LICENSE); this repository is MIT licensed.
