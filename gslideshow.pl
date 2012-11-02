#!/usr/bin/perl -w

use v5.16;
use Getopt::Long;


#################################
##### Argumente deklaration #####
#################################

# slideshow.pl [-options --options] File1/Dir1 ... File_n/Dir_n
# -v, --verbose                 =>  schreibt XML auf STDOUT
# -t, --time (seconds)          =>  Zeit bis zum naechsten Bildwechsel.
#                                   Alternativ kann auch :200 an die
#                                   Bildpfade angehängt werden wobei 
#                                   200 fuer die Anzahl der sek steht
# -f, --file (path/xml-file)    =>  erstellt die XML am angegebenen Ort
# -s, --set-background          =>  setzt die XML als Hintergrund-Bild
#                                   wenn kein XML-Pfad angegeben ist 
#                                   wird $HOME/slideshow.xml erstellt


my (@dateien, 
    $duration, 
    $verbose, 
    $file, 
    $slideshow, 
    $set_background,
    $std_xml);

Getopt::Long::Configure('bundling');
GetOptions( 'time:i'            => \$duration,
            't:i'               => \$duration,
            'verbose'           => \$verbose,
            'v'                 => \$verbose,
            'file:s'            => \$file,
            'f:s'               => \$file,
            'set-background'    => \$set_background,
            's'                 => \$set_background
            ) or die ('Fehler bei den Parameter');
            
            
## $duration standard           : 300 sekunden
## xml standard speicherort     : $HOME/slideshow.xml

$duration       or $duration = 300;
$std_xml        = "$ENV{HOME}/.slideshow.xml";
@dateien        = extractFiles(@ARGV, $duration);
$slideshow      = createSlideshow(@dateien);
$verbose        and say $slideshow;

if($file)
{ 
    createXMLFile($slideshow, $file); 
}
else
{
    ## wenn keine Pfadangabe fuer die XML gemacht wurde
    ## wird $std_xml gesetzt falls der -s/--set-background 
    ## flag gesetzt ist.
    
    $file = $std_xml;
    createXMLFile($slideshow, $file) if $set_background;
}

$set_background and setBackground($file);


##################################
##### Funktionen Deklaration #####
##################################


## setBackground($file) setzt die eingegebene Datei
## als Hintergrund fuer Gnome 3 ueber gsettings

sub setBackground
{
    my $file = shift @_;
    `gsettings set org.gnome.desktop.background picture-uri "file://$file"`;
}


## createXMLFile($slidehsow, $file) schreibt die Slideshow in eine Datei

sub createXMLFile
{
    my ($slideshow, $file) = @_;
    
    open (DATEI, "> $file") or die ('Fehler beim Schreiben');
    print DATEI "$slideshow";
    close DATEI;
    
    return 1;
}


## extractFiles(@pfade, $dateien) gibt alle Dateien aus den 
## angegebenen Pfaden(Dateien und Ordner) in eine Liste

sub extractFiles
{
    my $duration    = pop @_ ;
    my @pfade       = @_ ;
    my @pictures;
    my $temp; 
    
    foreach (@pfade)
    {
        /(.*):(\d*)/;
        push (@pictures, getPicturesOfPath($1, $2)) if $2;
        push (@pictures, getPicturesOfPath($_, $duration)) unless $2;
    }
    
    return @pictures;
}


## getPicturesOfPath($pfad, $duration) gibt alle Bilder am $pfad in Form
## Hashes in einem Array aus

sub getPicturesOfPath
{
    my ( $pfad, $duration ) = @_ ;
    my @pictures;
    my %pichash;
    
    if (-d $pfad)
    {
        for (glob "$pfad/*")
        {
			push (@pictures, getPictureHash($_, $duration)) if isPicture($_);
        }
    }
    
    if (-f $pfad)
    {
		if (getPictureHash($_, $duration)){
			push (@pictures, getPictureHash($pfad, $duration));
		}
    }
    
    return @pictures;
}


## getPictureHash($pfad, $duration) wirft ein hash der form
## (picture => $pfad, duration => $duration) aus

sub getPictureHash
{
    my ( $pfad, $duration ) = @_ ;
    my %picture ;
    
    %picture = ( picture => $pfad , duration => $duration );
    return \%picture;
}


## isPicture($pfad) testet ob $pfad ein Bild ist

sub isPicture
{
    my $file = shift @_ ;
    
    my $_ = `file --mime-type "$file"`;
    if ( /:\s(image)\/.*/ ) { 
		return 1; 
	}else{ 
		return 0; 
	}
}


## createSlideshow(@BildListe)

sub createSlideshow
{
    my @pictures    = @_ ;
    my $xml;
    
    $xml  = "<?xml version='1.0' ?>\n";
    $xml .= "<background>\n";
    $xml .= createSlideshowHeader();
    $xml .= createSlideshowBody(@pictures);
    $xml .= "</background>";
    
    return $xml;
}


## createSlideshowHeader() erstellt den Header der Slideshow XML

sub createSlideshowHeader
{
    my $xml = "";
    my ($sekunden, $minuten, $stunden, $tag, $monat, $jahr) = localtime;
    $monat++;
    $jahr += 1900;
    
    $xml .= "<starttime>\n";
    $xml .= "    <year>$jahr</year>\n";
    $xml .= "    <month>$monat</month>\n";
    $xml .= "    <day>$tag</day>\n";
    $xml .= "    <hour>$stunden</hour>\n";
    $xml .= "    <minute>$minuten</minute>\n";
    $xml .= "    <second>$sekunden</second>\n";
    $xml .= "</starttime>\n";
    
    return $xml;
}


## createSlideshowBody(@BildListe, $DurationTime) erstellt den
## Slideshow Body für jedes in der @BildListe vorhandenes Bild
## Bilder werden nach MIMITYP : image erkannt

sub createSlideshowBody
{
    my $typ;
    my $xml         = "";
    my @pictures    = @_ ;
    
    
    foreach (@pictures)
    {
        $xml .= createSlideshowElement(${$_}{picture}, ${$_}{duration});
    }
    
    return $xml;
}


## createSlideshowElement($Picture, $DurationTime) erstellt ein
## Slideshow Body-Element fuer ein gegebenes Bild mit der angegebenen
## Bild-Wechsel-Zeit ($DurationTime)

sub createSlideshowElement
{
    my $xml         = "";
    my $picture     = shift @_ ;
    my $duration    = shift @_ ; 
    
    $xml  = "<static>\n";
    $xml .= "<duration>$duration</duration>\n";
    $xml .= "<file>$picture</file>\n";
    $xml .= "</static>\n";
    
    return $xml;
}


