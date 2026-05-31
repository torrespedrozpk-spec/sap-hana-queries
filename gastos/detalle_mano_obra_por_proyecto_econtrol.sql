-- ============================================================
-- Detalle Costo de Mano de Obra y Servicios por Proyecto
-- Versión: 2 — Solo SESER% y GA.% (servicios + gastos varios)
-- Esquema: E_CONTROL
-- Fuente: PCH1 + OPCH
-- Uso: Filtrar por proyecto específico en el WHERE
-- Nota: ZZ% excluido (ajuste contable IVA, no es costo real)
-- ============================================================
SELECT
    T0."Project"                                     AS "Proyecto",
    PR."PrjName"                                     AS "Nombre Proyecto",
    T5."DocNum"                                      AS "Nro Factura Compra",
    TO_DATE(T5."DocDate")                            AS "Fecha Factura",
    T5."CardCode"                                    AS "Cod Proveedor",
    T5."CardName"                                    AS "Proveedor",
    T5."NumAtCard"                                   AS "Ref Proveedor",
    T0."LineNum"                                     AS "Nro Linea",
    T0."ItemCode"                                    AS "Codigo Item",
    T0."Dscription"                                  AS "Descripcion",
    T0."Quantity"                                    AS "Cantidad",
    T0."Price"                                       AS "Precio Unitario",
    T0."GTotal"                                      AS "Total Linea"
FROM "E_CONTROL"."PCH1" T0
INNER JOIN "E_CONTROL"."OPCH" T5 ON T5."DocEntry" = T0."DocEntry"
LEFT JOIN "E_CONTROL"."OPRJ" PR ON T0."Project" = PR."PrjCode"
WHERE T0."Project" = 'PROY0797'         -- reemplazar por proyecto deseado
  AND T5."CANCELED" = 'N'
  AND (
      T0."ItemCode" LIKE 'SESER%'
   OR T0."ItemCode" LIKE 'GA.%'
  )
ORDER BY T5."DocDate", T5."DocNum", T0."LineNum"
