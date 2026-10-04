#!/usr/bin/env bash

WORK_DIR="$(pwd)"

# Models
MODELS_DIR="$WORK_DIR/models"
QWEN_MODEL_NAME="Qwen/Qwen3-4B-FP8"
QWEN_MODEL_PATH="$MODELS_DIR/$QWEN_MODEL_NAME"

# Code
VLLM_VERSION="v0.19.0"
DOCKER_MODELS_DIR="/root/models"
DOCKER_MODEL_PATH="$DOCKER_MODELS_DIR/$QWEN_MODEL_NAME"

download_model () {
    if [[ ! -d "$QWEN_MODEL_PATH" ]] ; then
        hf download $QWEN_MODEL_NAME --local-dir $QWEN_MODEL_PATH
        echo "downloaded model $QWEN_MODEL_NAME: model_path = $QWEN_MODEL_PATH" >&2
    else
        echo "found local model $QWEN_MODEL_NAME: model_path = $QWEN_MODEL_PATH" >&2
    fi
}

run_vllm () {
    # Run in docker
    docker run -d --rm --gpus "device=0" --env "HF_HUB_OFFLINE=1" -v $MODELS_DIR:$DOCKER_MODELS_DIR \
        -p 8000:8000 --ipc host --name vllm \
        vllm/vllm-openai:$VLLM_VERSION $DOCKER_MODEL_PATH \
        --served-model-name $QWEN_MODEL_NAME \
        --gpu_memory_utilization 0.5 \
        --seed 22 --max_model_len 16384 \
        --reasoning-parser qwen3 --enable-auto-tool-choice --tool-call-parser hermes
}

download_model
run_vllm
