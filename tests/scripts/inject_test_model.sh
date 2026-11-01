#!/bin/bash
set -e
DATA_DIR=$(xcrun simctl get_app_container 396D8747-C119-49D2-9168-74F09BB1C184 com.nevergone.zrxx.ios data)
mkdir -p "$DATA_DIR/Documents/Models"
echo "GGUF_TEST_DATA" > "$DATA_DIR/Documents/Models/qwen2.5-0.5b-instruct-q4_k_m.gguf"
echo "Injected test model to $DATA_DIR/Documents/Models"
