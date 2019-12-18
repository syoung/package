package nextflow;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
    $self->logDebug("installdir", $installdir);
    $self->logDebug("version", $version);
    $version = $self->version() if not defined $version;
     
    # return 0 if not $self->gitInstall( $installdir, $version );

$version = "19.11.0-edge";
$self->version( $version );

    return 0 if not $self->autogenInstall( $installdir, $version );

    return 1;
}

method customTag ( $tag ) {
    $tag = "v" . $tag if not $tag =~ /^v/;

    return $tag;
}

method autogenInstall( $installdir, $version ) {
    $self->logDebug("installdir", $installdir);
    $self->logDebug("version", $version);

    my $dependencies = $self->dependencies();
    $self->logDebug( "dependencies", $dependencies );
    my $java = $dependencies->{java};
    my $envartext = $java->{envars};
    $self->logDebug( "envartext", $envartext );
    my $envars = $self->envarTextToArray( $envartext );
    $self->logDebug( "envars", $envars );
    $self->opsinfo()->envars( $envars );

    my $target = "$installdir/$version";
    chdir( $target );

    my $commands = [
        "$envars make compile",
        "make pack",
        # "make install"
    ];
    
    # my $output  = undef;
    # my $error   = undef;
    # for my $command ( @$commands ) {
    #     ( $output, $error ) = $self->runCommand( $command );
    #     $self->logDebug( "output", $output );
    #     $self->logDebug( "error", $error );        
    # }

    return 1;
}

method preInstall( $installdir, $version ) {
  
return 1;

    my $packager = $self->getPackageManager();
    $self->logDebug( "packager", $packager );

    my $output  = undef;
    my $error   = undef;
    if ( $packager eq "yum" ) {
        print "Doing yum installation\n";
        # CENTOS 7
        my $commands = [
            "yum -y install git autoconf libtool automake build-essential gettext cmake python curl",
            "yum -y install libtool-ltdl",
            "yum -y install which",
            "yum -y install gcc-c++",
            "yum -y install make"
        ];

        foreach my $command ( @$commands ) {
            ( $output, $error ) = $self->runCommand( $command );
            $self->logDebug( "output", $output );
            $self->logDebug( "error", $error );        
        }

        # my $command = qq{yum install -y mono};
        # $command .= "=$version" if defined $version and $version ne "";
        # ( $output, $error ) = $self->runCommand( $command );
        # $self->logDebug( "output", $output );
        # $self->logDebug( "error", $error );

    } 
    elsif ( $packager eq "apt" ) {
        print "Doing apt-get installation\n";
        # UBUNTU 18.04
        my $commands = [ 
            "apt install -y git autoconf libtool automake build-essential gettext cmake python curl",
            "apt install -y libtool",
            "apt install -y libtool-bin"
        ];

        foreach my $command ( @$commands ) {
            ( $output, $error ) = $self->runCommand( $command );
            $self->logDebug( "output", $output );
            $self->logDebug( "error", $error );        
        }
    }

    return 1;
}

method setFileUrl( $version ) {
    $self->logDebug("version", $version);

# CHANGE IN FILE SUFFIX
# mono-1.2.3.tar.gz      #
# mono-1.2.4.tar.bz2     # FORGET THESE
# mono-5.20.1.19.tar.bz2
# mono-5.20.1.27.tar.bz2
# mono-5.20.1.34.tar.bz2
# mono-6.0.0.313.tar.xz
# mono-6.0.0.319.tar.xz
# mono-6.0.0.327.tar.xz
# mono-6.0.0.334.tar.xz
# mono-6.4.0.198.tar.xz

    my $fileurl =   $self->opsinfo()->url();
    $fileurl =~ s/\$version\s*/$version/g;

    if ( $version =~ /^6/ ) {
        $fileurl =~ s/bz2$/xz/;
    }
    $self->logDebug("fileurl", $fileurl);

    return $fileurl;
}



1;