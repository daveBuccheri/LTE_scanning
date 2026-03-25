#!/bin/bash

# ================================
# LTE Cell Scanner + Notifiche
# ================================

# Path tool
#CELLSEARCH="/usr/src/LTE-Cell-Scanner/CellSearch_rtlsdr"
CELLSEARCH="/usr/src/LTE-Cell-Scanner/CellSearch_hackrf"

# Directory output
OUTPUT_DIR="<directory_path>"
OUTPUT_FILE="$OUTPUT_DIR/<output_file_name>.txt"

# Frequencies (to be adjusted based on the LTE band in question)
# Ex: Band 3
FREQ_START="1800e6"
FREQ_END="1820e6"

# Notify binary
NOTIFY="/usr/bin/notify-send"

# Fix DISPLAY for notify (useful in VM)
export DISPLAY=:0

# ================================
# CHECK
# ================================

if [ ! -f "$CELLSEARCH" ]; then
    echo "Errore: CellSearch_hackrf not found in $CELLSEARCH"
    exit 1
fi

if [ ! -f "$NOTIFY" ]; then
    echo "Errore: notify-send not found"
    exit 1
fi

# Create dir if not exists
mkdir -p "$OUTPUT_DIR"

echo "🚀 Start Scanning LTE..."
echo "Range: $FREQ_START - $FREQ_END"
echo "Output: $OUTPUT_FILE"
echo "----------------------------------"

# ================================
# SCAN + PARSING
# ================================

"$CELLSEARCH" -s "$FREQ_START" -e "$FREQ_END" | tee "$OUTPUT_FILE" | awk -v notify="$NOTIFY" '
#!/usr/bin/env bash

CELLSEARCH="/usr/src/LTE-Cell-Scanner/CellSearch_rtlsdr"
OUTPUT_FILE="/home/dave/Desktop/LTE/lte_cell_scan_output.txt"
NOTIFY="/usr/bin/notify-send"

export DISPLAY=:0

"$CELLSEARCH" -s 1800e6 -e 1820e6 | tee "$OUTPUT_FILE" | awk -v notify="$NOTIFY" '

/Detected a FDD cell/ {
    print "\n======================"
    print "🚨 CELL DETECTED 🚨"

    # extract frequency
    match($0, /frequency ([0-9.]+MHz)/, f)
    freq = f[1]

    system(notify " \"LTE Alert\" \"Cell detected at " freq "\"")
}

/cell ID:/ {
    pci=$3
    print
}

/RX power level:/ {
    rsrp=$4 " " $5
    print

    cmd = notify " \"LTE Cell Found\" \"PCI: " pci " | RSRP: " rsrp "\""
    system(cmd)

    print "======================\n"
}

{ print }
'
