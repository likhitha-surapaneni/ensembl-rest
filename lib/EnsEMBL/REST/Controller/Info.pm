package EnsEMBL::REST::Controller::Info;

use Moose;
use namespace::autoclean;
use Bio::EnsEMBL::ApiVersion;
use Try::Tiny;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN {extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  map => {
    'text/plain' => ['YAML'],
  }
);

sub ping : Local : ActionClass('REST') :Args(0) { }

sub ping_GET {
  my ($self, $c) = @_;
  my ($dba) = @{$c->model('Registry')->get_all_DBAdaptors()};
  my $ping = 0;
  if($dba) {
    try {
      $dba->dbc()->work_with_db_handle(sub {
        my ($dbh) = @_;
        $ping = ($dbh->ping()) ? 1 : 0;
        return;
      });
    }
    catch {
      $c->log()->fatal('Cannot ping the database server due to error');
      $c->log()->fatal($_);
    };
  }
  $self->status_ok($c, entity => { ping => $ping}) if $ping;
  $self->status_gone($c, message => 'Database is unavailable') unless $ping;
  return;
}

sub rest : Local : ActionClass('REST') :Args(0) { }

sub rest_GET :Args(0) {
  my ($self, $c) = @_;
  $self->status_ok($c, entity => { release => $EnsEMBL::REST::VERSION});
  return;
}

sub software : Local : ActionClass('REST') :Args(0) { }

sub software_GET :Args(0) {
  my ($self, $c) = @_;
  my $release = Bio::EnsEMBL::ApiVersion::software_version();
  $self->status_ok($c, entity => { release => $release});
  return;
}

sub data : Local : ActionClass('REST') :Args(0) { }

sub data_GET :Args(0) {
  my ($self, $c) = @_;
  my $releases = $c->model('Registry')->get_unique_schema_versions();
  $self->status_ok($c, entity => { releases => $releases});
  return;
}

sub species : Local : ActionClass('REST') :Args(0) { }

sub species_GET :Local :Args(0) {
  my ($self, $c) = @_;
  my $division = $c->request->param('division');
  $self->status_ok($c, entity => { species => $c->model('Registry')->get_species($division)});
  return;
}

sub comparas : Local : ActionClass('REST') :Args(0) { }

sub comparas_GET :Local :Args(0) {
  my ($self, $c) = @_;
  $self->status_ok($c, entity => { comparas => $c->model('Registry')->get_comparas()});
  return;
}

__PACKAGE__->meta->make_immutable;

1;
