use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'Parallol';

# Sleep for 0.5 seconds, then return 1 in the callback
sub one {
  my $c = pop;
  Mojo::IOLoop->timer(0.5, sub { $c->(1) });
}

get '/' => sub {
  my $self = shift;
  my $a = 0;
  my $b = 0;

  $self->on_parallol(sub { shift->render(text => $a + $b) } );

  one $self->parallol(weaken => 0, sub {
    $a = pop;
  });

  one $self->parallol(sub {
    $self->req;
    $b = pop;
  });
};

get '/stash' => sub {
  my $self = shift;
  one $self->parallol('a');
  one $self->parallol('b');
};

get '/nested' => sub {
  my $self = shift;

  $self->on_parallol(sub { shift->render('stash') });

  one $self->parallol(sub {
    $self->stash(a => pop);
    one $self->parallol('b');
  });
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_is(2);
$t->get_ok('/stash')->status_is(200)->content_like(qr/11/);
$t->get_ok('/nested')->status_is(200)->content_like(qr/11/);

done_testing;

__DATA__

@@ stash.html.ep
<%= $a %><%= $b %>

