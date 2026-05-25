-- ============================================================
-- Entregas: Detalle de Items por Proyecto
-- Vista: VIEW_ENTREGAS_ZH
-- Útil para fiscalizar entregas: cantidades, costos, fechas, proveedor
-- Columnas disponibles:
--   DocEntry, Project, TipoCondicion, TaxDate, NumAtCard,
--   ItemCode, Dscription, ItmsGrpCod, ItmsGrpNam, NOMBREFABRICANTE,
--   Quantity, Costo1, Costo, PriceAfVAT, TotalLinea,
--   CardCode, CardName, SlpCode, SlpName, SUCURSAL,
--   WhsCode, Mes, Anho, PymntGroup
-- ============================================================

SELECT
    "Project",
    "TaxDate"         AS "Fecha Entrega",
    "CardCode"        AS "Cod. Proveedor",
    "CardName"        AS "Proveedor",
    "ItemCode"        AS "Cod. Item",
    "Dscription"      AS "Descripcion",
    "ItmsGrpNam"      AS "Grupo Item",
    "NOMBREFABRICANTE" AS "Fabricante",
    "Quantity"        AS "Cantidad",
    "Costo"           AS "Costo Unit.",
    "TotalLinea"      AS "Total Linea",
    "SUCURSAL",
    "PymntGroup"      AS "Condicion Pago"
FROM "E_CONTROL"."VIEW_ENTREGAS_ZH"
WHERE "Project" != '00'
-- Filtrar por proyecto específico (descomentar):
-- AND "Project" = 'PROY0208'
-- Filtrar por año:
-- AND "Anho" = 2025
-- Filtrar por proveedor:
-- AND "CardCode" = 'PROV001'
ORDER BY "Project", "TaxDate" DESC