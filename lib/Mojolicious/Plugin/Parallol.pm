package Mojolicious::Plugin::Parallol;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app) = @_;

  $app->hook(before_dispatch => sub {
    my $self = shift;
    $self->attr(paralloling => 0);
    $self->attr('parallol_done' => sub {
      sub { $self->render }
    });
  });
  
  $app->helper(
    parallol => sub {
      my ($self, $callback) = @_;

      $self->render_later;
      $self->paralloling($self->paralloling + 1);

      sub {
        &$callback(@_);
        $self->paralloling($self->paralloling - 1);

        &{$self->parallol_done} if ($self->paralloling == 0);
      }
    }
  );
}

1;

