#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use autodie;
use IO::Uncompress::Gunzip;
use File::Path qw(make_path);
use File::Basename;
use BMM::Iget4 qw(iopen);

#Try and include Term::ProgressBar
my $has_progressbar = 1;
eval {
    require Term::ProgressBar;
};
$has_progressbar = 0 if $@;

my %options = ();
Getopt::Long::Configure(qw(bundling no_ignore_case));
GetOptions(\%options,
    'list|l=s',
    'middle|m',
    'help|h',
) or pod2usage(2);
pod2usage(-verbose => 2, -noperldoc => 1, -exitval => 1) if $options{help};

my $PDB_DIR = shift or pod2usage('No PDB directory supplied.');

#List of files to process
my @PDBS = @ARGV;
if($options{list}){

    #Read STDIN if specified
    my $in = undef;
    if($options{list} eq '-'){
        $in = \*STDIN;
    }else{
        open $in, q{<}, $options{list};
    }

    #The list file may be an rsync log or similar, so only add things that look
    #like PDB files.
    while(<$in>){
        chomp;
        next unless /\d\w{3}[.]ent(?:[.]gz)?$/;
        next if /^deleting /;
        push @PDBS, $_;
    }
    close $in if $in != \*STDIN;
}

#Initialise progressbar if running on a terminal
my $progressbar = undef;
if($has_progressbar && (-t STDOUT)){
    $progressbar = Term::ProgressBar->new({
        name => 'Generating files',
        count => scalar(@PDBS),
        ETA => 'linear',
    });
}
my $num_processed = 0;
for my $pdb(@PDBS){
    #For progressbar, if any
    $num_processed++;

    my $source_file = "$PDB_DIR/$pdb";

    #Get ATOM records
    my @ATOMs = ();
    eval {
        my $pdb_in = open_pdb($source_file);
        while(<$pdb_in>){
            push @ATOMs, $_ if /^ATOM/;
            last if /^ENDMDL/;
        }
        close $pdb_in;
    };
    if($@){
        warn $@;
        warn "Skipping `$source_file'";
        next;
    }

    #Get chains
    my %chains = ();
    $chains{substr $_, 21, 1}++ for @ATOMs;

    #Write out the file for each chain
    for my $chain(keys %chains){
        my $out_file = file_name($source_file, $chain);
        next if (-e $out_file);

        #Create output directory if it doesn't exist
        my ($name, $dirname) = fileparse($out_file);
        make_path($dirname);

        open my $out, q{>}, $out_file;
        print {$out}
            "REMARK   5 Generated from:\n",
            "REMARK   5 $source_file\n",
            "REMARK   5 ", scalar(localtime),
            "\n";
        my $body = iopen($name);
        print {$out} $body;
        close $out;
    }

    #Update progress bar
    if($progressbar){
        $progressbar->update($num_processed);
    }
}

#Return a filehandle to a PDB file (that may or may not be compressed)
sub open_pdb {
    my ($pdb) = @_;
    if($pdb =~ /[.]gz$/){
        my $gz = IO::Uncompress::Gunzip->new($pdb)
            or die "Couldn't open $pdb: $!";
        return $gz;
    }else{
        open my $in, q{<}, $pdb;
        return $in;
    }
}

#Get the output file name from the input file name, according to whether
#--middle is set.
sub file_name {
    my ($name, $chain) = @_;
    my ($pdb) = $name =~ m{(\d\w{3})[.]ent(?:[.]gz)?$};

    my $out_name = "c${pdb}${chain}_.pdb";
    if($options{middle}){
        my ($middle) = $pdb =~ /^\d(\w\w)\w/;
        $out_name = "$middle/$out_name";
    }
    return $out_name;
}

__END__
=head1 NAME

pdb_to_chains.pl - Build per-chain PDB files for each PDB entry

=head1 USAGE

B<pdb_to_chains.pl> B<PDBDIR> [B<-l> I<LIST>] [B<PDB1> [B<PDB2>...]]

B<pdb_to_chains.pl> B<--help>

=head1 OPTIONS AND ARGUMENTS

The first argument, B<PDBDIR> must be the location of the PDB files downloaded
from the RCSB.

Positional arguments (B<PDB1>, B<PDB2>, etc) should be paths to PDB files.
Alternatively (or additionally) the B<-l>=I<LIST> option may be supplied, in
which case a list of PDB files is read. If I<LIST> is "-", standard input is
read.

=head2 Options

=over

=item B<-l>, B<--list>=I<LIST>

Read PDB files from I<LIST> as well as from the PDB files given as arguments.

=item B<-m>, B<--middle>

Place the output files in subdirectories according to the middle two letters of
the PDB code. For example, F<c12asA.pdb> will be stored in F<2a/c12asA_.pdb>.

=item B<-h>, B<--help>

Display this help message.

=back

=cut
