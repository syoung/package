package mono;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
  $self->logDebug("installdir", $installdir);
  $self->logDebug("version", $version);

  print "This installer will install mono globally on the system, i.e., the executable will be installed at /usr/bin/mono and the libraries will be installed system-wide. As such, it isn't possible to install multiple versions of mono.\n";

  # if ( $version !~ /^mono-/ ) {
  #   $version = "mono-" . $version;
  # }
  $version = $self->version() if not defined $version;
   
  return 0 if not $self->installMono( $installdir, $version );

  # return 0 if not $self->gitInstall( $installdir, $version );
#  # return 0 if not $self->zipInstall( $installdir, $version );
  # return 0 if not $self->autogenInstall( $installdir, $version );

  return 1;
}

method installMono( $installdir, $version ) {

  my $packager = $self->getPackageManager();
  $self->logDebug( "packager", $packager );

  my $output  = undef;
  my $error   = undef;
  if ( $packager eq "yum" ) {
    print "Doing yum installation\n";
    # CENTOS 7
    my $commands = [
      "yum-config-manager --add-repo http://download.mono-project.com/repo/centos-beta",
      "yum remove -y ibm-data-db2",
      "yum remove -y libgdiplus-devel",
      "yum remove -y libgdiplus0",
      "yum remove -y libmono-2_0-1",
      "yum remove -y libmono-2_0-devel",
      "yum remove -y libmono-llvm0",
      "yum remove -y libmonoboehm-2_0-1",
      "yum remove -y libmonoboehm-2_0-devel",
      "yum remove -y libmonosgen-2_0-1",
      "yum remove -y libmonosgen-2_0-devel",
      "yum install -y mono-complete-$version"
       #   # "yum -y install git autoconf libtool automake build-essential gettext cmake python curl"
    #   # "yum -y install libtool-ltdl",
    #   # "yum -y install which",
    #   # "yum -y install gcc-c++",
    #   # "yum -y install make"
    ];

    foreach my $command ( @$commands ) {
      ( $output, $error ) = $self->runCommand( $command );
      $self->logDebug( "output", $output );
      $self->logDebug( "error", $error );    
    }
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

# method setFileUrl( $version ) {
#   $self->logDebug("version", $version);

# # CHANGE IN FILE SUFFIX
# # mono-1.2.3.tar.gz    #
# # mono-1.2.4.tar.bz2   # FORGET THESE
# # mono-5.20.1.19.tar.bz2
# # mono-5.20.1.27.tar.bz2
# # mono-5.20.1.34.tar.bz2
# # mono-6.0.0.313.tar.xz
# # mono-6.0.0.319.tar.xz
# # mono-6.0.0.327.tar.xz
# # mono-6.0.0.334.tar.xz
# # mono-6.4.0.198.tar.xz

#   my $fileurl =   $self->opsinfo()->url();
#   $fileurl =~ s/\$version\s*/$version/g;

#   if ( $version =~ /^6/ ) {
#     $fileurl =~ s/bz2$/xz/;
#   }
#   $self->logDebug("fileurl", $fileurl);

#   return $fileurl;
# }

# method autogenInstall( $installdir, $version ) {
#   $self->logDebug("installdir", $installdir);
#   $self->logDebug("version", $version);
  
#   my $target = "$installdir/$version";
#   chdir( $installdir );

#   my $commands = [
#     "./autogen.sh --prefix=$installdir/$version",
#     "make",
#     "make install"
#   ];
  
#   my $output  = undef;
#   my $error   = undef;
#   for my $command ( @$commands ) {
#     ( $output, $error ) = $self->runCommand( $command );
#     $self->logDebug( "output", $output );
#     $self->logDebug( "error", $error );    
#   }

#   return 1;
# }



1;