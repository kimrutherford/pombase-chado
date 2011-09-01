#!/usr/bin/perl -w

use perl5i::2;
use Moose;

use Getopt::Long;
use lib qw(lib);
use YAML qw(LoadFile);

my $dry_run = 0;

if (!GetOptions("dry-run|d" => \$dry_run)) {
  usage();
}

if (@ARGV != 6) {
  die qq($0: needs six arguments:
  config_file   - the YAML format configuration file name
  import_type   - possibilities:
                    - "biogrid": interaction data in BioGRID BioTAB 2.0 format
                    - "gaf": GO gene association file format
  host          - the database server machine name
  database_name - the Chado database name
  username      - the database user name
  password      - the database password

usage:
  $0 <args> < input_file
);
}

my $config_file = shift;
my $import_type = shift;
my $host = shift;
my $database = shift;
my $username = shift;
my $password = shift;

use PomBase::Chado;
use PomBase::Chado::IdCounter;

my $chado = PomBase::Chado::db_connect($host, $database, $username, $password);

my $guard = $chado->txn_scope_guard;

my $config = LoadFile($config_file);

my $id_counter = PomBase::Chado::IdCounter->new();
$config->{id_counter} = $id_counter;

my %import_modules = (
  biogrid => 'PomBase::Import::BioGRID',
  gaf => 'PomBase::Import::GeneAssociationFile',
);

my $import_module = $import_modules{$import_type};
my $importer;

if (defined $import_module) {
  $importer =
    eval qq{
require $import_module;
$import_module->new(chado => \$chado, config => \$config);
    };
  die "$@" if $@;
} else {
  die "unknown type to import: $import_type\n";
}

open my $fh, '<-' or die;

$importer->load($fh);

$guard->commit unless $dry_run;
