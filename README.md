# ailapyu

A lightweight AI chat app, fully containerized application featuring a localized AI service in VPS.
The project pairs a Flutter Web frontend with a FastAPI backend, powered by a local Ollama LLM instance and a PostgreSQL database.

## Architecture Overview

[ User's Browser ]
          │
          │ (Port 8080)
          ▼
┌──────────────────┐      (Port 8000)      ┌──────────────────┐
│  ailapyu_frontend│──────────────────────>│   ailapyu_api    │
│  (Nginx/Flutter) │                       │    (FastAPI)     │
└──────────────────┘                       └──────────────────┘
                                                     │
                             ┌───────────────────────┴───────────────────────┐
                             ▼                                               ▼
                  ┌──────────────────┐                            ┌──────────────────┐
                  │  ailapyu_ollama  │                            │    ailapyu_db    │
                  │     (Ollama)     │                            │   (PostgreSQL)   │
                  └──────────────────┘                            └──────────────────┘
