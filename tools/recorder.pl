#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

use File::stat;

my $game_dir = $ENV{'HOME'} . '/.warsow-0.6/';
my $mod = 'promod';
my $ipc_dir = 'ipc/';
my $demo_dir = 'demos/server/';
my $delay = 1;
my $deadfile;

$ipc_dir = $game_dir . $mod . '/' . $ipc_dir;
$demo_dir = $game_dir . $mod . '/' . $demo_dir;
$deadfile = $ipc_dir . 'external/dead';

while (!deadfile_exists()) {
    delay();
}
while (1) {
    remove_internals();
    remove_deadfile();
    while (!deadfile_exists()) {
        handle_requests();
        delay();
    }
}
exit;

sub delay {
    sleep $delay;
}

sub deadfile_exists {
    if (-e $deadfile) {
        return 1;
    }
    return 0;
}

sub remove_internals {
    unlink glob $ipc_dir . 'internal/*';
}

sub remove_deadfile {
    unlink $deadfile;
}

sub handle_requests {
    my @numbers = glob $ipc_dir . 'internal/*';
    for my $number (@numbers) {
        $number =~ /(\d+)$/;
        $number = $1;
    }
    for my $number (sort {$a <=> $b} @numbers) {
        my $file = $ipc_dir . 'internal/' . $number;
        open my $in, '<', $file;
        while (my $command = <$in>) {
            handle_command($command);
        }
        close $in;
        unlink $file;
    }
}

sub handle_command {
    my($command) = @_;
    if ($command =~ /^record (.+)$/) {
        my(undef, $player, $start, $end) = split / /, $1;
        my @demos = glob $demo_dir . '*';
        my $latest;
        my $latest_time;
        for my $demo (@demos) {
            my $time = (stat $demo)->mtime;
            if (!defined $latest_time || $time > $latest_time) {
                $latest = $demo;
                $latest_time = $time;
            }
        }
        if (defined $latest) {
            system "replay/replay.pl '$latest' --mod $mod --audio"
                . " --player $player --start $start --end $end";
        } else {
            say 'No demo found :-(';
        }
    }
}
