#!/bin/bash

# Script final: DoH + WARP automático en Linux Mint 21+
# Requisitos: sudo, curl

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

echo "🛡️  Configurador DoH + WARP automático con cloudflared"
echo ""

# Verificar curl
if ! command -v curl &>/dev/null; then
    echo "❌ Necesitas instalar curl primero."
    exit 1
fi

# Instalar cloudflared si no existe
if ! command -v cloudflared &>/dev/null; then
    echo "⬇️ Instalando cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb
    sudo dpkg -i /tmp/cloudflared.deb
    rm /tmp/cloudflared.deb
fi

# Elegir proveedor DoH
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
echo "🔧 Endpoint DoH: $PROVIDER_URL"
echo ""

# Crear configuración DoH
echo "📝 Creando configuración DoH en /etc/cloudflared/config.yml..."
sudo mkdir -p /etc/cloudflared
sudo tee /etc/cloudflared/config.yml >/dev/null <<EOF
proxy-dns: true
proxy-dns-port: 5053
proxy-dns-address: 127.0.0.1
proxy-dns-upstream:
  - $PROVIDER_URL
EOF

# Crear servicio systemd para DoH
echo "⚙️  Configurando systemd para DoH..."
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

# Activar servicio DoH
sudo systemctl daemon-reexec
sudo systemctl enable --now cloudflared

# Configurar systemd-resolved
sudo tee /etc/systemd/resolved.conf >/dev/null <<EOF
[Resolve]
DNS=127.0.0.1:5053
FallbackDNS=
Domains=~.
LLMNR=no
MulticastDNS=no
DNSSEC=no
EOF

# Ajustar /etc/resolv.conf
if [ ! -L /etc/resolv.conf ] || [ "$(readlink /etc/resolv.conf)" != "/run/systemd/resolve/stub-resolv.conf" ]; then
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

sudo systemctl restart systemd-resolved

# Registrar WARP automáticamente si no existe
if ! cloudflared warp status &>/dev/null; then
    echo "🔐 Registrando WARP automáticamente..."
    sudo cloudflared warp register
fi

echo "🌐 Activando WARP..."
sudo cloudflared warp enable
sudo systemctl enable --now cloudflared-warp

# Verificar DoH
echo ""
echo "🔍 Verificando resolución DoH..."
sleep 2
if dig +short @127.0.0.1 -p 5053 example.com | grep -q "^[0-9]"; then
    echo "✅ DoH funcionando con $PROVIDER_NAME"
else
    echo "❌ No se pudo resolver a través de cloudflared."
    exit 1
fi

echo ""
echo "ℹ️  Comprueba tu estado en: https://one.one.one.one/help/"
echo "🎉 ¡Listo! DNS cifrado activo con WARP y DoH."
