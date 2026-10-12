# Lee solo la ESTRUCTURA de la base de Gescom (formatos y cantidades). No imprime datos de clientes.
$ErrorActionPreference = 'Stop'
$clave = $env:GESCOM_LPE_CLAVE; if (-not $clave) { throw 'Falta GESCOM_LPE_CLAVE' }
$BASE = 'https://datos-gescom.panelempresas.workers.dev'
function Sql([string]$q) {
  $p = @{ Uri = "$BASE/consulta"; Method = 'POST'; UseBasicParsing = $true; Headers = @{ Authorization = "Bearer $clave" }; ContentType = 'application/json'
          Body = [Text.Encoding]::UTF8.GetBytes((@{ sql = $q } | ConvertTo-Json -Compress)) }
  $r = Invoke-WebRequest @p; $j = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
  if ($j.error) { throw $j.error }; @($j.filas) }
function Show($t,$q){ "== $t"; try { Sql $q | ForEach-Object { "  " + (($_.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' | ') } } catch { "  $_" } }
Show 'claves dentro de rutas' "SELECT DISTINCT k.key AS clave FROM clientes c, json_each(c.rutas) r, json_each(r.value) k"
Show 'valores de dias (distintos)' "SELECT json_extract(r.value,'$.dias') AS dias, COUNT(*) AS n FROM clientes c, json_each(c.rutas) r GROUP BY 1 ORDER BY n DESC LIMIT 30"
Show 'tipo de dato de dias' "SELECT DISTINCT json_type(r.value,'$.dias') AS t FROM clientes c, json_each(c.rutas) r"
Show 'rutas por cliente' "SELECT json_array_length(rutas) AS rutas, COUNT(*) AS n FROM clientes WHERE rutas IS NOT NULL AND rutas<>'' GROUP BY 1"
Show 'activo/baja' "SELECT activo, (baja IS NOT NULL AND baja<>'') AS con_baja, COUNT(*) AS n FROM clientes GROUP BY 1,2"
Show 'frecuencia en rutas' "SELECT json_extract(r.value,'$.frecuencia') AS f, COUNT(*) AS n FROM clientes c, json_each(c.rutas) r GROUP BY 1"
Show 'vendedor en rutas (formato)' "SELECT json_extract(r.value,'$.vendedor') AS v, COUNT(*) AS n FROM clientes c, json_each(c.rutas) r GROUP BY 1 ORDER BY n DESC LIMIT 40"
Show 'coordenadas vacias/activos' "SELECT activo, SUM(latitud IS NULL OR latitud=0) AS sin_coord, COUNT(*) AS n FROM clientes GROUP BY activo"
Show 'actualizado (ultimo)' "SELECT MAX(actualizado) AS ult, MAX(alta) AS ult_alta, MAX(baja) AS ult_baja FROM clientes"
