use strict; use warnings; use utf8; use Encode;
our %LOCMAP;
sub fixenc{ my $s=shift//''; $s=~s/ââ‚¬Å¾|â€ž|„/Ñ/g; $s=~s/ÃÂ\x{81}?|ÃÂ/Í/g if $s=~/ECHEVERR|BERAZATEGU/i;
 for(1..3){ last unless $s=~/[ÃÂ]/; my $b=eval{encode('cp1252',$s,1)}; last unless defined $b; my $d=eval{decode('UTF-8',$b,1)}; last unless defined $d; $s=$d }
 $s=~s/\s+/ /g; $s=~s/^ | $//g; $s }
sub noacc{ my $s=uc shift; $s=~tr/ÁÉÍÓÚÜ/AEIOUU/; $s }
# canonical localidad + partido
my @L=(
 [qr/^BERAZATEGUI( OESTE)?$|^BERAZATEGU/, 'Berazategui','Berazategui'],
 [qr/HUDSON/,'Guillermo Enrique Hudson','Berazategui'], [qr/RANELAGH/,'Ranelagh','Berazategui'], [qr/SOURIGUES/,'Sourigues','Berazategui'],
 [qr/PLATANOS?$/,'Plátanos','Berazategui'], [qr/GUTIERREZ/,'Juan María Gutiérrez','Berazategui'], [qr/EL PATO/,'Centro Agrícola El Pato','Berazategui'],
 [qr/^QUILMES OESTE/,'Quilmes Oeste','Quilmes'], [qr/^QUILMES/,'Quilmes','Quilmes'], [qr/^BERNAL OESTE/,'Bernal Oeste','Quilmes'], [qr/^BERNAL ESTE/,'Bernal Este','Quilmes'], [qr/^BERNAL/,'Bernal','Quilmes'],
 [qr/EZPELETA/,'Ezpeleta','Quilmes'], [qr/SOLANO/,'San Francisco Solano','Quilmes'], [qr/DON BOSCO/,'Don Bosco','Quilmes'], [qr/LA CERAMICA/,'Quilmes','Quilmes'],
 [qr/^(FLORENCIO )?VARELA/,'Florencio Varela','Florencio Varela'], [qr/ZEBALLOS/,'Zeballos','Florencio Varela'], [qr/LA UNION/,'La Unión','Florencio Varela'], [qr/SAN JUAN BAUTISTA/,'San Juan Bautista','Florencio Varela'],
 [qr/BOSQUES/,'Bosques','Florencio Varela'], [qr/INGENIERO ALLAN/,'Ingeniero Allan','Florencio Varela'], [qr/VILLA VATTEONE/,'Villa Vatteone','Florencio Varela'],
 [qr/^LANUS ESTE/,'Lanús Este','Lanús'], [qr/^LANUS/,'Lanús','Lanús'], [qr/ALSINA/,'Valentín Alsina','Lanús'], [qr/GERLI/,'Gerli','Lanús'], [qr/MONTE CHINGOLO/,'Monte Chingolo','Lanús'], [qr/ESCALADA/,'Remedios de Escalada','Lanús'],
 [qr/AVELLANEDA/,'Avellaneda','Avellaneda'], [qr/WILDE/,'Wilde','Avellaneda'], [qr/DOMINICO/,'Villa Domínico','Avellaneda'], [qr/SARANDI/,'Sarandí','Avellaneda'], [qr/DOCK SUD/,'Dock Sud','Avellaneda'], [qr/PI.?EYRO/,'Piñeyro','Avellaneda'], [qr/CRUCE[SC]ITA/,'Crucecita','Avellaneda'],
 [qr/LOMAS DE ZAMORA/,'Lomas de Zamora','Lomas de Zamora'], [qr/TEMPERLEY/,'Temperley','Lomas de Zamora'], [qr/BANFIELD/,'Banfield','Lomas de Zamora'], [qr/TURDERA/,'Turdera','Lomas de Zamora'], [qr/LL?AVALLOL/,'Llavallol','Lomas de Zamora'],
 [qr/BUDGE/,'Ingeniero Budge','Lomas de Zamora'], [qr/CENTENARIO/,'Villa Centenario','Lomas de Zamora'], [qr/FIORITO/,'Villa Fiorito','Lomas de Zamora'],
 [qr/ECHEVERR/,'Esteban Echeverría','Esteban Echeverría'], [qr/MONTE GRANDE/,'Monte Grande','Esteban Echeverría'], [qr/LUIS GUILLON/,'Luis Guillón','Esteban Echeverría'], [qr/JAGUEL/,'El Jagüel','Esteban Echeverría'], [qr/9 DE ABRIL/,'9 de Abril','Esteban Echeverría'], [qr/CANNING/,'Canning','Esteban Echeverría'],
 [qr/EZEIZA/,'Ezeiza','Ezeiza'], [qr/TRISTAN SUAREZ/,'Tristán Suárez','Ezeiza'], [qr/SPEGAZZINI/,'Carlos Spegazzini','Ezeiza'], [qr/UNION FERROVIARIA/,'Unión Ferroviaria','Ezeiza'],
 [qr/BURZACO/,'Burzaco','Almirante Brown'], [qr/LONGCHAMPS/,'Longchamps','Almirante Brown'], [qr/CLAYPOLE/,'Claypole','Almirante Brown'], [qr/ADROGUE/,'Adrogué','Almirante Brown'], [qr/GLEW/,'Glew','Almirante Brown'],
 [qr/CALZADA/,'Rafael Calzada','Almirante Brown'], [qr/SAN JOSE/,'San José','Almirante Brown'], [qr/MARMOL/,'José Mármol','Almirante Brown'], [qr/MALVINAS/,'Malvinas Argentinas','Almirante Brown'], [qr/ALM(IRAN)?TE BROWN/,'Almirante Brown','Almirante Brown'],
 [qr/MINISTRO RIVADAVIA/,'Ministro Rivadavia','Almirante Brown'], [qr/DON ORIONE/,'Don Orione','Almirante Brown'], [qr/SOLANO/,'San Francisco Solano','Quilmes'],
 [qr/GUERNICA/,'Guernica','Presidente Perón'], [qr/PRESIDENTE PERON/,'Guernica','Presidente Perón'], [qr/VILLA ESPA/,'Villa España','Berazategui'], [qr/LUGANO/,'Villa Lugano','Ciudad Autónoma de Buenos Aires'],
);
sub canonloc{ my $u=noacc(fixenc(shift)); $u=~s/\(.*?\)//g; $u=~s/\s+/ /g; $u=~s/^ | $//g; for(@L){ return ($_->[1],$_->[2]) if $u=~$_->[0] } return (ucfirst(lc $u),'') }
sub nstreet{ my $s=shift//''; $s=~s/^\s+|\s+$//g; $s=~s/\bjusto\b//i; $s=~s/\s+/ /g;
 if($s=~/^(?:CALLE\s+)?(\d+)\s*(BIS|[A-Z])?$/i){ $s="Calle $1".($2?" ".uc($2):'') }
 $s=~s/^AV(DA)?\.?\s+/Avenida /i; $s=~s/^AVENIDA\s+/Avenida /i; $s=~s/^GRL\.?\s+/General /i; $s=~s/^GRAL\.?\s+/General /i; $s=~s/^TGRL\.?\s+/Teniente General /i; $s=~s/^PTE\.?\s+/Presidente /i; $s=~s/^CNEL\.?\s+/Coronel /i;
 $s=~s/^Calle\s+(?=[A-Z]{3,})//i unless $s=~/^Calle \d/; $s }
sub parseaddr{ my $s=fixenc(shift); my $cross='';
 # house number = trailing number of the raw string (after dropping trailing 0 / depto)
 if($s=~/\(\s*(?:ESQ(?:UINA)?\.?|E\/)\s*([^),]*)/i){ $cross=$1; $cross=~s/\s+(gerli|lanus.*|wilde|hudson.*)$//i; $cross=~s/\s+y\s+.*$//i }
 $s=~s/\([^)]*\)?/ /g; $s=~s/\s+-\s+|\s+-$|^-\s+/ /g; $s=~s/N[º°]\s*|NÂº/ /gi; $s=~s/\bN\s+(?=\d)//; $s=~s/[,;.]/ /g; $s=~s/\be\/\s*/ E\/ /gi; $s=~s/\s+/ /g; $s=~s/^ | $//g;
 my @t=split / /,$s; while(@t>1 && $t[-1] eq '0'){pop @t}
 if(@t>3 && $t[-1]=~/^\d{1,2}$/ && $t[-2]=~/^\d{2,}$/ && $t[-3]!~/^\d+$/){pop @t}
 $s=join ' ',@t; my $num='';
 if(my($m,$r)=$s=~/^(.*?\S)\s+(?:ESQ(?:UINA)?|E\/|ENTRE|Y)\s+(.*)$/i){
   if($m=~/^(.*\D)\s+(\d{2,})$/ && $m!~/^(?:CALLE\s+|AVENIDA\s+|AV\s+)?\d+$/i){ $m=$1; $num=$2 }
   if($r=~/\S\s+(\d+)$/ && !($r=~/^(?:CALLE\s+)?\d+$/i)){ my $n=$1; $num||=$n; $r=~s/\s+\d+$// }
   $r=~s/\s+(?:Y|E\/)\s+.*$//i; $r=~s/\s+(HUDSON|BERAZATEGUI|QUILMES|EL PATO).*$//i;
   $s=$m; $cross||=$r }
 elsif($s=~s/\s+(\d+)$//){ $num=$1 }
 $num='' if $num ne '' && $num<10;
 if($s=~/^(?:CALLE|AV|AVENIDA)$/i && $num ne ''){ $s="Calle $num"; $num='' }
 (nstreet($s),$num,$cross?nstreet($cross):'') }
sub hav{my($a,$b,$c,$d)=@_;my $r=0.017453292519943295;my $x=sin(($c-$a)*$r/2)**2+cos($a*$r)*cos($c*$r)*sin(($d-$b)*$r/2)**2;12742*atan2(sqrt($x),sqrt(1-$x))}
sub med{my @v=sort{$a<=>$b}@_;return undef unless @v; @v%2?$v[$#v/2]:($v[@v/2-1]+$v[@v/2])/2}
1;
