# ailapyu - AI chat app

A lightweight app, fully containerized application featuring a localized AI service in VPS.
The project pairs a Flutter Web frontend with a FastAPI backend, powered by a local Ollama LLM instance and a PostgreSQL database.

## Architecture Overview

User Browser ➡️ Flutter Web (8080) ➡️ FastAPI Backend (8000) ➡️ Ollama LLM / PostgreSQL DB
