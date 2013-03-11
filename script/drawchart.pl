#!/usr/bin/env perl
use strict;
use Time::Piece;

sub versionify {
    my $v = shift;
    $v =~ /^5\.(\d{3})(\d{3})/
      and return join '.', 5, $1+0, $2+0;
}

my(%uniq, %versions);

while (<>) {
    my @line = split / /, $_;
    my($ip, $perl) = @line[0, 12];
    if ($perl =~ /^perl\/(5\.\d{6})"$/) {
        $uniq{"$ip-$1"}++ or $versions{$1}++;
    }
}

my $js_data = join ",\n", map { "[ '@{[versionify($_)]}', $versions{$_} ]" } sort keys %versions;

my $time = Time::Piece->new;
my $date = $time->ymd;

print <<HTML;
<html>
    <head>
      <title>Perl versions used with cpanm: $date</title>
      <script type="text/javascript" src="https://www.google.com/jsapi"></script>
      <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Version', 'Requests'],
          $js_data
        ]);

        var options = {
          title: 'Perl versions used with cpanm'
        };

        var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
    </script>
    </head>
  <body>
    <div id="chart_div" style="width: 900px; height: 500px;"></div>
    <p class="note">This graph is based on the sample requests sent to the <a href="http://cpanmetadb.plackperl.org/">CPAN Meta DB</a> from cpanm (version 1.604 or later).</p>
  </body>
</html>
HTML
