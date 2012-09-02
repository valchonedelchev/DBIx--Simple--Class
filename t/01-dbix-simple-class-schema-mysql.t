#!perl

use 5.10.1;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  eval { require DBD::mysql; 1 }
    or plan skip_all => 'DBD::mysql is required for this test.';
  eval { DBD::mysql->VERSION >= 4.005 }
    or plan skip_all => 'DBD::mysql >= 4.005 required. You have only'
    . DBD::mysql->VERSION;
  use File::Basename 'dirname';
  use Cwd;
  use lib (Cwd::abs_path(dirname(__FILE__) . '/..') . '/examples/lib');
}


use DBI::Const::GetInfoType;
use Data::Dumper;
use_ok('DBIx::Simple::Class::Schema');

my $DSCS = 'DBIx::Simple::Class::Schema';
my $dbix;
eval {
  $dbix = DBIx::Simple->connect('dbi:mysql:database=test;host=localhost',
    $ENV{USER}, '', {mysql_enable_utf8 => 1});
}
  or plan skip_all => (
  $@ =~ /Can't connect to local/
  ? 'Please start MySQL on localhost to enable this test.'
  : $@
  );


isa_ok(ref($DSCS->dbix($dbix)), 'DBIx::Simple');
can_ok($DSCS, qw(load_schema dump_schema_at dump_class_at));


#create some tables
#=pod

$dbix->query('DROP TABLE IF EXISTS `users`');
$dbix->query(<<'TAB');
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL COMMENT 'Primary group for this user',
  `login_name` varchar(100) NOT NULL,
  `login_password` varchar(100) NOT NULL COMMENT 'Mojo::Util::md5_sum($login_name.$login_password)',
  `first_name` varchar(255) NOT NULL DEFAULT '',
  `last_name` varchar(255) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT 'email@domain.com',
  `description` varchar(255) DEFAULT NULL,
  `created_by` int(11) NOT NULL DEFAULT '1'  COMMENT 'id of who created this user.',
  `changed_by` int(11) NOT NULL DEFAULT '1' COMMENT 'Who modified this user the last time?',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'last modification time',
  `reg_tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'registration time',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `login_name` (`login_name`),
  UNIQUE KEY `email` (`email`),
  KEY `group_id` (`group_id`),
  KEY `reg_tstamp` (`reg_tstamp`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='This table stores the users'

TAB

#=cut

$dbix->query('DROP TABLE IF EXISTS `groups`');
$dbix->query(<<'TAB');
CREATE TABLE  IF NOT EXISTS groups(
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  group_name VARCHAR(12),
  `is blocked` INT,
  data TEXT

  ) DEFAULT CHARSET=utf8 COLLATE=utf8_bin
TAB


my $tables = $DSCS->_get_table_info();
$DSCS->_get_column_info($tables);
$DSCS->_generate_COLUMNS($tables);
$DSCS->_generate_ALIASES($tables);
ok((grep { $_->{TABLE_NAME} eq 'users' || $_->{TABLE_NAME} eq 'groups' } @$tables),
  '_get_table_info works');
my @column_infos = (@{$tables->[0]->{column_info}}, @{$tables->[1]->{column_info}});
is((grep { $_->{COLUMN_NAME} eq 'id' } @column_infos), 2, '_get_column_info works');
my %alaiases = (%{$tables->[0]->{ALIASES}}, %{$tables->[1]->{ALIASES}});
is((grep { $_ eq 'is_blocked' || $_ eq 'column_data' } values %alaiases),
  2, '_generate_ALIASES works');
TODO: {
  local $TODO = "load_schema, dump_schema_at and dump_class_at  not finished";
  warn $dbix->dbh->{Name};
  $DSCS->_generate_CHECKS($tables);
  warn Dumper($tables);

#load_schema
  warn Dumper($DSCS->load_schema);

#dump_schema_at

#dump_class_at
}


done_testing;
