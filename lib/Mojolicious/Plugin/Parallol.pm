package Mojolicious::Plugin::Parallol;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app) = @_;

  $app->hook(before_dispatch => sub {
    my $self = shift;
    $self->{paralloling} = 0;
    $self->attr('parallol_done' => sub {
      sub { $self->render }
    });
  });
  
  $app->helper(
    parallol => sub {
      my ($self, $callback) = @_;

      $self->render_later;
      $self->{paralloling}++;

      sub {
        &$callback(@_);
        &{$self->parallol_done}($self) if --$self->{paralloling} == 0;
      }
    }
  );
}

1;

