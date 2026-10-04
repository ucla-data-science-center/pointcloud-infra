#!/usr/bin/env bash
# Health check for pointcloud.ucla.edu: HTTP status and days until the TLS
# certificate expires. Exits non-zero on any problem.
#
# Let's Encrypt stopped sending expiry emails in 2025, and in August 2026 the
# certs expired silently for weeks. This check is the alarm.
#
# Usage: scripts/site-check.sh [min_days]   (default 21)
set -euo pipefail

MIN_DAYS="${1:-21}"
HOSTS=(www.pointcloud.ucla.edu pointcloud.ucla.edu)
fail=0

for host in "${HOSTS[@]}"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "https://${host}/" || echo "000")
  if [[ "$code" != "200" && "$code" != "301" ]]; then
    echo "FAIL ${host}: HTTP ${code}"
    fail=1
  else
    echo "ok   ${host}: HTTP ${code}"
  fi

  end=$(echo | openssl s_client -servername "$host" -connect "${host}:443" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
  if [[ -z "$end" ]]; then
    echo "FAIL ${host}: could not read certificate"
    fail=1
    continue
  fi
  end_epoch=$(date -d "$end" +%s 2>/dev/null || date -j -f "%b %e %T %Y %Z" "$end" +%s)
  days=$(( (end_epoch - $(date +%s)) / 86400 ))
  if (( days < MIN_DAYS )); then
    echo "FAIL ${host}: certificate expires in ${days} days (${end})"
    fail=1
  else
    echo "ok   ${host}: certificate valid for ${days} more days"
  fi
done

exit "$fail"
