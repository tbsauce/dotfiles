---
topic: ble-mouse-pairing
category: config-fix
learned: 2026-04-25
---

**Problem:** `bluetoothctl pair` fails with `org.bluez.Error.AuthenticationFailed` for BLE devices like Logitech MX Master 4. Separate `bluetoothctl` invocations lose the device between sessions because BLE uses random rotating MAC addresses. Auto-reconnect doesn't work with default BlueZ config.

**Fast path:** `ble-pair "MX Master 4"` — script at `scripts/.local/bin/ble-pair` wraps the full dance below. Just run it when the mouse LED is fast-blinking. The script uses substring matching so `ble-pair "MX Master"` also works (BLE devices sometimes advertise a short name before updating to the full name).

**Solution:** Run scan + pair + connect in a single persistent bluetoothctl session with the correct agent:
1. Use `agent NoInputNoOutput` (required for BLE "Just Works" pairing — default agent type causes auth failure)
2. Scan, pair, and connect in the **same session** — don't exit bluetoothctl between steps
3. If pairing keeps failing, switch to an unused channel on the mouse (1/2/3 button on bottom) and re-enter pairing mode
4. `trust <MAC>` after pairing enables auto-reconnect on boot
5. A python subprocess wrapper works well for scripting this since `expect` may not be installed

**BlueZ config for auto-reconnect** (`/etc/bluetooth/main.conf`):

Under `[General]`:
- `Privacy = device` — stores IRK so BlueZ can resolve BLE rotating MACs (critical for reconnection)
- `AutoEnable = true` — Bluetooth powers on at boot
- `FastConnectable = true` — faster reconnection for paired devices
- `JustWorksRepairing = always` — auto-accept BLE re-pairing without manual intervention

Under `[Policy]`:
- `ReconnectAttempts = 7` — actively retry after link loss (default was 0/disabled)
- `ReconnectIntervals = 1,2,4,8,16,32,64` — exponential backoff in seconds between retries

After changing these: `sudo systemctl restart bluetooth`. This invalidates existing pairings (MAC rotates), so re-pair once with `ble-pair`. After that, auto-reconnect works — mouse reconnects on its own after power cycle, sleep, etc.

**When reconnection fails on a previously paired device:**
- BLE uses random rotating MACs — the saved MAC goes stale over time
- Symptom: `connect` returns `le-connection-abort-by-local` or `Input/output error` on a device that shows `Paired: yes`
- Fix: `bluetoothctl remove <old-MAC>`, then put mouse in pairing mode and do a fresh scan+pair+trust+connect cycle
- The new MAC is often only 1-2 digits different from the old one, but BlueZ cannot resolve it without a fresh scan

**Why Linux Bluetooth is worse than Windows:**
- BlueZ is the only Bluetooth stack for Linux — no alternatives exist
- Windows has a proprietary stack with vendor-specific quirks baked into drivers (Microsoft works directly with Logitech etc.)
- BlueZ defaults are bad for BLE: wrong privacy mode (`off` instead of `device`), no reconnect attempts, wrong agent type for Just Works pairing
- The `Privacy = device` + `ReconnectAttempts = 7` config fixes are the biggest improvements
- Known BlueZ bug: BLE HID reconnect is unreliable (github.com/bluez/bluez/issues/875, #1079). Root cause: kernel LL Privacy bug (since 5.9) breaks passive IRK resolution for rotated BLE MACs
- **Fix: `btmgmt find -l`** forces active LE discovery that resolves rotated MACs via stored IRKs. This is the confirmed workaround from the BlueZ issue tracker
- **Custom `ble-autoconnect` daemon** at `/usr/local/bin/ble-autoconnect` (source: `scripts/.local/bin/ble-autoconnect`), systemd service `bluetooth-autoconnect.service`. Polls every 30s, runs `btmgmt find` before connecting disconnected trusted devices. Replaced upstream jrouleau/bluetooth-autoconnect which only triggered on adapter power-on
- **Sleep/resume hook** at `/usr/lib/systemd/system-sleep/bt-reconnect.sh` — runs `btmgmt find` immediately on wake from suspend
- If devices still don't reconnect after extended disconnect (days): MAC may have rotated beyond IRK resolution. Use `bluetoothctl remove <MAC>` + `ble-pair` as last resort

**Troubleshooting commands:**
- `sudo sed -i 's/^#Privacy = off/Privacy = device/' /etc/bluetooth/main.conf` — keep these as one-liners, multiline sed breaks in zsh terminal paste
- `bluetoothctl info <MAC>` — check Connected/Paired/Trusted status
- `bluetoothctl remove <MAC>` then `ble-pair` — nuclear option for stale connections
- `sudo systemctl restart bluetooth` can hang with connected devices — disconnect first or just wait

**Hardware context:**
- Fedora 43, BlueZ 5.86, IMC Networks Bluetooth Radio (USB, internal)
- Logitech MX Master 4 (BLE with 3 switchable channels, ~30s pairing timeout)
- Laptop has USB-C only — no Bolt receiver (would need USB-C Bolt or adapter)
- Bolt receiver (proprietary 2.4GHz, not Bluetooth) bypasses BlueZ entirely and is the most reliable option if ports allow
