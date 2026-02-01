#!/bin/bash

# SystemVerilog Linter using Verilator
# Usage: ./lint.sh <file.sv>        - lint single file
#        ./lint.sh <directory>      - lint all .sv files in directory
#        ./lint.sh                  - lint all .sv files in rtl/

# Ensure environment is set
export YOSYSHQ_ROOT="${YOSYSHQ_ROOT:-/c/Users/AndrewParedes/Downloads/oss-cad-suite}"
export VERILATOR_ROOT="${VERILATOR_ROOT:-$YOSYSHQ_ROOT/share/verilator}"

TARGET="${1:-rtl}"

if [[ -f "$TARGET" ]]; then
    # Single file
    echo "Linting: $TARGET"
    verilator_bin --lint-only -sv -Wall "$TARGET"
elif [[ -d "$TARGET" ]]; then
    # Directory - lint all .sv files
    echo "Linting all .sv files in: $TARGET"
    find "$TARGET" -name "*.sv" -print0 | while IFS= read -r -d '' file; do
        echo "--- $file ---"
        verilator_bin --lint-only -sv -Wall "$file"
    done
else
    echo "Error: '$TARGET' is not a file or directory"
    exit 1
fi

echo "Done."
