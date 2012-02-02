use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";

plugin 'Parallol';

# Sleep for 0.5 seconds, then return 1 in the callback
sub one {
  my $c = pop;
  Mojo::IOLoop->timer(0.5, sub { $c->(1) });
}

helper one => sub { one(@_); };

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

get '/instant' => sub {
  my $self = shift;

  $self->on_parallol(sub { shift->render('stash') });

  $self->parallol('a')->(1);
  $self->parallol('b')->(1);
};

my $r = app->routes;

$r->route('/app')->to('ParallolController#do_index');
$r->route('/app/stash')->to('ParallolController#do_stash');
$r->route('/app/nested')->to('ParallolController#do_nested');
$r->route('/app/instant')->to('ParallolController#do_instant');

my $t = Test::Mojo->new;
my $p;

eval {
  use Mojo::Server::PSGI;
  use Plack::Util;
  $p = Mojo::Server::PSGI->new;
};

sub t {
  my ($path, $content) = @_;
  $t->get_ok($path)->status_is(200)->content_like($content);

  if ($p) {
    my ($status, $header, $body) = @{$p->run({PATH_INFO => $path})};
    is $status, 200;
    my $full = "";
    Plack::Util::foreach($body, sub { $full .= shift });
    like $full, $content;
  }
}

# Lite
t '/', qr/2/;
t '/stash', qr/11/;
t '/nested', qr/11/;
t '/instant', qr/11/;

# Controller
t '/app', qr/2/;
t '/app/stash', qr/11/;
t '/app/nested', qr/11/;
t '/app/instant', qr/11/;

done_testing;

__DATA__

@@ stash.html.ep
<%= $a %><%= $b %>

