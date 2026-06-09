# Dangerous Command Patterns

Commands matching ANY of these patterns must be flagged, explained, and explicitly confirmed before execution. No exceptions.

---

## Destructive Filesystem

| Pattern | Risk |
|---------|------|
| `rm -rf /`, `rm -rf ~`, `rm -rf *` | Deletes entire filesystem, home dir, or cwd recursively |
| `rm -rf` on any broad path (`.`, `..`, `/home`, `/var`) | Mass data loss |
| `mv` or `cp` overwriting system dirs (`/usr`, `/etc`, `/boot`) | Corrupts OS |
| `> /dev/sda`, `dd if=/dev/zero of=/dev/sda` | Wipes entire disk |
| `mkfs` on mounted partitions | Destroys live filesystem |
| Any command with `--no-preserve-root` | Bypasses safety on `/` |
| `shred` on non-target files | Irrecoverable deletion |

## Privilege Escalation / System Damage

| Pattern | Risk |
|---------|------|
| `chmod 777` or `chmod -R 777` | World-writable = security hole |
| `chown -R` on system directories | Breaks OS file ownership |
| `kill -9 1` | Kills init — system crash |
| `kill -9 -1` | Kills ALL user processes |
| Writing to `/etc/passwd`, `/etc/shadow`, `/etc/sudoers` directly | Locks out users, breaks auth |
| `echo` or `>` redirect to `/etc/`, `/usr/`, `/boot/` | Corrupts system config |
| `sudo` anything without explicit user request | Unauthorized privilege escalation |

## Remote Code Execution / Supply Chain

| Pattern | Risk |
|---------|------|
| `curl \| bash`, `wget \| sh` | Executes unreviewed remote code |
| `eval` on untrusted or external input | Arbitrary code execution |
| `pip install` / `npm install` from unknown sources | Supply chain attack vector |
| Adding unknown PPAs, repos, or COPRs | Untrusted package sources |
| `docker run` with `--privileged` or `-v /:/host` | Container escape / host access |

## Fork Bombs / Resource Exhaustion

| Pattern | Risk |
|---------|------|
| `:()\{:\|:&\};:` and variants | Fork bomb — freezes system |
| `yes > /dev/null &` in loops | CPU exhaustion |
| Unbounded `while true` without exit condition | Infinite loop, resource drain |
| `cat /dev/urandom > file` without limit | Fills disk |

## Git Footguns

| Pattern | Risk |
|---------|------|
| `git push --force` to main/master | Overwrites shared history |
| `git reset --hard` without stash/backup | Discards uncommitted work |
| `git clean -fdx` | Deletes ALL untracked files including build artifacts |
| `git checkout .` | Discards all unstaged changes silently |
| `git rebase` on pushed/shared branches | Rewrites public history |

## Dotfiles-Specific

| Pattern | Risk |
|---------|------|
| `stow -D` on all packages at once | Unlinks every managed config |
| `stow --adopt` without backup | Overwrites stow source with target (data loss) |
| Deleting `~/.config/` dirs that are stow-managed | Breaks symlink chain |
| Editing files in `~/.config/` instead of `~/dotfiles/` | Changes lost on next `stow` |
| `stow` a package with conflicting files without `--adopt` | Stow refuses, leaves broken state |

---

**Protocol:** When any command matches these patterns:
1. **Stop** — do not execute
2. **Name the risk** — one sentence, what could go wrong
3. **Ask** — get explicit "yes, do it" before proceeding
