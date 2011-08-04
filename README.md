Mojolicious::Plugin::Parallol
=============================

Because parallel requests should be as fun as parallololololol!

## Synopsis

Simply wrap your callbacks in `$self->parallol()` and the response will
only render when *all* your callbacks are done:

```perl
use Mojolicious::Lite;

plugin 'parallol';

get '/' => sub {
  my $self = shift;
  
  $ua->get('http://bbc.co.uk/', $self->parallol(sub {
    $self->stash('bbc', pop->res->dom);
  }));
  
  $ua->get('http://twitter.com/, $self->parallol(sub {
    $self->stash('twitter, pop->res->dom);
  }));
};
```

Or, if you need to do more advanced stuff:

```perl
use Mojolicious::Lite;

plugin 'parallol';

get '/' => sub {
  my $self = shift;
  my $foo;
  my $bar;
  
  $db->select('foo', $self->parallol(sub { $foo = pop }));
  $db->select('bar', $self->parallol(sub { $bar = pop }));

  $self->on_parallol(sub {
    $self->render(json => { foo => $foo, bar => $bar });
  });
};
```

