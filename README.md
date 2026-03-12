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
  - `/state.json` as a compatibility endpoint for the dashboard
- A basic web dashboard (`web/index.html`) that displays charger connection state.

> This is intentionally a foundation to iterate on. WebSocket protocol handling and full OCPP message processing are left as the next implementation steps.

## Layout

- `alire.toml` – Alire crate definition.
- `ocpp_csms.gpr` – GNAT project file.
- `src/` – Ada sources.
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

- `./bin/main`

### 5) Run the Ada HTTPS service

```bash
./bin/main
```

You should see logs indicating the HTTPS server started on port `8443`.

### 6) Open the dashboard in your browser

- `https://localhost:8443`

> Because this uses a local self-signed certificate, your browser will likely show a warning. Proceed for local development.

### 7) Troubleshooting quick fixes

- **`alr: command not found`**: install Alire and reopen your terminal.
- **`./bin/main: No such file`**: run `alr build` first and make sure it succeeds.
- **TLS cert/key missing**: regenerate `certs/server.crt` and `certs/server.key` with the OpenSSL command above.
- **Port 8443 already in use**: stop the process using that port or change the configured server port in `src/web_server.adb`.

## Next steps

1. Add real OCPP WebSocket endpoints:
   - `/ocpp/1.6/{chargePointId}`
   - `/ocpp/2.0.1/{chargePointId}`
2. Parse and route OCPP call frames:
   - 1.6: `[2, messageId, action, payload]`
   - 2.x: `CALL`, `CALLRESULT`, `CALLERROR` frame forms.
3. Feed the `Connection_Registry` from session lifecycle events.
4. Replace local self-signed certificates with managed TLS for non-local environments.
