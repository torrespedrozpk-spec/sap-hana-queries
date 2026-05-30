-- =============================================
-- COSTEO DE IMPORTACIONES - HIDROINGENIERIA
-- Tablas: OIPF (Precio de entrega / Landed Costs)
--         IPF1 (líneas por ítem, costo prorrateado)
--         OPDN (Goods Receipt, tipo de cambio)
-- Filtro año: cambiar el valor de YEAR()
-- Para todos los años: eliminar el WHERE
-- =============================================

SELECT
    I."DocNum"                                      AS Nro_PrecioEntrega,
    I."DocDate"                                     AS Fecha,
    I."SuppName"                                    AS Proveedor,
    I."AgentName"                                   AS Agencia_Aduanal,
    L."ItemCode"                                    AS Codigo_Item,
    L."Dscription"                                  AS Descripcion,
    L."Quantity"                                    AS Cantidad,
    L."Currency"                                    AS Moneda,
    L."PriceFOB"                                    AS Precio_FOB_Origen,
    L."PriceFOB" * L."Quantity"                     AS Total_FOB_Origen,
    D."DocRate"                                     AS Tipo_Cambio,
    L."PriceFOB" * D."DocRate"                      AS Precio_FOB_en_GS,
    L."TtlExpndLC"                                  AS Gastos_Adicionales_GS,
    L."TtlCustLC"                                   AS Gastos_Aduana_GS,
    L."TtlCostLC"                                   AS Costo_Total_GS,
    L."PriceAtWH"                                   AS Precio_Unit_Deposito_GS,
    L."PriceAtWH" * L."Quantity"                    AS Total_Deposito_GS,
    CASE
        WHEN L."PriceFOB" * D."DocRate" = 0 THEN NULL
        ELSE L."PriceAtWH" / (L."PriceFOB" * D."DocRate")
    END                                             AS Multiplicador
FROM "HIDROINGENIERIA".OIPF I
INNER JOIN "HIDROINGENIERIA".IPF1 L ON L."DocEntry" = I."DocEntry"
INNER JOIN "HIDROINGENIERIA".OPDN D ON D."DocEntry" = L."BaseEntry"
WHERE YEAR(I."DocDate") = 2026   -- ← cambiar año aquí
ORDER BY I."DocDate" DESC, I."DocNum", L."LineNum"
