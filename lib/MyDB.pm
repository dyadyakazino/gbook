package MyDB;
#Пакет для работы с СУБД
use strict;
use Time::HiRes qw( gettimeofday tv_interval );
use base qw/Exporter/;

use Cfg;

my $orig_selectall_arrayref;
BEGIN {
    eval "use DBI";
    $orig_selectall_arrayref = \&DBI::db::selectall_arrayref;
}

our @EXPORT = (qw/dbh sql sql_do sql_prepare sql_execute sql_select_line sql_quote/);

my $dbh = undef;

sub dbh
{
  $dbh ||= DBI->connect(
        "DBI:mysql:database=gbook;host=$Cfg::db_host", $Cfg::db_user, $Cfg::db_pass,
        {'AutoCommit' => 1, 'RaiseError' => 0, 'PrintError' => 0}
  ) or die "Cannot connect: " . $DBI::errstr;
  return $dbh;
}

sub sql_quote
{
  my $self = shift;
  return $self->dbh->quote( @_ );
}

sub sql_do{
    my $self = shift;
    my $sql  = shift;
    my $tm_sql = [gettimeofday];
    my $dbh = &dbh();
    my $rows;
    my $show_sql = $sql;
    if( @_ && $sql =~ /\?/ ){
        my @p = @_;
        shift @p;
        map { s/\?/_/g } @p;
        map { $show_sql =~ s/\?/'$_'/ } @p;
    }
    eval{ $rows = $dbh->do( $sql, @_ ) };
    $tm_sql = sprintf "%.8f",tv_interval($tm_sql);
    if( $@ || !$rows){
       my $reason = $DBI::errstr;
       return $reason;
    }
    return [$rows, $tm_sql];
}

my $last_sql_id = 0;
my %sth = ();

sub sql_prepare{
    my $self = shift;
    my $sql  = shift;
    my $dbh  = &dbh();
    $last_sql_id++;
    my $show_sql = $sql;
    if( @_ && $sql =~ /\?/ ){
        my @p = @_;
        shift @p;
        map { ref $_ ? ($show_sql =~ s/\?/'%%%HIDDEN%%%'/) : ($show_sql =~ s/\?/'$_'/) } @p;
    }
    my $sth = $dbh->prepare( $sql, @_ );
    $sth{ $sth } = { dbh => $dbh, sql => $sql, sql_id => $last_sql_id };
    return $sth;
}

sub sql_select_line{
    my $self = shift;
    my $sql  = shift;
    my $sth  = MyDB->sql_prepare( $sql );
    $sth{ $sth }{param} = shift;
    my $res  = $sth->sql_execute( @_ );
    $res or return ();
    my $p = $sth->fetchrow_hashref;
    return $p ? %$p : ();
}

sub sql{
    my $self = shift;
    my $sql  = shift;
    my $sth  = MyDB->sql_prepare( $sql );
    $sth{ $sth }{param} = shift;
    $sth->sql_execute( @_ );
    return $sth;
}

package DBI::st;
use Time::HiRes qw( gettimeofday tv_interval );

sub sql_execute{
    my $sth = shift;
    if( !$sth ){
		#Prepare вернул ошибку
		return undef;
    }
    my $sql_id = $sth{ $sth }{sql_id};
    my $param = $sth{ $sth }{param};
    my $tm_sql = [gettimeofday];
    my $sql = $sth{$sth}{sql};
    if( @_ && $sql=~/\?/ ){
        my $i = 1 ;
        foreach my $p( @_ ){
            if( ref $param eq 'HASH' && $param->{"hide_param_$i"} ){
                $sql =~ s/\?/'%%%HIDDEN%%%'/;
            }
             else{
                $sql =~ s/\?/'$p'/;
            }
            $i++;
        }
    }
    my $res;
    eval{ $res = $sth->execute( @_ ) };
    $tm_sql = sprintf "%.8f", tv_interval($tm_sql);
    if( $@ || $sth->rows < 0 || !$res ){
       my $reason = $sth->errstr;
       return $reason;
    }

    return $res;
}

sub sql_get_line{
    my $sth = shift;
    my $p = $sth->fetchrow_hashref;
    return $p ? %$p : ();
}

sub selectall_arrayref{
    my $tm_sql = [gettimeofday];
    my $res;
    eval{ $res = &{$orig_selectall_arrayref}(@_) };
    my $rows = ref $res eq 'ARRAY'? scalar @$res: 0;
    $tm_sql = sprintf "%.8f", tv_interval($tm_sql);
    return [$res, $tm_sql];
}

1;
