-- ============================================================
-- Detalle Costo de Materiales por Proyecto (con devoluciones)
-- Versión: 3 — UNION ALL entregas + devoluciones negativas
-- Esquema: ENVING
-- Fuente: VIEW_ENTREGAS_ZH (ODLN) + VIEW_DEV_ENTREGAS_ZH (ORDN)
-- Uso: reemplazar 'PROY0797' por el proyecto deseado
-- ============================================================
SELECT
    V."Project"          AS "Proyecto",
    PR."PrjName"         AS "Nombre Proyecto",
    DL."DocNum"          AS "Nro Documento",
    TO_DATE(V."TaxDate") AS "Fecha",
    'Entrega'            AS "Tipo",
    V."CardCode"         AS "Cod Cliente",
    V."CardName"         AS "Cliente",
    V."NumAtCard"        AS "Ref Cliente",
    V."ItmsGrpNam"       AS "Grupo Item",
    V."NOMBREFABRICANTE" AS "Fabricante",
    V."ItemCode"         AS "Codigo Item",
    V."Dscription"       AS "Descripcion",
    V."WhsCode"          AS "Deposito",
    V."Quantity"         AS "Cantidad",
    V."Costo"            AS "Costo Unitario",
    V."TotalLinea"       AS "Total Linea"
FROM "ENVING"."VIEW_ENTREGAS_ZH" V
INNER JOIN "ENVING"."ODLN" DL ON DL."DocEntry" = V."DocEntry"
LEFT JOIN "ENVING"."OPRJ" PR  ON V."Project" = PR."PrjCode"
WHERE V."Project" = 'PROY0797'
  AND V."ItemCode" NOT LIKE 'SESER%'
  AND V."ItemCode" NOT LIKE 'GA.%'
  AND V."ItemCode" NOT LIKE 'ZZ%'

UNION ALL

SELECT
    V."Project"           AS "Proyecto",
    PR."PrjName"          AS "Nombre Proyecto",
    DL."DocNum"           AS "Nro Documento",
    TO_DATE(V."TaxDate")  AS "Fecha",
    'Devolucion'          AS "Tipo",
    V."CardCode"          AS "Cod Cliente",
    V."CardName"          AS "Cliente",
    V."NumAtCard"         AS "Ref Cliente",
    V."ItmsGrpNam"        AS "Grupo Item",
    V."NOMBREFABRICANTE"  AS "Fabricante",
    V."ItemCode"          AS "Codigo Item",
    V."Dscription"        AS "Descripcion",
    V."WhsCode"           AS "Deposito",
    V."Quantity" * -1     AS "Cantidad",
    V."Costo"             AS "Costo Unitario",
    V."TotalLinea" * -1   AS "Total Linea"
FROM "ENVING"."VIEW_DEV_ENTREGAS_ZH" V
INNER JOIN "ENVING"."ORDN" DL ON DL."DocEntry" = V."DocEntry"
LEFT JOIN "ENVING"."OPRJ" PR  ON V."Project" = PR."PrjCode"
WHERE V."Project" = 'PROY0797'
  AND V."ItemCode" NOT LIKE 'SESER%'
  AND V."ItemCode" NOT LIKE 'GA.%'
  AND V."ItemCode" NOT LIKE 'ZZ%'

ORDER BY "Fecha", "Nro Documento"
