# Backend

Backend services for Altis live here.

## Current direction

- primary backend stack: NestJS
- database access: Prisma
- first service: `api-nest/`

## Architecture rule

Backend persistence models are not the shared app contract. Shared contracts belong in `shared/contracts/`.
