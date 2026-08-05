#!/bin/bash

# Etapa 13 - Instala o Android SDK (cmdline-tools, plataformas, build-tools,
# NDK, cmake, emulador) em ~/Android/Sdk

step_13_android_sdk() {
    ANDROID_HOME="$USER_HOME/Android/Sdk"
    ANDROID_JAVA_HOME="/opt/android-studio/jbr"
    SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    show_message "Instalando Android SDK em $ANDROID_HOME"

    mkdir -p /tmp/cmdline-tools-extract
    LATEST_CMDLINE=$(curl -s "https://dl.google.com/android/repository/repository2-3.xml" \
        | grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' | sort -u -t- -k3 -n | tail -1 || true)
    [ -n "$LATEST_CMDLINE" ] || { echo "❌ Falha ao obter o cmdline-tools do Android"; return 1; }
    wget "https://dl.google.com/android/repository/$LATEST_CMDLINE" -O /tmp/cmdline-tools.zip
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extract
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    rm -rf "$ANDROID_HOME/cmdline-tools/latest"
    mv /tmp/cmdline-tools-extract/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
    chown -R "$USER_NAME:$USER_NAME" "$ANDROID_HOME"

    user_do "export JAVA_HOME=$ANDROID_JAVA_HOME && yes | $SDKMANAGER --licenses >/dev/null 2>&1" || true

    show_message "Resolvendo pacotes do Android SDK (pode demorar)"
    SDK_LIST=$(user_do "export JAVA_HOME=$ANDROID_JAVA_HOME && $SDKMANAGER --list" || true)

    PLAT_LINES=$(printf '%s\n' "$SDK_LIST" | awk -F'|' '
        /^  platforms;android-/ {
            p=$1; gsub(/^ +| +$/,"",p); sub(/^platforms;android-/,"",p);
            if (p ~ /(-beta|-rc|-alpha|-canary)/) next;
            m=p; sub(/-.*|\..*/,"",m);
            print m, p
        }' | sort -u -k2)
    TOP_MAJORS=$(printf '%s\n' "$PLAT_LINES" | awk '{print $1}' | sort -un | tail -2)

    SDK_PACKAGES=()
    for m in $TOP_MAJORS; do
        while read -r M P; do
            [ "$M" = "$m" ] || continue
            SDK_PACKAGES+=("platforms;android-$P")
            [[ "$P" != *-ext* ]] && SDK_PACKAGES+=("sources;android-$P")
        done <<< "$PLAT_LINES"
    done
    for m in $TOP_MAJORS; do
        while read -r M V; do
            [ "$M" = "$m" ] && SDK_PACKAGES+=("build-tools;$V")
        done <<< "$(printf '%s\n' "$SDK_LIST" | awk -F'|' '
            /^  build-tools;/ {
                v=$1; gsub(/^ +| +$/,"",v); sub(/^build-tools;/,"",v);
                if (v ~ /-rc|-beta/) next;
                m=v; sub(/\..*/,"",m); print m, v
            }' | sort -V -k2)"
    done

    LATEST_NDK=$(printf '%s\n' "$SDK_LIST" | awk -F'|' '/^  ndk;/{gsub(/^ +| +$/,"",$1); sub(/^ndk;/,"",$1); if($1 ~ /-/) next; print $1}' | sort -V | tail -1)
    LATEST_CMAKE=$(printf '%s\n' "$SDK_LIST" | awk -F'|' '/^  cmake;/{gsub(/^ +| +$/,"",$1); sub(/^cmake;/,"",$1); print $1}' | sort -V | tail -1)

    # Componentes de "SDK Tools" solicitados explicitamente.
    # "cmdline-tools;latest" NÃO é pedido aqui de propósito: o cmdline-tools já
    # foi extraído manualmente em "$ANDROID_HOME/cmdline-tools/latest" acima.
    # Pedir o pacote faria o sdkmanager detectar o diretório já existente e
    # instalar num duplicado "latest-2", gerando warnings de local inconsistente.
    SDK_PACKAGES+=(
        "platform-tools"
        "emulator"
        "ndk;$LATEST_NDK"
        "cmake;$LATEST_CMAKE"
        "extras;android;m2repository"
        "extras;google;m2repository"
        "extras;google;google_play_services"
        "extras;google;market_apk_expansion"
        "extras;google;market_licensing"
        "extras;google;webdriver"
        "skiaparser;1"
        "skiaparser;2"
        "skiaparser;3"
        "build;lightbuild;0.0.10-alpha01"
    )

    SDK_PACKAGES_Q=$(printf '%q ' "${SDK_PACKAGES[@]}")
    user_do "export JAVA_HOME=$ANDROID_JAVA_HOME && yes | $SDKMANAGER $SDK_PACKAGES_Q"

    echo "ANDROID_HOME=$ANDROID_HOME" >> /etc/environment
    echo "ANDROID_SDK_ROOT=$ANDROID_HOME" >> /etc/environment
}
