# MacOs-Awan

Remote macOS via GitHub Actions (`macos-latest`) + Tailscale.

## Engine status

| Engine | Status | Note |
|---|---|---|
| Native VNC (Screen Sharing) | FAILED | No usable framebuffer on GitHub macOS runner; RealVNC connects but black screen. |
| BetterDisplay virtual screen | FAILED | App launches but `create VirtualScreen` times out headlessly. |
| CGVirtualDisplay (`tools/vdisplay`) | ABANDONED / NOT PRIMARY | Display object valid (id, mode, bounds) but VNC still black; kept in repo as experiment history. |
| AnyDesk | CURRENT EXPERIMENT | See workflow `macOS Runner - Phase 4 AnyDesk`. |

## Secrets

| Secret | Purpose |
|---|---|
| `TAILSCALE_AUTHKEY` | Tailscale auth key (reusable, ephemeral, 90d). |
| `ANYDESK_PASSWORD` | AnyDesk Unattended Access password (min 8 chars, 12+ recommended). Never printed. |

## Run

Actions → `macOS Runner - Phase 4 AnyDesk` → Run workflow → read the
`ANYDESK REMOTE ACCESS` banner for the AnyDesk ID → connect from AnyDesk
client + unattended password. Cancel the workflow to stop (max 6h).
