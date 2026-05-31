-- ============================================================
-- Detalle Costo de Materiales por Proyecto
-- Versión: 2 — Excluye SESER%, GA.%, ZZ% (solo ítems físicos)
-- Esquema: E_CONTROL
-- Fuente: VIEW_ENTREGAS_ZH + ODLN
-- Uso: Filtrar por proyecto específico en el WHERE
-- ============================================================
SELECT
    V."Project"                                      AS "Proyecto",
    PR."PrjName"                                     AS "Nombre Proyecto",
    DL."DocNum"                                      AS "Nro Entrega",
    TO_DATE(V."TaxDate")                             AS "Fecha Entrega",
    V."CardCode"                                     AS "Cod Proveedor",
    V."CardName"                                     AS "Proveedor",
    V."NumAtCard"                                    AS "Ref Proveedor",
    V."ItmsGrpNam"                                   AS "Grupo Item",
    V."NOMBREFABRICANTE"                             AS "Fabricante",
    V."ItemCode"                                     AS "Codigo Item",
    V."Dscription"                                   AS "Descripcion",
    V."WhsCode"                                      AS "Deposito",
    V."Quantity"                                     AS "Cantidad",
    V."Costo"                                        AS "Costo Unitario",
    V."TotalLinea"                                   AS "Total Linea"
FROM "E_CONTROL"."VIEW_ENTREGAS_ZH" V
INNER JOIN "E_CONTROL"."ODLN" DL ON DL."DocEntry" = V."DocEntry"
LEFT JOIN "E_CONTROL"."OPRJ" PR ON V."Project" = PR."PrjCode"
WHERE V."Project" = 'PROY0797'          -- reemplazar por proyecto deseado
  AND V."ItemCode" NOT LIKE 'SESER%'
  AND V."ItemCode" NOT LIKE 'GA.%'
  AND V."ItemCode" NOT LIKE 'ZZ%'
ORDER BY V."TaxDate", DL."DocNum"
