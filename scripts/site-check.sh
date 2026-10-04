#!/usr/bin/env bash
# Outside-in health check for pointcloud.ucla.edu. Exits non-zero on any problem.
#
# Checks the failures this site has actually had:
#   1. The canonical site answers 200.
#   2. The bare domain 301s to the exact www URL. Serving pages there breaks
#      point clouds, because S3 only serves data to pages whose Referer is www.
#   3. A real collection page's point cloud data loads from S3 the way a
#      browser would request it (with that page as Referer).
#   4. Certificates on both names have at least MIN_DAYS left. Let's Encrypt
#      no longer emails expiry warnings; in 2026 the certs expired unnoticed.
#
# Usage: scripts/site-check.sh [min_days]   (default 21)
set -euo pipefail

MIN_DAYS="${1:-21}"
CANONICAL="${CANONICAL:-www.pointcloud.ucla.edu}"
BARE="${BARE:-pointcloud.ucla.edu}"
DATA_PAGE="${DATA_PAGE:-Iceland/Torfljar.html}"   # a stable, public collection page
fail=0

ok()   { echo "ok   $*"; }
bad()  { echo "FAIL $*"; fail=1; }

# 1. Canonical site
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "https://${CANONICAL}/" || echo 000)
[[ "$code" == "200" ]] && ok "https://${CANONICAL}/ -> 200" || bad "https://${CANONICAL}/ -> ${code}, expected 200"

# 2. Bare domain must redirect to the same path on www
want="https://${CANONICAL}/${DATA_PAGE}"
got=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 20 "https://${BARE}/${DATA_PAGE}" || echo "000 -")
if [[ "$got" == "301 ${want}" ]]; then
  ok "https://${BARE}/${DATA_PAGE} -> 301 ${want}"
else
  bad "https://${BARE}/${DATA_PAGE} -> ${got}, expected 301 ${want}"
fi

# 3. Point cloud data loads for a real page, as a browser would request it
page_url="https://${CANONICAL}/${DATA_PAGE}"
data_url=$(curl -s --max-time 20 "$page_url" | grep -oE 'loadPointCloud\("https://[^"]+' | head -1 | cut -d'"' -f2 || true)
if [[ -z "$data_url" ]]; then
  bad "${DATA_PAGE}: no loadPointCloud URL found in the page"
else
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -H "Referer: ${page_url}" "$data_url" || echo 000)
  [[ "$code" == "200" ]] && ok "${DATA_PAGE}: point cloud metadata loads (200)" \
                         || bad "${DATA_PAGE}: point cloud metadata -> ${code} (${data_url})"
fi

# 4. Certificates
for host in "$CANONICAL" "$BARE"; do
  end=$(echo | openssl s_client -servername "$host" -connect "${host}:443" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
  if [[ -z "$end" ]]; then
    bad "${host}: could not read certificate"
    continue
  fi
  end_epoch=$(date -d "$end" +%s 2>/dev/null || date -j -f "%b %e %T %Y %Z" "$end" +%s)
  days=$(( (end_epoch - $(date +%s)) / 86400 ))
  (( days >= MIN_DAYS )) && ok "${host}: certificate valid for ${days} more days" \
                         || bad "${host}: certificate expires in ${days} days (${end})"
done

exit "$fail"
