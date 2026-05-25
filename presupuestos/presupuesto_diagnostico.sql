-- ============================================================
-- Diagnóstico: verificar si un proyecto existe en cada tabla
-- Útil cuando un proyecto no aparece en el query principal
-- Reemplazar PROY0198 por el código de proyecto a investigar
-- ============================================================

-- 1. ¿Existe en OQUT (presupuestos)?
SELECT "Project", "DocNum", "DocDate"
FROM "E_CONTROL"."OQUT"
WHERE "Project" = 'PROY0198';

-- 2. ¿Existe en VIEW_EJECUCION_PRESUPUESTO_ZH?
SELECT *
FROM "E_CONTROL"."VIEW_EJECUCION_PRESUPUESTO_ZH"
WHERE "Project" = 'PROY0198';

-- 3. ¿Existe en OPRJ (maestro de proyectos)?
SELECT *
FROM "E_CONTROL"."OPRJ"
WHERE "PrjCode" = 'PROY0198';