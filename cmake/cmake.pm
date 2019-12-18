package cmake;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	$version 	= 	$self->version() if not defined $version;

	return if not $self->zipInstall($installdir, $version);

  return 0 if not $self->preBuild($installdir, $version);

	return 0 if not $self->customBuild($installdir, $version);	

#	$self->confirmInstall($installdir, $version);
	
	return 1;
}

method preBuild ($installdir, $version) {
  $self->logDebug("version", $version);
  $self->logDebug("installdir", $installdir);
  my $username = $self->username();
  $self->logDebug("username", $username);

  my $arch  = $self->getArch();
  $self->logDebug("arch", $arch);
  if ( $arch eq "ubuntu" ) {
    $self->runCommand("apt -y update");

    $applications = [
      "g++",
    ];

    foreach my $application ( @$applications ) {
      ( $stdout, $stderr ) =  $self->runCommand("apt -y install $application");
      $self->logDebug("stdout", $stdout);
      $self->logDebug("stderr", $stderr);
    }

  }
  elsif ( $arch eq "centos" ) {
    $applications = [
      "gcc-c++",
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
	
	#### CHANGE DIR
  $self->changeDir("$installdir/$version");
	
	#### MAKE
	$self->runCommand("./bootstrap");
	$self->runCommand("make");
	$self->runCommand("make install");
	
	return 1;
}


1;