use lib 'lib';
use Mojolicious::Lite;

plugin 'parallol';

get '/' => sub {
  my $self = shift;
  my $ua = $self->ua;

  $self->stash(template => 'index');

  $ua->get('http://judofyr.net/', $self->parallol(sub {
    $self->stash(judo => pop->res->dom('title')->[0]->text);
  }));

  $ua->get('http://mojolicio.us/', $self->parallol(sub {
    $self->stash(mojo => pop->res->dom('title')->[0]->text);
  }));
};

app->start;

__DATA__

@@ index.html.ep
<%= $judo %> loves <%= $mojo %>

