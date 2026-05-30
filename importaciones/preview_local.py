# =============================================
# PREVIEW LOCAL — Conecta directo a SAP HANA
# Genera HTML en el escritorio de tu Mac
# Uso:
#   cd /ruta/a/etl_sap
#   source venv/bin/activate
#   python preview_local.py
# =============================================

from hdbcli import dbapi
from datetime import datetime, timedelta
import subprocess

# ── Configuración SAP HANA ───────────────────
HANA_HOST     = "192.168.0.200"
HANA_PORT     = 30015
HANA_USER     = "TU_USUARIO"       # ← completar
HANA_PASSWORD = "TU_PASSWORD"      # ← completar

# ── Salida ───────────────────────────────────
OUTPUT_FILE   = "/Users/TU_USUARIO_MAC/Desktop/preview_importaciones.html"  # ← completar

# ── Fechas ───────────────────────────────────
fecha_hasta = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
fecha_desde = fecha_hasta - timedelta(days=7)

def conectar():
    return dbapi.connect(
        address=HANA_HOST,
        port=HANA_PORT,
        user=HANA_USER,
        password=HANA_PASSWORD
    )

def fetch(conn, query):
    cur = conn.cursor()
    cur.execute(query)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    cur.close()
    return cols, rows

def tabla_html(cols, rows, vacia="Sin registros esta semana."):
    if not rows:
        return f'<p style="color:#888;">{vacia}</p>'
    html = '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-size:13px;width:100%;">'
    html += "<thead><tr>" + "".join(
        f'<th style="background:#2c3e50;color:white;text-align:left;padding:8px;">{c}</th>'
        for c in cols
    ) + "</tr></thead><tbody>"
    for i, row in enumerate(rows):
        bg = "#f9f9f9" if i % 2 == 0 else "#ffffff"
        html += f'<tr style="background:{bg};">' + "".join(
            f'<td style="padding:6px;">{("" if v is None else v)}</td>'
            for v in row
        ) + "</tr>"
    html += "</tbody></table>"
    return html

def main():
    print("Conectando a SAP HANA...")
    conn = conectar()
    print("✅ Conectado")

    print("Consultando nuevas cargas...")
    cols_nuevas, rows_nuevas = fetch(conn, f"""
        SELECT
            'E_CONTROL'                                         AS "Empresa",
            I."DocNum"                                          AS "N° Doc",
            TO_VARCHAR(I."DocDate", 'DD/MM/YYYY')               AS "Fecha Doc",
            TO_VARCHAR(I."CreateDate", 'DD/MM/YYYY')            AS "Ingresado SAP",
            I."SuppName"                                        AS "Proveedor",
            I."AgentName"                                       AS "Agencia"
        FROM "E_CONTROL".OIPF I
        WHERE I."CreateDate" >= '{fecha_desde.strftime('%Y-%m-%d')}'
          AND I."CreateDate" <  '{fecha_hasta.strftime('%Y-%m-%d')}'
        UNION ALL
        SELECT
            'ENVING',
            I."DocNum",
            TO_VARCHAR(I."DocDate", 'DD/MM/YYYY'),
            TO_VARCHAR(I."CreateDate", 'DD/MM/YYYY'),
            I."SuppName",
            I."AgentName"
        FROM "ENVING".OIPF I
        WHERE I."CreateDate" >= '{fecha_desde.strftime('%Y-%m-%d')}'
          AND I."CreateDate" <  '{fecha_hasta.strftime('%Y-%m-%d')}'
        ORDER BY 1, 4 DESC
    """)

    print("Consultando demoras históricas...")
    cols_demora, rows_demora = fetch(conn, """
        SELECT empresa, COUNT(*) AS total,
               ROUND(AVG(dias), 1) AS prom,
               MAX(dias) AS maximo,
               MIN(dias) AS minimo
        FROM (
            SELECT
                'E_CONTROL' AS empresa,
                I."DocNum",
                MAX(DAYS_BETWEEN(
                    CASE WHEN L."BaseType" = 20 THEN D."CreateDate"
                         WHEN L."BaseType" = 69 THEN I2."CreateDate"
                    END, I."CreateDate")) AS dias
            FROM "E_CONTROL".OIPF I
            INNER JOIN "E_CONTROL".IPF1 L ON L."DocEntry" = I."DocEntry"
            LEFT JOIN "E_CONTROL".OPDN D ON D."DocEntry" = L."BaseEntry" AND L."BaseType" = 20
            LEFT JOIN "E_CONTROL".OIPF I2 ON I2."DocEntry" = L."BaseEntry" AND L."BaseType" = 69
            GROUP BY I."DocNum", I."CreateDate"
            UNION ALL
            SELECT
                'ENVING',
                I."DocNum",
                MAX(DAYS_BETWEEN(
                    CASE WHEN L."BaseType" = 20 THEN D."CreateDate"
                         WHEN L."BaseType" = 69 THEN I2."CreateDate"
                    END, I."CreateDate"))
            FROM "ENVING".OIPF I
            INNER JOIN "ENVING".IPF1 L ON L."DocEntry" = I."DocEntry"
            LEFT JOIN "ENVING".OPDN D ON D."DocEntry" = L."BaseEntry" AND L."BaseType" = 20
            LEFT JOIN "ENVING".OIPF I2 ON I2."DocEntry" = L."BaseEntry" AND L."BaseType" = 69
            GROUP BY I."DocNum", I."CreateDate"
        ) X
        GROUP BY empresa
        ORDER BY empresa
    """)
    cols_demora = ["Empresa", "Total importaciones", "Días promedio", "Máximo días", "Mínimo días"]

    print("Consultando costeo de la semana...")
    cols_costeo, rows_costeo = fetch(conn, f"""
        SELECT
            'E_CONTROL'                                                 AS "Empresa",
            I."SuppName"                                                AS "Proveedor",
            L."ItemCode"                                                AS "Código",
            L."Dscription"                                              AS "Descripción",
            L."Quantity"                                                AS "Cant.",
            L."Currency"                                                AS "Mon.",
            ROUND(L."PriceFOB", 2)                                      AS "FOB Unit.",
            ROUND(L."PriceFOB" * L."Quantity", 2)                       AS "Total FOB",
            ROUND(D."DocRate", 2)                                       AS "TC",
            ROUND(L."TtlCostLC", 0)                                     AS "Costo Total GS",
            ROUND(L."PriceAtWH", 0)                                     AS "Precio Depósito",
            ROUND(L."PriceAtWH" / NULLIF(L."PriceFOB" * D."DocRate", 0), 3) AS "Multiplicador"
        FROM "E_CONTROL".OIPF I
        INNER JOIN "E_CONTROL".IPF1 L ON L."DocEntry" = I."DocEntry"
        INNER JOIN "E_CONTROL".OPDN D ON D."DocEntry" = L."BaseEntry"
        WHERE I."CreateDate" >= '{fecha_desde.strftime('%Y-%m-%d')}'
          AND I."CreateDate" <  '{fecha_hasta.strftime('%Y-%m-%d')}'
        UNION ALL
        SELECT
            'ENVING',
            I."SuppName",
            L."ItemCode",
            L."Dscription",
            L."Quantity",
            L."Currency",
            ROUND(L."PriceFOB", 2),
            ROUND(L."PriceFOB" * L."Quantity", 2),
            ROUND(D."DocRate", 2),
            ROUND(L."TtlCostLC", 0),
            ROUND(L."PriceAtWH", 0),
            ROUND(L."PriceAtWH" / NULLIF(L."PriceFOB" * D."DocRate", 0), 3)
        FROM "ENVING".OIPF I
        INNER JOIN "ENVING".IPF1 L ON L."DocEntry" = I."DocEntry"
        INNER JOIN "ENVING".OPDN D ON D."DocEntry" = L."BaseEntry"
        WHERE I."CreateDate" >= '{fecha_desde.strftime('%Y-%m-%d')}'
          AND I."CreateDate" <  '{fecha_hasta.strftime('%Y-%m-%d')}'
        ORDER BY 1, 2
    """)

    print("Consultando alertas de demora...")
    cols_alerta, rows_alerta = fetch(conn, """
        SELECT empresa, doc, f_entrada, f_costeo, proveedor, dias FROM (
            SELECT
                'E_CONTROL'                                             AS empresa,
                I."DocNum"                                              AS doc,
                TO_VARCHAR(
                    CASE WHEN L."BaseType" = 20 THEN D."DocDate"
                         WHEN L."BaseType" = 69 THEN I2."DocDate"
                    END, 'DD/MM/YYYY')                                  AS f_entrada,
                TO_VARCHAR(I."CreateDate", 'DD/MM/YYYY')                AS f_costeo,
                I."SuppName"                                            AS proveedor,
                DAYS_BETWEEN(
                    CASE WHEN L."BaseType" = 20 THEN D."CreateDate"
                         WHEN L."BaseType" = 69 THEN I2."CreateDate"
                    END, I."CreateDate")                                AS dias
            FROM "E_CONTROL".OIPF I
            INNER JOIN "E_CONTROL".IPF1 L ON L."DocEntry" = I."DocEntry"
            LEFT JOIN "E_CONTROL".OPDN D ON D."DocEntry" = L."BaseEntry" AND L."BaseType" = 20
            LEFT JOIN "E_CONTROL".OIPF I2 ON I2."DocEntry" = L."BaseEntry" AND L."BaseType" = 69
            GROUP BY I."DocNum", I."CreateDate", I."SuppName", L."BaseType",
                     D."DocDate", D."CreateDate", I2."DocDate", I2."CreateDate"
            HAVING DAYS_BETWEEN(
                CASE WHEN L."BaseType" = 20 THEN D."CreateDate"
                     WHEN L."BaseType" = 69 THEN I2."CreateDate"
                END, I."CreateDate") > 7
            UNION ALL
            SELECT
                'ENVING',
                I."DocNum",
                TO_VARCHAR(
                    CASE WHEN L."BaseType" = 20 THEN D."DocDate"
                         WHEN L."BaseType" = 69 THEN I2."DocDate"
                    END, 'DD/MM/YYYY'),
                TO_VARCHAR(I."CreateDate", 'DD/MM/YYYY'),
                I."SuppName",
                DAYS_BETWEEN(
                    CASE WHEN L."BaseType" = 20 THEN D."CreateDate"
                         WHEN L."BaseType" = 69 THEN I2."CreateDate"
                    END, I."CreateDate")
            FROM "ENVING".OIPF I
            INNER JOIN "ENVING".IPF1 L ON L."DocEntry" = I."DocEntry"
            LEFT JOIN "ENVING".OPDN D ON D."DocEntry" = L."BaseEntry" AND L."BaseType" = 20
            LEFT JOIN "ENVING".OIPF I2 ON I2."DocEntry" = L."BaseEntry" AND L."BaseType" = 69
            GROUP BY I."DocNum", I."CreateDate", I."SuppName", L."BaseType",
                     D."DocDate", D."CreateDate", I2."DocDate", I2."CreateDate"
            HAVING DAYS_BETWEEN(
                CASE WHEN L."BaseType" = 20 THEN D."CreateDate"
                     WHEN L."BaseType" = 69 THEN I2."CreateDate"
                END, I."CreateDate") > 7
        ) X
        ORDER BY dias DESC
        LIMIT 10
    """)
    cols_alerta = ["Empresa", "N° Doc", "Fecha Entrada", "Costeo Ingresado", "Proveedor", "Días de demora"]

    conn.close()
    print("✅ Consultas completadas")

    semana_str = f"{fecha_desde.strftime('%d/%m/%Y')} al {fecha_hasta.strftime('%d/%m/%Y')}"
    fecha_str  = datetime.now().strftime("%d/%m/%Y %H:%M")

    html = f"""
    <html><body style="font-family:Arial,sans-serif;color:#333;max-width:1100px;margin:auto;padding:20px;">
    <div style="background:#2c3e50;color:white;padding:20px;border-radius:6px;margin-bottom:24px;">
        <h2 style="margin:0;">📦 Reporte Semanal de Importaciones</h2>
        <p style="margin:6px 0 0 0;font-size:14px;">Semana: {semana_str} &nbsp;|&nbsp; Generado: {fecha_str}</p>
        <p style="margin:4px 0 0 0;font-size:13px;opacity:0.8;">Empresas: E_CONTROL · ENVING</p>
    </div>
    <h3 style="color:#2c3e50;border-bottom:2px solid #2c3e50;padding-bottom:4px;">🆕 Nuevas cargas ingresadas esta semana</h3>
    {tabla_html(cols_nuevas, rows_nuevas)}
    <h3 style="color:#2c3e50;border-bottom:2px solid #2c3e50;padding-bottom:4px;margin-top:28px;">📊 Resumen de demora por empresa (histórico)</h3>
    <p style="font-size:12px;color:#888;">Referencia: E_CONTROL ~7 días · ENVING ~14 días</p>
    {tabla_html(cols_demora, rows_demora)}
    <h3 style="color:#2c3e50;border-bottom:2px solid #2c3e50;padding-bottom:4px;margin-top:28px;">💰 Detalle de costeo — cargas de esta semana</h3>
    {tabla_html(cols_costeo, rows_costeo)}
    <h3 style="color:#e74c3c;border-bottom:2px solid #e74c3c;padding-bottom:4px;margin-top:28px;">⚠️ Importaciones con demora mayor a 7 días (top 10)</h3>
    {tabla_html(cols_alerta, rows_alerta, "No hay importaciones con demora mayor a 7 días. ✅")}
    <p style="font-size:11px;color:#aaa;margin-top:32px;border-top:1px solid #eee;padding-top:12px;">
        Preview local — conexión directa SAP HANA desde Mac.
    </p>
    </body></html>
    """

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"✅ HTML generado: {OUTPUT_FILE}")
    subprocess.run(["open", OUTPUT_FILE])

if __name__ == "__main__":
    main()
