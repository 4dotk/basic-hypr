#!/usr/bin/env -S python3 -I
"""wallet-to-nm.py — move Wi-Fi / 802.1x passwords from KDE Wallet into NetworkManager.

Networks saved under Plasma often keep their password in KDE Wallet
(secret flag "agent-owned"). Outside Plasma nothing hands that password to
NetworkManager, so those networks never autoconnect. This copies each one
into NetworkManager's own root-only storage and clears the flag.

    wallet-to-nm.py --dry-run    list what would move, change nothing
    wallet-to-nm.py              do it (may ask for your admin password)

Passwords are never printed, never put on a command line and never written
to a temp file: kwallet-query's output goes straight into NetworkManager's
D-Bus API (libnm), which saves it to /etc/NetworkManager/system-connections/.
"""

import json
import subprocess
import sys
import warnings

import gi

gi.require_version("NM", "1.0")
from gi.repository import NM  # noqa: E402

# commit_changes is deprecated in favour of an async call; it still works fine here
warnings.filterwarnings("ignore", category=DeprecationWarning)

WALLET = "kdewallet"
FOLDER = "Network Management"  # where plasma-nm keeps them

# (setting, how to get it, the secret, its flags property)
KINDS = [
    (NM.SETTING_WIRELESS_SECURITY_SETTING_NAME, "get_setting_wireless_security", "psk", "psk-flags"),
    (NM.SETTING_802_1X_SETTING_NAME, "get_setting_802_1x", "password", "password-flags"),
]


def from_wallet(uuid, setting):
    """The wallet entry for this connection+setting as a dict, or None."""
    r = subprocess.run(
        ["kwallet-query", "-f", FOLDER, "-r", "{%s};%s" % (uuid, setting), WALLET],
        capture_output=True, text=True,
    )
    if r.returncode != 0 or not r.stdout.strip():
        return None
    try:
        return json.loads(r.stdout)
    except ValueError:
        return None


def main():
    dry = "--dry-run" in sys.argv[1:]
    client = NM.Client.new(None)
    moved = skipped = 0

    for conn in client.get_connections():
        name, uuid = conn.get_id(), conn.get_uuid()
        for setting, getter, key, flags_prop in KINDS:
            s = getattr(conn, getter)()
            if s is None:
                continue
            if not (s.get_property(flags_prop) & NM.SettingSecretFlags.AGENT_OWNED):
                continue  # already stored by NetworkManager (or not saved at all)

            entry = from_wallet(uuid, setting)
            secret = entry.get(key) if isinstance(entry, dict) else None
            if not secret:
                print(f"  skip  {name} ({setting}): not found in the wallet")
                skipped += 1
                continue

            if dry:
                print(f"  would move  {name} ({key})")
                moved += 1
                continue

            s.set_property(key, secret)
            s.set_property(flags_prop, NM.SettingSecretFlags.NONE)
            try:
                conn.commit_changes(True, None)  # True = save to disk
                print(f"  moved  {name} ({key})")
                moved += 1
            except Exception as e:  # e.g. admin password refused
                print(f"  FAILED  {name}: {e.__class__.__name__}")
                skipped += 1
            del secret

    verb = "would move" if dry else "moved"
    print(f"\n{verb}: {moved}   skipped: {skipped}")


if __name__ == "__main__":
    main()
