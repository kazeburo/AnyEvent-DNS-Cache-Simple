# NAME

AnyEvent::DNS::Cache::Simple - Simple cache for AnyEvent::DNS

# SYNOPSIS

    use AnyEvent::DNS::Cache::Simple;

    my $guard = AnyEvent::DNS::Cache::Simple->register(
        ttl => 60,
        negative_ttl => 5
    );
    

    for my $i ( 1..3 ) {
        my $cv = AE::cv;
        AnyEvent::DNS::a "example.com", sub {
            warn join " | ",@_;
            $cv->send;
        };
        $cv->recv;
    }
    

    undef $guard;

# DESCRIPTION

AnyEvent::DNS::Cache::Simple provides simple cache capability for AnyEvent::DNS

CPAN already has AnyEvent::CacheDNS module. It also provides simple cache. 
AnyEvent::DNS::Cache::Simple support ttl, negative\_ttl, dns-rr and changing any cache module.
And AnyEvent::DNS::Cache::Simple don't use AnyEvent->timer for purging cache.

# METHOD

## register

Register cache to <$AnyEvent::DNS::RESOLVER>. This method returns guard object.
If the guard object is destroyed, original resolver will be restored

- ttl: Int

    positive cache ttl in seconds. (default: 5)

- negative\_ttl: Int

    negative cache ttl in seconds. (default: 1)

- cache: Object

    Cache object, requires support get and set methods.
    default: Cache::Memory::Simple is used

# SEE ALSO

[AnyEvent::DNS](http://search.cpan.org/perldoc?AnyEvent::DNS), [AnyEvent::Socket](http://search.cpan.org/perldoc?AnyEvent::Socket), [AnyEvent::CacheDNS](http://search.cpan.org/perldoc?AnyEvent::CacheDNS), [Cache::Memory::Simple](http://search.cpan.org/perldoc?Cache::Memory::Simple)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
