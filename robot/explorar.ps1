# Lee solo cantidades agregadas de la base de Gescom (sin datos de clientes).
$ErrorActionPreference = 'Stop'
$clave = $env:GESCOM_LPE_CLAVE; if (-not $clave) { throw 'Falta GESCOM_LPE_CLAVE' }
$BASE = 'https://datos-gescom.panelempresas.workers.dev'
function Sql([string]$q) {
  $p = @{ Uri = "$BASE/consulta"; Method = 'POST'; UseBasicParsing = $true; Headers = @{ Authorization = "Bearer $clave" }; ContentType = 'application/json'
          Body = [Text.Encoding]::UTF8.GetBytes((@{ sql = $q } | ConvertTo-Json -Compress)) }
  $r = Invoke-WebRequest @p; $j = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
  if ($j.error) { throw $j.error }; @($j.filas) }
function Show($t,$q){ "== $t"; try { Sql $q | ForEach-Object { "  " + (($_.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' | ') } } catch { "  $_" } }
Show 'codigos de combo mas usados en octubre' "SELECT c.combo, COUNT(*) AS renglones, SUM(c.cantidad) AS cant FROM venta_combos c JOIN ventas v ON v.id=c.venta_id WHERE v.fecha>='2026-10-01' GROUP BY c.combo ORDER BY renglones DESC LIMIT 15"
Show 'combo 1137 en octubre por vendedor y tipo' "SELECT v.vendedor, v.tipo, COUNT(DISTINCT v.id) AS ventas, SUM(c.cantidad) AS cant, MIN(v.fecha) AS desde, MAX(v.fecha) AS hasta, SUM(NULLIF(v.comprobante,'') IS NOT NULL) AS facturadas FROM venta_combos c JOIN ventas v ON v.id=c.venta_id WHERE c.combo IN ('1137','1501137') AND COALESCE(NULLIF(v.entrega,''),v.fecha)>='2026-10-01' GROUP BY v.vendedor, v.tipo ORDER BY cant DESC"
Show 'v_combos 1137 octubre por vendedor' "SELECT vendedor, canal, COUNT(*) AS filas, SUM(combo_cantidad) AS cant, MIN(fecha) AS desde, MAX(fecha) AS hasta FROM v_combos WHERE combo_codigo IN ('1137','1501137') AND mes='2026-10' GROUP BY vendedor, canal ORDER BY cant DESC"
Show 'v_combos meses cargados' "SELECT mes, COUNT(*) AS filas FROM v_combos GROUP BY mes"
