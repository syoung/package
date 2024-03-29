
package vcflib;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
    $self->logDebug("version", $version);
    $self->logDebug("installdir", $installdir);
    $version = $self->version() if not defined $version;
   
    return 0 if not $self->gitInstall($installdir, $version);
    return 0 if not $self->makeInstall($installdir, $version);
   
    return $version;
}

#### TAG TO BE CHECKED OUT
method customTag ( $tag ) {
  $tag = "v$tag" if $tag !~ /^v/;
  $self->logDebug("tag", $tag);

  return $tag;
}


1;
