#!/bin/bash
set -e
set -o pipefail
set -x

export PYTHONPATH=$(pwd)

# Ensure reports folder exists
mkdir -p reports

# Load environment variables from Jenkins
PARAM1=${PARAM1:-""}
BROWSER=${browser:-"chrome"}
ENVIRONMENT=${ENVIRONMENT:-"pie1"}
SCREENSHOT=${screenshot:-"false"}
TASK=${TASK:-"misc:run"}
RERUNS=${reruns:-0}

echo "============================================"
echo " Running Automated Tests"
echo "--------------------------------------------"
echo " PARAM1      = $PARAM1"
echo " BROWSER     = $BROWSER"
echo " ENVIRONMENT = $ENVIRONMENT"
echo " SCREENSHOT  = $SCREENSHOT"
echo " TASK        = $TASK"
echo " RERUNS      = $RERUNS"
echo "============================================"

# Detect Python version
PYTHON_BIN=""
if command -v python3 &>/dev/null; then
    PYTHON_BIN="python3"
elif command -v python &>/dev/null; then
    PYTHON_BIN="python"
else
    echo "ERROR: No python interpreter found!"
    exit 1
fi

PY_VERSION=$($PYTHON_BIN -c 'import sys; print("{}.{}".format(sys.version_info[0], sys.version_info[1]))')
echo "Using Python binary: $PYTHON_BIN"
echo "Python version detected: $PY_VERSION"

# Install requirements based on Python version
if [[ $PY_VERSION == 2.7* ]]; then
    echo "Python 2 detected → installing pinned Py2 requirements..."
    $PYTHON_BIN -m pip install --no-cache-dir --prefer-binary --upgrade "pip<21.0"
    $PYTHON_BIN -m pip install --no-cache-dir --prefer-binary -r requirements-py2.txt
else
    echo "Python 3.x detected → installing dependencies..."
    $PYTHON_BIN -m pip install --no-cache-dir --prefer-binary --upgrade pip
    $PYTHON_BIN -m pip install --no-cache-dir --prefer-binary -r requirements.txt
fi

# Build pytest command dynamically
PYTEST_CMD="$PYTHON_BIN -m pytest Tests/ \
    --env="$ENVIRONMENT" \
    --disable-warnings \
    --html=reports/report.html \
    --self-contained-html \
    --junitxml=reports/results.xml"

# Apply reruns if provided
if [ "$RERUNS" -gt 0 ]; then
    PYTEST_CMD="$PYTEST_CMD --reruns $RERUNS"
fi

# Apply test selection if PARAM1 is given
if [ -n "$PARAM1" ]; then
  PYTEST_CMD="$PYTEST_CMD -m \"$PARAM1\""
fi

# Pass custom options as env vars
export BROWSER=$BROWSER
export ENVIRONMENT=$ENVIRONMENT
export SCREENSHOT=$SCREENSHOT
export TASK=$TASK

# Log Python & Pytest version for debugging
echo "Using Python version: $($PYTHON_BIN --version)"
echo "Using Pytest version: $($PYTHON_BIN -m pytest --version || echo 'pytest not installed!')"

# Run tests
echo "Executing: $PYTEST_CMD"
eval $PYTEST_CMD

# === Setup log files ===
LOGFILE="reports/jenkins_run.log"
SUMMARY="reports/summary.log"
exec > >(tee -a "$LOGFILE") 2>&1

# === Extract test results summary ===
RESULTS_FILE="reports/results.xml"

if [ -f "$RESULTS_FILE" ]; then
    TOTAL=$(grep -o 'tests="[^"]*"' "$RESULTS_FILE" | head -1 | cut -d'"' -f2)
    FAILURES=$(grep -o 'failures="[^"]*"' "$RESULTS_FILE" | head -1 | cut -d'"' -f2)
    ERRORS=$(grep -o 'errors="[^"]*"' "$RESULTS_FILE" | head -1 | cut -d'"' -f2)
    SKIPPED=$(grep -o 'skipped="[^"]*"' "$RESULTS_FILE" | head -1 | cut -d'"' -f2)

    # Ensure all values are numeric
    TOTAL=${TOTAL:-0}
    FAILURES=${FAILURES:-0}
    ERRORS=${ERRORS:-0}
    SKIPPED=${SKIPPED:-0}

    PASSED=$((TOTAL - FAILURES - ERRORS - SKIPPED))

    echo "============================================"
    echo "   TEST SUMMARY"
    echo "--------------------------------------------"
    echo " Total tests : $TOTAL"
    echo " Failures    : $FAILURES"
    echo " Errors      : $ERRORS"
    echo " Skipped     : $SKIPPED"
    echo " Passed      : $PASSED"
    echo "============================================"

    # Save to summary.log
    {
        echo "Test Summary - $(date)"
        echo "Total tests : $TOTAL"
        echo "Failures    : $FAILURES"
        echo "Errors      : $ERRORS"
        echo "Skipped     : $SKIPPED"
        echo "Passed      : $PASSED"
    } > "$SUMMARY"

    echo "Summary also saved to $SUMMARY"

    # Optional: exit with non-zero if there are failures or errors
    if [ "$FAILURES" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
        echo "Test run completed with issues."
        exit 2
    fi
else
    echo "No results.xml found — pytest may have failed before generating results."
    exit 1
fi
