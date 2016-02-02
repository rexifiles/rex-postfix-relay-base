#
# AUTHOR: Paul Williams <kwakwa@cpan.org>
# REQUIRES: postfix
# LICENSE: Apache License 2.0
#
# A Rex module to install Postfix as a mail relay on your Server.

package Rex::Postfix::Relay::Base;

use Rex -base;
use Rex::Ext::ParamLookup;

# The prepare task needs root privileges. Run as root.
task prepare => make {
  if (Rex::Config::get_user() ne 'root') {
    Rex::Logger::info "Please set rex user as root for this task (rex -u root)", 'error';
    return;
  }

  my $os = get_operating_system;
  unless ($os eq 'debian' or $os eq 'ubuntu') {
    Rex::Logger::info "Only Debian and Ubuntu have been tested for this package", 'error';
    return;
  }
  
  my $relay_host = param_lookup "postfix_relay_host", 'mail';

  my $version = run q!dpkg-query -W -f='${Status} ${Version}\n' postfix!;
  if ($version !~ m,not-installed,) {
    Rex::Logger::info "postfix has already been installed [$version]";
    return;
  }

  run q!debconf-set-selections <<< "postfix postfix/mailname string $(hostname -f)"!;
  run q!debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Satellite system'"!;
  run qq!debconf-set-selections <<< "postfix postfix/relayhost string $relay_host"!;
  run q!apt-get update && apt-get install -y postfix!;

  my $version = run q!dpkg-query -W -f='${Status} ${Version}\n' postfix!;
  if ($version !~ m,not-installed,) {
    Rex::Logger::info "postfix has been installed [$version]";
  }
  else {
    Rex::Logger::info "postfix didn't install";
  }
};

task setup => make {
  Rex::Logger::info "Setup has not been implemented, use the prepare method", 'error';
};

1;
