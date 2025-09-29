#!/bin/bash

# Script para configurar DNS over HTTPS (DoH) en Linux Mint 21+ usando cloudflared
# Opcional: habilitar Cloudflare WARP

set -e

# Lista de proveedores DoH
declare -A PROVIDERS=(
    [cloudflare]="https://cloudflare-dns.com/dns-query"
    [google]="https://dns.google/dns-query"
    [quad9]="https://dns.quad9.net/dns-query"
    [adguard]="https://dns.adguard-dns.com/dns-query"
)

show_menu() {
    echo "🌐 Selecciona un proveedor de DNS over HTTPS (DoH):"
    echo "--------------------------------------------------"
    local i=1
    for name in "${!PROVIDERS[@]}"; do
        echo "  $i) $name"
        ((i++))
    done
    echo "  0) Salir"
    echo -n "Tu elección (0-$((${#PROVIDERS[@]}))): "
}

# --- Inicio ---
echo "🛡️  Configurador de DNS over HTTPS (DoH) con cloudflared + WARP opcional"
echo ""

# Verificar dependencias
if ! command -v curl &>/dev/null; then
    echo "❌ Necesitas instalar curl primero."
    exit 1
fi

# Mostrar menú
PS3="Selecciona proveedor: "
options=( "${!PROVIDERS[@]}" )
select opt in "${options[@]}" "Salir"; do
    if [[ $opt == "Salir" ]]; then
        echo "👋 Cancelado."
        exit 0
    elif [[ -n ${PROVIDERS[$opt]} ]]; then
        PROVIDER_NAME=$opt
        PROVIDER_URL=${PROVIDERS[$opt]}
        break
    else
        echo "❌ Opción inválida."
    fi
done

echo ""
echo "✅ Proveedor seleccionado: $PROVIDER_NAME"
echo "🔧 Usando endpoint: $PROVIDER_URL"
echo ""

# Preguntar si quiere WARP
read -p "¿Quieres habilitar Cloudflare WARP (VPN ligera con DoH integrado)? (s/N): " -n 1 -r
echo
USE_WARP=false
if [[ $REPLY =~ ^[Ss]$ ]]; then
    USE_WARP=true
fi

# Instalar cloudflared si no existe
if ! command -v cloudflared &>/dev/null; then
    echo "⬇️  Instalando cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb
    sudo dpkg -i /tmp/cloudflared.deb
    rm /tmp/cloudflared.deb
fi

if $USE_WARP; then
    echo "🌐 Configurando WARP..."
    sudo cloudflared service install
    echo "🔄 Habilitando WARP..."
    sudo systemctl enable --now cloudflared-warp
    echo "✅ WARP activado. Todo el tráfico pasa por Cloudflare."
else
    # Crear configuración de cloudflared (solo DoH)
    echo "📝 Creando configuración en /etc/cloudflared/config.yml..."
    sudo mkdir -p /etc/cloudflared
    sudo tee /etc/cloudflared/config.yml >/dev/null <<EOF
proxy-dns: true
proxy-dns-port: 5053
proxy-dns-address: 127.0.0.1
proxy-dns-upstream:
  - $PROVIDER_URL
EOF

    # Crear servicio systemd
    echo "⚙️  Creando servicio systemd..."
    sudo tee /etc/systemd/system/cloudflared.service >/dev/null <<EOF
[Unit]
Description=Cloudflare DNS over HTTPS proxy
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/cloudflared --config /etc/cloudflared/config.yml
Restart=on-failure
User=nobody
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

    # Activar servicio
    echo "🔄 Habilitando y arrancando cloudflared..."
    sudo systemctl daemon-reexec
    sudo systemctl enable --now cloudflared

    # Configurar systemd-resolved
    echo "📝 Configurando systemd-resolved..."
    sudo tee /etc/systemd/resolved.conf >/dev/null <<EOF
[Resolve]
DNS=127.0.0.1:5053
FallbackDNS=
Domains=~.
LLMNR=no
MulticastDNS=no
DNSSEC=no
EOF

    # Asegurar resolv.conf
    if [ ! -L /etc/resolv.conf ] || [ "$(readlink /etc/resolv.conf)" != "/run/systemd/resolve/stub-resolv.conf" ]; then
        echo "🔗 Ajustando /etc/resolv.conf..."
        sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi

    sudo systemctl restart systemd-resolved

    # Verificar
    echo ""
    echo "🔍 Verificando configuración..."
    sleep 2
    if dig +short @127.0.0.1 -p 5053 example.com | grep -q "^[0-9]"; then
        echo "✅ DoH funcionando con $PROVIDER_NAME"
    else
        echo "❌ No se pudo resolver a través de cloudflared."
        exit 1
    fi
fi

echo ""
echo "ℹ️  Para comprobar tu estado visita: https://one.one.one.one/help/"
echo "🎉 ¡Listo! Estás usando DNS cifrado (${USE_WARP:+con WARP} ${USE_WARP:-DoH puro})"
