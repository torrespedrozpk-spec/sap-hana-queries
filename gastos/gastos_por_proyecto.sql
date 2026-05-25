-- ============================================================
-- Gastos por Proyecto vs Presupuesto — Margen
-- Fuentes de gasto: OPCH, OPOR, OVPM, JDT1
-- Tablas: OQUT, OPRJ, OPCH, OPOR, OVPM, JDT1
-- Nota: ORDER BY no permitido en SAP HANA en este contexto,
--       ordenar desde la herramienta de visualización (Grafana, etc.)
-- ============================================================

SELECT
    T0."Project"                          AS "Proyecto",
    X2."PrjName"                          AS "Nombre del Proyecto",
    T0."CardName"                         AS "Nombre Cliente",
    T0."DocTotal"                         AS "Presupuesto",

    COALESCE(GC."TotalFacturasCompra", 0) AS "Facturas Compra",
    COALESCE(OC."TotalOrdenesCompra",  0) AS "Ordenes Compra",
    COALESCE(NM."TotalNomina",         0) AS "Nomina",
    COALESCE(AS1."TotalAsientos",      0) AS "Asientos Manuales",

    COALESCE(GC."TotalFacturasCompra", 0) +
    COALESCE(OC."TotalOrdenesCompra",  0) +
    COALESCE(NM."TotalNomina",         0) +
    COALESCE(AS1."TotalAsientos",      0) AS "Total Gastos",

    T0."DocTotal" - (
        COALESCE(GC."TotalFacturasCompra", 0) +
        COALESCE(OC."TotalOrdenesCompra",  0) +
        COALESCE(NM."TotalNomina",         0) +
        COALESCE(AS1."TotalAsientos",      0)
    ) AS "Margen",

    ROUND(
        (T0."DocTotal" - (
            COALESCE(GC."TotalFacturasCompra", 0) +
            COALESCE(OC."TotalOrdenesCompra",  0) +
            COALESCE(NM."TotalNomina",         0) +
            COALESCE(AS1."TotalAsientos",      0)
        )) / NULLIF(T0."DocTotal", 0) * 100
    , 2) AS "Margen %"

FROM "E_CONTROL"."OQUT" T0

LEFT JOIN "E_CONTROL"."OPRJ" X2
    ON T0."Project" = X2."PrjCode"

LEFT JOIN (
    SELECT T1."Project", SUM(T1."DocTotal") AS "TotalFacturasCompra"
    FROM "E_CONTROL"."OPCH" T1
    WHERE T1."CANCELED" = 'N'
    GROUP BY T1."Project"
) GC ON T0."Project" = GC."Project"

LEFT JOIN (
    SELECT T2."Project", SUM(T2."DocTotal") AS "TotalOrdenesCompra"
    FROM "E_CONTROL"."OPOR" T2
    WHERE T2."CANCELED" = 'N'
    GROUP BY T2."Project"
) OC ON T0."Project" = OC."Project"

LEFT JOIN (
    SELECT T3."Project", SUM(T3."DocTotal") AS "TotalNomina"
    FROM "E_CONTROL"."OVPM" T3
    WHERE T3."CANCELED" = 'N'
    GROUP BY T3."Project"
) NM ON T0."Project" = NM."Project"

LEFT JOIN (
    SELECT T4."Project", SUM(T4."Debit") AS "TotalAsientos"
    FROM "E_CONTROL"."JDT1" T4
    WHERE T4."TransType" = 30
    GROUP BY T4."Project"
) AS1 ON T0."Project" = AS1."Project"