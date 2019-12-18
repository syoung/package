package bwa;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	$version 	= 	$self->version() if not defined $version;

	#### INSTALL DEPENDENCIES
	my $arch	=	$self->getArch();
	$self->logDebug("arch", $arch);
	$self->runCommand("apt -y install zlib-dev") if $arch eq "ubuntu";
	$self->runCommand("yum -y install zlib-devel") if $arch eq "centos";

	$self->zipInstall($installdir, $version);

	#### CHANGE DIR
	$self->logDebug("DOING changDir($installdir/$version)");
  $self->changeDir("$installdir/$version");
	
	#### MAKE
	$self->runCommand("make");


	$version	=	$self->configInstall($installdir, $version);
		
	$self->confirmInstall($installdir, $version);

	return $version;
}


1;
