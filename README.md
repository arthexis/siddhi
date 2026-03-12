# Ada OCPP CSMS Starter

This repository is a **starter template** for building an Ada-based CSMS that can serve OCPP chargers using JSON over WebSocket for:

- OCPP 1.6J
- OCPP 2.x (starting with 2.0.1/2.1-ready structure)

## What is included now

- Ada project scaffold (`alr`/GNAT project files).
- Core domain modules for:
  - connection state registry,
  - charger/session model,
  - OCPP version routing stub.
- A basic web dashboard (`web/index.html`) that displays charger connection state.
- Mock state endpoint payload (`web/state.json`) for immediate preview.

> This is intentionally a foundation to iterate on. WebSocket protocol handling and full OCPP message processing are left as the next implementation steps.

## Layout

- `alire.toml` – Alire crate definition.
- `ocpp_csms.gpr` – GNAT project file.
- `src/` – Ada sources.
- `web/` – Static dashboard UI.

## Start the service (absolute beginner walkthrough)

If you are new to Ada, follow these steps exactly.

### 1) Install tools

You need:

- **Git** (to clone the project)
- **Python 3** (to serve the dashboard files locally)
- **Alire (`alr`)** + GNAT (Ada compiler/toolchain)

Check if they are installed:

```bash
git --version
python3 --version
alr --version
```

If one command says "not found", install that tool first and then continue.

### 2) Clone the project

```bash
git clone <your-repo-url>
cd siddhi
```

### 3) Build the Ada starter service

```bash
alr build
```

This compiles the Ada code and creates the executable at:

- `./bin/main`

### 4) Run the Ada starter service

```bash
./bin/main
```

You should see log lines like:

- `OCPP CSMS Ada starter`
- `TODO: wire HTTP + WebSocket endpoints...`

> Note: this starter does not run a real HTTP/WebSocket backend yet. It seeds demo state and prints progress logs.

### 5) Start the dashboard in a second terminal

Keep `./bin/main` output visible, then open another terminal in the same project folder and run:

```bash
python3 -m http.server 8080 -d web
```

### 6) Open the dashboard in your browser

- `http://localhost:8080`

If everything is working, you will see the starter dashboard UI from `web/index.html`.

### 7) Troubleshooting quick fixes

- **`alr: command not found`**: install Alire and reopen your terminal.
- **`./bin/main: No such file`**: run `alr build` first and make sure it succeeds.
- **Port 8080 already in use**: use another port, for example:
  `python3 -m http.server 8081 -d web`
  and open `http://localhost:8081`.

## Next steps

1. Add an Ada HTTP/WebSocket server package (e.g., AWS or another Ada web stack).
2. Bind WebSocket endpoints:
   - `/ocpp/1.6/{chargePointId}`
   - `/ocpp/2.0.1/{chargePointId}`
3. Parse and route OCPP call frames:
   - 1.6: `[2, messageId, action, payload]`
   - 2.x: `CALL`, `CALLRESULT`, `CALLERROR` frame forms.
4. Feed the `Connection_Registry` from session lifecycle events.
5. Expose `/api/state` from Ada backend for live dashboard updates.
