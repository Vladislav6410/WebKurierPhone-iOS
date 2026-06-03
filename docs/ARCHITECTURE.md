# WebKurierPhone-iOS Architecture

## Role

Level 3 iOS Client.

## Responsibilities

- native iOS UI
- API client
- secure local storage
- user interaction
- connection to Core and PhoneCore

## Must NOT

- contain business logic
- store WebCoin ledger
- control drones
- replace PhoneCore
- replace Core

## Boundary

iOS is a client only.