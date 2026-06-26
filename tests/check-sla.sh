#!/bin/bash

JTL_FILE=$1
SLA_MS=2000  # 2 seconds in milliseconds
BREACH_COUNT=0
TOTAL=0
FAIL_COUNT=0

echo "========================================="
echo "CIBC Performance Pipeline — SLA Report"
echo "SLA Threshold: ${SLA_MS}ms"
echo "========================================="

# Skip header line, read each result
while IFS=',' read -r timestamp elapsed label code message success bytes; do
    # Skip header
    if [[ "$elapsed" == "elapsed" ]]; then
        continue
    fi

    TOTAL=$((TOTAL + 1))

    # Check if request failed
    if [[ "$success" == "false" ]]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "❌ FAILED request: ${label} — ${elapsed}ms"
    fi

    # Check SLA breach
    if (( elapsed > SLA_MS )); then
        BREACH_COUNT=$((BREACH_COUNT + 1))
        echo "⚠️  SLA BREACH: ${label} — ${elapsed}ms > ${SLA_MS}ms"
    fi

done < "$JTL_FILE"

echo "========================================="
echo "Total requests : $TOTAL"
echo "Failed requests: $FAIL_COUNT"
echo "SLA breaches   : $BREACH_COUNT"
echo "========================================="

# Fail pipeline if any breach or failure
if (( BREACH_COUNT > 0 || FAIL_COUNT > 0 )); then
    echo "❌ PIPELINE FAILED — SLA breached or requests failed"
    exit 1
else
    echo "✅ PIPELINE PASSED — all requests within SLA"
    exit 0
fi