#!/usr/bin/perl -w
# spell.pl 0.5.0
# 
# Skriptas(imho jau iðaugo ið "skriptuko" dydþio bei funkcionalumo) naujiems 
# lietuviðkiems ispell þodynams sudarinëti. Skaito þodþius, ir jeigu neapibrëþti 
# jokie flagai, iðsiaiðkina, kokiø reikia, bei iðsaugo þodá /~ esanèiuose þodynuose
# ið kuriø, vëliau, kompiliuojamas pagrindinis ispell þodynas.
#
# Vartojimas:
# spell.pl                       # skaito þodþius ið klaviatûros
# spell.pl þodynas               # skaito ið failo þodynas
#
# Paraðë Laimonas Vëbra <l.v@centras.lt> stipriai patobulinæs skriptà, kurá
# paraðë Gediminas Paulauskas <menesis@delfi.lt>, patobulinæs skriptus ið
# Alberto Agejevo <alga@uosis.mif.vu.lt> bei Mariaus Gedmino <mgedmin@delfi.lt>. :)
# 
# TODO:
# * daugiau intelekto atspëjant þodþiø formas
# * parametrais nurodomos ávesties/iðvesties bylos 
# # ispell þodyno kompiliavimas
# # UI pagerinimas, galbût .conf file'iukas
# # þodþiø automatinio patikrinimo/kaupimo sistema susieta su http://doneaitis.vdu.lt resursais
# # yra minèiø, sumanymø..
# #
# #
#             api ati
#             ap  at  á ið nu pa par per pra pri su uþ
# be nieko     a   b  c  d  e  f  g   h   i   j   k  l
# su sangràþa  m   n  o	 p  q  r  s   t   u   v   w  x
$SIG{INT} = \&sub_exit;  
$SIG{TERM} = \&sub_exit;
$SIG{KILL} = \&sub_exit;

%prefix = (
	   c => 'á',     d => 'ið',	e => 'nu',
	   f => 'pa',    g => 'par',    h => 'per',
	   i => 'pra',	 j => 'pri',	k => 'su',
	   l => 'uþ',	 m => 'apsi',	n => 'atsi',
	   o => 'ási',	 p => 'iðsi',	q => 'nusi',
	   r => 'pasi',	 s => 'parsi',	t => 'persi',
	   u => 'prasi', v => 'prisi',	w => 'susi',
	   x => 'uþsi'
);
# filename hash
%fn_h = (
	 1 => 'lietuviu.daiktavardziai', 2 => 'lietuviu.tarpt.daiktavardziai', 3 => 'lietuviu.vardai', 
	 4 => 'lietuviu.veiksmazodziai', 5 => 'lietuviu.tarpt.veiksmazodziai', 
	 6 => 'lietuviu.budvardziai', 7 => 'lietuviu.tarpt.budvardziai', 
	 8 => 'lietuviu.nekaitomi', 9 => 'lietuviu.ivairus', 10 => 'lietuviu.jargon'
);
# file handle hash
%fh_h = (
	 1 => 'DAIKT', 2 => 'TARPT_DAIKT', 3 => 'VARDAI', 
	 4 => 'VEIKS', 5 => 'TARPT_VEIKS',
	 6 => 'BUDV', 7 => 'TARPT_BUDV',
	 8 => 'NEKAIT', 9 => 'IVAIR', 10 => 'JARGON'
);

$versija = "spell.pl 0.5.0, paraðë Laimonas Vëbra <l.v\@centras.lt>, 2002, Vilnius.";
# Escape sekos spalvotam raðymui
$G="\e[1;33m"; # geltona
#$Z="\e[1;32m"; # þalia
$R="\e[1;31m"; # raudona
#$M="\e[0;34m"; # mëlyna
$B="\e[1;37m"; # balta
$Y="\e[1;36m"; # þydra
#$V="\e[0;35m"; # violetinë
$d="\e[0;39m";  # pagrindinë(default)

#  @bkl_veiks_daikt_pries
#Bûtojo kartinio laiko(bkl) formø ðaknies balsá daþniausiai(su retomis iðimtimis) turi ðiø priesagø veiksmaþodiniai daiktavardþiai
#gyn-(imas) (: gynë) , myn-(ikas) (: mynë), ...
@bkl_veiks_daikt_pries=('imas','ikas','ëjas','ëja','yba','ykla','inys','iklis', 'oklis', 'ûnas','ûnë', 'ëlis','ëlë', 'ena', 'ësis');

# @veiks_bendr_daikt_pries
# Bendraties ðakná turi ðiø priesagø daiktavardþiai
# -tuvas, -tuvë : vytuvas( :vyti), trintuvas (:trinti), durtuvas (: durti)
@veiks_bendr_daikt_pries=('tuvas','tuvë','tukas','tis','tas','tynë','klas','klë','klys');

local $found_u = 0; # ar þodis buvo rastas vartotojo ( (u)ser ) þodyne
local $found_i = 0; # ar þodis buvo rastas pagrindiniame, ispell'o ( (i)spell ) þodyne
local $flags;
local ($opt_b, $opt_B,  # force  black & white
       $opt_v, $opt_V,  # print version
       $opt_h, $opt_H,  # print usage(--help)
       $opt_p, $opt_P,  # PATH (jei þodynai yra ne /~ direktorijoje)
       $opt_f, $opt_F   # Tekstinis þodþiø failas
);


# Komandinës eilutës argumentø tikrinimas
use Getopt::Std;

if( !getopts('bBvVhHp:P:f:F:') || @ARGV ) { 
    print "Ávyko klaida - neteisingai nurodyti argumentai.\nPerþiûrëkite ar programa buvo iðkviesta teisingai?\n";
    exit;
}
else {
    if ($opt_b || $opt_B) {
	# Force Black & White. Sutinku, kad spalvos gali rëþti aká ar ákyrëti. TODO: custom colors
	$d = $Y = $R = $G = $B = '';
    }
    if($opt_v || $opt_V) { 
	print "$versija\n"; 
	exit;
    }
    if($opt_h || $opt_H) {
	&usage();
	exit;
    }
    
}

$pskirt = "$B"."====================$d\n"; # þodþio ávedimo (p)abaigos skiriamoji eilutë

&atidaryti_zodynus();

print "\n-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
print "Programa, nustatanti naujø þodþiø afiksus ir raðanti þodþius á þodynus. \n";
print "Vëliau ið ðiø þodynø yra kompiliuojamas lietuviø kalbos $G"."ispell$d þodynas.\n";
print "    -$B Ctrl+D$d bet kada gráþta á programos pradþià.\n";
print "    -$B Ctrl+C$d bet kada nutraukia programos vykdymà.\n";
print "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";

$ARGV = '-'; # iðankstinis nustatymas á STDIN

if($opt_f || $opt_F) { 
    $_ = defined($opt_f) ? $opt_f : $opt_F; 
    if(-e && -T) { $ARGV = $_; }
    else {
	print "$R"."Klaida$d, nëra tokio failo: $B$_$d, arba jis nëra tekstinis.\nBlogas programos rakto -(f|F) argumentas.\n"; 
	print "Nagrinësiu jûsø ávedamus þodþius..\n";
    }
}

$KLAUSTI = $ARGV eq '-';
open (BYLA, $ARGV) or warn "Negaliu atidaryti $ARGV: $!\n";

# Pradedam..
&main();

sub main() {
    my $msg;
    my $main_msg = "\nÁveskite þodá ($G\^D$B baigti$d\, $G"."?$B pagalba$d\): $B";
    print  $main_msg if $KLAUSTI;
    
    while ($word = <BYLA>) {{
	if ($word =~ /^[\s\#]+/) { next; } 
	elsif($word =~ /.\/./) { # komentarai, tuðèios eilutës bei þodþiai su flag'ais
	    chomp($word);
	    print "$word - jau turi afiksus.\n";
	    next;
	}

	chomp $word;
	print "$B$word$d\n";
	print "$d";
	if (!legal ($word)) { next; }  
	$flags = '';
	
	if ($word =~ /\?/) { pagalba(); next; }
	elsif ($word =~ /q/i) { sub_exit(); }
	
	$msg = "Tai $G"."d$d"."aiktavardis, $G"."v$d"."eiksmaþodis, $G"."b$d"."ûdvardis ar $G"."n$d"."ekaitomas þodis? ($G"."d$d\/$G"."v$d\/$G"."b$d\/$G"."n$d)";
	do  {
	    if(!ivesti_zodi($msg, 'n')) { next; }
	} until (/^[bdnvq\?]$/i);
	
	if    (/v/i) { veiksmazodis($word); }
	elsif (/d/i) { daiktavardis($word); }
	elsif (/b/i) { budvardis($word); }
	elsif (/n/i) { nekaitomas($word); }
	
	if(($found_u || $found_i) && $ARGV ne '-') { print "Norëdami tæsti paspauskite $B\"Enter\"$d klaviðà..."; $_ = <STDIN>; }
    
    }
    print $main_msg if $KLAUSTI;
    }
}  

sub veiksmazodis {
    my ($bend, $es, $but);
    my ($msg, $ats);
    
    print "$Y"."=== Veiksmaþodis ===\n$B$word$d\n";
    $msg = "Áveskite veiksmaþodþio bendratá($G"."kà daryti$d\/$G"."veikti?$d\)";
    do {
	if(! ($bend = ivesti_zodi($msg, ($word =~/.*tis?$/i) ? $word : '' )) ) { return; }
	elsif(!($bend =~ /.*tis?$/i)) { print "\n$R"."Dëmesio$d\, veiksmaþodþio bendratis turi baigtis galûne \'$G"."-ti(s)$d\' !\n"; }
    }until ($bend =~/.*tis?$/i);
    
    $msg =  "Áveskite veiksmaþodþio esamàjá laikà($G"."kà daro$d\/$G"."veikia?$d\)";
    if(! ($es = ivesti_zodi($msg, ($word =~/.*(a|[^t]i)$/i) ? $word : '' )) ) { return; };
    
    $msg = "Áveskite veiksmaþodþio bûtàjá kartiná laikà ($G"."kà darë$d\/$G"."veikë?$d\)";
    if(! ($but = ivesti_zodi($msg, ($word =~/.*ë$/i) ? $word : '')) ) { return; } 

    my %v_h = (1 => $bend, 2 => $es, 3 => $but); # pagrindiniø (v)eiksmaþodþio formø (h)ash
    my %vr_h = (1 => 0, 2 => 0, 3 => 0); # (v)eiksmaþodþio forma (r)asta hash
    
    foreach $i (1,2,3) {
	&paieska_zodynuose($v_h{$i}, 2);  
	if($found_i || $found_u) { $vr_h{$i} = 1; }
    }
    if($found_i) {
	if($vr_h{1} && $vr_h{2} && $vr_h{3}) { return; } 
	else {
	    print "\n\nJûsø ávestø veiksmaþodþiø:\n";
	    foreach $i (1,2,3) { 
		if(!$vr_h{$i}) {  print "$B$v_h{$i}$d\n"; }
	    }
	    print "$R"."nëra$d pagrindiniame ispell þodyne.\n\n";
	    print "Labai tikëtina, kad ðie, jûsø ávesti, veiksmaþodþiai yra neteisingi, o\npagrindiniame þodyne yra saugomos teisingos veiksmaþodþio formos(bendratis,\nesamasis bei bûtasis kartinis laikai).\n\n";
	    print "$B"."Kitavertus$d - neatmetama galimybë, kad pagrindiniame ispell þodyne yra klaida.\n";
	    print "Jei manote, kad tai yra þodyno klaida -  bûkite malonûs, $B"."praneðkite$d\napie tai þodyno bazës koordinatoriui.\n";
	}	
    }
    elsif($found_u) {
	# TODO :
	return;
    }
    if(!veiks_tikrinimas(\$bend, \$es, \$but)) { return; }
    foreach $i (keys (%prefix), 'a[pt]', 'a[pt]i') {
        $prefix = ($i =~ /^a\[/) ? $i : $prefix{$i};
        next unless ($bend =~ /^$prefix(.*)/); 
        local $sb = $1;
        next unless ($es =~ /^$prefix(.*)/); 
        local $se = $1;
        next unless ($but =~ /^$prefix(.*)/); 
        local $su = $1;
	$msg = "$R"."Dëmesio$d\, gali bûti, kad jûsø ávestas veiksmaþodþis turi trumpesnæ(be prieðdëliø)\npamatinæ formà)\nAr teisinga: $sb, $se, $su?";
	$ats = taip_ne ($msg, "t");
	if(!$ats) {  return; }
	elsif($ats == 1) {   
	    print "Toliau nagrinësim veiksmaþodþius: $sb, $se, $su\n";
	    $bend = $sb; $es = $se; $but = $su;
	    return;
	}
    }
    if (!append_flags("${bend}s, ${es}si, ${but}si?", 't', 'SX', 'NX')) { return; }
    
    $pref = ($bend =~ /^[bp]/i) ? 'api' : 'ap';
    if (!append_flags("$pref$bend, $pref$es, $pref$but?", 't', 'a')) { return; }
    
    $pref = ($bend =~ /^[dt]/i) ? 'ati' : 'at';
    if (!append_flags("$pref$bend, $pref$es, $pref$but?", 't', 'b')) {  return; }
    
    foreach $i (sort keys %prefix) {
        $pref = $prefix{$i};
        if (!append_flags("$pref$bend, $pref$es, $pref$but?", 't', "$i")) {  return; }
    }

    if ($bend =~ /[ûy]ti$/i and  $es =~ /[ûy].a$/i and $but =~ /[ui].o$/i) {
        $bf = "U";
    } else {
        $bf = "T";
    }

    $word = "$bend/$bf$flags\n";
    $word .= "$es/E$flags\n";
    if ($bend =~ /yti$/i){
	$word .= "but/Y$flags\n";
    } else {
	$word .= "$but/P$flags\n";
    }
    if ($flags =~ /S/) {
        $word .= "${bend}s/$bf\n";
        $word .= "${es}si/E\n";
        if ($bend =~ /yti$/i){
            $word .= "${but}si/Y";
        } else {
    	    $word .= "${but}si/P";
        }
    }
    print $pskirt;
    print "$word\n";
    irasyti_izodyna(2, $word);
    
}  # veiksmaþodþio pabaiga

sub daiktavardis() {
    my $word = shift;
    my $msg;
    my $ats;
    print "\n=== $Y"."Daiktavardis$d ===\n$B$word$d\n";
    $msg = "Áveskite vardininko laipsná ($G"."kas?$d\)";
    do {
	if (! ($word = ivesti_zodi($msg, $word)) ) { return; }
    	elsif($word =~ /.*[^aëios]$/i) { print "\n$R"."Dëmesio$d\, daiktavardþio vardininko laipsnis turi baigtis raidëmis \'$G"."a,ë,i,o,s$d\' !\n"; }
    } until( $word =~ /.*[aëios]$/i );    

    &paieska_zodynuose($word, 1);
    if($found_i) { return; }
    elsif($found_u)  { return; }  # TODO 

    # Patikrinimas ar teisingai raðomi veiksmaþodiniø daiktavardþiø ðaknies balsiai #
    my $pries_id = 0;
    foreach (@bkl_veiks_daikt_pries) {
	if ($word =~ /.*$_$/i) { 
	    $pries_id = 1;
	    last;
	}
    }
    foreach (@veiks_bendr_daikt_pries) {
	if ($word =~ /.*$_$/i) { 
	    $pries_id = 2;
	    last;
	}
    }
    if ($pries_id && !daikt_teisingas_balsis($word, $pries_id)) {  return; }
    ##
		
    if ($word !~ /(.*)(is|uo)$/i) {
        $flags = 'D'
    } else {
        my ($sak, $gal) = ($1, $2);
	$sak =~ s/t$/è/;
    	$sak =~ s/d$/dþ/;
	$ats = taip_ne('Ar þodis yra vyriðkos giminës?', 't');
	if(!$ats) {  return; }
       	if ($gal =~ /is/i && $ats == 1) {
	    # panaðu, kad visi vyriðkos gim. daiktavardþiai su galûne *.is  vns. kilmininko laipsnyje turi galunæ *.io, todël klausimas(þr. þemiau) yra nereikalingas
	    # taip_ne ("Ar vienaskaitos kilmininko($G"."ko?$d\) linksnis yra \'$B${sak}io$d\'\?", "t")) {
	    $flags = 'D'
    	} else {
            $flags = ($ats == 1) ? 'V' : 'M';
            $msg = "Ar galûnë minkðta - daugiskaitos kilminiko($G"."ko?$d\) laipsnis yra \'$B${sak}iø$d\'?";
	    if (!append_flags($msg, 't', 'I', 'K')) {  return; }
    	}
    }
    if(!append_flags("Ar yra toks daiktas ne$word?", 'n', 'N')) {  return; }
    $word = "$word/$flags";
    print $pskirt;
    print "$word\n";
    irasyti_izodyna(1, $word);
}  # daiktavardþio pabaiga

sub budvardis {
    my ($kokyb, $ivardz);
    my $msg;
    my $ats;

    $word = $_[0];
    print "\n==== $Y"." Bûdvardis$d =====\n$B$word$d\n";
    $msg = "Áveskite vardininko laipsná ($G"."kas?$d\)";  
    do {
	if (! ($word = ivesti_zodi($msg, $word)) ) {  return; }
	if($word =~ /.*[^s]$/i) { print "\n$R"."Dëmesio$d\, bûdvardþio vardininko laipsnis turi baigtis raide \'$G"."s$d\' !\n"; }
    } until( $word =~ /.*s$/i );    

    &paieska_zodynuose($word, 3);
    if($found_i) { return; }
    elsif ($found_u) { return; } # TODO

    $word =~ /(.*)(.)s$/i;
    $kokyb = $2 ne 'i';
    $msg = "Ar tai kokybinis bûdvardis (kaip $1$2; ${word}is; turi laipsnius?)";
    if (! ($ats = append_flags($msg, 't', 'AQ')) ) {  return; }
    elsif($ats == 2) {
        my ($sak, $gal) = ($1, $2);
        $sak =~ s/t$/è/;
	$sak =~ s/d$/dþ/;
        if(!append_flags("Ar tai santykinis bûdvardis (kokiems - ${sak}iams)?", 't', 'B', 'A')) {  return; } 
    }
    
    if(!append_flags("Ar gali bûti ne$word?", 'n', 'N')) {  return; }
    $word = "$word/$flags";
    print $pskirt;
    print  "$word\n";
    irasyti_izodyna(3, "$word");
}  # bûdvardþio pabaiga


sub nekaitomas {

    $word = $_[0];
    print "\n==== $Y"." Nekaitomas$d =====\n$B$word$d\n";
    &paieska_zodynuose($word, 4);
    if($found_i) { return; }
    elsif ($found_u) { return; } # TODO

    irasyti_izodyna(4, "$word");
}  # nekaitomas pabaiga

sub legal {
    # Funkcija, kuri tikrina ávedamø þodþiø "legalumà". Mano manymu, tai ðiek tiek padeda iðvengti klaidø ir sutaupyti laiko(pvz: vëlai pastebëjus, kad klaidingai 
    # ávestas þodis, reikia ið naujo pradëti procedûrà). 
    # Kitavertus, mano "uþprogramuotas legalumas" (besikartojantys, sulipæ priebalsiai(pvz.: ' kk','ðð' ir t.t.), daugiau kaip trys  priebalsiai esantys greta
    # (pvz. : '.*ndþk.*'), gali bûti klaidingas. Jei pastebësite klaidas - praneðkite <l.v@centras.lt>

    if ($word =~/^[^?q]$|.*([b,c,è,d,f-h,j-n,p-t,ð,v,z,à,è,æ,ë,á,ø,û])\1+.*|.*[0-9]+.*|.*[wxq].+|.*[b,c,è,d,f-h,j-n,p-t,ð,v,z,þ]{4,}.*/) {
	print	"\n$R"."Dëmesio$d, labai tikëtina, kad jûs ávedëte blogà þodá(jame negali bûti skaièiø,\n\"sulipusiø\"(esanèiø greta) priebalsiø bei kai kuriø balsiø, lotynø abëcëlës\nraidþiø [q,w,x]..ir kt.)!\n";
	return 0;
    }
    else { return 1; }
}
## main() pabaiga ##
print "$d\nIki!\n";


sub daikt_teisingas_balsis($) {
    my $word = shift;
    my $id = shift;
    my $msg;
    if ($id == 1) {
	print "\n\n$R"."Dëmesio$d - tikëtina, kad þodis$B $word$d yra veiksmaþodinis daiktavardis.\n"; 
	print "Tokie daiktavardþiai yra kilæ ið veiksmaþodþio(pvz. vytukas <- "; 
	print "vyti;\nirklas <- irti) ir savo ðaknyje daþniausiai turi toki patá balsá\n";
	print "kaip ir pamatinio veiksmaþodþio bendraties forma.\n\n";
	print "$Y"."Pvz:\n";
	print "\t$B\-tuvas:$d v$G"."y$d"."tuvas (: v$G"."y$d"."ti); tr$G"."i$d"."ntuvas (: tr$G"."i$d"."nti); d$G"."u$d"."rtuvas (: d$G"."u$d"."rti)...\n";
	print "\t$B\-tas:$d b$G"."u$d"."rtas (: b$G"."u$d"."rti); k$G"."e$d"."ltas (: k$G"."e$d"."lti); sv$G"."e$d"."rtas (: sv$G"."e$d"."rti)...\n";
	print "\t$B\-klë:$d b$G"."û$d"."klë (: b$G"."û$d"."ti); þ$G"."û$d"."klë (: þ$G"."û$d"."ti); v$G"."i$d"."ryklë (: v$G"."i$d"."rti)...\n\n";
    }
    elsif ($id == 2) {
	print "\n\n$R"."Dëmesio$d - tikëtina, kad þodis$B $word$d yra veiksmaþodinis daiktavardis.\n"; 
	print "Tokie daiktavardþiai yra kilæ ið veiksmaþodþio(pvz. veikëjas <- "; 
	print "veikia,veikë;\nraðinys <- raðo,raðë) ir savo ðaknyje daþniausiai turi toki patá balsá\n";
	print "kaip ir pamatinio veiksmaþodþio bûtojo kartinio laiko forma.\n\n";
	print "$Y"."Pvz:\n";
	print "\t$B\-imas:$d g$G"."y$d"."nimas (: g$G"."y$d"."në); r$G"."i$d"."jimas (: r$G"."i$d"."jo); k$G"."û$d"."limas (: k$G"."û$d"."lë)...\n";
	print "\t$B\-inys:$d k$G"."û$d"."rinys (: k$G"."û$d"."rë); n$G"."ë$d"."rinys (: n$G"."ë$d"."rë); si$G"."u$d"."vinys (: si$G"."u$d"."vo)...\n";
	print "\t$B\-ësis:$d gri$G"."u$d"."vësis (: gri$G"."u$d"."vo); dþi$G"."û$d"."vësis (: dþi$G"."û$d"."vo); p$G"."u$d"."vësis (: p$G"."u$d"."vo)...\n\n";
    }
    $msg = "Pasitikrinkite ar daiktavardþio ðaknyje yra teisingas balsis?";
    if ( !taip_ne($msg, "t")) {
	$msg = "Áveskite teisingà þodá ($G"."q$d sugráþti á pradþià)";
	if (! ($word = ivesti_zodi($msg, $word)) ) {  return; };
    }
    return 1;
}

sub atidaryti_zodynus()
{
    use Fcntl qw(:DEFAULT :flock);
    my $home; 
    if($opt_p || $opt_P){
       	$_ = defined($opt_p) ? $opt_p : $opt_P;
	if(-d) {
	    if(/\/bin\/?.*|\/usr\/bin\/?.*|\/usr\/local\/bin\/?.*|\/sbin\/?.*|\/usr\/sbin\/?.*|\/usr\/X11R6\/?.*/) {
		print "$R"."Bûtø neprotinga$d saugoti þodynø failus $B$_$d direktorijoje.\n";
		print "Jei jûs manote kitaip - fixme($0, ".(__LINE__ - 2)." eilutë)\n";
		print "Uþsispyriau, toliau neveiksiu! ;)\n";
		exit;
	    }
	    else { $home = $_; }
	}
	else { print "$R"."Klaida$d, nëra tokios direktorijos: $B$_$d !\nBlogas programos rakto -(p|P) argumentas.\n"; exit; }
    }
    else{ $home = $ENV{"HOME"} || $ENV{"LOGDIR"} || (getpwuid($<))[7]; }
           
    foreach $key ( keys (%fn_h) ) {
	sysopen( $fh_h{$key},"$home/$fn_h{$key}", O_RDWR | O_CREAT) or die "\$n$R"."Dëmesio$d\, negaliu atidaryti/sukurti /$home/$fn_h{$key} !";
	flock($fh_h{$key}, LOCK_EX) or die "\n$R"."Dëmesio$d\, negaliu uþrakinti(lock) /$home/$fn_h{$key} !";    
    }

}
sub paieska_zodynuose($$) {
    my $word = shift;
    my $dalis_id = shift; # kokia kalbos dalis 1 - daiktavardis, 2 - veiksmaþodis, 3 - bûdvardis, 4 - nekaitoma
    my ($str1, $msg, $ats);
    my $af = '';
    $found_i = 0;
    # paieðka pagrindiniame ispell þodyne #
    open(FROM_ISPELL, "echo $word | ispell -d lietuviu -a | grep \'^[*,-,+,&,#,?]\' |") or die 	"\n$R"."Dëmesio$d".", negaliu ávykdyti komandos \'echo $word | ispell -d lietuviu -a | grep \'^[*,-,+,&,#,?]\' \' !";
    $_ = <FROM_ISPELL>;
    close(FROM_ISPELL);
    if (/^\*/) {
	print "$R"."Dëmesio$d".", þodis $B\'$word\'$d yra pagrindiniame ispell þodyne.\n";
	$found_i = 1;
	return;
    }
    elsif ( /^\+.(.*)$/ ) {
	print "$R"."Dëmesio$d".", jûsø ávesta þodþio forma $B\'$word\'$d turi ðakniná þodá $G\'$1\'$d,\nkuris  yra pagrindiniame ispell þodyne.\n";
	$found_i = 1;
	return;
    }
    ##	   
    
    # TODO: tikrinti abu þodynus(tiek sukompiliuotà, tiek vartotojo) ir ieðkoti galimai pasikartojanèiø þodþiø
    if ($dalis_id == 1) {
    # daiktavardþio paieðka ~ direktorijoje esanèiuose þodynuose #
	foreach $key (1,2,3,9) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		$af = $_;
		last;
	    }
	}
    }##
    elsif($dalis_id == 2) {
    # veiksmaþodþio paieðka ~ direktorijoje esanèiuose þodynuose #
	foreach $key (4,5) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		$af = $_;
		last;
	    }
	}
    }##
    elsif($dalis_id == 3) {
    # bûdvardþio paieðka ~ direktorijoje esanèiuose þodynuose #
	foreach $key (6,7) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		$af = $_;
		last;
	    }
	}
    }##
    elsif($dalis_id == 4) {
    # nekaitomo þodþio paieðka ~ direktorijoje esanèiuose þodynuose #
	foreach $key (8,9,10) {
	    if(find_in($fh_h{$key}, $word)) {
		$str1 = $fn_h{$key};
		last;
	    }
	}
    }##
    if ($found_u) { print "\n$R"."Dëmesio$d".", þodis $B$word$Y\/$af$d yra þodyne \'$str1\'.";  }
}  

sub taip_ne($$) {
    my $msg = shift;
    my $def_ans = shift;
    my $kart = 0;
    do {
	if ($kart > 3) { 
	    print "\n$d"."Áveskite ($G"."t$d,$G"."n$d arba $G"."q$d): $B"; 
	}
	else { print "$msg ($G"."t$d\/$G"."n$d\) [$B"."$def_ans$d\]: $B"; }
    	$_ = <STDIN>;
	print "$d";
	if (!defined || /q/i) {  return; }
	chomp($_);
	$_ = $def_ans if $_ eq '';
	$kart++;
    } until /^[tnq]$/i;
    return (/t/i) ? 1 : 2;
}

sub ivesti_zodi($;$) {
    my $msg = shift;
    my $def_word = shift ;
    my $kart = 0;
    do {
	if($kart >= 3) { print "\nÁveskite teisingà þodá ($G"."q$d sugráþti á pradþià): $B"; } 
	else { 
	    if( defined($def_word) && $def_word ne '' ) { print "$msg [$B$def_word$d\]: $B"; }
	    else { print "$msg: $B"; }
	} 
	$_ = <STDIN>;
	print "$d";
	if (!defined || /q/i) {  return; }
	chomp ($_);
	if( $_ eq '' && defined($def_word) ) { $_ = $def_word; }
    } until (legal ($_) );
    return $_;
}

sub sub_exit {
    print "$d";
    exit;
}

sub irasyti_izodyna ($$) {
    my $id = shift;
    my $word = shift;
    my $lst_ref;
    my ($ats, $idx);
    
    my $msg = "\nJûsø ávestas þodis yra? :";
    
    if ($id == 1) {
	$lst_ref = ['Lietuviðkas daiktavardis', 'Taptautinës kilmës þodþio daiktavardis', 'Vardas', 'Kita (skaitvardis, ávardis)'];
	if(! ($ats = v_choice($msg, $lst_ref,  1 )) ) {  return; }
	else { $ats = ($ats == 4) ? 9 : $ats; }
    }
    elsif ($id == 2) {
	$lst_ref = ['Lietuviðkas veiksmaþodis', 'Taptautinës kilmës þodþio veiksmaþodis'];
	if(! ($ats = v_choice($msg, $lst_ref,  1 )) ) {  return; }
	else { $ats += 3; }
    }
    elsif ($id == 3) {
	$lst_ref = ['Lietuviðkas bûdvardis', 'Taptautinës kilmës þodþio bûdvardis'];
	if(! ($ats = v_choice($msg, $lst_ref,  1 )) ) {  return; }
	else { $ats += 5; }
    }
    elsif ($id == 4) {
	$lst_ref = ['Tiesiog nekaitomas (arba neaiðkus) þodis', 'Þargonas'];
	if(! ($ats = v_choice($msg, $lst_ref,  2 )) ) {  return; }
	else { $ats = ($ats == 1) ? 8 : 10; }  
    }
    $idx = $ats;
    write_to($fh_h{$idx}, $word);

}

sub v_choice($$$) {
    my $msg = shift;
    my $lst_ref = shift;
    my $def = shift;
    my $tmp = 1;
    my $range;

    print "$msg\n";
    foreach $i (@$lst_ref) {
	print "\n\t\t$G$tmp$d $i";
	$tmp++;
	next;
    }
    print "\n\n";
    $range = $tmp--;
    $tmp = 0;
    do {
	if ($tmp >= 3) {
	    print "\nÁveskite variantà atitinkantá skaièiø nuo $G"."1$d iki $G$range$d arba $G"."q$d iðeiti [$B$def$d]: $B" ;
	}
	else {	print "Áveskite [$B$def$d]: $B"; }
	$_ = <STDIN>;
	print "$d";
	if (!defined || /q/i) {  return; }
	chomp($_);
	$_ = $def if $_ eq '';
	$tmp++;
    } until( /[1-$range]/ );
    return $_;
}

sub write_to($$)
{
    my $FH = shift;
    my $word = shift;

    seek($FH, 0, 1) or die "$R"."Dëmesio$d\, negaliu pereiti á failo galà.\n";
    print $FH "$word\n" or die "$R"."Dëmesio$d\, negaliu áraðyti á failo galà.\n";
    print "Áraðyta\n";
}

sub find_in($$)
{
    my $FH = shift;
    my $word = shift;
    $found_u = 0;
    
    if (tell($FH)) { seek($FH, 0, 0) or die "$R"."Dëmesio$d\, negaliu pereiti á failo pradþià.\n"; }
    while ( <$FH> ) {
	if (/^$word(\/(.+))?$/i) {
	    $found_u = 1;
	    $_ = $2;
	    last;
	}
    }
    if ($found_u) {  return ($_) ? $_ : 1; }
}

sub append_flags($$$;$) {
    my $msg = shift;
    my $def = shift;
    my $f_true = shift;
    my $f_false = shift;
    my $ats = taip_ne($msg, $def);
    if(!$ats) {  return; }
    elsif($ats == 1) { $flags .= $f_true; }
    elsif($ats == 2 && defined($f_false)) { $flags .= $f_false; }
    return $ats;
}

sub veiks_tikrinimas (\$\$\$) {
    my $bend = shift;
    my $es = shift;
    my $but = shift;
    my ($msg, $ats);
    
    # Patikrinimas ar teisingai raðmos nosinës balsës veiksmaþodþiø ðaknyse prieð raidæ 's'
    if ( $$bend =~ /^(.*)(.)([aeiyuû])(s.*)$/i || $es =~ /^(.*)(.)([aeiyuû])(s.*)$/i ) {
	my ($_1, $_2, $_3, $_4) = ($1, $2, $3, $4);
	my $itart; # átartina bendratis?(1), esamasis laikas?(0), abu?(2) 
	($$bend eq "$1$2$3$4") ? ($itart = 1) : ($itart = 0);
	if ($itart) { ($$es =~/$1$2$3s.*/i) ? ($itart = 2)  : ($itart = 1); }
	if ( $$es =~ /$1$2[aeiu]n.*/i || $$but =~ /$1$2[aeiu]n.*/i || $$bend =~ /$1$2[aeiu]n.*/i ) {
	    print "\n$R"."Dëmesio$d\, nosinës balsës $B"."à$d\,$B"."æ$d\,$B"."á$d\,$B"."ø$d raðomos veiksmaþodþiø ðaknyse prieð \'$d"."s$d\',\nkai pagrindiniuose kamienuose ðios balsës kaitaliojasi su $G"."an$d\,$G"."en$d\,$G"."in$d\,$G"."un$d.\n$Y"."Pvz:$d\n\tgr$B\á$d\(s)ti : gr$G"."in$d"."dþia, gr$G"."in$d"."dë; br$B"."æ$d\(s)ti, br$B"."æ$d\(s)ta : br$G"."en$d"."do...\n"; 
	    $_ = $_3;
	    if( /a/i ) { $_ = 'à'; }
	    elsif( /e/i ) { $_ = 'æ'; }
	    elsif( /[uû]/i ) { $_ = 'ø'; }
	    elsif( /[iy]/i ) { $_ = 'á'; }
	    my ($str1, $str2, $es_tb, $bend_tb); # $es_tb, $bend_tb - (t)urëtø (b)ûti
	    print "-------------------------------------------------------------------------------";
	    if ($itart == 2) {
		my $tmp = $$es;
		$tmp =~ s/$_1$_2$_3(.*)/$_1$_2$G$_3$d$1/i;
	        $str1 = "\'$_1$_2$G$_3$d$_4\', \'$tmp\'";
		$tmp = $$es;
		$tmp =~ s/$_1$_2$_3(.*)/$_1$_2$_$1/i;
	        $es_tb = $tmp;
		$bend_tb = "$_1$_2$_$_4";
	        $tmp =~ s/^$_1$_2$_(.*)/$_1$_2$G$_$d$1/i ;
	        $str2 = "\'$_1$_2$G$_$d$_4\', \'$tmp\'";
            }
	    else { 
		$str1 = "$_1$_2$G$_3$d$_4"; 
		$str2 = "$_1$_2$G$_$d$_4"; 
		($itart == 0) ? ($es_tb = "$_1$_2$_$_4") : ($bend_tb = "$_1$_2$_$_4");  
	    }
	    do {
		print "\n$B"."Jûs ávedëte$d $str1 nors taisyklë byloja, kad:\n$R"."Turëtø bûti$d $str2.\n";
		$msg = "Ar sutinkate su taisyke?";
		if(! ($ats = taip_ne($msg, 't')) ) {  return; }
		elsif($ats == 2) {
		    $msg = "Neregëtas uþsispyrimas.. :). Belieka paklausti ar esate ásitikinæ, kad þodþius\návedëte teisingai?\n$$bend, $$es, $$but?";
		    if(! ($ats = taip_ne($msg, "n")) ) {  return; }
		
		}
		else { 
		    if($es_tb) { $$es = $es_tb; } 
		    if ($bend_tb) { $$bend = $bend_tb; }
		    print "\n$$bend, $$es, $$but\n";
		}
	    } while ($ats == 2);
	}
    }
    return 1;
}

sub pagalba() {
    system('clear');
    print "Programos veikimo $G"."principas$d\:\n\n";
    print "Þodþiø kaupimas yra iðskirtas á 4 pagrindinius skyrius, tai yra:\n";
    print "    -$B Daiktavardis$d\n";
    print "    -$B Veiksmaþodis$d\n";
    print "    -$B Bûdvardis$d\n";
    print "    -$B Nekaitoma$d\n";
    print "    Ávedus þodá bei pasirinkus skyriø, programa papraðys ávesti ðakninæ þodþio\n";
    print "formà(daiktavardþiams, bûdvardþiams  - vardininko laipsnis, veiksmaþodþiams tai\n";
    print "yra bendratis, esamasis bei bûtasis kartinis laikai). Sàvoka \"ðakninis þodis\"\n";
    print "reiðkia, kad ðis þodþis kartu su nustatytais afiksø parametrais(vëliavëlës) bus\n";
    print "iðsaugotas þodyne.\n";
    print "    Toliau programa ieðko jûsø ávesto ðakninio þodþ-io(iø) pagrindiniame bei \n";
    print "-(p|P) raktu nurodytoje arba namø direktorijoje(/~) esanèiuose þodynuose.\n";
    print "    Jei þodis ið tikrøjø neþinomas, programa kaip ámanoma draugiðkiau papraðys\n";
    print "suteikti jai paildomà informacijà(þodþio linksniai, laikai, prieðdëliai,\n";
    print "galûnës, kita) kuri reikalinga teisingiems þodþio afiksams nustatyti. Po visø\n"; 
    print "ðiø veiksmø, jums sutikus, þodis bus áraðytas á atitinkamà þodynà.\n\n";
    print "    -$B Ctrl+D$d - bet kada gráþta á programos pradþià. Esant programos pradþioje\n";
    print "ði kombinacija nutraukia jos vykdymà.\n";
    print "    -$B Ctrl+C$d - bet kada nutraukia programos vykdymà.\n";
}

sub usage()
{
print "$versija\n";
print "\nProgramos argumentai:\n\n";
print "-b, -B\tNenaudoti spalvø(áprastas, bespalvis tekstas)\n";
print "-f, -F\tFailas ið kurio bus skaitomi ir nagrinëjami þodþiai.\n\tNutylëjus(nenurodþius -f ar -F) bus skaitomi ir nagrinëjami vartotojo\n\távedami þodþiai\n";
print "-h, -H\tPagalba(ðis programos argumentø sàraðas)\n";
print "-p, -P\tDirektorija, kurioje saugomi þodyno failai.\n\tNutylëjus(nenurodþius -p ar -P) tai yra vartotojo namø direktorija /~\n";

}
