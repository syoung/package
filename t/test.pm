use MooseX::Declare;

=head2

	PACKAGE		test
	
	PURPOSE
	
		ROLE FOR GITHUB REPOSITORY ACCESS AND CONTROL

=cut

class test with (Util::Logger, Ops::Install) {
# class test with (Util::Logger) {

use Ops::Info;
has 'opsinfo' 	=> (
	is 			=>	'rw',
	isa 		=> 'Ops::Info'
);



# Boolean
has 'warn'			=> ( isa => 'Bool', is 	=> 'rw', default	=>	1	);
has 'help'			=> ( isa => 'Bool', is  => 'rw', required	=>	0, documentation => "Print help message"	);
has 'backup'		=> ( isa => 'Bool', is  => 'rw', default	=>	0, documentation => "Automatically back up files before altering"	);

# Int
has 'log'				=> ( isa => 'Int', is => 'rw', default 	=> 	4 	);  
has 'printlog'	=> ( isa => 'Int', is => 'rw', default 	=> 	2 	);
has 'sleep'			=> ( is  => 'rw', 'isa' => 'Int', default	=>	600	);
has 'upgradesleep'	=> ( is  => 'rw', 'isa' => 'Int', default	=>	600	);

# Str
has 'opsrepo'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'user' 			=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'password'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'host'			=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'envfile'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'hostname'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'cwd'				=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'envars'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempdir'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'hubtype'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 	);
has 'remote'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

#### Object
has 'db'				=> ( isa => 'Any', is => 'rw', required => 0 );
has 'ssh'				=> ( isa => 'Util::Ssh', is => 'rw', required	=>	0	);
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy => 1, builder => "setJsonParser" );

#### INITIALIZATION VARIABLES FOR Ops::GitHub
has 'owner'			=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'packagename'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'login'			=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'token'			=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'password'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'version'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'treeish'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'branch'		=> ( isa => 'Str|Undef', is => 'rw', default	=>	"master");
has 'keyfile'		=> ( isa => 'Str|Undef', is => 'rw', default	=>	''	);


method testModule ($pmfile) {
	print "pmfile: $pmfile\n";
	my ($opsdir, $modulename) = $pmfile =~ /^(.+?)\/([^\/]+)\.pm$/;
	print "opsdir: $opsdir\n";
	print "modulename: $modulename\n";



	$opsdir =~ s/$modulename$//;
	$self->loadOpsModule( $opsdir, $modulename );
	print "opsdir: $opsdir\n";


	# if ( -f $pmfile ) {
	# 	print "Found modulefile: $pmfile\n";
	# 	# print ""Doing require $modulename"\n";
	# 	unshift @INC, $opsdir;
	# 	my ($olddir) = `pwd` =~ /^(\S+)/;
	# 	print "olddir: $olddir\n";
	# 	chdir($opsdir);
	# 	eval "require $modulename";

	# 	Moose::Util::apply_all_roles($self, $modulename);
	# 	$self->doInstall();
		
	# }
	# else {
	# 	print "Can't find pmfile: $pmfile\n";
	# 	print "Deploy::setOps    Can't find pmfile: $pmfile\n";
	# 	exit;
	# }
}

method runCommand ($command) {
	#### RUN COMMAND LOCALLY OR ON REMOTE HOST
	#### ADD ENVIRONMENT VARIABLES IF EXIST
	
	my $pwd = $self->getPwd();
	$self->logDebug("FIRST pwd", $pwd);

	$command = $self->envars() . $command if defined $self->envars();

	if ( defined $self->ssh() ) {
		$self->logDebug("DOING ssh->execute($command)");
		return $self->ssh()->execute($command);
	}

	if ( defined $self->cwd() and $self->cwd() ) {
		chdir( $self->cwd() );
	}

	my $stdoutfile = "/tmp/$$.out";
	my $stderrfile = "/tmp/$$.err";
	my $output = '';
	my $error = '';
	
	#### TAKE REDIRECTS IN THE COMMAND INTO CONSIDERATION
	if ( $command =~ />\s+/ ) {
		#### DO NOTHING, ERROR AND OUTPUT ALREADY REDIRECTED
		if ( $command =~ /\s+&>\s+/
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>\s+/)
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>&1\s+/) ) {
			print `$command`;
		}
		#### STDOUT ALREADY REDIRECTED - REDIRECT STDERR ONLY
		elsif ( $command =~ /\s+1>\s+/ or $command =~ /\s+>\s+/ ) {
			$command .= " 2> $stderrfile";
			print `$command`;
			$error = `cat $stderrfile`;
		}
		#### STDERR ALREADY REDIRECTED - REDIRECT STDOUT ONLY
		elsif ( $command =~ /\s+2>\s+/ or $command =~ /\s+2>&1\s+/ ) {
			$command .= " 1> $stdoutfile";
			print `$command`;
			$output = `cat $stdoutfile`;
		}
	}
	else {
		$command .= " 1> $stdoutfile 2> $stderrfile";
		print `$command`;
		$output = `cat $stdoutfile`;
		$error = `cat $stderrfile`;
	}
	
	$self->logNote("output", $output) if $output;
	$self->logNote("error", $error) if $error;
	
	##### CHECK FOR PROCESS ERRORS
	$self->logError("Error with command: $command ... $@") and exit if defined $@ and $@ ne "" and $self->can('warn') and not $self->warn();

	#### CLEAN UP
	`rm -fr $stdoutfile`;
	`rm -fr $stderrfile`;
	chomp($output);
	chomp($error);
	
	$self->logDebug("LAST pwd", $pwd);
	if ( defined $self->cwd() and $self->cwd() ) {
		chdir($pwd);
	}

	return $output, $error;
}




}