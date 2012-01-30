package Parallol;

use Mojo::Base -base;

our $VERSION = '1.00';

has on_done => sub { sub { } };

sub do {
  my ($self, $callback) = @_;

  $self->{paralloling}++;

  sub {
    $callback->(@_);
    $self->on_done->($self) if --$self->{paralloling} == 0;
  }
}

"Parallolololololololololol";

