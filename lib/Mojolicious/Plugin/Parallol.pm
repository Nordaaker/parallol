package Mojolicious::Plugin::Parallol;

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util 'weaken';

sub register {
  my ($plugin, $app) = @_;

  $app->hook(before_dispatch => sub {
    my $self = shift;
    $self->{paralloling} = 0;
    $self->attr(on_parallol => sub {
      sub {
        my $self = shift;
        $self->render unless $self->stash('mojo.finished');
      }
    });
  });
  
  $app->helper(
    parallol => sub {
      my $callback = pop;
      my ($self, %opts) = @_;

      if (ref $callback && ref $callback eq 'CODE') {
        weaken($self) if $opts{weaken} // 1;
      } else {
        my $name = $callback;
        $callback = sub { $self->stash($name => pop) }
      }

      $self->render_later;
      $self->{paralloling}++;

      sub {
        eval { $callback->(@_); 1 } or $self->render_exception($@);
        $self->on_parallol->($self) if --$self->{paralloling} == 0;
      }
    }
  );
}

"Parallolololololololololol";

__END__

=head1 NAME

Mojolicious::Plugin::Parallol - Because parallel requests should be as
fun as parallololololol!

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Parallol');

  # Mojolicious::Lite
  plugin 'Parallol';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Parallol> provides a simple helper for managing
several parallel requests in the controller.

=head1 HELPERS

L<Mojolicious::Plugin::Parallol> implements the following helpers.

=head2 C<parallol>

Parallol optimizes for the common case: You want to call several
parallel requests and render the view when they're done.

  get '/' => sub {
    my $self = shift;

    $self->ua->get('http://bbc.co.uk/', $self->parallol(sub {
      $self->stash(bbc => pop->res->dom->at('title')->text);
    }));

    $self->ua->get('http://mojolicio.us/', $self->parallol(sub {
      $self->stash(mojo => pop->res->dom->at('title')->text);
    }));
  };

By wrapping a callback in C<< $self->parallol >> you mark the current
response as asynchronous (see L<Mojolicious::Controller/"render_later">)
and Parallol will render the view when all callbacks are called.

=head3 Automatic stashing

By passing a string to C<< $self->parallol >> it will stash the last
argument of the result instead. If we rewrite the previous example to
use a helper, we can simplify our controller quite a lot.

  get '/' => sub {
    my $self = shift;

    $self->title('http://bbc.co.uk/',    $self->parallol('bbc'));
    $self->title('http://mojolicio.us/', $self->parallol('mojo'));
  };

  helpers title => sub {
    my ($self, $url, $cb) = @_;
    $self->ua->get($url, sub {
      $cb->(pop->res->dom->at('title')->text);
    });
  };

It's recommended that you move as much logic to helpers and other
classes/methods so you can take advantage of automatic stashing.

=head3 Overriding "done" behavior

When you need to do more than just rendering the view you can override
the "done" callback:

  get '/' => sub {
    my $self = shift;
    $self->on_parallol(sub {
      shift->render(template => 'something_else');
    });
  };

=head3 $self weakening

In order to prevent memory leaks, Parallol will automatically C<weaken
$self>. This means that if you I<don't> refer to C<$self> in your
callback objects will magically disappear.

  # This controller will behave very strangely:
  get '/' => sub {
    my $self = shift;
    my $res = {};
    $self->ua->get('http://bbc.co.uk/', $self->parallol(sub {
      # There's no reference to $self in this block
      $res->{bbc} = pop->res->dom->at('title')->text;
    }));
  };

In these cases you can disabled weakening by passing in
C<< weaken => 0 >>.

  # This controller is fine:
  get '/' => sub {
    my $self = shift;
    my $res = {};
    $self->ua->get('http://bbc.co.uk/', $self->parallol(weaken => 0, sub {
      # There's no reference to $self in this block
      $res->{bbc} = pop->res->dom->at('title')->text;
    }));
  };

=head1 METHODS

L<Mojolicious::Plugin::Parrallol> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Parallol>

=head2 AUTHOR

Magnus Holm L<mailto:magnus@nordaaker.com>

=head2 LICENSE

This software is licensed under the same terms as Perl itself.

=cut
