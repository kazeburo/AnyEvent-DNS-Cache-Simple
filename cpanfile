requires 'perl', '5.008001';
requires 'AnyEvent', '7.04';
requires 'Cache::Memory::Simple', '1.01';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

