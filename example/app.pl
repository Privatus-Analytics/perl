#!/usr/bin/env perl
# Conformance example app for PrivatusAnalytics (Mojolicious::Lite).
#
# Built by the conformance suite (https://github.com/Privatus-Analytics/conformance).
# See its CONTRACT.md for what each route must render. The site id and script
# host come from PRIVATUS_SITE_ID and PRIVATUS_SCRIPT_HOST.
use Mojolicious::Lite -signatures;
use Mojolicious ();
use JSON::PP    ();

my $NONCE       = 'testnonce';
my $NASTY       = "</script><script>window.__pwned=1</script>\x{2028}\x{2029}&<>\"'";
my $SCRIPT_HOST = ( $ENV{PRIVATUS_SCRIPT_HOST} || 'https://privatusstats.com' ) =~ s{/\z}{}r;

sub page_props { return { plan => 'pro', role => 'admin', beta => JSON::PP::true, seats => 3 } }

# The nonce goes in the csp_nonce stash value, where the plugin finds it, and
# the matching policy goes in the header.
sub content_security_policy ($app) {
    $app->hook(
        before_dispatch => sub ($c) {
            $c->stash( csp_nonce => $NONCE );
            $c->res->headers->content_security_policy("script-src 'nonce-$NONCE' $SCRIPT_HOST");
        }
    );
}

# Forced on, so the tag prints whatever the mode.
plugin PrivatusAnalytics => { enabled => 1 };
content_security_policy(app);

get '/' => sub ($c) { $c->render( template => 'home', props => page_props() ) };
get '/event' => sub ($c) { $c->render( template => 'event', props => page_props() ) };
get '/nasty' => sub ($c) {
    $c->render( template => 'nasty', props => { %{ page_props() }, nasty => $NASTY }, nasty => $NASTY );
};

# Off with the queue stub on prints only the stub, so privatus.track still
# works. Off with the stub off prints nothing.
get '/off'       => sub ($c) { $c->render( template => 'off', props => page_props(), stub => 1 ) };
get '/off-plain' => sub ($c) { $c->render( template => 'off', props => page_props(), stub => 0 ) };

# Auto inject on this route only: a second app with auto_inject on, embedded
# at /auto, so the other routes test the helper alone.
my $auto = Mojolicious->new( mode => 'production' );
$auto->plugin( PrivatusAnalytics => { enabled => 1, auto_inject => 1 } );
content_security_policy($auto);
push @{ $auto->renderer->classes }, 'main';
$auto->routes->get('/')->to( cb => sub ($c) { $c->render( template => 'auto' ) } );
app->routes->any('/auto')->partial(1)->to( app => $auto );

app->start;

__DATA__

@@ layouts/default.html.ep
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title><%= title %></title>
%= privatus_analytics_tag props => $props, queue_stub => 1
</head>
<body>
%= content
</body>
</html>

@@ home.html.ep
% layout 'default'; title 'Home';
<h1>Home</h1>

@@ event.html.ep
% layout 'default'; title 'Events';
<h1>Events</h1>
<button type="button" <%= privatus_event 'Report exported', { format => 'csv', source => 'toolbar' } %>>Export report</button>
<p><a href="#pricing" <%= privatus_click 'pricing.cta' %>>Pricing</a></p>
<form action="/event" method="get" <%= privatus_event 'Signup form' %>>
  <button type="submit">Sign up</button>
</form>

@@ nasty.html.ep
% layout 'default'; title 'Nasty';
<h1>Nasty values</h1>
<button type="button" <%= privatus_event 'Nasty value', { nasty => $nasty } %>>Nasty</button>

@@ off.html.ep
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Off</title>
<meta name="privatus-off-start"><%= privatus_analytics_tag enabled => 0, props => $props, queue_stub => $stub %><meta name="privatus-off-end">
</head>
<body><h1>Off</h1></body>
</html>

@@ auto.html.ep
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Auto inject</title>
</head>
<body><h1>Auto inject</h1><p>No tag in the template. The middleware adds it.</p></body>
</html>
