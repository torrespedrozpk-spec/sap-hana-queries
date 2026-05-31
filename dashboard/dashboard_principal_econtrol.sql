-- ============================================================
-- Dashboard Principal: Presupuesto, Facturación, Costos y Margen por Proyecto
-- Versión: 4 — Incluye devoluciones de materiales (VIEW_DEV_ENTREGAS_ZH)
-- Esquema: E_CONTROL
-- Tablas: OQUT, OPRJ, VIEW_EJECUCION_PRESUPUESTO_ZH,
--         VIEW_ENTREGAS_ZH, VIEW_DEV_ENTREGAS_ZH, PCH1, OPCH
-- Clasificación ítems:
--   Materiales : todo excepto SESER%, GA.%, ZZ%
--   Mano Obra  : SESER%, GA.%
--   Excluido   : ZZ% (ajuste contable IVA)
-- ============================================================
WITH "COSTOS_MAT" AS (
    SELECT "Project", SUM("TotalLinea") AS "CostoMateriales"
    FROM "E_CONTROL"."VIEW_ENTREGAS_ZH"
    WHERE "Project" <> '00'
      AND "Project" != ''
      AND "Project" IS NOT NULL
      AND "ItemCode" NOT LIKE 'SESER%'
      AND "ItemCode" NOT LIKE 'GA.%'
      AND "ItemCode" NOT LIKE 'ZZ%'
    GROUP BY "Project"
),
"DEVOLUCIONES_MAT" AS (
    SELECT "Project", SUM("TotalLinea") AS "TotalDevoluciones"
    FROM "E_CONTROL"."VIEW_DEV_ENTREGAS_ZH"
    WHERE "Project" <> '00'
      AND "Project" != ''
      AND "Project" IS NOT NULL
      AND "ItemCode" NOT LIKE 'SESER%'
      AND "ItemCode" NOT LIKE 'GA.%'
      AND "ItemCode" NOT LIKE 'ZZ%'
    GROUP BY "Project"
),
"COSTOS_MO" AS (
    SELECT T0."Project", SUM(T0."GTotal") AS "CostoManoObra"
    FROM "E_CONTROL"."PCH1" T0
    INNER JOIN "E_CONTROL"."OPCH" T5 ON T5."DocEntry" = T0."DocEntry"
    WHERE T5."CANCELED" = 'N'
      AND T0."Project" <> '00'
      AND T0."Project" != ''
      AND T0."Project" IS NOT NULL
      AND (
          T0."ItemCode" LIKE 'SESER%'
       OR T0."ItemCode" LIKE 'GA.%'
      )
    GROUP BY T0."Project"
),
"FACT" AS (
    SELECT "Project",
        SUM("TOTALFACTURA")        AS "TotalFacturado",
        SUM("TOTALPAGADO")         AS "TotalCobrado",
        SUM(IFNULL("TOTALNCR", 0)) AS "TotalNotasCredito"
    FROM "E_CONTROL"."VIEW_EJECUCION_PRESUPUESTO_ZH"
    WHERE "Project" <> '00' AND "Project" IS NOT NULL
    GROUP BY "Project"
),
"PRESUP" AS (
    SELECT T0."Project", T0."CardName", T0."DocTotal", T0."DocDate"
    FROM "E_CONTROL"."OQUT" T0
    WHERE T0."CANCELED" = 'N'
      AND T0."Project" <> '00'
      AND T0."Project" != ''
      AND T0."Project" IS NOT NULL
      AND T0."DocTotal" > 1
),
"RESULT" AS (
    SELECT
        P."Project"                                                                                        AS "Proyecto",
        PR."PrjName"                                                                                       AS "Nombre Proyecto",
        P."CardName"                                                                                       AS "Cliente",
        P."DocDate"                                                                                        AS "Fecha",
        P."DocTotal"                                                                                       AS "Presupuesto",
        IFNULL(F."TotalFacturado", 0)                                                                      AS "TotalFacturado",
        IFNULL(F."TotalCobrado", 0)                                                                        AS "TotalCobrado",
        IFNULL(F."TotalNotasCredito", 0)                                                                   AS "TotalNotasCredito",
        IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0)                                  AS "FacturacionNeta",
        ROUND((IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0)) / NULLIF(P."DocTotal", 0) * 100, 2) AS "EjecucionPct",
        IFNULL(M."CostoMateriales", 0) - IFNULL(D."TotalDevoluciones", 0)                                 AS "CostoMateriales",
        IFNULL(D."TotalDevoluciones", 0)                                                                   AS "TotalDevoluciones",
        IFNULL(MO."CostoManoObra", 0)                                                                      AS "CostoManoObra",
        (IFNULL(M."CostoMateriales", 0) - IFNULL(D."TotalDevoluciones", 0))
            + IFNULL(MO."CostoManoObra", 0)                                                                AS "CostoTotal",
        (IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0))
            - ((IFNULL(M."CostoMateriales", 0) - IFNULL(D."TotalDevoluciones", 0))
            + IFNULL(MO."CostoManoObra", 0))                                                               AS "MargenBruto",
        ROUND(
            ((IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0))
                - ((IFNULL(M."CostoMateriales", 0) - IFNULL(D."TotalDevoluciones", 0))
                + IFNULL(MO."CostoManoObra", 0)))
            / NULLIF(IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0), 0) * 100
        , 2)                                                                                               AS "MargenPct",
        P."DocTotal" - (IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0))                 AS "SaldoPorFacturar",
        (IFNULL(F."TotalFacturado", 0) - IFNULL(F."TotalNotasCredito", 0)) - IFNULL(F."TotalCobrado", 0)  AS "SaldoPorCobrar"
    FROM "PRESUP" P
    LEFT JOIN "E_CONTROL"."OPRJ" PR  ON P."Project" = PR."PrjCode"
    LEFT JOIN "FACT" F                ON P."Project" = F."Project"
    LEFT JOIN "COSTOS_MAT" M          ON P."Project" = M."Project"
    LEFT JOIN "DEVOLUCIONES_MAT" D    ON P."Project" = D."Project"
    LEFT JOIN "COSTOS_MO" MO          ON P."Project" = MO."Project"
)
SELECT * FROM "RESULT"
ORDER BY "Fecha" DESC
