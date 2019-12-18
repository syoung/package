package bamtools;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);

	$self->gitInstall($installdir, $version);

	$self->makeInstall($installdir, $version);	

	$self->confirmInstall($installdir, $version);
	
	return 1;
}

#### SET 'v' IN VERSION (e.g.: v2.5.1)
method getTarget ( $version ) {
	$self->logDebug("version", $version);
	my $target = $version;
	$target =~ s/^v//g;

	return $target;
}

#### TAG TO BE CHECKED OUT
method customTag ( $tag ) {
	$tag = "v$tag" if $tag !~ /^v/;
	$self->logDebug("tag", $tag);

	return $tag;
}

method makeInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	my $username = $self->username();
	$self->logDebug("username", $username);

  my $query = "SELECT installdir FROM package 
WHERE packagename='cmake'";
	$self->logDebug("query", $query);
  my $cmakedir = $self->table()->db()->query( $query );
  $self->logDebug("cmakedir", $cmakedir);

	#### CREATE BUILD DIR
	my $builddir	=	"$installdir/$version/build";
	`mkdir -p $builddir` if not -d $builddir;
	
	#### CHANGE DIR
  $self->changeDir($builddir);
	
	#### MAKE
	$self->runCommand("$cmakedir/bin/cmake ..");

	$self->runCommand("make");

	return 1;
}


1;
