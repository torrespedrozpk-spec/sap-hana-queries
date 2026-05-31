#!/usr/bin/env python3
"""
SAP HANA MCP Server
Conecta Claude Desktop directamente a SAP HANA via hdbcli
"""

import asyncio
import json
import os
import sys
from typing import Any

try:
    from hdbcli import dbapi
except ImportError:
    print("ERROR: hdbcli no instalado. Ejecutar: pip install hdbcli", file=sys.stderr)
    sys.exit(1)

# ── Configuración desde variables de entorno ──────────────────────────────────
HANA_HOST     = os.environ.get("HANA_HOST", "192.168.0.200")
HANA_PORT     = int(os.environ.get("HANA_PORT", "30015"))
HANA_USER     = os.environ.get("HANA_USER", "")
HANA_PASSWORD = os.environ.get("HANA_PASSWORD", "")
MAX_ROWS      = int(os.environ.get("MAX_ROWS", "500"))

# ── MCP Protocol helpers ──────────────────────────────────────────────────────

def send(obj: dict):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()

def error_response(req_id, code: int, message: str):
    send({"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}})

def ok_response(req_id, result: Any):
    send({"jsonrpc": "2.0", "id": req_id, "result": result})

# ── HANA connection ───────────────────────────────────────────────────────────

def get_connection():
    return dbapi.connect(
        address=HANA_HOST,
        port=HANA_PORT,
        user=HANA_USER,
        password=HANA_PASSWORD,
        encrypt=False,
        sslValidateCertificate=False
    )

def execute_query(sql: str, max_rows: int = MAX_ROWS) -> dict:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(sql)

        if cursor.description is None:
            # DDL / no result set
            conn.commit()
            return {"type": "ok", "rowcount": cursor.rowcount, "columns": [], "rows": []}

        columns = [d[0] for d in cursor.description]
        rows = []
        for i, row in enumerate(cursor):
            if i >= max_rows:
                break
            rows.append([str(v) if v is not None else None for v in row])

        return {
            "type": "select",
            "columns": columns,
            "rows": rows,
            "row_count": len(rows),
            "truncated": cursor.rowcount > max_rows if cursor.rowcount >= 0 else False
        }
    finally:
        cursor.close()
        conn.close()

def format_result(result: dict) -> str:
    if result["type"] == "ok":
        return f"OK — {result['rowcount']} filas afectadas"

    cols = result["columns"]
    rows = result["rows"]

    if not rows:
        return f"Sin resultados. Columnas: {', '.join(cols)}"

    # Calcular anchos de columna
    widths = [len(c) for c in cols]
    for row in rows:
        for i, val in enumerate(row):
            widths[i] = max(widths[i], len(str(val)) if val is not None else 4)

    sep  = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    head = "|" + "|".join(f" {c:<{widths[i]}} " for i, c in enumerate(cols)) + "|"

    lines = [sep, head, sep]
    for row in rows:
        line = "|" + "|".join(f" {str(v) if v is not None else 'NULL':<{widths[i]}} " for i, v in enumerate(row)) + "|"
        lines.append(line)
    lines.append(sep)

    summary = f"\n{result['row_count']} filas"
    if result.get("truncated"):
        summary += f" (truncado a {MAX_ROWS})"

    return "\n".join(lines) + summary

# ── MCP Tool definitions ──────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "hana_query",
        "description": (
            "Ejecuta una consulta SQL de solo lectura (SELECT) contra SAP HANA. "
            "Usar para explorar datos, verificar resultados de queries, inspeccionar "
            "vistas y tablas de los esquemas E_CONTROL y ENVING."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "sql": {
                    "type": "string",
                    "description": "Consulta SQL a ejecutar (SELECT solamente)"
                },
                "max_rows": {
                    "type": "integer",
                    "description": f"Máximo de filas a retornar (default {MAX_ROWS})",
                    "default": MAX_ROWS
                }
            },
            "required": ["sql"]
        }
    },
    {
        "name": "hana_schemas",
        "description": "Lista los esquemas disponibles en SAP HANA",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "hana_tables",
        "description": "Lista tablas y vistas de un esquema específico",
        "inputSchema": {
            "type": "object",
            "properties": {
                "schema": {
                    "type": "string",
                    "description": "Nombre del esquema (ej: E_CONTROL, ENVING)"
                },
                "filter": {
                    "type": "string",
                    "description": "Filtro opcional por nombre (ej: VIEW, OQUT)"
                }
            },
            "required": ["schema"]
        }
    },
    {
        "name": "hana_columns",
        "description": "Lista columnas de una tabla o vista específica",
        "inputSchema": {
            "type": "object",
            "properties": {
                "schema": {"type": "string", "description": "Nombre del esquema"},
                "table":  {"type": "string", "description": "Nombre de la tabla o vista"}
            },
            "required": ["schema", "table"]
        }
    },
    {
        "name": "hana_ping",
        "description": "Verifica la conexión a SAP HANA",
        "inputSchema": {"type": "object", "properties": {}}
    }
]

# ── Tool handlers ─────────────────────────────────────────────────────────────

def handle_hana_ping(_args):
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM DUMMY")
        conn.close()
        return f"✅ Conexión OK — {HANA_HOST}:{HANA_PORT} (usuario: {HANA_USER})"
    except Exception as e:
        return f"❌ Error de conexión: {e}"

def handle_hana_schemas(_args):
    sql = "SELECT SCHEMA_NAME FROM SYS.SCHEMAS ORDER BY SCHEMA_NAME"
    result = execute_query(sql)
    return format_result(result)

def handle_hana_tables(args):
    schema = args.get("schema", "").upper()
    filt   = args.get("filter", "")
    sql = f"""
        SELECT TABLE_NAME AS NAME, 'TABLE' AS TYPE
        FROM SYS.TABLES
        WHERE SCHEMA_NAME = '{schema}'
        {'AND TABLE_NAME LIKE \'%' + filt.upper() + '%\'' if filt else ''}
        UNION ALL
        SELECT VIEW_NAME AS NAME, 'VIEW' AS TYPE
        FROM SYS.VIEWS
        WHERE SCHEMA_NAME = '{schema}'
        {'AND VIEW_NAME LIKE \'%' + filt.upper() + '%\'' if filt else ''}
        ORDER BY TYPE, NAME
    """
    result = execute_query(sql, max_rows=1000)
    return format_result(result)

def handle_hana_columns(args):
    schema = args.get("schema", "").upper()
    table  = args.get("table", "").upper()
    sql = f"""
        SELECT COLUMN_NAME, DATA_TYPE_NAME, LENGTH, IS_NULLABLE, POSITION
        FROM SYS.TABLE_COLUMNS
        WHERE SCHEMA_NAME = '{schema}' AND TABLE_NAME = '{table}'
        UNION ALL
        SELECT COLUMN_NAME, DATA_TYPE_NAME, LENGTH, IS_NULLABLE, POSITION
        FROM SYS.VIEW_COLUMNS
        WHERE SCHEMA_NAME = '{schema}' AND VIEW_NAME = '{table}'
        ORDER BY POSITION
    """
    result = execute_query(sql, max_rows=200)
    return format_result(result)

def handle_hana_query(args):
    sql      = args.get("sql", "").strip()
    max_rows = args.get("max_rows", MAX_ROWS)

    # Seguridad: solo SELECT
    sql_upper = sql.upper().lstrip()
    if not sql_upper.startswith("SELECT") and not sql_upper.startswith("WITH"):
        return "❌ Solo se permiten consultas SELECT / WITH ... SELECT"

    try:
        result = execute_query(sql, max_rows=max_rows)
        return format_result(result)
    except Exception as e:
        return f"❌ Error SQL: {e}"

TOOL_HANDLERS = {
    "hana_ping":    handle_hana_ping,
    "hana_schemas": handle_hana_schemas,
    "hana_tables":  handle_hana_tables,
    "hana_columns": handle_hana_columns,
    "hana_query":   handle_hana_query,
}

# ── MCP main loop ─────────────────────────────────────────────────────────────

def handle_request(req: dict):
    method = req.get("method", "")
    req_id = req.get("id")
    params = req.get("params", {})

    if method == "initialize":
        ok_response(req_id, {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "hana-mcp", "version": "1.0.0"}
        })

    elif method == "tools/list":
        ok_response(req_id, {"tools": TOOLS})

    elif method == "tools/call":
        tool_name = params.get("name", "")
        tool_args  = params.get("arguments", {})
        handler = TOOL_HANDLERS.get(tool_name)
        if handler is None:
            error_response(req_id, -32601, f"Tool desconocida: {tool_name}")
        else:
            try:
                text = handler(tool_args)
                ok_response(req_id, {
                    "content": [{"type": "text", "text": text}]
                })
            except Exception as e:
                ok_response(req_id, {
                    "content": [{"type": "text", "text": f"❌ Error interno: {e}"}]
                })

    elif method == "notifications/initialized":
        pass  # no response needed

    else:
        if req_id is not None:
            error_response(req_id, -32601, f"Método no soportado: {method}")

def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            handle_request(req)
        except json.JSONDecodeError as e:
            send({"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": f"JSON inválido: {e}"}})
        except Exception as e:
            send({"jsonrpc": "2.0", "id": None, "error": {"code": -32603, "message": f"Error interno: {e}"}})

if __name__ == "__main__":
    main()
