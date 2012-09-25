package Captcha;
#Пакет для общения с сервером API reCAPTCHA
use strict;
use LWP::UserAgent;
use Data::Dumper;

use Cfg;

sub check_captcha{
	my ( $self, $rf, $cf ) = @_;
	
	my $resp = $self->send_post( $Cfg::captcha_url, {	'privatekey'	=> $Cfg::private_key,
														'remoteip'		=> $self->{'usr'}{'ip'},
														'challenge'		=> $cf,
														'response'		=> $rf
													} 
								);
	my ( $res, $reason ) = split( /\n/, $resp );

	$res eq 'true' ? return '1' : $reason;
}

sub send_post{
	my ( $self, $url, $content ) = @_;
	my $ua = LWP::UserAgent->new();
	$ua->requests_redirectable(['POST']);
	my $response = $ua->post($url, $content);
	return $response->content;
}

1;