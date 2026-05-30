# SAP HANA Queries — E_CONTROL / ENVING

Repositorio de consultas SQL para SAP Business One / HANA.
Esquemas: `E_CONTROL`, `ENVING`

## Estructura

```
sap-hana-queries/
├── presupuestos/
│   ├── presupuesto_vs_facturado.sql        # Presupuesto vs facturado/pagado por proyecto
│   └── presupuesto_diagnostico.sql         # Diagnóstico de proyecto faltante en query
├── gastos/
│   └── gastos_por_proyecto.sql             # Gastos desglosados vs presupuesto y margen
├── entregas/
│   ├── entregas_total_por_proyecto.sql     # Costo total agrupado por proyecto
│   └── entregas_detalle_items.sql          # Detalle de items por proyecto
├── intercompany/
│   └── intercompany_estado_facturacion.sql # Estado de facturación de entregas intercompany
└── importaciones/
    ├── costeo_importaciones_econtrol.sql   # Costeo landing cost por ítem — E_CONTROL
    ├── costeo_importaciones_enving.sql     # Costeo landing cost por ítem — ENVING
    ├── demora_costeo_econtrol.sql          # Días reales entrada → costeo — E_CONTROL (media ~7 días)
    └── demora_costeo_enving.sql            # Días reales entrada → costeo — ENVING (media ~14 días)
```

## Tablas principales

| Tabla/Vista | Descripción |
|---|---|
| `OQUT` | Presupuestos (cotizaciones) |
| `OPRJ` | Proyectos |
| `VIEW_EJECUCION_PRESUPUESTO_ZH` | Vista de facturación/pagos por proyecto |
| `VIEW_ENTREGAS_ZH` | Vista de entregas por proyecto |
| `OPCH` | Facturas de compra |
| `OPOR` | Órdenes de compra |
| `OVPM` | Pagos (nómina) |
| `JDT1` | Asientos contables |
| `ODLN` | Entregas (Delivery) |
| `OINV` | Facturas de venta (AR Invoice) |
| `INV1` | Líneas de facturas de venta |
| `OIPF` | Precio de entrega / Landed Costs (cabecera) |
| `IPF1` | Líneas de Precio de entrega (costo por ítem prorrateado) |
| `OPDN` | Entrada de mercancías / Goods Receipt |

