#
# This file is part of IO-Socket-Timeout
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package PerlIO::via::Timeout::Strategy::AlarmWithReset;
{
  $PerlIO::via::Timeout::Strategy::AlarmWithReset::VERSION = '0.11';
}

# ABSTRACT: like L<PerlIO::via::Timeout::Strategy::Alarm>, but ECONNRESET after timeout

require 5.008;
use strict;
use warnings;
use Carp;
use Errno qw(ETIMEDOUT ECONNRESET);

use parent qw(PerlIO::via::Timeout::Strategy::Alarm);



sub new {
    $^O eq 'MSWin32'
      and croak "This Strategy is not supported on 'MSWin32'";
    return shift->SUPER::new(@_);
}

sub READ {
    my ($self, undef, undef, $fh) = @_;

    $self->{_is_invalid}
      and $! = ECONNRESET, return 0;

    my $rv = shift->SUPER::READ(@_);
    ($rv || 0) <= 0 && 0+$! == ETIMEDOUT
      and $self->{_is_invalid} = 1;

    return $rv;
}

sub WRITE {
    my ($self, undef, $fh, $fd) = @_;

    $self->{_is_invalid}
      and $! = ECONNRESET, return -1;

    my $rv = shift->SUPER::WRITE(@_);
    ($rv || 0) <= 0 && 0+$! == ETIMEDOUT
      and $self->{_is_invalid} = 1;

    return $rv;
}


sub is_valid { $_[0] && ! $_[0]->{_is_invalid} }


1;

__END__

=pod

=head1 NAME

PerlIO::via::Timeout::Strategy::AlarmWithReset - like L<PerlIO::via::Timeout::Strategy::Alarm>, but ECONNRESET after timeout

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use PerlIO::via::Timeout qw(timeout_strategy);
  binmode($fh, ':via(Timeout)');
  timeout_strategy($fh, 'Alarm', read_timeout => 0.5);

=head1 DESCRIPTION

This class implements a timeout strategy to be used by L<PerlIO::via::Timeout>.

This strategy is like L<PerlIO::via::Timeout::Strategy::Alarm> (it inherits
from it), but in addition, it adds this behaviour: once a timeout has been hit,
subsequent use of the handle will return undef and C<$!> will be set to
C<ECONNRESET>. This can be checked by using the C<is_valid> method.

=head1 METHODS

=head2 new

Constructor of the strategy. Takes as arguments a list of key / values :

=over

=item read_timeout

The read timeout in second. Can be a float

=item write_timeout

The write timeout in second. Can be a float

=item timeout_enabled

Boolean. Defaults to 1

=back

=head2 is_valid

  $strategy->is_valid()

Returns wether the socket from the strategy is still valid.

=head1 SEE ALSO

=over

=item L<PerlIO::via::Timeout>

=back

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
