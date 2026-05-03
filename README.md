# SSH Ramdisk Activation Script (palera1n)

Automates uploading activation files and applying them on a device running an SSH ramdisk via [palera1n](https://github.com/palera1n/palera1n). Handles directory setup, file transfer, permission fixing, and service reloading — all from your host machine.

---

## ⚠️ Disclaimer

- **Use entirely at your own risk**
- You must supply your own valid activation files — this script does not generate or provide them
- Intended for advanced users familiar with SSH ramdisk environments, iOS internals, and jailbreak tooling
- The author(s) are not responsible for bricked devices, data loss, or any other damage

---

## 📋 Requirements

### 1. palera1n

Install from the [official repository](https://github.com/palera1n/palera1n) and boot your device into SSH ramdisk mode.

- Device must be connected via USB
- SSH ramdisk must be active before running the script

---

### 2. iproxy

`iproxy` tunnels the device SSH over USB to localhost port `2222`.

```bash
iproxy 2222 22
```

If your palera1n setup already handles this automatically, no action is needed.

> `iproxy` is part of the `libusbmuxd-tools` / `usbmuxd` package depending on your distro.

---

### 3. sshpass

Used to pass the SSH password non-interactively.

| Distro | Command |
|---|---|
| Ubuntu / Debian | `sudo apt install sshpass` |
| Arch Linux | `sudo pacman -S sshpass` |
| Fedora | `sudo dnf install sshpass` |
| macOS (Homebrew) | `brew install sshpass` |

---

### 4. OpenSSH / SCP

Ensure the following commands are available on your host:

- `ssh`
- `scp`

> **Important:** `scp` must support the `-O` flag (legacy SCP protocol mode). This is required because Dropbear — the SSH server used in the ramdisk — does not support the SFTP subsystem. Modern OpenSSH clients default to SFTP for `scp`; the `-O` flag forces the old protocol. This is already handled inside `run.sh`.

---

## 📁 Project Structure

```
.
├── run.sh          ← Main script (run this from your host)
├── device.sh       ← Executed on-device via SSH
└── Activation/     ← Your activation files (must match structure below)
```

### Required `Activation/` layout

```
Activation/
├── activation_record.plist
├── com.apple.commcenter.device_specific_nobackup.plist
├── data_ark.plist
└── FairPlay/
    └── iTunes_Control/
        └── iTunes/
            ├── IC-Info.sidb
            ├── IC-Info.sidt
            ├── IC-Info.sisb
            └── IC-Info.sisv
```

> If any of these files are missing or in the wrong location, the script will complete but activation will fail silently or the device will not activate after reboot.

---

## 🚀 Usage

### Step 1 — Boot SSH ramdisk

Start the device in SSH ramdisk mode using palera1n.

### Step 2 — Start iproxy

```bash
iproxy 2222 22
```

### Step 3 — Verify SSH access

```bash
ssh root@localhost -p 2222
```

Password: `alpine`

If the connection fails, see [Troubleshooting](#-troubleshooting).

### Step 4 — Place activation files

Make sure the `Activation/` folder is at:

```
~/Desktop/Activation/
```

If you use a different path, edit the following line in `run.sh` before running:

```bash
~/Desktop/Activation root@$IP:/var/mobile/Media/Downloads/1
```

### Step 5 — Make the script executable

```bash
chmod +x run.sh
```

### Step 6 — Run

```bash
./run.sh
```

---

## ⚙️ What the Script Does

### `run.sh` (host-side)

| Step | Action |
|---|---|
| 1 | Polls SSH until the device is reachable |
| 2 | Wipes and recreates `/var/mobile/Media/Downloads/1` on-device |
| 3 | Uploads the `Activation/` folder via `scp -O` (Dropbear-compatible) |
| 4 | Uploads `device.sh` to `/tmp/device.sh` |
| 5 | Executes `device.sh` on the device |

### `device.sh` (on-device)

| Step | Action |
|---|---|
| 1 | Moves uploaded files from `Downloads/1` to `Media/1` |
| 2 | Sets `mobile:mobile` ownership and `755` permissions |
| 3 | Sets `644` on all `.plist` files inside `Activation/` |
| 4 | Kills `backboardd` and waits 12 seconds for it to settle |
| 5 | Moves `FairPlay/` to `/var/mobile/Library/FairPlay` |
| 6 | Locates the system container holding the `internal` directory |
| 7 | Strips the `uchg` flag from `data_ark.plist`, replaces it, re-applies `uchg` |
| 8 | Creates `activation_records/` if missing, installs `activation_record.plist` with `uchg` |
| 9 | Strips `uchg` from the commcenter plist, replaces it, re-applies `uchg` and ownership |
| 10 | Unloads and reloads `com.apple.mobileactivationd` |
| 11 | Runs `ldrestart`, then `reboot` |

---

## 📝 Behavior Notes

- **`scp -O` is mandatory** — Dropbear does not implement an SFTP server; without `-O`, modern `scp` will fail with `sftp-server not found`.
- **`StrictHostKeyChecking=no`** is set on all SSH/SCP calls to avoid host-key prompts during a ramdisk session where the key changes each boot.
- **`ldrestart` vs `reboot`** — `ldrestart` reloads launchd services in-place before a full `reboot` is issued. Both are intentional.
- **`chflags uchg`** — Several system files are immutable-flagged (`uchg`). The script strips the flag before replacing them and re-applies it afterward. Some of these `chflags` calls may print errors but still succeed; this is expected.
- **`backboardd` kill + 12 s sleep** — Required to allow the UI layer to settle before files are moved into place. Shortening this delay may cause the activation to be ignored.
- **Some commands may return non-zero exit codes** but the script continues. This is intentional — certain paths may not exist on all devices/iOS versions.

---

## ❓ FAQ

**Q: Where do I get the activation files?**  
A: This script does not provide or generate activation files. You must obtain valid files for your specific device and iOS version through your own means.

**Q: What iOS versions are supported?**  
A: The script targets the file paths used by iOS 15–16 ramdisk environments via palera1n. Paths such as `/var/mobile/Library/FairPlay` and the system container layout may differ on other versions.

**Q: Can I run this on macOS?**  
A: Yes. Install `sshpass` via Homebrew (`brew install sshpass`) and ensure `iproxy` is available through libimobiledevice. Everything else is standard shell.

**Q: The script finishes but the device doesn't activate after reboot.**  
A: Verify that all required files are present in `Activation/` and match the exact layout shown above. A missing `IC-Info.sid*` file or misplaced `data_ark.plist` is the most common cause. Also confirm the files are valid for your ECID/device.

**Q: Can I change the upload path from `~/Desktop/Activation`?**  
A: Yes. Edit this line in `run.sh`:
```bash
~/Desktop/Activation root@$IP:/var/mobile/Media/Downloads/1
```
Replace `~/Desktop/Activation` with your actual path.

**Q: What is `ldrestart` and is it safe?**  
A: `ldrestart` is an Apple-internal command that restarts launchd and all managed processes without a full kernel reboot. In a ramdisk context it is used here to reload activation-related daemons before the final `reboot` call.

**Q: My SSH times out immediately — what's wrong?**  
A: The most common causes are: iproxy not running, the device not fully booted into ramdisk mode yet, or a USB connection issue. See [Troubleshooting](#-troubleshooting).

---

## 🧩 Troubleshooting

### SSH connection fails

- Confirm the device is in SSH ramdisk mode (not normal boot or recovery)
- Confirm `iproxy 2222 22` is running in a separate terminal
- Try connecting manually: `ssh root@localhost -p 2222` (password: `alpine`)
- Try a different USB cable or port
- Restart the ramdisk boot and try again

### `sftp-server not found` SCP error

This means `scp` is trying to use SFTP mode. The `-O` flag in the script forces legacy SCP mode. If you see this error:

- Verify you are running the unmodified `run.sh`
- Check your OpenSSH version: `ssh -V` — versions older than 8.x may not need `-O` but it is harmless

### Script is stuck on `[*] Waiting for SSH...`

- Device is not yet ready — wait a few more seconds
- Re-seat the USB cable
- Restart the ramdisk
- Ensure `iproxy` is running

### `Permission denied` or `chflags` errors

These can generally be ignored as long as the script continues to completion. If the script exits early due to a permission error, check that you are connecting as `root` (not `mobile`).

### Device reboots but is still not activated

- Double-check the `Activation/` folder structure matches exactly
- Confirm `data_ark.plist` and `activation_record.plist` are valid and not corrupted
- Re-run the full process from a fresh ramdisk boot

---

## ✅ Expected Result

If everything succeeds:

1. The script prints `[✓] All done`
2. The device runs `ldrestart`, then reboots
3. After reboot, activation data is in place and the device activates

---

## 🙏 Credits

- **[palera1n team](https://github.com/palera1n/palera1n)** — SSH ramdisk environment, tooling, and ongoing jailbreak research
- **[pixdoet](https://gist.github.com/pixdoet/2b58cce317a3bc7158dfe10c53e3dd32)** — Reference implementation and inspiration for the activation file placement steps
- **Community contributors** — iOS ramdisk research, activation workflow documentation, and testing across devices and iOS versions
