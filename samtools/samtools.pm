package samtools;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);

	return 0 if not $self->gitInstall($installdir, $version);

  return 0 if not $self->preBuild($installdir, $version);

	return 0 if not $self->customBuild($installdir, $version);	

	#$self->confirmInstall($installdir, $version);
	
	return 1;
}

method preBuild ($installdir, $version) {
  $self->logDebug("version", $version);
  $self->logDebug("installdir", $installdir);
  my $username = $self->username();
  $self->logDebug("username", $username);

  # See INSTALL file in repo for dependencies  
  my $arch  = $self->getArch();
  $self->logDebug("arch", $arch);
  my ( $stdout, $stderr );
  my $applications = [];
  if ( $arch eq "ubuntu" ) {
    $self->runCommand("apt -y update");

    $applications = [
      "libncurses5 libncurses5-dev",
      "autoconf automake make gcc perl",
      "zlib1g zlib1g-dev",
      "libbz2-1.0 libbz2-dev",
      "liblzma liblzma-dev",
      "libcurl4 libcurl4-gnutls-dev",
      "libssl-dev",
      "libbzip2",
    ];

    foreach my $application ( @$applications ) {
      ( $stdout, $stderr ) =  $self->runCommand("apt -y install $application");
      $self->logDebug("stdout", $stdout);
      $self->logDebug("stderr", $stderr);
    }

  }
  elsif ( $arch eq "centos" ) {
    $applications = [
      "autoconf automake make gcc perl-Data-Dumper",
      "zlib zlib-devel",
      "bzip2 bzip2-devel ",
      "xz xz-devel ",
      "curl curl-devel",
      "openssl openssl-devel",
      "ncurses ncurses-devel",
    ];

    foreach my $application ( @$applications ) {
      ( $stdout, $stderr ) =  $self->runCommand("yum -y install $application");
      $self->logDebug("stdout", $stdout);
      $self->logDebug("stderr", $stderr);
    }
  }

  return 1;
}

method customBuild ($installdir, $version) {
  $self->logDebug("version", $version);
  $self->logDebug("installdir", $installdir);
  my $username = $self->username();
  $self->logDebug("username", $username);

  #### CHANGE DIR
  $self->logDebug("DOING changeDir($installdir/$version)");
  $self->changeDir("$installdir/$version");
  
  my $query = "SELECT installdir FROM package 
WHERE username='$username' 
AND packagename='htslib' 
AND version='$version'";
	$self->logDebug("query", $query);
  my $htsdir = $self->table()->db()->query( $query );
  $self->logDebug("htsdir", $htsdir);
  
  #### MAKE
  my ( $stdout, $stderr );
  my $commands = [
    "autoheader",
    "autoconf -Wno-syntax",
    "./configure  --with-htslib=$htsdir",
    "make",
  ];

  foreach my $command ( @$commands ) {
    ( $stdout, $stderr ) =  $self->runCommand( $command );
    $self->logDebug("stdout", $stdout);
    $self->logDebug("stderr", $stderr);
  }
  return 1;
}


1;
