#!/usr/bin/perl -w
#Индексный файл
use strict;

BEGIN{
	my $prj_root = "../";
	unshift @INC, $prj_root.'lib';
	$ENV{'OF_INSTDIR'} = $prj_root;
	$ENV{'HTML_TEMPLATE_ROOT'} = $prj_root.'tmpl';
}

use CGI::Fast;
use CGI::Carp qw/fatalsToBrowser/;

eval{ require Gbook; };
if( $@ ){
	die "Could not load Gbook package in index.cgi $@";
}

while( my $q = new CGI::Fast ){
	$q->{'.charset'} = 'UTF-8';
	
	my $app;
	eval{ $app = new Gbook; };
	if( $@ ){
		die "Could not create new application in index.cgi $@";
	}
	
	delete $app->{'__QUERY_OBJ'};
	unless( $q->param('do') ){
		$q->param('do', $q->url_param('do'));
	}
	
	$app->query($q);
	$app->header_add( '-charset' => 'utf-8' );
	eval{ $app->run(); };
	$@ or next;
	die ':( '.$@;
}
