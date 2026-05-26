# SAP HANA Queries — E_CONTROL

Repositorio de consultas SQL para SAP Business One / HANA.
Esquema: `E_CONTROL`

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
└── intercompany/
    └── intercompany_estado_facturacion.sql # Estado de facturación de entregas intercompany
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

