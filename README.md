# ailapyu - AI chat app

A lightweight app, fully containerized application featuring a localized AI service in VPS.
The project pairs a Flutter Web frontend with a FastAPI backend, powered by a local Ollama LLM instance and a PostgreSQL database.

## Architecture Overview

```mermaid
graph TD
    User([User's Browser]) -- Port 8080 --> Frontend[ailapyu_frontend <br> Nginx / Flutter]
    Frontend -- Port 8000 --> API[ailapyu_api <br> FastAPI]
    API --> Ollama[ailapyu_ollama <br> Ollama LLM]
    API --> DB[ailapyu_db <br> PostgreSQL]

    style User fill:#f9f,stroke:#333,stroke-width:2px
    style Frontend fill:#bbf,stroke:#333,stroke-width:1px
    style API fill:#bbf,stroke:#333,stroke-width:1px
    style Ollama fill:#bfb,stroke:#333,stroke-width:1px
    style DB fill:#fbb,stroke:#333,stroke-width:1px
