#!env perl 
use strict;
use warnings;
use Text::CSV;
use Bio::DB::Fasta;
use Bio::SeqIO;
use Getopt::Long;
my $dbdir = 'Naegr1';
my $prefix = 'Naegr1';
# need to gunzip Naegr1/Naegleria_gruberi_NEG-M.aa.fasta.gz first
GetOptions(
    'd|dir:s' => \$dbdir,
    'p|pref:s' => \$prefix,
    );

my $dbh = Bio::DB::Fasta->new($dbdir);

my $file = shift || "FileS2_FMs.simple.csv";
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $fh, "<:encoding(utf8)", $file or die "$file: $!";
my $out = Bio::SeqIO->new(-format => 'fasta',
			  -file   => ">$prefix.FM.aa");
my $header = <$fh>;
my @missing;
while( my $row = $csv->getline( $fh ) ) {
    my ($fmname,$pepid,$ch_homolog, $other_homolog) = @$row;
    my $pname = sprintf("%s_%s",$prefix,$pepid);
    my $seq = $dbh->get_Seq_by_acc($pname);
    if( ! $seq ) {
	warn("cannot find $pname in db\n");
	push @missing, $pepid;
	next;
    }
    my $desc = sprintf("JGI=%s",$pname);
    if( $ch_homolog ) {
	my @n = split(/\s*;\s*/,$ch_homolog);
       	$desc .= sprintf(" Name=%s",join(",",@n));
    }
    if( $other_homolog ) {
	my @n = split(/\s*;\s*/,$other_homolog);
	$desc .= sprintf(" Other=%s",join(",",@n));
    }
    my $newp = Bio::Seq->new(-seq => $seq->seq,
			     -id  => "$fmname",
			     -desc => $desc);
    $out->write_seq($newp);
}

if( @missing ) {
    print "missing: @missing\n";
}
