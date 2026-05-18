---
topic: usbc-hub-pd-charging
category: config-fix
learned: 2026-05-12
---

**Problem:** Charging through a USB-C hub (UGREEN Revodok 1071) doesn't work — laptop shows "discharging" and AC0 stays offline. Data passthrough works fine (mouse/keyboard dongles). Direct charger-to-laptop works. This is a hardware limitation of the ASUS Vivobook M1502YA, not a software bug.

**Root cause:** No UCSI ACPI device (`PNP0CA0`) exists in the firmware at all. The `ucsi_acpi` kernel module loads but binds to nothing (0 references) — `/sys/class/typec/` is empty, zero ucsi/typec messages in `dmesg`. The EC handles PD negotiation autonomously for direct charger connections only. Hub PD passthrough requires OS-side UCSI support that ASUS never implemented on this budget Vivobook model. This is a hardware/firmware design limitation, not a fixable software issue on any OS.

**What didn't work (all confirmed):**
1. Blacklisting `ucsi_acpi` — module not binding to anything anyway
2. EC reset (poweroff → unplug all → hold power 40s → wait 60s → boot) — no effect
3. `acpi_enforce_resources=lax` kernel param — no effect, weakens ACPI protection for no benefit
4. **BIOS update 302 → 316** — updated successfully via EZ Flash, confirmed `dmidecode` shows 316, but no UCSI device added. `/sys/class/typec/` still empty, zero dmesg messages. ASUS simply didn't add UCSI support in any firmware version.

**Confirmed diagnosis (post-BIOS update):**
- `sudo cat /sys/bus/acpi/devices/*/hid | grep -i ucsi` — empty, no UCSI ACPI device
- `lsmod | grep ucsi` — `ucsi_acpi` loaded with 0 references (nothing to bind to)
- `ls /sys/class/typec/` — empty
- ASUS WMI modules loaded (`asus_nb_wmi`, `asus_wmi`, `asus_armoury`) but these handle keyboard backlight/fans/battery limits, not USB-C PD
- Red Hat Bug 2248484 (UCSI_GET_PDOS failed) is NOT related — that's about a partially working UCSI, this is about UCSI not existing at all

**Workaround:** Use separate ports — charger direct into USB-C, hub into USB-A via a USB-C female to USB-A male adapter. Hub data works fine over USB-A (loses DisplayPort alt mode and PD passthrough, neither of which worked anyway). Laptop has 1x USB-C + USB-A ports.

**Diagnostic commands:**
- `ls /sys/class/typec/` — empty = no UCSI support
- `sudo cat /sys/bus/acpi/devices/*/hid | grep -i ucsi` — check for PNP0CA0 ACPI device
- `lsmod | grep ucsi` — check module binding (0 refs = nothing to bind to)
- `cat /sys/class/power_supply/AC0/online` — 1 = charging, 0 = not
- `cat /sys/class/power_supply/BAT0/status` — Charging/Discharging/Full
- `sudo dmidecode -s bios-version` — verify BIOS version (currently 316)

**Context:** ASUS Vivobook M1502YA, Fedora 43, kernel 6.19.12. Laptop has 1x USB-C port + USB-A ports. Hub charging was also tested to NOT work on a different device (ThinkPad on Windows worked, confirming the hub itself is fine — the ASUS laptop is the limitation). No alternative kernel modules apply (tps6598x = TI I2C controller not present, cros_ec = ChromeOS only).
