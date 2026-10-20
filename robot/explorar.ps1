# Lee solo ESTRUCTURA y cantidades agregadas de la base de Gescom (sin datos de clientes).
$ErrorActionPreference = 'Stop'
$clave = $env:GESCOM_LPE_CLAVE; if (-not $clave) { throw 'Falta GESCOM_LPE_CLAVE' }
$BASE = 'https://datos-gescom.panelempresas.workers.dev'
function Sql([string]$q) {
  $p = @{ Uri = "$BASE/consulta"; Method = 'POST'; UseBasicParsing = $true; Headers = @{ Authorization = "Bearer $clave" }; ContentType = 'application/json'
          Body = [Text.Encoding]::UTF8.GetBytes((@{ sql = $q } | ConvertTo-Json -Compress)) }
  $r = Invoke-WebRequest @p; $j = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
  if ($j.error) { throw $j.error }; @($j.filas) }
function Show($t,$q){ "== $t"; try { Sql $q | ForEach-Object { "  " + (($_.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' | ') } } catch { "  $_" } }
foreach ($t in @('venta_combos','v_combos','venta_items')) { "== definicion $t"; try { Sql "SELECT sql FROM sqlite_master WHERE name='$t'" | ForEach-Object { $_.sql } } catch { "  $_" } }
Show 'combos mas vendidos en octubre (codigo, cantidad)' "SELECT * FROM v_combos LIMIT 0"
