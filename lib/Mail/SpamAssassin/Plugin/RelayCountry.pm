# <@LICENSE>
# Copyright 2004 Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>

=head1 NAME

RelayCountry - add message metadata indicating the country code of each relay

=head1 SYNOPSIS

  loadplugin     Mail::SpamAssassin::Plugin::RelayCountry

=head1 DESCRIPTION

By the RelayCountry plugin attempts to determine the domain country
codes of each relay used in the delivery path of messages and add that
information to the message metadata as "X-Relay-Countries".

=head1 REQUIREMENT

This plugin requires the IP::Country module from CPAN.

=cut

package Mail::SpamAssassin::Plugin::RelayCountry;

# Make the main dbg() accessible in our package w/o an extra function
*dbg=\&Mail::SpamAssassin::Plugin::dbg;

use Mail::SpamAssassin::Plugin;
use strict;
use warnings;
use bytes;

use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

# constructor: register the eval rule
sub new {
  my $class = shift;
  my $mailsaobject = shift;

  # some boilerplate...
  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsaobject);
  bless ($self, $class);
  return $self;
}

# and the eval rule itself
sub extract_metadata {
  my ($self, $opts) = @_;

  my $reg;

  eval {
    require IP::Country::Fast;
    $reg = IP::Country::Fast->new();
  };
  if ($@) {
    dbg("metadata: failed to load 'IP::Country::Fast', skipping");
    return 1;
  }

  my $msg = $opts->{msg};

  my $countries = '';
  foreach my $relay (@{$msg->{metadata}->{relays_untrusted}}) {
    my $ip = $relay->{ip};
    my $cc = $reg->inet_atocc($ip) || "XX";
    $countries .= $cc." ";
  }

  chop $countries;
  $msg->put_metadata ("X-Relay-Countries", $countries);
  dbg("metadata: X-Relay-Countries: $countries");

  return 1;
}

1;
