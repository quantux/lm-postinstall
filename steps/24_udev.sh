#!/bin/bash

# Etapa 24 - Configura regras udev para permitir acesso a qualquer dispositivo
# USB (ex.: adb) sem necessidade de regras específicas por vendor.

step_24_udev() {
    show_message "Configurando regras udev para dispositivos USB"
    cat > /etc/udev/rules.d/51-android.rules <<'EOF'
SUBSYSTEM=="usb", MODE="0666", GROUP="plugdev"
EOF
    udevadm control --reload-rules
    udevadm trigger
}