# Setup Claude Desktop + SAP HANA MCP

## Requisitos
- Claude Desktop instalado (https://claude.ai/download)
- Python 3.8+
- `hdbcli` instalado: `pip install hdbcli`
- Acceso de red a SAP HANA (192.168.0.200:30015)

## Pasos

### 1 — Crear carpeta del servidor
```bash
mkdir -p ~/sap-hana-mcp
cp hana_mcp_server.py ~/sap-hana-mcp/
```

### 2 — Instalar dependencia
```bash
pip3 install hdbcli
```

### 3 — Configurar Claude Desktop
Abrí el archivo de configuración:
```bash
# Mac
open ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Pegá este contenido (ajustando usuario, password y path):
```json
{
  "mcpServers": {
    "sap-hana": {
      "command": "python3",
      "args": ["/Users/TU_USUARIO/sap-hana-mcp/hana_mcp_server.py"],
      "env": {
        "HANA_HOST": "192.168.0.200",
        "HANA_PORT": "30015",
        "HANA_USER": "TU_USUARIO_HANA",
        "HANA_PASSWORD": "TU_PASSWORD_HANA",
        "MAX_ROWS": "500"
      }
    }
  }
}
```

### 4 — Reiniciar Claude Desktop
Cerrá y volvé a abrir Claude Desktop completamente.

### 5 — Verificar conexión
En Claude Desktop escribí:
> "Hacé un ping a SAP HANA"

Claude debería responder con ✅ Conexión OK.

## Herramientas disponibles

| Tool | Descripción |
|---|---|
| `hana_ping` | Verifica la conexión |
| `hana_schemas` | Lista esquemas disponibles |
| `hana_tables` | Lista tablas/vistas de un esquema |
| `hana_columns` | Lista columnas de una tabla/vista |
| `hana_query` | Ejecuta cualquier SELECT |

## Seguridad
- Solo permite SELECT / WITH...SELECT (no INSERT, UPDATE, DELETE)
- Password se pasa por variable de entorno, no queda en el código
- Conexión local desde tu Mac, no expone HANA a internet

## Troubleshooting

**"command not found: python3"**
```bash
which python3   # verificar path
# Si falla, usar el path completo en "command", ej: "/usr/local/bin/python3"
```

**"No module named hdbcli"**
```bash
pip3 install hdbcli
# O con el python específico:
/usr/local/bin/python3 -m pip install hdbcli
```

**Error de conexión HANA**
- Verificar que estés en la misma red que el servidor SAP (o VPN activa)
- Confirmar host, puerto, usuario y password en la config
