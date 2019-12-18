package agent;
use Moose::Role;
use Method::Signatures::Simple;


use File::Path qw(make_path);
use File::Copy qw(move);

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	$version 	= 	$self->version() if not defined $version;
	
	print "Failed to download version: $version\n" and exit if not $self->zipInstall($installdir, $version);
	
	$self->createVersionDir( $installdir, $version );

	return $version;
}

method createVersionDir ( $installdir, $version ) {
	$self->logDebug("installdir", $installdir);
	my $installpath = "$installdir/$version";
	$self->logDebug("installpath", $installpath);

	File::Path::make_path( $installpath );
	chmod 0755, $installpath;
	# $self->runCommand( "chmod 755 $installdir" );
	File::Copy::move( "$installdir/LocatIt_v$version.jar", $installpath );
	File::Copy::move( "$installdir/SurecallTrimmer_v$version.jar", $installpath );

	return 1;
}


1;
