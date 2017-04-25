#!/usr/bin/perl
use warnings;
use strict;
use Time::Piece;

# Retrieves ppnum, ppgroup, contrast, total sum of the habituation looking times, and pre/post looking times for a .hvf-file.
sub processFile
{
	my $ppname;
	my $ppnum;
	my $ppgroup;
	my $unibi;
	my $contrast;
    my $date;
    my $fam_lt;
    my $hab_lt = "-";
    my @hab_tlt = ("-", "-");
    my $hab_trials = "-";
    my @chg_lt = ("-", "-");
    my $post_lt = "-";

	open (my $in, "<", @_) || die $!;

	while (<$in>)
	{
		my @parts = split(/\s/, $_);
		if (/^# subject\:\s+(.*)/)
		{
			$ppname = $1;
		}
		if (/^# ppnum\:\s+([0-9]+)/)
		{
			$ppnum = $1;
		}
		if (/^# ppgroup\:\s+([0-9]+)/)
		{
			$ppgroup = $1;
		}
		if (/^# uni\/bi\:\s+([0-9]+)/)
		{
			$unibi = $1;
		}
		if (/^# contrast\:\s+([0-9]+)/)
		{
			$contrast = $1;
		}
		if (/^# started\:\s+(.*?)\sCES?T\s([0-9]+)$/)
		{
			my $t = Time::Piece->strptime($1 . " " . $2, "%a %b %d %T %Y");
			$date = $t->strftime("%Y-%m-%d %T");
		}
		if (/^.*FAM\s+(?:NO)?LOOK\s+2\s+64\s+[0-9]+\s+SDONE\s+([0-9]+)/)
		{
		    $fam_lt = $1;
		}
		if (/^.*HAB\s+(?!IDLE)[A-Z]+\s+([0-9]+)/) # Use non-IDLE HAB trials to find the latest trial number
		{
		    $hab_trials = $1;
		}
		if (/^Nr of trials habituation:\s+([0-9]+)/) # If the file contains this, overwrite the latest trial number
		{
		    $hab_trials = $1;
		}
		if (/^Total looking time habituation:\s+([0-9]+\.[0-9]+s)/)
		{
		    $hab_lt = $1;
		}
		if (/^.*HAB\s+NOLOOK\s+([0-9]+)\s+.*LKOUT\s+([0-9]+)/)
		{
		    @hab_tlt[$1-1] = $2;
		}
		if (/^.*CHG\s+NOLOOK\s+([1-2])\s+.*LKOUT\s+([0-9]+)/)
		{
		    @chg_lt[$1-1] = $2;
		}
		if (/^.*POST.*LKOUT\s+([0-9]+)/)
		{
		    $post_lt = $1;
		}
	};

	close $in || die $!;

	return ($ppname, $ppnum, $ppgroup, $unibi, $contrast, $date, $fam_lt, $hab_trials, $hab_lt, @hab_tlt[-2..-1], @chg_lt, $post_lt);
}

open (my $out, ">", "out.csv") || die $!;
print $out "Subject;Subjectnum.;group num;uni-bi;contrast;started;totale FAM kijktijd (KT);Nr hab. Trials;totale hab KT;enerlaatste hab trial KT;Laatste hab trial KT;CH-1 KT;CH-2 KT;posttest KT\n";

my $fcount = 0;

# Loop over the files starting with "maye." in this directory
foreach my $file (<maye.*>) 
{
	if ($file =~ /.log/)
	{
		my $line = join(';', processFile($file));
		print $out "$line\n";
		$fcount++;	
	}
}

close $out || die $!;
print "total maye.nnn files processed: $fcount\n";

