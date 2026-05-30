# Reporte Semanal de Importaciones — Guía de Implementación

Envío automático cada lunes a las 7am con resumen de cargas, costeo y demoras.
Empresas cubiertas: **E_CONTROL** y **ENVING**.

---

## Arquitectura

```
SAP HANA
    ↓ (ETL Python existente — cron 6am diario)
PostgreSQL (sap_dashboard)
    ↓ (nuevo script reporte_semanal.py — cron 7am lunes)
Email HTML via SMTP Zoho
```

---

## Paso 1 — Agregar queries al ETL existente

Abrir `~/etl_sap/etl.py` y agregar los siguientes dos queries dentro del diccionario `QUERIES`:

```python
"importaciones_costeo": """
    SELECT
        'E_CONTROL' AS empresa,
        I."DocNum"                                  AS nro_precio_entrega,
        I."DocDate"                                 AS fecha,
        I."CreateDate"                              AS fecha_creacion,
        I."SuppName"                                AS proveedor,
        I."AgentName"                               AS agencia_aduanal,
        L."ItemCode"                                AS codigo_item,
        L."Dscription"                              AS descripcion,
        L."Quantity"                                AS cantidad,
        L."Currency"                                AS moneda,
        L."PriceFOB"                                AS precio_fob_origen,
        L."PriceFOB" * L."Quantity"                 AS total_fob_origen,
        D."DocRate"                                 AS tipo_cambio,
        L."PriceFOB" * D."DocRate"                  AS precio_fob_gs,
        L."TtlExpndLC"                              AS gastos_adicionales_gs,
        L."TtlCustLC"                               AS gastos_aduana_gs,
        L."TtlCostLC"                               AS costo_total_gs,
        L."PriceAtWH"                               AS precio_unit_deposito_gs,
        L."PriceAtWH" * L."Quantity"                AS total_deposito_gs,
        CASE
            WHEN L."PriceFOB" * D."DocRate" = 0 THEN NULL
            ELSE L."PriceAtWH" / (L."PriceFOB" * D."DocRate")
        END                                         AS multiplicador
    FROM "E_CONTROL".OIPF I
    INNER JOIN "E_CONTROL".IPF1 L ON L."DocEntry" = I."DocEntry"
    INNER JOIN "E_CONTROL".OPDN D ON D."DocEntry" = L."BaseEntry"
    UNION ALL
    SELECT
        'ENVING' AS empresa,
        I."DocNum",
        I."DocDate",
        I."CreateDate",
        I."SuppName",
        I."AgentName",
        L."ItemCode",
        L."Dscription",
        L."Quantity",
        L."Currency",
        L."PriceFOB",
        L."PriceFOB" * L."Quantity",
        D."DocRate",
        L."PriceFOB" * D."DocRate",
        L."TtlExpndLC",
        L."TtlCustLC",
        L."TtlCostLC",
        L."PriceAtWH",
        L."PriceAtWH" * L."Quantity",
        CASE
            WHEN L."PriceFOB" * D."DocRate" = 0 THEN NULL
            ELSE L."PriceAtWH" / (L."PriceFOB" * D."DocRate")
        END
    FROM "ENVING".OIPF I
    INNER JOIN "ENVING".IPF1 L ON L."DocEntry" = I."DocEntry"
    INNER JOIN "ENVING".OPDN D ON D."DocEntry" = L."BaseEntry"
""",

"importaciones_demora": """
    SELECT
        'E_CONTROL' AS empresa,
        I."DocNum"                                          AS nro_precio_entrega,
        I."DocDate"                                         AS fecha_documento,
        I."CreateDate"                                      AS fecha_ingreso_sistema,
        I."SuppName"                                        AS proveedor,
        I."AgentName"                                       AS agencia_aduanal,
        D."DocDate"                                         AS fecha_entrada_mercancia,
        D."CreateDate"                                      AS fecha_creacion_entrada,
        DAYS_BETWEEN(D."CreateDate", I."CreateDate")        AS dias_entrada_a_costeo,
        DAYS_BETWEEN(I."DocDate", I."CreateDate")           AS dias_backdating,
        DAYS_BETWEEN(D."DocDate", I."CreateDate")           AS dias_total_llegada_a_costeo
    FROM "E_CONTROL".OIPF I
    INNER JOIN "E_CONTROL".OPDN D ON D."DocEntry" = (
        SELECT MIN(L."BaseEntry")
        FROM "E_CONTROL".IPF1 L
        WHERE L."DocEntry" = I."DocEntry"
    )
    UNION ALL
    SELECT
        'ENVING' AS empresa,
        I."DocNum",
        I."DocDate",
        I."CreateDate",
        I."SuppName",
        I."AgentName",
        D."DocDate",
        D."CreateDate",
        DAYS_BETWEEN(D."CreateDate", I."CreateDate"),
        DAYS_BETWEEN(I."DocDate", I."CreateDate"),
        DAYS_BETWEEN(D."DocDate", I."CreateDate")
    FROM "ENVING".OIPF I
    INNER JOIN "ENVING".OPDN D ON D."DocEntry" = (
        SELECT MIN(L."BaseEntry")
        FROM "ENVING".IPF1 L
        WHERE L."DocEntry" = I."DocEntry"
    )
"""
```

---

## Paso 2 — Crear archivo reporte_semanal.py

```bash
nano ~/etl_sap/reporte_semanal.py
```

Pegar el siguiente contenido y completar los campos marcados con `← completar`:

```python
# =============================================
# REPORTE SEMANAL DE IMPORTACIONES
# Envía resumen por email cada lunes 7am
# Cron: 0 7 * * 1 /usr/bin/python3 /root/etl_sap/reporte_semanal.py
# =============================================

import psycopg2
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime, timedelta
import logging

# ── Configuración Email SMTP Zoho ────────────────────────────
SMTP_HOST     = "smtp.zoho.com"
SMTP_PORT     = 587
SMTP_USER     = "TU_EMAIL@TUDOMINIO.COM"       # ← completar
SMTP_PASSWORD = "TU_PASSWORD_ZOHO"             # ← completar
EMAIL_FROM    = "TU_EMAIL@TUDOMINIO.COM"       # ← completar
EMAIL_TO      = ["DESTINATARIO@DOMINIO.COM"]   # ← completar, puede ser lista

# ── Configuración PostgreSQL ─────────────────────────────────
PG_HOST       = "localhost"
PG_PORT       = 5432
PG_DATABASE   = "sap_dashboard"
PG_USER       = "etl_user"
PG_PASSWORD   = "CambiarPorPasswordSeguro"     # ← completar

# ── Logging ──────────────────────────────────────────────────
logging.basicConfig(
    filename="/root/etl_sap/reporte_semanal.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def get_pg_connection():
    return psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        dbname=PG_DATABASE,
        user=PG_USER,
        password=PG_PASSWORD
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

def construir_html(conn, fecha_desde, fecha_hasta):

    # ── 1. Nuevas cargas de la semana ────────────────────────
    cols_nuevas, rows_nuevas = fetch(conn, f"""
        SELECT
            empresa                                         AS "Empresa",
            nro_precio_entrega                              AS "N° Doc",
            TO_CHAR(fecha_documento, 'DD/MM/YYYY')          AS "Fecha Doc",
            TO_CHAR(fecha_ingreso_sistema, 'DD/MM/YYYY')    AS "Ingresado",
            proveedor                                       AS "Proveedor",
            agencia_aduanal                                 AS "Agencia"
        FROM importaciones_demora
        WHERE fecha_ingreso_sistema >= '{fecha_desde}'
          AND fecha_ingreso_sistema <  '{fecha_hasta}'
        ORDER BY empresa, fecha_ingreso_sistema DESC
    """)

    # ── 2. Resumen de demora por empresa (histórico) ─────────
    cols_demora, rows_demora = fetch(conn, """
        SELECT
            empresa                                 AS "Empresa",
            COUNT(*)                                AS "Total importaciones",
            ROUND(AVG(dias_entrada_a_costeo)::numeric, 1) AS "Días promedio (histórico)",
            MAX(dias_entrada_a_costeo)              AS "Máximo días",
            MIN(dias_entrada_a_costeo)              AS "Mínimo días"
        FROM importaciones_demora
        GROUP BY empresa
        ORDER BY empresa
    """)

    # ── 3. Detalle de costeo de la semana ────────────────────
    cols_costeo, rows_costeo = fetch(conn, f"""
        SELECT
            empresa                                         AS "Empresa",
            proveedor                                       AS "Proveedor",
            codigo_item                                     AS "Código",
            descripcion                                     AS "Descripción",
            cantidad                                        AS "Cant.",
            moneda                                          AS "Mon.",
            ROUND(precio_fob_origen::numeric, 2)            AS "FOB Unitario",
            ROUND(total_fob_origen::numeric, 2)             AS "Total FOB",
            ROUND(tipo_cambio::numeric, 2)                  AS "TC",
            ROUND(costo_total_gs::numeric, 0)               AS "Costo Total GS",
            ROUND(precio_unit_deposito_gs::numeric, 0)      AS "Precio Depósito",
            ROUND(multiplicador::numeric, 3)                AS "Multiplicador"
        FROM importaciones_costeo
        WHERE fecha_creacion >= '{fecha_desde}'
          AND fecha_creacion <  '{fecha_hasta}'
        ORDER BY empresa, fecha DESC
    """)

    # ── 4. Top 10 importaciones con mayor demora ─────────────
    cols_pendientes, rows_pendientes = fetch(conn, """
        SELECT
            empresa                                         AS "Empresa",
            nro_precio_entrega                              AS "N° Doc",
            TO_CHAR(fecha_entrada_mercancia, 'DD/MM/YYYY')  AS "Fecha Entrada",
            TO_CHAR(fecha_ingreso_sistema, 'DD/MM/YYYY')    AS "Costeo Ingresado",
            proveedor                                       AS "Proveedor",
            dias_entrada_a_costeo                           AS "Días de demora"
        FROM importaciones_demora
        WHERE dias_entrada_a_costeo > 7
        ORDER BY dias_entrada_a_costeo DESC
        LIMIT 10
    """)

    fecha_str   = datetime.now().strftime("%d/%m/%Y")
    semana_str  = f"{fecha_desde.strftime('%d/%m/%Y')} al {fecha_hasta.strftime('%d/%m/%Y')}"

    html = f"""
    <html><body style="font-family:Arial,sans-serif;color:#333;max-width:1100px;margin:auto;padding:20px;">

    <div style="background:#2c3e50;color:white;padding:20px;border-radius:6px;margin-bottom:24px;">
        <h2 style="margin:0;">📦 Reporte Semanal de Importaciones</h2>
        <p style="margin:6px 0 0 0;font-size:14px;">Semana: {semana_str} &nbsp;|&nbsp; Generado: {fecha_str}</p>
        <p style="margin:4px 0 0 0;font-size:13px;opacity:0.8;">Empresas: E_CONTROL · ENVING</p>
    </div>

    <h3 style="color:#2c3e50;border-bottom:2px solid #2c3e50;padding-bottom:4px;">
        🆕 Nuevas cargas ingresadas esta semana
    </h3>
    {tabla_html(cols_nuevas, rows_nuevas)}

    <h3 style="color:#2c3e50;border-bottom:2px solid #2c3e50;padding-bottom:4px;margin-top:28px;">
        📊 Resumen de demora por empresa (histórico)
    </h3>
    <p style="font-size:12px;color:#888;">Referencia: E_CONTROL ~7 días · ENVING ~14 días</p>
    {tabla_html(cols_demora, rows_demora)}

    <h3 style="color:#2c3e50;border-bottom:2px solid #2c3e50;padding-bottom:4px;margin-top:28px;">
        💰 Detalle de costeo — cargas de esta semana
    </h3>
    {tabla_html(cols_costeo, rows_costeo)}

    <h3 style="color:#e74c3c;border-bottom:2px solid #e74c3c;padding-bottom:4px;margin-top:28px;">
        ⚠️ Importaciones con demora mayor a 7 días (top 10)
    </h3>
    {tabla_html(cols_pendientes, rows_pendientes, "No hay importaciones con demora mayor a 7 días. ✅")}

    <p style="font-size:11px;color:#aaa;margin-top:32px;border-top:1px solid #eee;padding-top:12px;">
        Reporte generado automáticamente desde SAP HANA vía ETL PostgreSQL.<br>
        Para consultas contactar al área de TI.
    </p>

    </body></html>
    """
    return html

def enviar_reporte():
    logging.info("=== Iniciando reporte semanal ===")

    fecha_hasta = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    fecha_desde = fecha_hasta - timedelta(days=7)

    try:
        conn = get_pg_connection()
        html = construir_html(conn, fecha_desde, fecha_hasta)
        conn.close()
    except Exception as e:
        logging.error(f"Error consultando PostgreSQL: {e}")
        return

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"📦 Reporte Importaciones — Semana {fecha_desde.strftime('%d/%m')} al {fecha_hasta.strftime('%d/%m/%Y')}"
    msg["From"]    = EMAIL_FROM
    msg["To"]      = ", ".join(EMAIL_TO)
    msg.attach(MIMEText(html, "html"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())
        logging.info(f"Reporte enviado a {EMAIL_TO}")
    except Exception as e:
        logging.error(f"Error enviando email: {e}")

    logging.info("=== Reporte semanal finalizado ===\n")

if __name__ == "__main__":
    enviar_reporte()
```

---

## Paso 3 — Agregar cron para ejecución automática

```bash
crontab -e
```

Agregar esta línea al final:

```
0 7 * * 1 /usr/bin/python3 /root/etl_sap/reporte_semanal.py >> /root/etl_sap/cron_reporte.log 2>&1
```

Esto ejecuta el reporte **todos los lunes a las 7:00 AM**.

El ETL diario (6am) corre primero y actualiza PostgreSQL, luego el reporte (7am) lee los datos ya frescos.

---

## Paso 4 — Probar manualmente

```bash
cd /root/etl_sap

# Primero correr el ETL para poblar las tablas nuevas
python3 etl.py

# Luego probar el reporte
python3 reporte_semanal.py

# Ver log en tiempo real
tail -f reporte_semanal.log
```

---

## Paso 5 — Verificar tablas en PostgreSQL

```bash
sudo -u postgres psql -d sap_dashboard -c "\dt"
sudo -u postgres psql -d sap_dashboard -c "SELECT COUNT(*) FROM importaciones_costeo;"
sudo -u postgres psql -d sap_dashboard -c "SELECT COUNT(*) FROM importaciones_demora;"
```

---

## Resumen de archivos involucrados

| Archivo | Acción |
|---|---|
| `~/etl_sap/etl.py` | Agregar los dos queries nuevos al diccionario QUERIES |
| `~/etl_sap/reporte_semanal.py` | Crear archivo nuevo (código completo arriba) |
| `crontab` | Agregar línea para lunes 7am |

---

## Contenido del reporte email

| Sección | Descripción |
|---|---|
| 🆕 Nuevas cargas | Importaciones ingresadas al sistema en los últimos 7 días |
| 📊 Demora por empresa | Promedio histórico, máximo y mínimo de días por empresa |
| 💰 Detalle de costeo | Ítem a ítem con FOB, tipo de cambio, costo GS y multiplicador |
| ⚠️ Top 10 demoras | Importaciones con más de 7 días sin costeo finalizado |

---

## Notas

- Las fechas usadas son `CreateDate` (inmodificables por el usuario), no `DocDate`.
- El umbral de alerta de demora es **7 días** — ajustable en el query de la sección ⚠️.
- Para agregar más destinatarios, agregar emails a la lista `EMAIL_TO`.
- Para agregar HIDROINGENIERIA en el futuro, agregar un `UNION ALL` en cada query del ETL.
