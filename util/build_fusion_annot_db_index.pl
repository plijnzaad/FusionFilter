#!/usr/bin/env perl

use strict;
use warnings;

use strict;
use warnings;
use Carp;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);
use TiedHash;


my $usage = <<__EOUSAGE__;

#####################################################################
#
# --gene_spans <string>     gene spans file
#
# --out_db_file <string>    output filename for database
#
# optional:
#
# --key_pairs <string>      annotations in key(tab)value format
#   
#
#####################################################################

__EOUSAGE__

    ;


my $help_flag;

my $gene_spans_file;
my $out_db_file;
my $key_pairs_file;

&GetOptions ( 'h' => \$help_flag,

              'gene_spans=s' => \$gene_spans_file,
              'out_db_file=s' => \$out_db_file,
              'key_pairs=s' => \$key_pairs_file,
    );

if ($help_flag) { die $usage; }

unless ($gene_spans_file && $out_db_file) { die $usage; }
              

main: {


    my $idx = new TiedHash( { create => $out_db_file } );
    
    open(my $fh, $gene_spans_file) or die "Error, cannot open file: $gene_spans_file";
    while (<$fh>) {
        chomp;
        my ($gene_id, $chr, $lend, $rend, $orient, $gene_name, $gene_type) = split(/\t/);
        if ($gene_name && $gene_name ne ".") {
            $gene_id = $gene_name;
        }

        $idx->store_key_value("$gene_id$;COORDS", "$chr:$lend-$rend:$orient"); # hacky way of specifying coordinate info for direct coordinate info lookups.
        if ($gene_type) {
            unless($idx->get_value($gene_id)) {
                # store at least the gene type info for the annotation string.
                $idx->store_key_value($gene_id, $gene_type);
            }
        }
    }
    close $fh;
    

    ## load in generic annotations:

    if ($key_pairs_file) {
        if ($key_pairs_file =~ /\.gz$/) {
            open($fh, "gunzip -c $key_pairs_file | ") or die "Error, cannot open( gunzip -c $key_pairs_file  )";
        }
        else {
            open($fh, $key_pairs_file) or die "Error, cannot read file $key_pairs_file";
        }

        while (<$fh>) {
            chomp;
            my ($gene_pair, $annot_string) = split(/\t/);
                
            $idx->store_key_value($gene_pair, $annot_string);
        }
        close $fh;
    }


    print STDERR "Done building annot db: $out_db_file\n";
    
    exit(0);
}
           
