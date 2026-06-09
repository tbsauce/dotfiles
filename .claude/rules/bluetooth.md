# Bluetooth Rules

- Always use the `ble-pair` script for BLE device pairing, never raw `bluetoothctl`. If a previously paired device won't reconnect, the BLE MAC has rotated — `bluetoothctl remove <MAC>` then re-pair.
