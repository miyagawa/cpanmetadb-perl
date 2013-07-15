package CPANMetaDB::Dist;
use strict;

my $index;

sub new {
    my($class, $version, $distfile) = @_;
    bless { version => $version, distfile => $distfile }, $class;
}

sub lookup {
    my($class, $pkg) = @_;
    if (my $record = $index->lookup($pkg)) {
        $class->new(@$record);
    } else {
        return;
    }
}

package CPANMetaDB::Dist::Index;
use UnQLite;

sub new {
    my($class, $file) = @_;
    bless {
        db => UnQLite->open($file),
    }, $class;
}

sub add {
    my($self, $key, $value) = @_;
    $self->{db}->kv_store($key, join "|", @$value);
}

sub lookup {
    my($self, $key) = @_;
    my $val = $self->{db}->kv_fetch($key);
    if (defined $val) {
        return [ split /\|/, $val, 2 ];
    } else {
        return;
    }
}

package CPANMetaDB::Dist::Updater;
use AnyEvent;
use AnyEvent::HTTP;
use File::Temp;
use IO::Uncompress::Gunzip;
use HTTP::Date ();
use Time::HiRes;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->register;
    return $self;
}

sub register {
    my $self = shift;
    $self->{tmpdir} = File::Temp::tempdir;
    $self->{modified} = HTTP::Date::time2str(time - 600);

    $self->{t} = AE::timer 0, 300, sub {
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
        headers => {
            'If-Modified-Since' => $self->{modified},
        },
        on_body => sub {
            my($data, $hdr) = @_;
            print $fh $data;
        },
        sub {
            my (undef, $hdr) = @_;
            close $fh;

            if ($hdr->{Status} == 200) {
                warn "----> Download complete!\n";
                $self->{modified} = $hdr->{'last-modified'};
                $self->update_packages($file);
            } elsif ($hdr->{Status} == 304) {
                warn "----> Not modified since $self->{modified}\n";
            } else {
                warn "!!! Error: $hdr->{Status}\n";
            }
        };
}

sub update_packages {
    my($self, $file) = @_;

    my $time = Time::HiRes::gettimeofday;
    my $new_index;

    warn "----> Extracting packages from $file\n";
    my $z = IO::Uncompress::Gunzip->new($file);

    my $in_body;
    my $count = 0;
    while (<$z>) {
        chomp;
        /^Last-Updated: (.*)/
            and warn "----> Last updated $1\n";
        if (/^$/) {
            $in_body = 1;
            next;
        } elsif ($in_body) {
            $new_index = CPANMetaDB::Dist::Index->new("/tmp/cpanmetadb-$time.db")
                if $count % 10000 == 0;
            $count++;
            my($pkg, $version, $path) = split /\s+/, $_, 3;
            $new_index->add($pkg, [ $version, $path ]);
        }
    }

    warn "----> Complete! Updated $count packages\n";

    unlink $file;
    undef $new_index;

    $index = CPANMetaDB::Dist::Index->new("/tmp/cpanmetadb-$time.db");
}

1;
