# Lee solo la ESTRUCTURA de la base de Gescom (tablas, columnas y cantidades). No imprime datos de clientes.
$ErrorActionPreference = 'Stop'
$clave = $env:GESCOM_LPE_CLAVE; if (-not $clave) { throw 'Falta GESCOM_LPE_CLAVE' }
$BASE = 'https://datos-gescom.panelempresas.workers.dev'
function Sql([string]$q) {
  $p = @{ Uri = "$BASE/consulta"; Method = 'POST'; UseBasicParsing = $true; Headers = @{ Authorization = "Bearer $clave" }; ContentType = 'application/json'
          Body = [Text.Encoding]::UTF8.GetBytes((@{ sql = $q } | ConvertTo-Json -Compress)) }
  $r = Invoke-WebRequest @p; $j = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
  if ($j.error) { throw $j.error }; @($j.filas) }
"== Tablas"
try { Sql "SELECT name FROM sqlite_master WHERE type IN ('table','view') ORDER BY name" | ForEach-Object { $_.name } } catch { "sqlite_master no disponible: $_" }
foreach ($t in @('clientes','rutas','clientes_rutas','visitas','vendedores')) {
  "== Columnas de $t"
  try { Sql "PRAGMA table_info($t)" | ForEach-Object { "  $($_.name) ($($_.type))" } } catch { "  (no existe o no se puede leer: $_)" }
}
"== Cantidad de clientes"; try { (Sql "SELECT COUNT(*) AS n FROM clientes")[0].n } catch { "$_" }
# por columna: cuantos valores distintos y cuantos vacios (sin mostrar valores)
try {
  $cols = Sql "PRAGMA table_info(clientes)" | ForEach-Object { $_.name }
  foreach ($c in $cols) {
    $r = (Sql "SELECT COUNT(DISTINCT `"$c`") AS d, SUM(CASE WHEN `"$c`" IS NULL OR `"$c`"='' THEN 1 ELSE 0 END) AS v FROM clientes")[0]
    "  $c : $($r.d) distintos, $($r.v) vacios"
  }
} catch { "$_" }
