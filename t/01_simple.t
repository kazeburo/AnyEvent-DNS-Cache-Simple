use strict;
use warnings;
use AnyEvent::DNS::Cache::Simple;
use Cache::Memory::Simple;
use Test::More;

my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname("google.com");

if( !$name or $length == 1 ) {
    plan skip_all => 'couldnot resolv google.com';
}

my $cache = Cache::Memory::Simple->new;
my $guard = AnyEvent::DNS::Cache::Simple->register(
    cache => $cache
);

for my $i ( 1..3 ) {
    my $cv = AE::cv;
    ok(!$cache->get('a:google.com:{}')) if $i == 1;
    AnyEvent::DNS::a "google.com", sub {
        ok(scalar @_);
        $cv->send;
    };
    $cv->recv;
    ok($cache->get('a:google.com:{}'));
}

undef $guard;

for my $i ( 1..3 ) {
    my $cv = AE::cv;
    AnyEvent::DNS::a "example.com", sub {
        ok(scalar @_);
        $cv->send;
    };
    $cv->recv;
    ok(!$cache->get('a:example.com:{}'));    
}

done_testing();

