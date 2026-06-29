# TP Macro Reports

Repositorio para los archivos macro de Excel que refrescan el reporte del portal de transparencia COR3 y generan las versiones finales del informe.

## Archivos principales

- `outputs/Template TP - Macro Portal Transparencia - Version Final Sin QPR Sin Localizacion.xlsm`
  - Version final regular del reporte.
  - No incluye `Periodo de QPR` ni `Localizacion`.
  - Mantiene 10 columnas finales.

- `outputs/Template TP - Macro Portal Transparencia - Export Municipios Applicant Type - Template Aguada.xlsm`
  - Version alterna para exportar un archivo por municipio.
  - Usa `Applicant Type = Municipio`.
  - Crea una carpeta por municipio y guarda cada Excel con solo los datos de ese municipio.

## Otras variantes incluidas

La carpeta `outputs/` incluye las variantes anteriores y finales que se construyeron durante el proceso:

- `Template TP - Macro Portal Transparencia.xlsm`
- `Template TP - Macro Portal Transparencia - Version Reducida.xlsm`
- `Template TP - Macro Portal Transparencia - Version Final Sin QPR.xlsm`
- `Template TP - Macro Portal Transparencia - Version Final Sin QPR Sin Localizacion.xlsm`
- `Template TP - Macro Portal Transparencia - Export por Municipio.xlsm`
- `Template TP - Macro Portal Transparencia - Export Municipios Applicant Type.xlsm`
- `Template TP - Macro Portal Transparencia - Export Municipios Applicant Type - Template Aguada.xlsm`

## Entradas de referencia

- `templates/Template TP.xlsx`: template base original.
- `templates/Aguada.xlsx`: template visual usado como referencia para el estilo final.
- `sample-data/COR3 Transparency Portal_RoadToRecovery_061626_1337.xlsx`: archivo de muestra descargado del portal de transparencia.

El nombre del archivo descargado del portal puede cambiar cada vez. El macro esta preparado para que el usuario seleccione el archivo nuevo al correr el proceso.

## Como usar

1. Descargar o clonar este repositorio.
2. Abrir el archivo `.xlsm` que se necesite desde la carpeta `outputs/`.
3. Habilitar macros en Excel.
4. En la hoja `Inicio`, usar los botones del proceso:
   - Seleccionar el Excel descargado del portal de transparencia.
   - Refrescar el reporte.
   - En la version de municipios, exportar los archivos por municipio.
5. Revisar la carpeta de salida generada por el macro.

## Validacion incluida

Antes de preparar este paquete se verifico lo siguiente en las 2 versiones finales:

- Los archivos conservan macros (`vbaProject.bin` presente).
- La hoja `RoadToRecovery` contiene 29,031 filas de datos mas encabezado.
- La salida final tiene 10 columnas.
- No existe columna `Localizacion` en la salida final.
- Las columnas `Costo de proyecto`, `Obligado` y `Desembolsado` usan formato de moneda con `$`.
- Los anchos de columnas estan ampliados para lectura.

Columnas finales:

1. Numero del PW
2. Titulo de proyecto
3. Tipo de solicitante
4. Solicitante
5. Costo de proyecto
6. Obligado
7. Desembolsado
8. Desastre
9. Nombre de dano
10. Detalles de etapa

## Mantenimiento

El script fuente usado para generar las variantes esta en:

`scripts/build_tp_macro.ps1`

Los resultados temporales de pruebas visuales y carpetas de export masivo no se incluyen en este repositorio porque son archivos generados durante QA. El repo contiene los workbooks finales, variantes, templates, logo y sample data necesarios para reproducir el proceso.
