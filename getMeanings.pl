#!/usr/bin/perl

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;
use warnings;
use Encode qw(encode_utf8);
#use URI::Escape;
#use diagnostics;

my $wordsFileName = "1000";
my $outputFileName = "outFile";

print "Begin parsing word list...\n\n";

open(wordsFile,  "<",  $wordsFileName)  or die "Can't open file: $!";
open(outputFile, ">> $outputFileName") or die "Can't open file: $!";

select((select(outputFile), $|=1)[0]);

while (<wordsFile>) { # assigns each line in turn to $_
    my $word = $_;
    print "Just read $_";
    my $data = GetRawDef($word);
    print "...got data";
    my $def = ProcessDef($data);
    print "...processed";
    my $card = "\\card{$word}{$def}\n";
    print outputFile "$card";
    print "...written\n";
    sleep 2;
}

print "\nWe are done... Thank you.\n";


#  http://api.wordreference.com/{api_version}/{API_key}/json/{dictionary}/{term}

sub GetRawDef {
    
    my $word = shift;
#    $word =  uri_escape($word);
    my $wordurl = "http://api.wordreference.com/APIKEY/json/fren/$word"; #set api key
 
    my $json;
    while ( ! defined $json) {
       print "...getting url";
       $json = get( $wordurl );
       sleep 5;
    }
#    die "Could not get $wordurl!" unless defined $json;

    $json = encode_utf8( $json );

    # Decode the entire JSON
    my $data = decode_json( $json );

    return $data;
}


sub ProcessDef {
    
    my $data = shift;

    # get a list of first level keys
    my @keys1 = keys $data;

    #print "@keys1\n";

    # keep needed one
    my @keys1n;
    foreach (@keys1) {
	if ($_ =~ /term/) {
	    $keys1n[$#keys1n+1] = $_;
	}
    }
    # and sort them
    @keys1n = sort @keys1n;

    #print "@keys1n\n";
    my $def = "";

    # now iterate in
    foreach my $k1 (@keys1n) {

        #print "$k1\n";
	# get list of integers and sort them
	if ( exists $data->{"$k1"}{"PrincipalTranslations"} ) {
	    my $principal = $data->{"$k1"}{"PrincipalTranslations"};
	    my @integers = keys $principal;
	    @integers = sort @integers;

	    foreach my $k2 (@integers) {
		
		#	print "$k2\n";
		# get list of translations for each integer
		my $intlist = $principal->{"$k2"};
		my @translations = keys $intlist;
		
		#print "@translations\n";
		my $pos;
		my $sense;
		my @terms = ();
		foreach my $k3 (@translations) {
		    
		    #print "$k3\n";
		    # now do a bit of parsing
		    if ($k3 =~ /Term/) {#do this for the original term
			$pos = $intlist->{"$k3"}{"POS"};
			$sense = $intlist->{"$k3"}{"sense"};
		    } elsif ($k3 =~ /Translation/) { #add a meaning
			my $tx = $intlist->{"$k3"}{"term"};
			$terms[$#terms+1] = "$tx,";
		    }
		    
		}
		# now you one set of meanings of the word
		#	print "@terms\n";
		
		my $mean = "\{\\bfseries @terms \} $pos \n";
		#	print "$mean";
		$def = "$def\n$mean";
		
	    }
	}
	
	#    print "$def";
    }
    
    #print "$def";
    return $def;
}

