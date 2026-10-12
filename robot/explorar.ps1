# Lee solo la ESTRUCTURA de la base de Gescom (definicion de tablas y cantidades). No imprime datos de clientes.
$ErrorActionPreference = 'Stop'
$clave = $env:GESCOM_LPE_CLAVE; if (-not $clave) { throw 'Falta GESCOM_LPE_CLAVE' }
$BASE = 'https://datos-gescom.panelempresas.workers.dev'
function Sql([string]$q) {
  $p = @{ Uri = "$BASE/consulta"; Method = 'POST'; UseBasicParsing = $true; Headers = @{ Authorization = "Bearer $clave" }; ContentType = 'application/json'
          Body = [Text.Encoding]::UTF8.GetBytes((@{ sql = $q } | ConvertTo-Json -Compress)) }
  $r = Invoke-WebRequest @p; $j = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
  if ($j.error) { throw $j.error }; @($j.filas) }
foreach ($t in @('clientes','vendedores','empleados','subramos','v_indicadores_ruta','v_censo_tp','sync')) {
  "== $t"; try { Sql "SELECT sql FROM sqlite_master WHERE name='$t'" | ForEach-Object { $_.sql } } catch { "  $_" }
}
"== /estado"; try { $p=@{Uri="$BASE/estado";UseBasicParsing=$true;Headers=@{Authorization="Bearer $clave"}}; [Text.Encoding]::UTF8.GetString((Invoke-WebRequest @p).RawContentStream.ToArray()) } catch { "$_" }
# Conteos agregados (sin datos personales)
"== clientes por vendedor (codigo: cantidad)"
try { Sql "SELECT vendedor AS v, COUNT(*) AS n FROM clientes GROUP BY vendedor ORDER BY n DESC" | ForEach-Object { "  $($_.v): $($_.n)" } } catch { "  $_" }
