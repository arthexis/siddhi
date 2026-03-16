# Ada OCPP CSMS Starter

This repository is a **starter template** for building an Ada-based CSMS that can serve OCPP chargers using JSON over WebSocket for:

- OCPP 1.6J
- OCPP 2.x (starting with 2.0.1/2.1-ready structure)

This repo exists primarily to experiment with Ada for CSMS development, so we prefer Ada-first solutions and avoid introducing other languages unless absolutely necessary.

## What is included now

- Ada project scaffold (`alr`/GNAT project files).
- Core domain modules for:
  - connection state registry,
  - charger/session model,
  - OCPP version routing stub.
- An Ada HTTPS server that serves:
  - `/` and `/index.html` from `web/index.html`
  - `/api/state` as live JSON generated from `Connection_Registry`
  - `/api/inbound?chargePointId=...&path=...&frame=...` to inject test OCPP frames into the router
  - `/state.json` as a compatibility endpoint for the dashboard
- A basic web dashboard (`web/index.html`) that displays charger connection state.
- A lightweight admin preview page (`/admin`, file: `web/admin/index.html`) for quick operational checks and frame simulation.

> This is intentionally a foundation to iterate on. WebSocket protocol handling and full OCPP message processing are left as the next implementation steps.

## Layout

- `alire.toml` – Alire crate definition.
- `ocpp_csms.gpr` – GNAT project file.
- `src/core/` – Core routing, parsing, and registry packages.
- `src/web/` – Ada HTTPS server package and web integration entrypoints.
- `src/cli/` – CLI/build main procedure (`csms_web_server.adb`).
- `src/ocpp/` – OCPP domain models and shared protocol packages.
- `src/ocpp16/` – OCPP 1.6-specific parser/dispatcher packages.
- `src/ocpp20/` – OCPP 2.0.x-specific operations and structures.
- `src/ocpp21/` – OCPP 2.1-specific operations and structures.
- `web/` – Static dashboard UI.
- `certs/` – TLS certificate and key for local HTTPS.

## Start the service (absolute beginner walkthrough)

If you are new to Ada, follow these steps exactly.

### 1) Install tools

You need:

- **Git** (to clone the project)
- **OpenSSL** (to generate local development certificates)
- **Alire (`alr`)** + GNAT (Ada compiler/toolchain)

Check if they are installed:

```bash
git --version
openssl version
alr --version
```

If one command says "not found", install that tool first and then continue.

### 2) Clone the project

```bash
git clone <your-repo-url>
cd siddhi
```

### 3) Generate local TLS certificates

```bash
mkdir -p certs
openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
  -keyout certs/server.key \
  -out certs/server.crt \
  -subj "/CN=localhost"
```

### 4) Build the Ada starter service

```bash
alr build
```

This compiles the Ada code and creates the executable at:

- `./bin/csms_web_server`

### 5) Run the Ada HTTPS service

```bash
./bin/csms_web_server
```

You should see logs indicating the HTTPS server started on port `8443`.

### 6) Open the dashboard in your browser

- `https://localhost:8443`
- `https://localhost:8443/admin`

> Because this uses a local self-signed certificate, your browser will likely show a warning. Proceed for local development.

### 7) Troubleshooting quick fixes

- **`alr: command not found`**: install Alire and reopen your terminal.
- **`./bin/csms_web_server: No such file`**: run `alr build` first and make sure it succeeds.
- **TLS cert/key missing**: regenerate `certs/server.crt` and `certs/server.key` with the OpenSSL command above.
- **Port 8443 already in use**: stop the process using that port or change the configured server port in `src/web/web_server.adb`.

## OCPP 1.6 implementation status

Implemented in this iteration:

- OCPP version detection from request path (including `/1.6`).
- OCPP 1.6 CALL frame validation for the array form: `[2, messageId, action, payload]`.
- Basic action dispatch for `BootNotification`, `Heartbeat`, and `StatusNotification`.
- Connection registry updates with parsed action context.

Still pending for full 1.6 support:

- WebSocket transport endpoint (`/ocpp/1.6/{chargePointId}`).
- JSON schema-level payload validation and CALLRESULT/CALLERROR generation.


## OCPP model package

`src/ocpp/ocpp-models.ads` now contains both runtime OCPP domain types and the charger session DB model/instance definitions.

- Runtime domain: `Charger_Session`, `OCPP_Version`, `Charger_State_Kind`
- DB model/instance: `Charger_Session_Model`, `Session_Status`
- Canonical table/column constants for `charger_sessions` are defined in the same package for repository/query reuse.

## Next steps

1. Add real OCPP WebSocket endpoints:
   - `/ocpp/1.6/{chargePointId}`
   - `/ocpp/2.0.1/{chargePointId}`
2. Parse and route OCPP call frames:
   - 1.6: `[2, messageId, action, payload]`
   - 2.x: `CALL`, `CALLRESULT`, `CALLERROR` frame forms.
3. Feed the `Connection_Registry` from session lifecycle events.
4. Replace local self-signed certificates with managed TLS for non-local environments.
