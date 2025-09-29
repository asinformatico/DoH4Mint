# DoH4Mint
Script para automatizar el uso de DoH (DNS over HTTPS) en Linux Mint 21+
Soporta Cloudflare, Google, Quad9 y AdGuard (a elección por el usuario).

El script realiza una copia de seguridad de la configuración previa para poder volver atrás en cualquier momento.
Tras descargarlo o editarlo, dale permisos de ejecución:
```bash
chmod +x DoH4Mint.sh
```
Verás al ejecutarlo el siguiente menú en pantalla:
```bash
🌐 Selecciona un proveedor de DNS over HTTPS (DoH):
--------------------------------------------------
  1) cloudflare
  2) google
  3) quad9
  4) adguard
  0) Salir
Tu elección (0-4): 1
```
Tan solo elije el proveedor y pulsa Enter.

<h2>✅ Ventajas de este script:</h2>

Interactivo y fácil de usar.<br>
Seguro: hace copia de seguridad.<br>
Verifica compatibilidad antes de aplicar cambios.<br>
Prueba la conexión al final.<br>
Totalmente reversible.<br>

