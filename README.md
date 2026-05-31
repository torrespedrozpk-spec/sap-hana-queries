# SAP HANA Queries — E_CONTROL / ENVING

Repositorio de consultas SQL para SAP Business One / HANA.
Esquemas: `E_CONTROL`, `ENVING`

## Estructura

```
sap-hana-queries/
├── dashboard/
│   ├── dashboard_principal.sql                     # Dashboard completo ENVING: presupuesto, facturación, costos, margen
│   └── dashboard_principal_econtrol.sql            # Ídem para E_CONTROL
├── presupuestos/
│   ├── presupuesto_vs_facturado.sql                # Presupuesto vs facturado/pagado por proyecto
│   └── presupuesto_diagnostico.sql                 # Diagnóstico de proyecto faltante en query
├── gastos/
│   ├── gastos_por_proyecto.sql                     # Gastos desglosados vs presupuesto y margen
│   ├── detalle_materiales_por_proyecto_enving.sql  # Detalle ítems físicos por proyecto — ENVING
│   ├── detalle_materiales_por_proyecto_econtrol.sql# Detalle ítems físicos por proyecto — E_CONTROL
│   ├── detalle_mano_obra_por_proyecto_enving.sql   # Detalle servicios/MO por proyecto — ENVING
│   └── detalle_mano_obra_por_proyecto_econtrol.sql # Detalle servicios/MO por proyecto — E_CONTROL
├── entregas/
│   ├── entregas_total_por_proyecto.sql             # Costo total agrupado por proyecto
│   └── entregas_detalle_items.sql                  # Detalle de items por proyecto
├── intercompany/
│   └── intercompany_estado_facturacion.sql         # Estado de facturación de entregas intercompany
└── importaciones/
    ├── costeo_importaciones_econtrol.sql           # Costeo landing cost por ítem — E_CONTROL
    ├── costeo_importaciones_enving.sql             # Costeo landing cost por ítem — ENVING
    ├── costeo_importaciones_hidroingenieria.sql    # Costeo landing cost por ítem — HIDROINGENIERIA
    ├── demora_costeo_econtrol.sql                  # Días reales entrada → costeo — E_CONTROL
    ├── demora_costeo_enving.sql                    # Días reales entrada → costeo — ENVING
    ├── demora_costeo_hidroingenieria.sql           # Días reales entrada → costeo — HIDROINGENIERIA
    └── reporte_semanal_implementacion.md           # Guía completa: ETL + script Python + cron email semanal
```

### Scripts Python

| Archivo | Descripción |
|---|---|
| `importaciones/preview_local.py` | Preview HTML desde Mac conectando directo a SAP HANA |
| `~/etl_sap/reporte_semanal.py` | Script completo de envío (ver guía de implementación) |

**Setup preview local (Mac):**
```bash
cd /ruta/a/etl_sap
python3 -m venv venv
source venv/bin/activate
pip install hdbcli
python preview_local.py
```

## Clasificación de ítems (costos)

| Prefijo | Tipo | Incluido en |
|---|---|---|
| `INMAT`, `INGAS`, `INAIS`, `INELE`, `INHID`, `INDUC`, `EQUEV`, `EQUCO`, `EQVENT`, `KNXDS` | Materiales físicos | CostoMateriales |
| `SESER%` | Servicios / mano de obra | CostoManoObra |
| `GA.%` | Gastos varios (envíos, descuentos) | CostoManoObra |
| `ZZ%` | Ajuste contable IVA | Excluido de ambos |

## Tablas principales

| Tabla/Vista | Descripción |
|---|---|
| `OQUT` | Presupuestos (cotizaciones) |
| `OPRJ` | Proyectos |
| `VIEW_EJECUCION_PRESUPUESTO_ZH` | Vista de facturación/pagos por proyecto |
| `VIEW_ENTREGAS_ZH` | Vista de entregas por proyecto (fuente CostoMateriales) |
| `PCH1` | Líneas de facturas de compra (fuente CostoManoObra) |
| `OPCH` | Facturas de compra (cabecera) |
| `ODLN` | Entregas (Delivery) |
| `OPOR` | Órdenes de compra |
| `OVPM` | Pagos (nómina) |
| `JDT1` | Asientos contables |
| `OINV` | Facturas de venta (AR Invoice) |
| `INV1` | Líneas de facturas de venta |
| `OIPF` | Precio de entrega / Landed Costs (cabecera) |
| `IPF1` | Líneas de Precio de entrega (costo por ítem prorrateado) |
| `OPDN` | Entrada de mercancías / Goods Receipt |

## Notas SAP HANA

- No permite alias del SELECT en ORDER BY del mismo nivel → envolver en CTE adicional `"RESULT"`
- No permite CTEs dentro de subqueries → el `WITH` siempre al nivel más externo
- No permite `ON EXISTS` en JOINs → usar subquery agrupado
- Ejecutar siempre con **Ctrl+A** en DBeaver para evitar errores de syntax en ORDER BY
