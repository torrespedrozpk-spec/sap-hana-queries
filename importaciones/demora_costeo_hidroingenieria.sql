-- =============================================
-- DEMORA EN COSTEO DE IMPORTACIONES - HIDROINGENIERIA
-- Mide días reales entre entrada de mercancía
-- y creación del costeo (fechas inmodificables)
-- =============================================
-- Dias_Entrada_a_Costeo    : CreateDate(OPDN) → CreateDate(OIPF) — demora real del área
-- Dias_Doc_a_Costeo        : DocDate(OIPF) → CreateDate(OIPF)    — detecta backdating
-- Dias_Total_Llegada_Costeo: DocDate(OPDN) → CreateDate(OIPF)    — demora total declarada
-- =============================================

SELECT
    I."DocNum"                                          AS Nro_PrecioEntrega,
    I."DocDate"                                         AS Fecha_Documento,
    I."CreateDate"                                      AS Fecha_Ingreso_Sistema,
    I."SuppName"                                        AS Proveedor,
    I."AgentName"                                       AS Agencia_Aduanal,
    D."DocDate"                                         AS Fecha_Entrada_Mercancia,
    D."CreateDate"                                      AS Fecha_Creacion_Entrada,
    DAYS_BETWEEN(D."CreateDate", I."CreateDate")        AS Dias_Entrada_a_Costeo,
    DAYS_BETWEEN(I."DocDate", I."CreateDate")           AS Dias_Doc_a_Costeo,
    DAYS_BETWEEN(D."DocDate", I."CreateDate")           AS Dias_Total_Llegada_a_Costeo
FROM "HIDROINGENIERIA".OIPF I
INNER JOIN "HIDROINGENIERIA".OPDN D ON D."DocEntry" = (
    SELECT MIN(L."BaseEntry")
    FROM "HIDROINGENIERIA".IPF1 L
    WHERE L."DocEntry" = I."DocEntry"
)
ORDER BY I."CreateDate" DESC
