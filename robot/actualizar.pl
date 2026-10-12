# Robot diario del mapa "Base ruta LP - ELEBES".
# Lee los clientes activos de la base de Gescom, mantiene las ubicaciones ya corregidas,
# revisa las altas y los cambios de dirección o coordenada, saca las bajas y arma index.html.
#
# Uso: GESCOM_LPE_CLAVE=... perl robot/actualizar.pl
use strict; use warnings; use utf8; use JSON::PP; use Time::HiRes qw(sleep);
use FindBin; use lib $FindBin::Bin;
binmode STDOUT, ':utf8'; binmode STDERR, ':utf8'; $| = 1;
my $DIR = $FindBin::Bin; my $RAIZ = "$DIR/..";
require "$DIR/common.pl";

my @VENDEDORES = (2,4,5,6,7,24,26,27,28,29,30,51,52,53,54,56,61,62,63,64,73,74,75,76);
my @COLORES = split / /, '#0b84a5 #3cb44b #4363d8 #f58231 #911eb4 #46a5a8 #f032e6 #7a9c00 #d4a017 #008080 #9a6324 #6a3d9a #2f4f4f #000075 #c71585 #17becf #1e90ff #228b22 #8b008b #b8860b #bcbd22 #4b0082 #556b2f #e377c2';
my %DIA = (L => 'Lu', M => 'Ma', X => 'Mi', J => 'Ju', V => 'Vi');
my $BASE = 'https://datos-gescom.panelempresas.workers.dev';
my $CLAVE = $ENV{GESCOM_LPE_CLAVE} or die "Falta la variable GESCOM_LPE_CLAVE\n";
my $J = JSON::PP->new->utf8->canonical;

# ---------- acceso a la base y a los geocodificadores ----------
sub http { my (@a) = @_; open my $ph, '-|', 'curl', '-s', '-m', '120', @a or die "curl: $!"; local $/; my $b = <$ph>; close $ph; $b // '' }
sub sql {
  my $q = shift; my $tmp = "$DIR/.consulta.json"; open my $f, '>:raw', $tmp or die; print $f $J->encode({ sql => $q }); close $f;
  my $b = http('-X', 'POST', '-H', "Authorization: Bearer $CLAVE", '-H', 'Content-Type: application/json', '--data-binary', "\@$tmp", "$BASE/consulta");
  unlink $tmp; my $j = eval { $J->decode($b) } or die "La base no respondió JSON\n"; die "La base respondió error: $j->{error}\n" if $j->{error};
  die "La consulta se cortó por el tope de filas\n" if $j->{truncado}; $j->{filas} }
my %cache; my $CACHE = "$DIR/cache.tsv";
if (open my $c, '<:raw', $CACHE) { while (<$c>) { chomp; my ($k, $v) = split /\t/, $_, 2; $cache{$k} = $v } close $c }
open my $CF, '>>:raw', $CACHE or die; { my $o = select $CF; $| = 1; select $o }
sub fetch { my ($url, %p) = @_; my $k = $url . '?' . join('&', map { "$_=$p{$_}" } sort keys %p); my $kb = Encode::encode('UTF-8', $k);
  unless (exists $cache{$kb}) { sleep 0.4; my @a = ('-G', '-A', 'LP-Elebes-mapa/1.0 (github.com/1605-83)', $url); push @a, '--data-urlencode', Encode::encode('UTF-8', "$_=$p{$_}") for sort keys %p;
    my $b = http(@a); $b =~ s/[\r\n]//g; return undef unless $b =~ /^[\[{]/; print $CF "$kb\t$b\n"; $cache{$kb} = $b }
  eval { $J->decode($cache{$kb}) } }
sub georef { my ($dir, $dep) = @_; my $d = fetch('https://apis.datos.gob.ar/georef/api/direcciones', direccion => $dir, departamento => $dep, provincia => 'Buenos Aires', max => 5);
  return () unless $d && $d->{direcciones}; map { +{ lat => $_->{ubicacion}{lat}, lon => $_->{ubicacion}{lon}, name => $_->{nomenclatura}, how => 'Georef' } } grep { defined $_->{ubicacion}{lat} } @{ $d->{direcciones} } }
sub partido_de { my ($la, $lo) = @_; my $d = fetch('https://apis.datos.gob.ar/georef/api/ubicacion', lat => sprintf('%.6f', $la), lon => sprintf('%.6f', $lo)); ($d && $d->{ubicacion}) ? ($d->{ubicacion}{departamento}{nombre} // '') : '' }
sub photon { my $q = shift; my $d = fetch('https://photon.komoot.io/api/', q => $q, limit => 6, bbox => '-58.95,-35.25,-57.95,-34.45'); return () unless $d && $d->{features};
  map { my $p = $_->{properties}; +{ lat => $_->{geometry}{coordinates}[1], lon => $_->{geometry}{coordinates}[0], road => ($p->{street} // $p->{name} // ''), hn => $p->{housenumber}, county => ($p->{county} // ''), how => 'OSM' } } @{ $d->{features} } }
sub core { my $s = noacc(shift // ''); $s =~ s/^(CALLE|AVENIDA|AV|DIAGONAL|DTO|TGRL|GRL)\.?\s+//; $s =~ s/[^A-Z0-9 ]//g;
  my @t = sort { length($b) <=> length($a) } grep { length >= 2 && !/^(DE|DEL|LA|LAS|LOS|EL|Y)$/ } split / /, $s; $t[0] // '' }

# ---------- 1. clientes activos de Gescom ----------
my %vnom = map { ($_->{codigo} + 0) => $_->{nombre} } grep { $_->{codigo} =~ /^\d+$/ } @{ sql('SELECT codigo, nombre FROM vendedores') };
my $filas = sql(q{SELECT codigo, razon_social, nombre, direccion, localidad, telefono, latitud, longitud,
  json_extract(rutas,'$[0].vendedor') AS ven, json_extract(rutas,'$[0].dias') AS dias, json_extract(rutas,'$[0].ruta') AS ruta
  FROM clientes WHERE activo = 1});
my %quiero = map { $_ => 1 } @VENDEDORES;
my @cli = grep { defined $_->{ven} && $_->{ven} =~ /^\d+$/ && $quiero{ $_->{ven} + 0 } && $DIA{ $_->{dias} // '' } } @$filas;
printf "Gescom: %d clientes activos, %d de los %d vendedores con día de visita\n", scalar(@$filas), scalar(@cli), scalar(@VENDEDORES);
die "Muy pocos clientes (" . scalar(@cli) . "): no se toca el mapa\n" if @cli < 2000;

# coordenadas genéricas: el mismo punto para 3 o más direcciones distintas
my %gen; for (@$filas) { next unless $_->{latitud}; $gen{ sprintf('%.5f,%.5f', $_->{latitud}, $_->{longitud}) }{ lc($_->{direccion} // '') } = 1 }

# ---------- 2. estado anterior ----------
my $estado = do { local $/; open my $f, '<:raw', "$DIR/estado.json" or die; $J->decode(<$f>) };
my $huella = sub { my $c = shift; join '|', $c->{direccion} // '', $c->{localidad} // '', sprintf('%.5f', $c->{latitud} // 0), sprintf('%.5f', $c->{longitud} // 0) };

my (@nuevos, %rec, %cnt);
for my $c (@cli) {
  my $cod = $c->{codigo}; my $e = $estado->{$cod}; my $fp = $huella->($c);
  my ($cl, $pt) = canonloc($c->{localidad} // '');
  my %r = (c => $cod, n => fixenc($c->{razon_social} || $c->{nombre} || ''), d => fixenc($c->{direccion} // ''), l => $cl, part => $pt,
           t => ($c->{telefono} // ''), v => $c->{ven} + 0, dia => $DIA{ $c->{dias} }, ru => ($c->{ruta} // ''), ola => $c->{latitud} + 0, olo => $c->{longitud} + 0, h => ($e ? $e->{h} // '' : ''), raw => $c);
  $r{t} =~ s/^\s+|\s+$//g;
  if ($e && $e->{semilla} && !$e->{fp}) {
    # primera corrida: se adoptan las correcciones hechas a mano si la coordenada de Gescom es la misma del Excel original
    if (defined $e->{ola} && hav($e->{ola}, $e->{olo}, $r{ola}, $r{olo}) < 0.05) { @r{qw(la lo s no)} = @$e{qw(la lo s no)}; $r{fp} = $fp; $cnt{igual}++ }
    else { push @nuevos, \%r; $cnt{cambio}++ }
  } elsif ($e && $e->{fp} && $e->{fp} eq $fp) { @r{qw(la lo s no)} = @$e{qw(la lo s no)}; $r{fp} = $fp; $cnt{igual}++ }
  else { push @nuevos, \%r; $cnt{ $e ? 'cambio' : 'alta' }++ }
  $rec{$cod} = \%r;
}
my @bajas = grep { !$rec{$_} } keys %$estado; $cnt{baja} = scalar @bajas;
die "Demasiadas bajas de golpe ($cnt{baja}): no se toca el mapa, revisar la base\n" if $cnt{baja} > 400;
printf "Sin cambios: %d · altas: %d · con cambios: %d · bajas: %d\n", map { $cnt{$_} // 0 } qw(igual alta cambio baja);

# centros de cada vendedor y día (con los clientes ya ubicados)
my (%pts, %ctr, %disp);
for (values %rec) { push @{ $pts{"$_->{v}|$_->{dia}"} }, [ $_->{la}, $_->{lo} ] if defined $_->{la} && ($_->{s} // '') ne 'revisar' }
for my $k (keys %pts) { my @p = @{ $pts{$k} }; $ctr{$k} = [ med(map { $_->[0] } @p), med(map { $_->[1] } @p) ]; $disp{$k} = med(map { hav(@$_, @{ $ctr{$k} }) } @p) }

# ---------- 3. revisar altas y cambios ----------
for my $r (@nuevos) {
  my ($la, $lo) = ($r->{ola}, $r->{olo}); my $k = "$r->{v}|$r->{dia}"; my $c = $ctr{$k}; my $dp = $disp{$k} // 2;
  my @por;
  if (!$la || $la == $lo) { push @por, 'coordenada inválida' }
  elsif ($lo > 0) { push @por, 'longitud positiva' }
  elsif ($la < -35.3 || $la > -34.4 || $lo < -58.95 || $lo > -57.9) { push @por, 'fuera del área' }
  elsif (scalar(keys %{ $gen{ sprintf('%.5f,%.5f', $la, $lo) } || {} }) >= 3) { push @por, 'coordenada genérica' }
  elsif ($c) { my $d = hav($la, $lo, @$c); my $th = 3.5 * $dp; $th = 4 if $th < 4; push @por, sprintf('lejos de su ruta (%.1f km)', $d) if $d > $th }
  if (!@por) { @$r{qw(la lo s no)} = ($la, $lo, 'ok', ''); next }
  # buscar la dirección dentro de su partido
  my ($st, $num, $cr) = parseaddr($r->{d}); my $kk = core($st); my $exp = $r->{part} || $r->{l};
  my $okname = sub { my $nm = noacc($_[0] // ''); $kk ne '' && $nm =~ /(^|[^A-Z0-9])\Q$kk\E([^A-Z0-9]|$)/ };
  my @cand;
  if ($st ne '') {
    push @cand, grep { $okname->($_->{name}) } georef("$st $num", $exp) if $num ne '';
    push @cand, grep { $okname->($_->{name}) } georef("$st y $cr", $exp) if $cr ne '';
    if ($num ne '') { for my $q ("$st $num, $r->{l}", "$st $num, $exp") {
      push @cand, map { +{ %$_, name => "$_->{road} $_->{hn}" } } grep { defined $_->{hn} && $_->{hn} eq $num && $okname->($_->{road}) && noacc($_->{county}) =~ /\Q${\noacc($exp)}\E/ } photon($q) } }
  }
  my $lim = 4 * $dp; $lim = 15 if $lim < 15;
  for (@cand) { $_->{dc} = $c ? hav($_->{lat}, $_->{lon}, @$c) : 0 } @cand = sort { $a->{dc} <=> $b->{dc} } grep { !$c || $_->{dc} <= $lim } @cand;
  if (@cand) { my $g = $cand[0];
    if (hav($g->{lat}, $g->{lon}, $la, $lo) < 0.3) { @$r{qw(la lo s no)} = ($la, $lo, 'ok', '') }
    else { @$r{qw(la lo s no)} = ($g->{lat}, $g->{lon}, 'reubicado', "Reubicado según la dirección ($g->{how}): $g->{name}. Motivo: $por[0]") } }
  elsif ($por[0] eq 'longitud positiva' && $lo > 57.9 && $lo < 58.95) { @$r{qw(la lo s no)} = ($la, -$lo, 'reubicado', 'Se corrigió el signo de la longitud') }
  elsif ($por[0] =~ /^lejos/ && noacc(partido_de($la, $lo)) eq noacc($exp)) { @$r{qw(la lo s no)} = ($la, $lo, 'ok', '') }
  else {
    my @same = grep { $_ ne $r && $_->{v} == $r->{v} && $_->{dia} eq $r->{dia} && $_->{l} eq $r->{l} && defined $_->{la} && ($_->{s} // '') ne 'revisar' } values %rec;
    my ($zla, $zlo, $donde) = @same >= 2 ? (med(map { $_->{la} } @same), med(map { $_->{lo} } @same), "junto a los clientes de $r->{l} de este vendedor")
                                         : $c ? (@$c, 'en la zona del vendedor') : ($la, $lo, 'en la coordenada cargada');
    @$r{qw(la lo s no)} = ($zla, $zlo, 'revisar', "Ubicación aproximada: la dirección \"$r->{d}\" no se pudo confirmar ($por[0]); se ubicó $donde. Confirmar dirección.") }
  $cnt{"revision $r->{s}"}++;
}
$_->{fp} = $huella->($_->{raw}) for @nuevos;
printf "Revisión de ubicaciones: %s\n", join(' · ', map { "$_: $cnt{$_}" } grep { /^revision/ } sort keys %cnt) if @nuevos;

# ---------- 4. duplicados: mismo vendedor, nombre y dirección ----------
my (%visto, @fin, $dup);
for my $r (sort { length($a->{c}) <=> length($b->{c}) || $a->{c} cmp $b->{c} } values %rec) {
  my $k = join '|', $r->{v}, map { my $x = lc $_; $x =~ s/[^a-z0-9]//g; $x } $r->{d}, $r->{n};
  if (my $o = $visto{$k}) { $o->{no} .= ($o->{no} ? ' ' : '') . "(Cliente repetido: también figura con el código $r->{c}; se dejó uno solo.)" unless $o->{no} =~ /\Q$r->{c}\E/; $dup++; next }
  $visto{$k} = $r; push @fin, $r }
printf "Duplicados omitidos: %d · clientes en el mapa: %d\n", $dup // 0, scalar @fin;

# ---------- 5. estado nuevo e index.html ----------
my %nuevo = map { $_->{c} => { la => 0 + sprintf('%.6f', $_->{la}), lo => 0 + sprintf('%.6f', $_->{lo}), s => $_->{s}, no => $_->{no} // '', h => $_->{h}, fp => $_->{fp} } } values %rec;
{ open my $f, '>:raw', "$DIR/estado.json" or die; print $f $J->encode(\%nuevo) }
my @vend = map { +{ id => $VENDEDORES[$_], name => ($vnom{ $VENDEDORES[$_] } // "Vendedor $VENDEDORES[$_]"), col => $COLORES[$_ % @COLORES] } } 0 .. $#VENDEDORES;
my %hay = map { $_->{v} => 1 } @fin; @vend = grep { $hay{ $_->{id} } } @vend;
my @data = map { +{ c => $_->{c}, n => $_->{n}, d => $_->{d}, l => $_->{l}, t => $_->{t}, h => $_->{h}, v => $_->{v}, vn => '', dia => $_->{dia}, ru => $_->{ru},
                    la => 0 + sprintf('%.6f', $_->{la}), lo => 0 + sprintf('%.6f', $_->{lo}), s => $_->{s}, no => $_->{no} // '' } } sort { $a->{c} cmp $b->{c} } @fin;
my $html = do { local $/; open my $f, '<:utf8', "$DIR/plantilla.html" or die; <$f> };
my $fondo = do { local $/; open my $f, '<:utf8', "$DIR/fondo.json" or die; <$f> };
my $JC = JSON::PP->new->canonical; my $djs = $JC->encode(\@data); $djs =~ s{</}{<\\/}g; $fondo =~ s{</}{<\\/}g;
$html =~ s{/\*DATA\*/}{$djs}; $html =~ s{/\*VEND\*/}{$JC->encode(\@vend)}e; $html =~ s{/\*BASE\*/}{$fondo};
{ open my $f, '>:utf8', "$RAIZ/index.html" or die; print $f $html }
# resumen para el mensaje del commit
{ open my $f, '>:utf8', "$DIR/.resumen" or die; printf $f "altas %d, bajas %d, cambios %d", map { $cnt{$_} // 0 } qw(alta baja cambio) }
print "Listo: index.html con " . scalar(@data) . " clientes\n";
