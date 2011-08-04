package Mojolicious::Plugin::Parallol;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app) = @_;

  $app->hook(before_dispatch => sub {
    my $self = shift;
    $self->{paralloling} = 0;
    $self->attr(on_parallol => sub {
      sub { shift->render }
    });
  });
  
  $app->helper(
    parallol => sub {
      my ($self, $callback) = @_;

      $self->render_later;
      $self->{paralloling}++;

      sub {
        $callback->(@_);
        $self->on_parallol->($self) if --$self->{paralloling} == 0;
      }
    }
  );
}

1;

