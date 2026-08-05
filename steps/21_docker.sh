#!/bin/bash

# Etapa 21 - Instala o Docker, adiciona o usuário aos grupos e sobe containers

step_21_docker() {
    show_message "Instalando Docker"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove -y "$pkg" || true; done
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    show_message "Adicionando usuário aos grupos"
    for grp in docker vboxusers kvm libvirt; do
        if getent group "$grp" >/dev/null 2>&1; then
            usermod -aG "$grp" "$USER_NAME"
        fi
    done

    show_message "Subindo containers"
    if [ ! -f "$DOCKER_COMPOSE_PATH" ]; then
        echo "⚠️  $DOCKER_COMPOSE_PATH não encontrado após o restore; pulando subida dos containers."
        return 0
    fi

    # O docker-compose reserva GPU para o ollama. Sem o driver NVIDIA carregado
    # (ex.: num VM sem GPU), o prestart hook do nvidia-container-cli falha com
    # "nvml error: driver not loaded" e derruba a subida. Nesses casos, sobemos
    # os containers com um override removendo a reserva de GPU (ollama em CPU).
    GPU_OFF="/tmp/docker-compose.no-gpu.yml"
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        docker compose -f "$DOCKER_COMPOSE_PATH" up -d
    else
        echo "⚠️  Driver NVIDIA não detectado; subindo containers sem reserva de GPU (ollama em CPU)."
        printf 'services:\n  ollama:\n    deploy:\n      resources:\n        reservations:\n          devices: !reset []\n' > "$GPU_OFF"
        docker compose -f "$DOCKER_COMPOSE_PATH" -f "$GPU_OFF" up -d
    fi
}
