#!/usr/bin/env bash
# Parse core_timing.rep: for each "slack (VIOLATED..." line,
# find the nearest preceding Startpoint and Endpoint.

set -e
REP="${1:-log/core_timing.rep}"

if [[ ! -f "$REP" ]]; then
  echo "Usage: $0 [path/to/core_timing.rep]" >&2
  echo "File not found: $REP" >&2
  exit 1
fi

awk '
  BEGIN { OFS = ","; print "count,slack,startpoint,endpoint" }
  /^\s+Startpoint:\s+/ {
    sub(/^\s+Startpoint:\s+/, "")
    startpoint = $0
    next
  }
  /^\s+Endpoint:\s+/ {
    sub(/^\s+Endpoint:\s+/, "")
    endpoint = $0
    next
  }
  /slack \(VIOLATED/ {
    if (startpoint != "" && endpoint != "") {
      n++
      slack = $NF
      # escape any double quotes in startpoint/endpoint for CSV
      gsub(/"/, "\"\"", startpoint)
      gsub(/"/, "\"\"", endpoint)
      print n, slack, "\"" startpoint "\"", "\"" endpoint "\""
    }
    next
  }
' "$REP" > violations.csv