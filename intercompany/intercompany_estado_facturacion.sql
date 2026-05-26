-- ============================================================
-- Informe de Entregas Intercompany - Estado de Facturación
-- Base: E_CONTROL | Filtro: Project = 'PROY0118'
-- Autor: SAP HANA Queries Collection
-- Fecha: 2026-05-26
-- ============================================================
-- DESCRIPCIÓN:
--   Muestra todas las entregas (ODLN) marcadas como intercompany
--   según el campo Project, indicando si cada entrega ya fue
--   facturada (AR Invoice en OINV) o está pendiente.
--
-- NOTAS:
--   - Ajustar 'PROY0118' al código exacto del proyecto intercompany
--   - BaseType = 15 corresponde a Delivery en SAP B1
--   - Ejecutar seleccionando TODO el texto en DBeaver (Ctrl+A)
--     para evitar error de syntax near ORDER BY
-- ============================================================

SELECT * FROM (

    SELECT
        T0."DocEntry"                           AS "IDEntrega",
        T0."DocNum"                             AS "NroEntrega",
        T0."DocDate"                            AS "FechaEntrega",
        T0."CardCode"                           AS "CódigoCliente",
        T0."CardName"                           AS "NombreCliente",
        T0."Project"                            AS "Proyecto",
        T0."DocTotal"                           AS "TotalEntrega",
        T0."DocCur"                             AS "Moneda",

        CASE
            WHEN I_AGG."InvDocEntry" IS NOT NULL THEN 'Facturada'
            ELSE 'Pendiente de Factura'
        END                                     AS "EstadoFactura",

        T1."DocNum"                             AS "NroFactura",
        T1."DocDate"                            AS "FechaFactura",
        T1."DocTotal"                           AS "TotalFactura",
        T1."DocStatus"                          AS "EstadoFacturaDoc"

    FROM "E_CONTROL"."ODLN" T0

    -- JOIN a líneas de factura agrupadas por entrega base
    LEFT JOIN (
        SELECT
            I1."BaseEntry",
            MIN(I1."DocEntry")                  AS "InvDocEntry"
        FROM "E_CONTROL"."INV1" I1
        WHERE I1."BaseType" = 15               -- 15 = Delivery
        GROUP BY I1."BaseEntry"
    ) I_AGG
        ON I_AGG."BaseEntry" = T0."DocEntry"

    -- JOIN a cabecera de factura
    LEFT JOIN "E_CONTROL"."OINV" T1
        ON T1."DocEntry" = I_AGG."InvDocEntry"

    -- Solo entregas intercompany
    WHERE T0."Project" = 'PROY0118'            -- ⚠️ Ajustar al código exacto

) RESULTADO
ORDER BY
    "EstadoFactura" ASC,                       -- Pendiente de Factura primero
    "FechaEntrega"  DESC
