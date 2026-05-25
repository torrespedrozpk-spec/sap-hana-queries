-- ============================================================
-- Presupuesto vs Facturado/Pagado por Proyecto
-- Tablas: OQUT, VIEW_EJECUCION_PRESUPUESTO_ZH, OPRJ
-- Nota: usa LEFT JOIN para incluir proyectos sin movimientos
-- ============================================================

SELECT
    T0."Project"       AS "Proyecto",
    X2."PrjName"       AS "Nombre del Proyecto",
    T0."CardName"      AS "Nombre Cliente",
    T0."DocTotal"      AS "Presupuesto",
    X1."TOTALFACTURA"  AS "Facturado",
    X1."TOTALPAGADO"   AS "Pagado",
    X1."TOTALNCR"      AS "Nota de Credito",
    T0."DocDate"       AS "Fecha",
    T0."DocEntry"      AS "ID Presupuesto",
    T0."DocNum"        AS "Número Presupuesto",
    T0."U_ESTADO"      AS "ESTADO"
FROM "E_CONTROL"."OQUT" T0
LEFT JOIN (
    SELECT
        "Project",
        SUM("TOTALFACTURA") AS "TOTALFACTURA",
        SUM("TOTALPAGADO")  AS "TOTALPAGADO",
        SUM("TOTALNCR")     AS "TOTALNCR"
    FROM "E_CONTROL"."VIEW_EJECUCION_PRESUPUESTO_ZH"
    GROUP BY "Project"
) X1 ON T0."Project" = X1."Project"
LEFT JOIN "E_CONTROL"."OPRJ" X2
    ON T0."Project" = X2."PrjCode"
ORDER BY T0."DocDate" DESC