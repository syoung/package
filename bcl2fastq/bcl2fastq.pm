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

method zipInstall ($installdir, $version) {
	$self->logDebug("self->opsinfo", $self->opsinfo());
	
	my $fileurl = $self->setFileUrl($version);

	my ($filename)	=	$fileurl	=~ /^.+?([^\/]+)$/;
	$self->logDebug("filename", $filename);
	
	#### DELETE EXISTING DOWNLOAD
	my $filepath	=	"$installdir/$filename";
	$self->logDebug("filepath", $filepath);
	$self->runCommand("rm -fr $filepath") if -f $filepath;

	#### CHECK IF FILE IS AVAILABLE
	my $exists 	=	$self->remoteFileExists($fileurl);
	$self->logDebug("exists", $exists);
	if ( not $exists ) {
		$self->logDebug("Remote file does not exist. Exiting");
		print "Remote file does not exist: $fileurl\n";
		return 0;
	}
	
	#### DELETE DIRECTORY AND ZIPFILE IF EXIST
	my $targetdir = "$installdir/$version";
	`rm -fr $targetdir`;
	$self->logCritical("Can't delete targetdir: $targetdir") and exit if -d $targetdir;
	my $targetfile	=	"$installdir/$filename";
	`rm -fr $targetfile` if -f $targetfile;
	$self->logCritical("Can't delete targetfile: $targetfile") and exit if -d $targetfile;

	#### MAKE INSTALL DIRECTORY
	$self->makeDir($installdir) if not -d $installdir;	

	#$self->logger()->write("Changing to installdir: $installdir");
    $self->changeDir($installdir);

	#$self->logger()->write("Downloading file: $filename");
	$self->runCommand("wget -c $fileurl --output-document=$filename --no-check-certificate");
	
	$self->logDebug("filepath", $filepath);
	if ( -z $filepath ) {
		$self->logDebug("filepath not found", $filepath);
		print "Filepath not found: $filepath\n";

		return 0;
	}

	#### GET ZIPTYPE
	my $ziptype = 	"tar";
	$ziptype	=	"tgz" if $filename =~ /\.tgz$/;
	$ziptype	=	"bz" if $filename =~ /\.bz2$/;
	$ziptype	=	"zip" if $filename =~ /\.zip$/;
	$self->logDebug("ziptype", $ziptype);

	#### GET UNZIPPED FOLDER NAME
	my ($unzipped)	=	$filename	=~ /^(.+)\.tar\.gz$/;
	($unzipped)	=	$filename	=~ /^(.+)\.tgz$/ if $ziptype eq "tgz";
	($unzipped)	=	$filename	=~ /^(.+)\.tar\.bz2$/ if $ziptype eq "bz";
	($unzipped)	=	$filename	=~ /^(.+)\.zip$/ if $ziptype eq "zip";
	if ( defined $self->opsinfo()->unzipped() ) {
		$unzipped	=	$self->opsinfo()->unzipped();
		$unzipped	=~ s/\$version\s*/$version/g;
	}
	$self->logDebug("unzipped", $unzipped);

	#### REMOVE UNZIPPED IF EXISTS AND NO 'asterisk'
	$self->runCommand("rm -fr $unzipped") if $unzipped !~ /\*/;

	#### SET UNZIP COMMAND
    $self->changeDir($installdir);
	my $command	=	"tar xvfz $filename"; # tar.gz AND tgz
	$command	=	"tar xvfj $filename" if $ziptype eq "bz";
	$command	=	"unzip $filename" if $ziptype eq "zip";
	$self->logDebug("command", $command);

	#### UNZIP AND CHANGE UNZIPPED TO VERSION
	$self->runCommand($command);	
	$self->runCommand("mv $unzipped $version");	
	
	#### REMOVE ZIPFILE
	$self->runCommand("rm -fr $filename");
	
	### CHECK !!!
	# my $packagename	=	$self->opsinfo()->packagename();
	#$self->logger()->write("Completed installation of $packagename, version $version");
	
	$self->version($version);
	
	return 1;
}




1;
