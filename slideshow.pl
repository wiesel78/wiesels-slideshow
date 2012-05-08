#!/usr/bin/perl

use v5.14;
use Getopt::Long;

# slideshow.pl [-options --options] pic_1 ... pic_n
# -v, --verbose                 => show XML on STDOUT
# -t, --time (seconds)          => time to next change
# -f, --file (path/xml-file)    => create xml on path/xml-file


my (@dateien, $duration, $verbose, $file, $slideshow);

Getopt::Long::Configure('bundling');
GetOptions( 'time:i'    => \$duration,
            't:i'       => \$duration,
            'verbose'   => \$verbose,
            'v'         => \$verbose,
            'file:s'    => \$file,
            'f:s'       => \$file
            ) or die ('Fehler bei den Parameter');
            

$duration       or $duration = 300;
@dateien        = extractFiles(@ARGV);
$slideshow      = createSlideshow(@dateien, $duration);
$verbose        and say $slideshow;

$file and 
createXMLFile($slideshow, $file) or 
$file = "$ENV{HOME}/slideshow2.xml";


sub createXMLFile
{
    my ($slideshow, $file) = @_;
    
    open (DATEI, ">> $file") or die ('Fehler beim Schreiben');
    print DATEI "$slideshow";
    close DATEI;
    
    return 1;
}

sub extractFiles
{
    my @pfade = shift @_ ;
    my @dateien;
    
    foreach (@pfade)
    {
        push (@dateien, glob "$_/*") if (-d $_); 
        push (@dateien, $_)          if (-f $_);
    }
    
    return @dateien;
}

sub createXMLHeader
{
    return "<?xml version='1.0' ?>\n";
}

sub createSlideshow
{
    my $xml;
    my $duration    = pop @_ ;
    my @pictures    = @_ ;
    
    $xml  = createXMLHeader();
    $xml .= "<background>\n";
    $xml .= createSlideshowHeader();
    $xml .= createSlideshowBody(@pictures, $duration);
    $xml .= "</background>";
    
    return $xml;
}

sub createSlideshowHeader
{
    my ($xml);
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

sub createSlideshowBody
{
    my $xml         = "";
    my $duration    = pop @_ ;
    my @pictures    = @_ ;
    
    foreach (@pictures)
    {
        $xml .= createSlideshowElement($_, $duration);
    }
    
    return $xml;
}

sub createSlideshowElement
{
    my $xml;
    my $picture     = shift @_ ;
    my $duration    = shift @_ ; 
    
    $xml  = "<static>\n";
    $xml .= "<duration>$duration</duration>\n";
    $xml .= "<file>$picture</file>\n";
    $xml .= "</static>\n";
    
    return $xml;
}


