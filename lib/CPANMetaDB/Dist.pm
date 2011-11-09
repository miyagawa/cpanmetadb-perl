package CPANMetaDB::Dist;
use strict;

my %dist;

sub lookup {
    my($class, $pkg) = @_;
    return $dist{$pkg};
}

sub update {
    my($class, $pkg, $data) = @_;
    return $dist{$pkg} = $data;
}

package CPANMetaDB::Dist::Updater;
use AnyEvent;
use AnyEvent::HTTP;
use File::Temp;
use IO::Uncompress::Gunzip;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->register;
    return $self;
}

sub register {
    my $self = shift;
    $self->{tmpdir} = File::Temp::tempdir;

    $self->{t} = AE::timer 0, 3600, sub {
        $self->fetch_packages;
    };
}

sub fetch_packages {
    my $self = shift;

    my $mirror = "http://cpan.metacpan.org";
    my $url    = "$mirror/modules/02packages.details.txt.gz";

    my $time = time;
    my $file = "$self->{tmpdir}/02packages.details.$time.txt.gz";
    open my $fh, ">", $file;

    warn "----> Start downloading $url\n";

    AnyEvent::HTTP::http_get $url,
        on_body => sub {
            my($data, $hdr) = @_;
            print $fh $data;
        },
        sub {
            my (undef, $hdr) = @_;
            close $fh;
            warn "----> Download complete!\n";

            if ($hdr->{Status} == 200) {
                $self->update_packages($file);
            } else {
                warn "!!! Error: $hdr->{Status}\n";
            }
        };
}

sub update_packages {
    my($self, $file) = @_;

    warn "----> Extracting packages from $file\n";
    IO::Uncompress::Gunzip::gunzip $file => \my $output;

    $output =~ /^Last-Updated: (.*)$/m
        and warn "----> Last updated $1\n";
    $output =~ s/^.*\r?\n\r?\n//s;

    open my $in, "<", \$output;
    my $count;
    while (<$in>) {
        $count++;
        chomp;
        my($pkg, $version, $path) = split /\s+/, $_, 3;
        CPANMetaDB::Dist->update($pkg, { version => $version, distfile => $path });
    }

    warn "----> Complete! Updated $count packages\n";

    unlink $file;
}

1;
