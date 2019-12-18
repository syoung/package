package maxquant;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
    $self->logDebug("installdir", $installdir);
    $self->logDebug("version", $version);

    $version = $self->version() if not defined $version;
     
    return 0 if not $self->zipInstall( $installdir, $version );

    return 1;
}

method installDependencies() {

    my $packager = $self->getPackageManager();
    $self->logDebug( "packager", $packager );

    my $output  = undef;
    my $error   = undef;
    if ( $packager eq "yum" ) {
        # CENTOS 7
        my $commands = [
            "yum -y install unzip"
        ];

        foreach my $command ( @$commands ) {
            print "$command\n";
            ( $output, $error ) = $self->runCommand( $command );
            $self->logDebug( "output", $output );
            $self->logDebug( "error", $error );        
        }
    } 
    elsif ( $packager eq "apt" ) {
        # UBUNTU 18.04
        my $commands = [ 
            "apt install -y unzip"
        ];

        foreach my $command ( @$commands ) {
            print "$command\n";
            ( $output, $error ) = $self->runCommand( $command );
            $self->logDebug( "output", $output );
            $self->logDebug( "error", $error );        
        }
    }


}


1;