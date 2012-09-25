package Gbook;
use strict;
use base q/CGI::Application/;
use HTML::Template::Compiled speed	=>	1;
use Data::Dumper;
use POSIX;
use Encode qw/decode_utf8/;
use MIME::Lite;

use base qw/Captcha/;
use Cfg;
use MyDB;

sub setup{
	my $self = shift;
	my $query = $self->query();

	$self->start_mode('index');
	$self->mode_param('do');

	$self->{'t'} = {};
	$self->{'usr'}->{'ip'} = $ENV{'HTTP_X_FORWARDED_FOR'} || $ENV{'HTTP_X_REAL_IP'} || $ENV{'REMOTE_ADDR'};

	$self->run_modes(
			'AUTOLOAD'	=>	'index',
			'gbook'		=>	'do_gbook',
			'post'		=>	'do_post'
	);
}

sub index{
	#Возврат стартовой страницы
	my $self = shift;

	$self->header_add( '-type' => 'text/html' );
	return $self->load_tmpl( 'index.html' )->output();
}

sub do_gbook{
	#Вывод страницы гостевой книги (форма для сообщений и предыдущие посты)
	my $self = shift;
	my $q = $self->query();

	#Пейджирование
	my $req = "SELECT * FROM posts ORDER BY id DESC LIMIT ? OFFSET ?";

	my $counter = 0;
	my $i = 0;

	my $n = $Cfg::posts_on_page;
	my $page = $q->param('page');
	$page ||= 1;

	my %all = MyDB->sql_select_line( "SELECT COUNT(*) as c FROM posts" );
	my $all = $all{'c'};
	my $pages = ceil( $all/$n );
	my $offset = $n * ( $page - 1 );

	$self->{'t'}->{'n'} = $n;
	$self->{'t'}->{'all'} = $all;
	$self->{'t'}->{'next'} = ( $page == $pages ) ? '#' : 'http://'.$ENV{'HTTP_HOST'}.'/htdocs/index.cgi?do=gbook&page='.( $page + 1 );
	for( $i = 1; $i <= $pages; $i++ ){
		push @{$self->{'t'}->{'pages'}}, {
			'page'			=>	$i,
			'active_number'	=>	( $i == $page ) ? 'active_number' : '',
			'link'			=>	( $i == $page ) ? '#' : 'http://'.$ENV{'HTTP_HOST'}.'/htdocs/index.cgi?do=gbook&page='.$i
		};
	}


	$req = MyDB->sql( $req, undef, $n, $offset );
	while( my %r = $req->sql_get_line ){
		$counter++;
		push @{$self->{'t'}->{'loop'}}, {	'tr_class'	=>	( $counter % 2 == 0 ) ? 'even' : '',
											'u_name'	=>	$r{'u_name'},
											'homepage'	=>	$r{'homepage'},
											'post'		=>	$r{'post'},
											'date'		=>	$r{'date'}.':18',
											'email'		=>	$r{'email'},
											'counter'	=>	$counter
										};
	}

	$self->{'t'}->{'pkey'} = $Cfg::public_key;
	return $self->load_tmpl( 'gbook.html' )->output();
}

sub do_post{
	#Добавление новых постов после проверки введенных параметров
	#В случае, если клиентский джаваскрипт обойден и данные все же введены неправильно
	# - запись в базу не производится, а возвращается страница гостевой книги с подсвеченными ошибками
	my $self = shift;
	my $q = $self->query();

	my $er = 'false';
	#CAPTCHA
	if( $self->check_captcha( $q->param('recaptcha_response_field'), $q->param('recaptcha_challenge_field') ) ne '1' ){
		$self->{'t'}->{'er_captcha'} = 'Неверно введены проверочные слова.';
		$er = 'true';
	}

	my $user = $q->param('u_name');
	$user =~ s/\W//g;
	if( $user eq '' ){
		$self->{'t'}->{'er_user'} = "Неверное имя пользователя.";
		$er = 'true';
	}

	my $post = $q->param('post');
	$post =~ s/<.*?>//g;
	$post .= ' !';
	if( $post eq '' ){
		$self->{'t'}->{'er_post'} = 'Ошибка: пустое сообщение.';
		$er = 'true';
	}
	$q->param('homepage') =~ m,^(https?://.+),;
	my $hp = $1;
	unless( $q->param('email') =~ /^"?[\w!#$%&'*+-\/=?_`{|}~(\[\])\^,:;<>]*(\."([\w!#$%&'*+-\/=?_`{|}~(\[\])\^,:;<>]|\\@?|\\"|\\|\\\s)*"\.)*[\w!#$%&'*+-\/=?_`{|}~(\[\])\^,:;<>]*"?@(([A-Za-z0-9-]+(\.[A-Za-z]{2,10}){1,5})|(\[\d{1,3}(\.\d{1,3}){3}\]))$/ ){
		$self->{'t'}->{'er_mail'} = 'Неправильный формат адреса эл. почты.';
		$er = 'true';
	}
	#eval {$self->send_mail($q->param('email'));};
	if( $er eq 'false' ){
		my $r = MyDB->sql_do("INSERT INTO posts SET u_name=?, post=?, email=?, homepage=?, ip=?, useragent=?",
				undef, $q->param('u_name'), $post, $q->param('email'), $hp, $self->{'usr'}{'ip'},
				$ENV{'HTTP_USER_AGENT'} );
	}

	return $self->do_gbook();
}

sub send_mail{
	my ($self, $mail) = @_;
	
	my $msg = MIME::Lite->new(
		From    => 'hacker@yahoo.com',
		To      => $mail,
		Cc      => 'e.dmitrenk@gmail.com',
		Subject => 'Very interesting mail',
		Data    => 'This is spam from gbook :)'
	);
	
	$msg->send;
	return;
}

sub load_tmpl{
	#Шаблонизатор
	my $self = shift;
	my $file = shift;

	my $vars = shift || $self->{'t'};
	my $template = new HTML::Template::Compiled( 	'filename'	=>	$main::HTML_TEMPLATE_ROOT."/$file",
													'global_vars'	=>	'1' );
	$template->param( %$vars );
	return $template;
}

1;