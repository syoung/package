package blat;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);

	# $self->zipInstall($installdir, $version);

	# $self->makeInstall($installdir, $version);

	$self->confirmInstall($installdir, $version);
	
	return 1;
}

method makeInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	
	my ($stdout, $stderr);
	my $arch = $self->getArch();
	$self->logDebug("arch", $arch);
	if ( $arch eq "centos" ){
		($stdout, $stderr) = $self->runCommand("rm -fr /var/run/yum.pid");		
		$self->logDebug("stdout", $stdout);
		$self->logDebug("stderr", $stderr);
		($stdout, $stderr) = $self->runCommand("yum install -y libpng-devel");
		$self->logDebug("stdout", $stdout);
		$self->logDebug("stderr", $stderr);
	}
	elsif ( $arch eq "ubuntu" ) {
		($stdout, $stderr) = $self->runCommand("apt-get -y update");
		($stdout, $stderr) = $self->runCommand("apt-get -y install libpng-dev");
		$self->logDebug("stdout", $stdout);
		$self->logDebug("stderr", $stderr);
	}
	else {
		print "Architecture not supported: $arch\n" and exit;
	}

	#### CHANGE DIR
  $self->changeDir("$installdir/$version");

	#### CHANGE BIN DIR IN .mk FILE common.mk
	my $targetfile	=	"$installdir/$version/inc/common.mk";
	my $backupfile	=	"$installdir/$version/inc/common.mk.bkp";
	`mv $targetfile $backupfile` if -f $targetfile;
	`mkdir -p $installdir/$version/bin`;
	my $filepath = "$installdir/$version";
	$filepath =~ s/\//\\\//g;
	my $command 	= 	"sed 's/\${HOME}\\/bin\\/\${MACHTYPE}/$filepath\\/bin/' $backupfile > $targetfile";
	$self->logDebug("command", $command);
	print `$command`;
	
	#### MAKE
	($stdout, $stderr) = $self->runCommand("export MACHTYPE=x64_86; make");
	$self->logDebug("stdout", $stdout);
	$self->logDebug("stderr", $stderr);

	$self->runCommand("export MACHTYPE=x64_86; make ebseq");
	
	return 1;
}


1;
