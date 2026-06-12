---
status: archived — owner: lessons-archive.md
created: 2026-05-12
archived: 2026-06-08
---

# USB-C hub PD passthrough not supported on Vivobook M1502YA

## Rule

ASUS Vivobook M1502YA has no UCSI support — USB-C hub charging is a hardware limitation, not fixable in software. Workaround: charge direct on USB-C, hub on USB-A via adapter.

## What happened

Charging through a UGREEN Revodok 1071 USB-C hub doesn't work — laptop shows "discharging", `AC0` stays offline. Data passthrough (mouse/keyboard dongles) works. Direct charger-to-laptop USB-C works. The EC handles PD negotiation autonomously for direct connections only; hub PD passthrough requires OS-side UCSI, which ASUS never implemented on this Vivobook model. Original capture lived in `.claude/lessons/usbc-hub-charging-ucsi.md`, compressed to archive one-liner in commit `1a2a562`.

## Evidence

- `ls /sys/class/typec/` — empty
- `sudo cat /sys/bus/acpi/devices/*/hid | grep -i ucsi` — empty (no PNP0CA0 device)
- `lsmod | grep ucsi` — `ucsi_acpi` loaded with 0 references (nothing to bind to)
- ASUS WMI modules (`asus_nb_wmi`, `asus_wmi`, `asus_armoury`) load fine but cover keyboard backlight / fans / battery limits, not USB-C PD.
- Same UGREEN hub charges a ThinkPad on Windows — confirms hub is fine, the Vivobook is the limitation.

## Dead ends

1. Blacklisting `ucsi_acpi` — module wasn't binding to anything anyway.
2. EC reset (poweroff → unplug all → hold power 40s → wait 60s → boot) — no effect.
3. `acpi_enforce_resources=lax` kernel param — no effect, weakens ACPI for nothing.
4. **BIOS update 302 → 316** via EZ Flash — `dmidecode` confirms 316, but no UCSI device added, `/sys/class/typec/` still empty. ASUS never added UCSI in any firmware version.
5. Red Hat Bug 2248484 — NOT related (that's a partially-working UCSI; here UCSI does not exist at all).

## Scope

ASUS Vivobook M1502YA, Fedora 43, kernel 6.19.12. Hardware limitation — no alternative kernel modules apply (`tps6598x` = TI I2C controller not present, `cros_ec` = ChromeOS only). Workaround is permanent: charger direct into USB-C, hub into USB-A via a USB-C-female-to-USB-A-male adapter (loses DP alt mode and PD passthrough, neither of which worked anyway).
