#!/usr/bin/perl -w

use v5.14;
use Getopt::Long;

# slideshow.pl [-options --options] pic_1 ... pic_n
# -v, --verbose                 => show XML on STDOUT
# -t, --time (seconds)          => time to next change
# -f, --file (path/xml-file)    => create xml on path/xml-file
# -s, --set-background          => set $file as background (gnome 3)


my (@dateien, $duration, $verbose, $file, $slideshow, $set_background);

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
            

$duration       or $duration = 300;
@dateien        = extractFiles(@ARGV);
$slideshow      = createSlideshow(@dateien, $duration);
$verbose        and say $slideshow;

if($file)
{ 
    createXMLFile($slideshow, $file); 
}else
{
    $file = "$ENV{HOME}/slideshow.xml";
    createXMLFile($slideshow, $file) if $set_background;
}

$set_background and setBackground($file);


sub setBackground
{
    my $file = shift @_;
    `gsettings set org.gnome.desktop.background picture-uri "file://$file"`;
}

sub createXMLFile
{
    my ($slideshow, $file) = @_;
    
    open (DATEI, "> $file") or die ('Fehler beim Schreiben');
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
    my $typ;
    my $xml         = "";
    my $duration    = pop @_ ;
    my @pictures    = @_ ;
    
    foreach my $file (@pictures)
    {
        $_ = `file --mime-type "$file"`;
        $xml .= createSlideshowElement($file, $duration) if /:\s(image)\/.*/;
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


