---
status: active — owner: rules/bluetooth.md
created: 2026-04-25
---

# BLE mouse pairing & auto-reconnect on BlueZ

## Rule

Always use the `ble-pair` script for BLE device pairing, never raw `bluetoothctl`. If a previously paired device won't reconnect, the BLE MAC has rotated — `bluetoothctl remove <MAC>` then re-pair.

## What happened

`bluetoothctl pair` against BLE devices like the Logitech MX Master 4 fails with `org.bluez.Error.AuthenticationFailed`. Separate `bluetoothctl` invocations lose the device between sessions because BLE uses rotating random MACs. Default BlueZ config does not auto-reconnect. Original capture lived in `.claude/lessons/ble-mouse-pairing-bluez.md` (15 paragraphs), compressed to one-liner in commit `1a2a562`.

## Evidence

- Scan + pair + connect must happen in a *single persistent bluetoothctl session* with `agent NoInputNoOutput` (default agent type causes auth failure on BLE "Just Works"). `ble-pair` at `scripts/.local/bin/ble-pair` wraps this dance.
- `/etc/bluetooth/main.conf` settings that matter:
  - `[General] Privacy = device` — stores IRK so BlueZ resolves rotated MACs
  - `[General] AutoEnable = true`, `FastConnectable = true`, `JustWorksRepairing = always`
  - `[Policy] ReconnectAttempts = 7`, `ReconnectIntervals = 1,2,4,8,16,32,64`
- Kernel LL Privacy bug since 5.9 breaks passive IRK resolution. Workaround: `btmgmt find -l` forces active LE discovery that resolves rotated MACs from stored IRKs (confirmed via BlueZ issues #875, #1079).
- Custom `ble-autoconnect` daemon at `/usr/local/bin/ble-autoconnect` (source: `scripts/.local/bin/ble-autoconnect`), systemd unit `bluetooth-autoconnect.service`, polls every 30s and runs `btmgmt find` before reconnecting trusted-but-disconnected devices.
- Sleep/resume hook at `/usr/lib/systemd/system-sleep/bt-reconnect.sh` runs `btmgmt find` on wake.

## Dead ends

- Default `Privacy = off` — no IRK stored, reconnection always fails after MAC rotation.
- Default `ReconnectAttempts = 0` — BlueZ never retries after link loss.
- Upstream `jrouleau/bluetooth-autoconnect` — only triggers on adapter power-on, doesn't handle the steady-state rotated-MAC case.

## Scope

Fedora 43, BlueZ 5.86, IMC Networks Bluetooth radio (USB internal), Logitech MX Master 4 (3 BLE channels, ~30s pairing window). Laptop is USB-C only — no Bolt receiver. If reconnect fails after days-long idle, MAC may have rotated past IRK resolution: `bluetoothctl remove <MAC>` + `ble-pair` is the nuclear option.
