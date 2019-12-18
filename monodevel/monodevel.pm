package monodevel;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
    $self->logDebug("version", $version);
    $self->logDebug("installdir", $installdir);
    $version = $self->version() if not defined $version;
     
    return 0 if not $self->addMonoRepo( $installdir, $version );

    return $version;
}

method addMonoRepo ($installdir, $version) {
    
    my $packager = $self->getPackageManager();
    $self->logDebug( "packager", $packager );

    # https://www.monodevelop.com/download/#fndtn-download-lin-centos
    my $output  = undef;
    my $error   = undef;
    if ( $packager eq "yum" ) {
        print "Doing yum installation\n";
        # CENTOS 7
        my $commands = [
            qq{rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"},
            qq{su -c 'curl https://download.mono-project.com/repo/centos7-vs.repo | tee /etc/yum.repos.d/mono-centos7-vs.repo'},
        ];

        foreach my $command ( @$commands ) {
            ( $output, $error ) = $self->runCommand( $command );
            $self->logDebug( "output", $output );
            $self->logDebug( "error", $error );        
        }

        my $command = qq{yum install -y mono};
        $command .= "=$version" if defined $version and $version ne "";
        ( $output, $error ) = $self->runCommand( $command );
        $self->logDebug( "output", $output );
        $self->logDebug( "error", $error );

    } 
    elsif ( $packager eq "apt" ) {
        print "Doing apt-get installation\n";
        # UBUNTU 18.04
        my $commands = [ 
            "sudo apt install apt-transport-https dirmngr",
            "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF",
            qq{echo "deb https://download.mono-project.com/repo/ubuntu vs-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-vs.list},
            "sudo apt update",
            "sudo apt-get install monodevelop"
        ];

        foreach my $command ( @$commands ) {
            ( $output, $error ) = $self->runCommand( $command );
            $self->logDebug( "output", $output );
            $self->logDebug( "error", $error );        
        }
    }

    return 1;
}




1;