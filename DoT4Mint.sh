#!/bin/bash

# Script interactivo para configurar DNS over TLS (DoT) en Linux Mint 21+
# Soporta: Cloudflare, Google, Quad9, AdGuard

set -e

PROVIDERS=(
    "cloudflare:1.1.1.1#cloudflare-dns.com"
    "google:8.8.8.8#dns.google"
    "quad9:9.9.9.9#dns.quad9.net"
    "adguard:94.140.14.14#dns.adguard-dns.com"
)

show_menu() {
    echo "🌐 Selecciona un proveedor de DNS over TLS (DoT):"
    echo "--------------------------------------------------"
    for i in "${!PROVIDERS[@]}"; do
        name="${PROVIDERS[i]%%:*}"
        echo "  $((i+1))) $name"
    done
    echo "  0) Salir"
    echo -n "Tu elección (0-4): "
}

get_provider_dns() {
    local choice=$1
    if [[ $choice -lt 1 || $choice -gt ${#PROVIDERS[@]} ]]; then
        echo "❌ Opción inválida."
        exit 1
    fi
    echo "${PROVIDERS[$((choice-1))]#*:}"
}

# --- Inicio del script ---

echo "🛡️  Configurador interactivo de DNS over TLS (DoT)"
echo ""

# Verificar Linux Mint 21+
if ! grep -q "Linux Mint 2[1-9]" /etc/os-release 2>/dev/null; then
    echo "⚠️  Advertencia: Este script está optimizado para Linux Mint 21+."
    read -p "¿Continuar de todos modos? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 0
    fi
fi

# Verificar systemd >= 248
SYSTEMD_VERSION=$(systemd --version | head -n1 | grep -o '[0-9]\+' || echo "0")
if [ "$SYSTEMD_VERSION" -lt 248 ]; then
    echo "❌ systemd versión $SYSTEMD_VERSION es demasiado antiguo. Se requiere >= 248."
    echo "   Actualiza tu sistema o usa dnscrypt-proxy."
    exit 1
fi

# Mostrar menú
while true; do
    show_menu
    read -r choice

    case $choice in
        0)
            echo "👋 Saliendo."
            exit 0
            ;;
        1|2|3|4)
            DNS_ENTRY=$(get_provider_dns "$choice")
            PROVIDER_NAME="${PROVIDERS[$((choice-1))]%%:*}"
            break
            ;;
        *)
            echo "❌ Por favor, selecciona una opción válida (0-4)."
            echo
            ;;
    esac
done

echo ""
echo "✅ Proveedor seleccionado: $PROVIDER_NAME"
echo "🔧 Configurando DoT con: $DNS_ENTRY"
echo ""

# Copia de seguridad
if [ ! -f /etc/systemd/resolved.conf.bak ]; then
    sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
    echo "💾 Copia de seguridad creada: /etc/systemd/resolved.conf.bak"
fi

# Configurar resolved.conf
echo "📝 Escribiendo configuración..."
sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=$DNS_ENTRY
FallbackDNS=
Domains=~.
DNSOverTLS=yes
Cache=yes
CacheFromLocalhost=yes
LLMNR=no
MulticastDNS=no
DNSSEC=no
EOF

# Asegurar resolv.conf
if [ ! -L /etc/resolv.conf ] || [ "$(readlink /etc/resolv.conf)" != "/run/systemd/resolve/stub-resolv.conf" ]; then
    echo "🔗 Configurando /etc/resolv.conf..."
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

# Reiniciar servicio
echo "🔄 Reiniciando systemd-resolved..."
sudo systemctl restart systemd-resolved

# Verificar
echo "🔍 Verificando configuración..."
sleep 2

if resolvectl status 2>/dev/null | grep -q "$DNS_ENTRY"; then
    echo "✅ ¡DoT configurado correctamente con $PROVIDER_NAME!"
else
    echo "❌ Error: La configuración no se aplicó como se esperaba."
    echo "   Ejecuta manualmente: resolvectl status"
    exit 1
fi

# Prueba rápida
echo "🧪 Probando resolución DNS..."
if timeout 5 dig +short example.com @127.0.0.53 | head -1 | grep -q "^[0-9]"; then
    echo "✅ Resolución DNS funcionando."
else
    echo "⚠️  No se pudo resolver 'example.com'. Puede haber un problema de red o firewall."
fi

echo ""
echo "ℹ️  Para revertir los cambios:"
echo "    sudo cp /etc/systemd/resolved.conf.bak /etc/systemd/resolved.conf"
echo "    sudo systemctl restart systemd-resolved"
echo ""
echo "🎉 ¡Listo! Estás usando DNS cifrado con $PROVIDER_NAME."
