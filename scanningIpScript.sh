#!/usr/bin/env bash

set -u

INPUT_FILE="${1:-clean_ips.txt}"
DETAIL_CSV="${2:-ip_details.csv}"
SUMMARY_TXT="${3:-ip_summary.txt}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "File not found: $INPUT_FILE"
  echo "Usage: ./ip_recon_report.sh [input_file] [details_csv] [summary_txt]"
  exit 1
fi

TMP_IPS=$(mktemp)
TMP_ORGS=$(mktemp)
TMP_SUBNETS=$(mktemp)
TMP_PTR=$(mktemp)
TMP_CATS=$(mktemp)
TMP_CLUSTERS=$(mktemp)

trap 'rm -f "$TMP_IPS" "$TMP_ORGS" "$TMP_SUBNETS" "$TMP_PTR" "$TMP_CATS" "$TMP_CLUSTERS"' EXIT

grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$INPUT_FILE" | sort -u > "$TMP_IPS"

TOTAL=$(wc -l < "$TMP_IPS")

csv_escape() {
  echo "$1" | sed 's/"/""/g'
}

detect_category() {
  local org="$1"
  local netname="$2"
  local descr="$3"
  local ptr="$4"

  local text
  text="$(printf '%s %s %s %s' "$org" "$netname" "$descr" "$ptr" | tr '[:upper:]' '[:lower:]')"

  if echo "$text" | grep -Eq 'smtp|mta|mx|mail'; then
    echo "mail"
    return
  fi

  if echo "$text" | grep -Eq 'digitalocean|microsoft|ovh|ionos|ucloud|byteplus|cloud|vps|hosting|dmzhost|techoff|serveroffer|pbiaas'; then
    echo "hosting/cloud"
    return
  fi

  if echo "$text" | grep -Eq 'broadband|dynamic|adsl|home|cpe|telecom|jio|jcom|turknet|netcabo|une|cepat'; then
    echo "residential/isp"
    return
  fi

  echo "unknown"
}

detect_cluster() {
  local ip="$1"
  local org="$2"
  local netname="$3"

  case "$ip" in
    2.57.122.*) echo "TECHOFF-DMZHOST"; return ;;
    45.148.10.*) echo "TECHOFF-DMZHOST"; return ;;
    2.57.121.*) echo "UNMANAGED-LTD"; return ;;
    92.118.39.*) echo "DMZHOST"; return ;;
    176.120.22.*) echo "PROTON66"; return ;;
  esac

  local text
  text="$(printf '%s %s' "$org" "$netname" | tr '[:upper:]' '[:lower:]')"

  if echo "$text" | grep -q 'techoff'; then
    echo "TECHOFF-DMZHOST"
    return
  fi

  if echo "$text" | grep -q 'dmzhost'; then
    echo "TECHOFF-DMZHOST"
    return
  fi

  if echo "$text" | grep -q 'unmanaged'; then
    echo "UNMANAGED-LTD"
    return
  fi

  if echo "$text" | grep -q 'digitalocean'; then
    echo "DIGITALOCEAN"
    return
  fi

  if echo "$text" | grep -q 'proton66'; then
    echo "PROTON66"
    return
  fi

  echo "OTHER"
}

echo '"ip","country","org","netname","descr","cidr_or_range","abuse_contact","ptr","category","cluster_hint"' > "$DETAIL_CSV"

COUNT=0
while read -r ip; do
  [[ -z "$ip" ]] && continue
  COUNT=$((COUNT + 1))

  echo "[${COUNT}/${TOTAL}] Processing $ip..." >&2

  WHOIS_DATA=$(timeout 12 whois "$ip" 2>/dev/null || true)
  PTR=$(timeout 5 dig -x "$ip" +short 2>/dev/null | sed 's/\.$//' | head -n 1 || true)

  COUNTRY=$(echo "$WHOIS_DATA" | grep -im1 -E '^(country|Country):' | sed 's/^[^:]*:[[:space:]]*//')
  ORG=$(echo "$WHOIS_DATA" | grep -im1 -E '^(org-name|OrgName|Organization):' | sed 's/^[^:]*:[[:space:]]*//')
  NETNAME=$(echo "$WHOIS_DATA" | grep -im1 -E '^(netname|NetName):' | sed 's/^[^:]*:[[:space:]]*//')
  DESCR=$(echo "$WHOIS_DATA" | grep -im1 -E '^(descr|Descr|Comment):' | sed 's/^[^:]*:[[:space:]]*//')
  CIDR=$(echo "$WHOIS_DATA" | grep -im1 -E '^(CIDR|cidr):' | sed 's/^[^:]*:[[:space:]]*//')
  INETNUM=$(echo "$WHOIS_DATA" | grep -im1 -E '^(inetnum|NetRange):' | sed 's/^[^:]*:[[:space:]]*//')
  ABUSE=$(echo "$WHOIS_DATA" | grep -im1 -E '(abuse.*@|OrgAbuseEmail:|AbuseEmail:|e-mail:)' | sed 's/^[^:]*:[[:space:]]*//')

  [[ -z "$COUNTRY" ]] && COUNTRY="N/A"
  [[ -z "$ORG" ]] && ORG="N/A"
  [[ -z "$NETNAME" ]] && NETNAME="N/A"
  [[ -z "$DESCR" ]] && DESCR="N/A"
  [[ -z "$ABUSE" ]] && ABUSE="N/A"
  [[ -z "$PTR" ]] && PTR="N/A"

  if [[ -n "$CIDR" ]]; then
    RANGE="$CIDR"
  elif [[ -n "$INETNUM" ]]; then
    RANGE="$INETNUM"
  else
    RANGE="N/A"
  fi

  SUBNET=$(echo "$ip" | cut -d. -f1-3)
  CATEGORY=$(detect_category "$ORG" "$NETNAME" "$DESCR" "$PTR")
  CLUSTER=$(detect_cluster "$ip" "$ORG" "$NETNAME")

  echo "$SUBNET" >> "$TMP_SUBNETS"
  echo "$CATEGORY" >> "$TMP_CATS"

  if [[ "$ORG" != "N/A" ]]; then
    echo "$ORG" >> "$TMP_ORGS"
  fi

  if [[ "$CLUSTER" != "OTHER" ]]; then
    echo "$CLUSTER" >> "$TMP_CLUSTERS"
  fi

  if [[ "$PTR" != "N/A" ]]; then
    echo "$ip -> $PTR" >> "$TMP_PTR"
  fi

  echo "\"$(csv_escape "$ip")\",\"$(csv_escape "$COUNTRY")\",\"$(csv_escape "$ORG")\",\"$(csv_escape "$NETNAME")\",\"$(csv_escape "$DESCR")\",\"$(csv_escape "$RANGE")\",\"$(csv_escape "$ABUSE")\",\"$(csv_escape "$PTR")\",\"$(csv_escape "$CATEGORY")\",\"$(csv_escape "$CLUSTER")\"" >> "$DETAIL_CSV"
done < "$TMP_IPS"

{
  echo "========================================"
  echo "IP RECON SUMMARY REPORT"
  echo "Generated: $(date)"
  echo "Input file: $INPUT_FILE"
  echo "Total unique IPs: $TOTAL"
  echo "Detailed CSV: $DETAIL_CSV"
  echo "========================================"
  echo

  echo "1. Top subnets (/24)"
  echo "----------------------------------------"
  sort "$TMP_SUBNETS" | uniq -c | sort -nr
  echo

  echo "2. Top organizations"
  echo "----------------------------------------"
  if [[ -s "$TMP_ORGS" ]]; then
    sort "$TMP_ORGS" | uniq -c | sort -nr
  else
    echo "No organization data found."
  fi
  echo

  echo "3. Top categories"
  echo "----------------------------------------"
  sort "$TMP_CATS" | uniq -c | sort -nr
  echo

  echo "4. Cluster candidates"
  echo "----------------------------------------"
  if [[ -s "$TMP_CLUSTERS" ]]; then
    sort "$TMP_CLUSTERS" | uniq -c | sort -nr
  else
    echo "No cluster candidates found."
  fi
  echo

  echo "5. PTR records"
  echo "----------------------------------------"
  if [[ -s "$TMP_PTR" ]]; then
    sort "$TMP_PTR"
  else
    echo "No PTR records found."
  fi
  echo

  echo "6. Sample detailed rows"
  echo "----------------------------------------"
  head -n 11 "$DETAIL_CSV"
} > "$SUMMARY_TXT"

echo
echo "Done."
echo "Detailed report: $DETAIL_CSV"
echo "Summary report : $SUMMARY_TXT"
