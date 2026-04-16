---
topic: ble-mouse-pairing
category: config-fix
learned: 2026-03-28
---

**Problem:** `bluetoothctl pair` fails with `org.bluez.Error.AuthenticationFailed` for BLE devices like Logitech MX Master 4. Separate `bluetoothctl` invocations lose the device between sessions because BLE uses random rotating MAC addresses.

**Fast path:** `ble-pair "MX Master 4"` — script at `scripts/.local/bin/ble-pair` wraps the full dance below. Just run it when the mouse LED is fast-blinking.

**Solution:** Run scan + pair + connect in a single persistent bluetoothctl session with the correct agent:
1. Use `agent NoInputNoOutput` (required for BLE "Just Works" pairing — default agent type causes auth failure)
2. Scan, pair, and connect in the **same session** — don't exit bluetoothctl between steps
3. If pairing keeps failing, switch to an unused channel on the mouse (1/2/3 button on bottom) and re-enter pairing mode
4. `trust <MAC>` after pairing enables auto-reconnect on boot
5. A python subprocess wrapper works well for scripting this since `expect` may not be installed

**When reconnection fails on a previously paired device:**
- BLE uses random rotating MACs — the saved MAC goes stale over time
- Symptom: `connect` returns `le-connection-abort-by-local` or `Input/output error` on a device that shows `Paired: yes`
- Fix: `bluetoothctl remove <old-MAC>`, then put mouse in pairing mode and do a fresh scan+pair+trust+connect cycle
- The new MAC is often only 1-2 digits different from the old one, but BlueZ cannot resolve it without a fresh scan

**Context:** Fedora 43 BlueZ stack. Logitech MX mice use BLE with 3 switchable channels. The mouse times out of pairing mode after ~30 seconds. `connect` can succeed without `pair` but HID input won't work unless properly bonded. Power cycling the adapter (`power off`/`power on`) can leave it in `NotReady` state — always verify with `power on` before scanning.
