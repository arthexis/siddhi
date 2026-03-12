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

## Run the dashboard preview

```bash
python3 -m http.server 8080 -d web
```

Open:

- `http://localhost:8080`

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

