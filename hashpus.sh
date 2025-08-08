#!/usr/bin/env bash
# hashcat_helper.sh
# Interactive wrapper to run common Hashcat attacks using /usr/share/wordlists/rockyou.txt
# Usage: ./hashcat_helper.sh

set -euo pipefail

ROCKYOU="/usr/share/wordlists/rockyou.txt"
DEFAULT_RULES="/usr/share/hashcat/rules/best64.rule"
OUTFILE="hashcat_crack_results.txt"

if ! command -v hashcat >/dev/null 2>&1; then
  echo "hashcat is not installed or not in PATH. Install hashcat and try again." >&2
  exit 1
fi

if [ ! -f "$ROCKYOU" ]; then
  echo "rockyou wordlist not found at $ROCKYOU. Please install rockyou or change the script." >&2
  exit 1
fi

clear
echo "=== Hashcat helper — interactive menu (rockyou forced) ==="
echo "Available hash files in current directory:"
select HASHFILE in *.hash *.txt; do
  if [ -n "$HASHFILE" ] && [ -f "$HASHFILE" ]; then
    break
  else
    echo "Invalid choice. Try again."
  fi
done

cat <<'EOF'
Choose the hash type (common ones listed). If your type isn't listed choose 9 to enter a custom -m number.
1) 0   — MD5
2) 100 — SHA1
3) 1400 — SHA256
4) 1700 — SHA512
5) 3200 — bcrypt (Blowfish)
6) 22000 — WPA-PBKDF2-PMKID+EAPOL (WPA/WPA2/PMKID)
7) Other / I don't know (hashcat autodetect recommended)
9) Enter custom -m number
EOF
read -rp "Pick number for hash type: " HTCHOICE
case "$HTCHOICE" in
  1) HASHMODE=0;;
  2) HASHMODE=100;;
  3) HASHMODE=1400;;
  4) HASHMODE=1700;;
  5) HASHMODE=3200;;
  6) HASHMODE=22000;;
  7) HASHMODE=""; AUTO_DETECT=true;;
  9) read -rp "Enter the hashcat mode number (e.g. 0 for MD5): " CUSTOMM; HASHMODE=$CUSTOMM;;
  *) echo "Invalid choice"; exit 1;;
esac

cat <<'EOF'
Choose attack mode:
1) Straight (dictionary) — rockyou
2) Rules (dictionary + rules) — rockyou + best64.rule
3) Combination (rockyou + rockyou)
4) Mask brute-force
5) Hybrid (rockyou + mask)
6) Hybrid (mask + rockyou)
EOF
read -rp "Pick attack (1-6): " ATCHOICE
case "$ATCHOICE" in
  1) ATFLAG="-a 0"; EXTRA_ARGS=("$ROCKYOU");;
  2) ATFLAG="-a 0"; EXTRA_ARGS=("-r" "$DEFAULT_RULES" "$ROCKYOU");;
  3) ATFLAG="-a 1"; EXTRA_ARGS=("$ROCKYOU" "$ROCKYOU");;
  4) ATFLAG="-a 3"; read -rp "Enter mask: " USER_MASK; EXTRA_ARGS=("$USER_MASK");;
  5) ATFLAG="-a 6"; read -rp "Enter mask suffix: " USER_MASK; EXTRA_ARGS=("$ROCKYOU" "$USER_MASK");;
  6) ATFLAG="-a 7"; read -rp "Enter mask prefix: " USER_MASK; EXTRA_ARGS=("$USER_MASK" "$ROCKYOU");;
  *) echo "Invalid attack choice"; exit 1;;
esac

read -rp "Extra hashcat options? (y/N): " EXTRA_OPT_ANS
EXTRA_OPTS=""
if [[ "$EXTRA_OPT_ANS" =~ ^[Yy] ]]; then
  read -rp "Enter extra options: " EXTRA_OPTS
fi

if [ -n "$HASHMODE" ]; then
  FINAL_CMD=(hashcat -m "$HASHMODE" $ATFLAG -o "$OUTFILE" "$HASHFILE")
else
  FINAL_CMD=(hashcat $ATFLAG -o "$OUTFILE" "$HASHFILE")
fi

if [ -n "$EXTRA_OPTS" ]; then
  read -ra SPLITEXTRA <<< "$EXTRA_OPTS"
  for p in "${SPLITEXTRA[@]}"; do FINAL_CMD+=("$p"); done
fi

for p in "${EXTRA_ARGS[@]}"; do FINAL_CMD+=("$p"); done

echo "Command to be run:"
printf ' %q' "${FINAL_CMD[@]}"
echo
read -rp "Run this command? (y/N): " CONF
if [[ ! "$CONF" =~ ^[Yy] ]]; then
  echo "Aborted by user."; exit 0
fi

"${FINAL_CMD[@]}"
echo "Done. Results saved in $OUTFILE."
