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
/Found cell/ {
    print "\n======================"
    print "🚨 CELL DETECTED 🚨"
    system(notify " \"LTE Alert\" \"Cell detected!\"")
    next
}

/PCI/ {
    pci=$2
    print
}

/EARFCN/ {
    earfcn=$2
    print
}

/RSRP/ {
    rsrp=$2
    print

    cmd = notify " \"LTE Cell Found\" \"PCI: " pci " | EARFCN: " earfcn " | RSRP: " rsrp "\""
    system(cmd)

    print "======================\n"
}

{ print }
'
