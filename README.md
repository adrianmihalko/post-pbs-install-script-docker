# PBS Post Install Script for Docker

## ⚠️ IMPORTANT WARNING

This script is **ONLY** intended to be run on **Docker-based installations** of Proxmox Backup Server (PBS) 4.x (Trixie), such as the one from [ayufan/pve-backup-server-dockerfiles](https://github.com/ayufan/pve-backup-server-dockerfiles).

Running this script on a standard, bare-metal Proxmox VE (PVE) or a standard PBS installation is **not supported** and may cause issues.

---

## Overview

This is a minimal, non-interactive utility script for **Proxmox Backup Server (PBS) 4.x (Trixie)**. It performs two primary tasks to make PBS usable in a lab or non-production environment without a subscription.

1.  **Disables the Enterprise Repository:** It finds and disables the `pbs-enterprise.sources` file. This prevents the `apt update` command from failing with "401 Unauthorized" errors.
2.  **Removes the Subscription Nag:** It patches the `proxmoxlib.js` file to permanently remove the "No valid subscription" pop-up nag screen from the web interface.

## Why This Script Exists

The original [Post PBS Install Script](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pbs-install) is an excellent tool for standard installations, but it is not designed to work on containerized versions of PBS.

This script was created to provide a minimal, non-interactive alternative that specifically targets the `pbs-enterprise.sources` file and patches the `proxmoxlib.js` file directly, making it compatible with Docker-based installations.

## How to Use

1.  **Find and enter your PBS Docker container:**
    ```bash
    # Find your container ID or name
    docker ps
    
    # Enter the container's shell (replace <container_id_or_name>)
    docker exec -it <container_id_or_name> bash
    ```

2.  **Download the script:**
    ```bash
    # (Inside the container)
    wget [https://github.com/adrianmihalko/post-pbs-install-script-docker/raw/main/pbs_post_install_script_for_docker.sh](https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME/raw/main/pbs_post_install_script_for_docker.sh)
    ```

3.  **Run it:**
    ```bash
    # (Inside the container)
    chmod +x pbs_post_install_script_for_docker.sh
    ./pbs_post_install_script_for_docker.sh
    ```

4.  **Profit!**
    * After the script finishes, clear your browser cache or perform a hard reload (**Ctrl+Shift+R** or **Cmd+Shift+R**) to see the nag message disappear.

The script is **idempotent**, meaning it is safe to run multiple times. It checks its work and will skip any steps that have already been completed.

---

## How It Works (Technical Details)

This script is designed to be safe and persistent:

* **Repo Fix:** It checks `/etc/apt/sources.list.d/pbs-enterprise.sources` and sets `Enabled: false` if it's not already.
* **Backup:** It creates a one-time backup of the original file at `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak`.
* **Patch:** It *manually* patches the `proxmoxlib.js` file by changing the line:
    `if (... res.data.status.toLowerCase() !== 'active')`
    ...to...
    `if (... res.data.status.toLowerCase() == 'NoMoreNagging')`
* **Persistence:** It creates an APT hook in `/etc/apt/apt.conf.d/no-nag-script`. This hook automatically re-applies the patch every time the `proxmox-widget-toolkit` package is updated, ensuring the fix survives system upgrades.

---

## 💖 Support the Proxmox Developers

This script is a workaround intended for home labs or testing environments.

The Proxmox team provides fantastic, powerful open-source software for free. If you are using Proxmox Backup Server in a business or production environment, **please support their work by purchasing a subscription.**

This ensures you get stable, tested updates, and professional support, while also funding the development of the products you rely on.
