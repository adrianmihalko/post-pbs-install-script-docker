#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
JS_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
JS_FILE_BACKUP="${JS_FILE}.bak"
HOOK_FILE="/etc/apt/apt.conf.d/no-nag-script"
ENTERPRISE_FILE="/etc/apt/sources.list.d/pbs-enterprise.sources"

# --- Main Script ---
main() {
  # 1. Check for root
  if [ "$(id -u)" -ne 0 ]; then
      echo "ERROR: This script must be run as root (or with sudo)." >&2
      exit 1
  fi
  echo "INFO: Running as root."

  # 2. Disable Enterprise Repository
  echo "INFO: Checking 'pbs-enterprise' repository status..."
  if [ -f "$ENTERPRISE_FILE" ]; then
    if grep -qE "^\s*Enabled:\s*false" "$ENTERPRISE_FILE"; then
      echo "INFO: 'pbs-enterprise' repository already disabled."
    else
      if grep -q "^Enabled:" "$ENTERPRISE_FILE" 2>/dev/null; then
        sed -i 's/^Enabled:.*/Enabled: false/' "$ENTERPRISE_FILE"
      else
        echo "Enabled: false" >>"$ENTERPRISE_FILE"
      fi
      echo "SUCCESS: Disabled 'pbs-enterprise' repository."
    fi
  else
    echo "INFO: File '$ENTERPRISE_FILE' is missing. No action taken."
  fi

  # 3. Create one-time backup
  echo "INFO: Checking for backup..."
  if [ -f "$JS_FILE" ] && [ ! -f "$JS_FILE_BACKUP" ]; then
      echo "INFO: Creating one-time backup of original file..."
      cp "$JS_FILE" "$JS_FILE_BACKUP"
      echo "INFO: Backup created at $JS_FILE_BACKUP"
  elif [ -f "$JS_FILE_BACKUP" ]; then
      echo "INFO: Backup file already exists. Skipping."
  elif [ ! -f "$JS_FILE" ]; then
      echo "ERROR: $JS_FILE not found. Cannot proceed."
      exit 1
  fi

  # 4. Apply the patch MANUALLY
  echo "INFO: Applying patch directly to $JS_FILE..."
  if grep -q -F 'NoMoreNagging' "$JS_FILE"; then
      echo "INFO: File is already patched. Skipping."
  else
      # This is the new, more specific command
      sed -i "/data\\.status/ s/!== 'active'/== 'NoMoreNagging'/" "$JS_FILE"
      
      # Verify patch
      if grep -q -F 'NoMoreNagging' "$JS_FILE"; then
          echo "INFO: Manual patch applied successfully."
      else
          echo "ERROR: Manual patch FAILED!"
          echo "The script could not find the expected string \`!== 'active'\` on the line with \`data.status\`."
          echo "Your file may be different. Please check it manually."
          exit 1
      fi
  fi

  # 5. Create the persistent APT hook (for future updates)
  echo "INFO: Creating persistent APT hook at $HOOK_FILE..."
  cat >"$HOOK_FILE" <<EOF
DPkg::Post-Invoke { "if [ -s $JS_FILE ] && ! grep -q -F 'NoMoreNagging' $JS_FILE; then sed -i \"/data\\.status/ s/!== 'active'/== 'NoMoreNagging'/\" $JS_FILE; fi" };
EOF
  echo "INFO: APT hook created for persistence."
  
  echo "---"
  echo "SUCCESS: The subscription nag has been removed."
  echo "IMPORTANT: Clear your browser cache or perform a hard reload (Ctrl+Shift+R) to see the change."
}

# Run the main function
main
