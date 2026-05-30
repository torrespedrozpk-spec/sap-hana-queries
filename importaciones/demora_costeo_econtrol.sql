-- =============================================
-- DEMORA EN COSTEO DE IMPORTACIONES - E_CONTROL
-- Mide días reales entre entrada de mercancía
-- y creación del costeo (fechas inmodificables)
-- Referencia: media histórica ~7 días
-- =============================================
-- Dias_Entrada_a_Costeo    : CreateDate(base) → CreateDate(OIPF) — demora real del área
-- Dias_Doc_a_Costeo        : DocDate(OIPF) → CreateDate(OIPF)    — detecta backdating
-- Dias_Total_Llegada_Costeo: DocDate(base) → CreateDate(OIPF)    — demora total declarada
-- BaseType=20 → base es OPDN directo
-- BaseType=69 → base es otro OIPF (cadena encadenada)
-- =============================================

SELECT
    'E_CONTROL'                                                 AS empresa,
    I."DocNum"                                                  AS nro_precio_entrega,
    I."DocDate"                                                 AS fecha_documento,
    I."CreateDate"                                              AS fecha_ingreso_sistema,
    I."SuppName"                                                AS proveedor,
    I."AgentName"                                               AS agencia_aduanal,
    CASE
        WHEN L."BaseType" = 20 THEN D."DocDate"
        WHEN L."BaseType" = 69 THEN I2."DocDate"
    END                                                         AS fecha_entrada_mercancia,
    CASE
        WHEN L."BaseType" = 20 THEN D."CreateDate"
        WHEN L."BaseType" = 69 THEN I2."CreateDate"
    END                                                         AS fecha_creacion_entrada,
    DAYS_BETWEEN(
        CASE
            WHEN L."BaseType" = 20 THEN D."CreateDate"
            WHEN L."BaseType" = 69 THEN I2."CreateDate"
        END,
        I."CreateDate"
    )                                                           AS dias_entrada_a_costeo,
    DAYS_BETWEEN(I."DocDate", I."CreateDate")                   AS dias_backdating,
    DAYS_BETWEEN(
        CASE
            WHEN L."BaseType" = 20 THEN D."DocDate"
            WHEN L."BaseType" = 69 THEN I2."DocDate"
        END,
        I."CreateDate"
    )                                                           AS dias_total_llegada_a_costeo
FROM "E_CONTROL".OIPF I
INNER JOIN "E_CONTROL".IPF1 L ON L."DocEntry" = I."DocEntry"
LEFT JOIN "E_CONTROL".OPDN D
    ON D."DocEntry" = L."BaseEntry"
    AND L."BaseType" = 20
LEFT JOIN "E_CONTROL".OIPF I2
    ON I2."DocEntry" = L."BaseEntry"
    AND L."BaseType" = 69
GROUP BY
    I."DocNum",
    I."DocDate",
    I."CreateDate",
    I."SuppName",
    I."AgentName",
    L."BaseType",
    D."DocDate",
    D."CreateDate",
    I2."DocDate",
    I2."CreateDate"
ORDER BY I."CreateDate" DESC
