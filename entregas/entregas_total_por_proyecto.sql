-- ============================================================
-- Entregas: Costo Total agrupado por Proyecto
-- Vista: VIEW_ENTREGAS_ZH
-- Columnas clave: TotalLinea (costo), Quantity, TaxDate
-- Excluye proyecto "00" (sin proyecto asignado)
-- ============================================================

SELECT
    "Project",
    "CardCode",
    "CardName",
    MAX("TaxDate")    AS "UltimaEntrega",
    SUM("Quantity")   AS "CantidadTotal",
    SUM("TotalLinea") AS "CostoTotal"
FROM "E_CONTROL"."VIEW_ENTREGAS_ZH"
WHERE "Project" != '00'
GROUP BY
    "Project",
    "CardCode",
    "CardName"
ORDER BY MAX("TaxDate") DESC