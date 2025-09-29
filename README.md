# DoH4Mint and DoT4Mint
Scripts para automatizar el uso de DoH (DNS over HTTPS) o DoT (DNS ovr TLS) en Linux Mint 21+
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

Puedes elegir si configurar en tu equipo DoT o DoH, en ambos casos las consultas DNS estarán cifradas. En el caso de elegir DoH4Mint también podrás activar la VPN de Cloudflare redirigiendo todo tu tráfico por la VPN.

<h2>✅ Verificar la configuración:</h2>

Una forma rápida de verificar el uso de DoT o DoH es accediendo desde el navegador a la URL https://one.one.one.one/help/

