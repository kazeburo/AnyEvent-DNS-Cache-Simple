package AnyEvent::DNS::Cache::Simple;

use 5.008005;
use strict;
use warnings;
use base qw/AnyEvent::DNS/;
use Cache::Memory::Simple;
use Data::Dumper;

our $VERSION = "0.01";

sub serialize_opt {
    my $value = shift;
    if ( defined $value && ref($value) ) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0; 
        local $Data::Dumper::Sortkeys = 1; 
        $value = Data::Dumper::Dumper($value);
    }
    $value;
}

sub resolve {
    my $cb = pop @_;
    my ($self, $qname, $qtype, %opt) = @_;
    my $cache_key = $qtype .':'. $qname . ':' . serialize_opt(\%opt);
    if ( my $cached = $self->{adcs_cache}->get($cache_key) ) {
        if ( @$cached == 0 ) {
            $cb->();
            return;
        }
        my @cached = @$cached; #copy
        if ( exists $self->{adcs_rr}{$cache_key} ) {
            $self->{adcs_rr}{$cache_key}++;
            $self->{adcs_rr}{$cache_key} = 0 if $self->{adcs_rr}{$cache_key} >= scalar @cached;
        } else {
            $self->{adcs_rr}{$cache_key} = 0;
        }
        my @spliced = splice @cached, 0, $self->{adcs_rr}{$cache_key};
        push @cached, @spliced;
        $cb->(@cached);
        return;
    }
    
    # request
    $self->SUPER::resolve($qname, $qtype, %opt, sub {
        if ( !@_ ) {
            $self->{adcs_cache}->set($cache_key, [], $self->{adcs_negative_ttl});
            $cb->();
            return;
        }
        $self->{adcs_cache}->set($cache_key, \@_, $self->{adcs_ttl});
        $self->{adcs_rr}{$cache_key} = 0;
        $cb->(@_);
    });
}

sub register {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $ttl = exists $args{ttl} ? delete $args{ttl} : 5;
    my $negative_ttl = exists $args{negative_ttl} ? delete $args{negative_ttl} : 1;
    my $cache = exists $args{cache} ? delete $args{cache} : Cache::Memory::Simple->new;

    my $old = $AnyEvent::DNS::RESOLVER;
    $AnyEvent::DNS::RESOLVER = do {
        no warnings 'uninitialized';
        my $resolver = AnyEvent::DNS::Cache::Simple->new(
            untaint         => 1,
            max_outstanding => $ENV{PERL_ANYEVENT_MAX_OUTSTANDING_DNS}*1 || 1,
            adcs_ttl => $ttl,
            adcs_negative_ttl => $negative_ttl,
            adcs_cache => $cache,
            adcs_rr => {},
            %args
        );
        if ( @{$resolver->{server}} == 0 ) {
            $ENV{PERL_ANYEVENT_RESOLV_CONF} 
                ? $resolver->_load_resolv_conf_file ($ENV{PERL_ANYEVENT_RESOLV_CONF})
                : $resolver->os_config;
        }
        $resolver;
    };
    AnyEvent::Util::guard {
        $AnyEvent::DNS::RESOLVER = $old;
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::DNS::Cache::Simple - Simple cache for AnyEvent::DNS

=head1 SYNOPSIS

    use AnyEvent::DNS::Cache::Simple;

    my $guard = AnyEvent::DNS::Cache::Simple->register(
        ttl => 60,
        negative_ttl => 5,
        timeout => 5
    );
    
    for my $i ( 1..3 ) {
        my $cv = AE::cv;
        AnyEvent::DNS::a "example.com", sub {
            say join " | ",@_;
            $cv->send;
        };
        $cv->recv;
    }
    
    undef $guard;

=head1 DESCRIPTION

AnyEvent::DNS::Cache::Simple provides simple cache capability for AnyEvent::DNS

CPAN already has AnyEvent::CacheDNS module. It also provides simple cache. 
AnyEvent::DNS::Cache::Simple support ttl, negative_ttl, dns-rr and changing any cache module.
And AnyEvent::DNS::Cache::Simple don't use AnyEvent->timer for purging cache.

=head1 METHOD

=head2 register

Register cache to <$AnyEvent::DNS::RESOLVER>. This method returns guard object.
If the guard object is destroyed, original resolver will be restored

register can accept all AnyEvent::DNS->new arguments and has some addtional arguments.

=over 4

=item ttl: Int

positive cache ttl in seconds. (default: 5)

=item negative_ttl: Int

negative cache ttl in seconds. (default: 1)

=item cache: Object

Cache object, requires support get and set methods.
default: Cache::Memory::Simple is used

=back

=head1 SEE ALSO

L<AnyEvent::DNS>, L<AnyEvent::Socket>, L<AnyEvent::CacheDNS>, L<Cache::Memory::Simple>

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

