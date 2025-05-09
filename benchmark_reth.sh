#!/bin/bash

format_time() {
    local seconds=$1
    if (( $(echo "$seconds >= 60" | bc -l) )); then
        local minutes=$(echo "$seconds / 60" | bc)
        local remaining_seconds=$(echo "$seconds - ($minutes * 60)" | bc)
        if (( $(echo "$remaining_seconds == ${remaining_seconds%.*}" | bc -l) )); then
            printf "%dm%ds" $minutes ${remaining_seconds%.*}
        else
            printf "%dm%.1fs" $minutes $remaining_seconds
        fi
    else
        if (( $(echo "$seconds == ${seconds%.*}" | bc -l) )); then
            printf "%ds" ${seconds%.*}
        else
            printf "%.1fs" $seconds
        fi
    fi
}

if [ -n "$TEST_MODE" ]; then
    echo "Running in test mode"
    N_VALUES=(1)
else
    N_VALUES=(1 6 18 27 36)
fi

OUTPUT_FILE="benchmark_reth_results.csv"

# Detect CPU capabilities and set SP1 and PICO configuration
if grep -q "avx512" /proc/cpuinfo; then
    RUSTFLAGS="-C target-cpu=native -C target-feature=+avx512f"
    SP1_NAME="SP1-AVX512"
    PICO_NAME="Pico-AVX512"
elif grep -q "avx2" /proc/cpuinfo; then
    RUSTFLAGS="-C target-cpu=native"
    SP1_NAME="SP1-AVX2"
    PICO_NAME="Pico-AVX2"
else
    RUSTFLAGS=""
    SP1_NAME="SP1-Base"
    PICO_NAME="Pico-Base"
fi

# Build all projects
echo "Building all projects..."
make build_rsp_sp1 RUSTFLAGS="$RUSTFLAGS"

# Initialize results file
echo "Prover,Megagas,Time" > $OUTPUT_FILE

for n in "${N_VALUES[@]}"; do
  ## Do not run Pico benchmarks yet
#    # Run rsp_pico benchmark
#    echo "Running RSP Pico with BLOCK_MEGAGAS=$n"
#    start=$(date +%s.%N)
#    make rsp_pico BLOCK_MEGAGAS=$n > /dev/null 2>&1
#    end=$(date +%s.%N)
#    time=$(echo "$end - $start" | bc)
#    echo "RSP Pico,$n,$(format_time $time)" >> $OUTPUT_FILE

    # Run rsp_sp1 benchmark
    echo "Running RSP SP1 with BLOCK_MEGAGAS=$n"
    start=$(date +%s.%N)
    make rsp_sp1 BLOCK_MEGAGAS=$n RUSTFLAGS="$RUSTFLAGS" > /dev/null 2>&1
    end=$(date +%s.%N)
    time=$(echo "$end - $start" | bc)
    echo "RSP $SP1_NAME,$n,$(format_time $time)" >> $OUTPUT_FILE
done
