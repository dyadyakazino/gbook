#!/usr/bin/perl

use strict;
use warnings;

my @libs = ('CGI::Fast',
			'CGI::Carp',
			'CGI::Application',
			'HTML::Template::Compiled',
			'Data::Dumper',
			'POSIX',
			'Encode',
			'LWP::UserAgent',
			'Time::HiRes',
			'Exporter');
			
foreach (@libs) {
	my $libPath = $_ . '.pm';
	$libPath =~ s,::,/,g;
	print "Checking library $_ ...\n";
	eval { require $libPath; };
	print $@ if $@;
	
	eval { $_->import(); };
	print $@ if $@;
}