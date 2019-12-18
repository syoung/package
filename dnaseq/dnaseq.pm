package dnaseq;
use Moose::Role;
use Method::Signatures::Simple;

require YAML::Tiny;

method doInstall ($installdir, $version) {
  $self->logDebug("version", $version);
  $self->logDebug("installdir", $installdir);
  $version = $self->version() if not defined $version;
  
  # return 0 if not $self->gitInstall($installdir, $version);

  $version = $self->version();
  $self->logDebug("AFTER gitInstall  version", $version);

  #### LOAD APP FILES
  my $username  =   $self->username();
  my $packagename  =   $self->packagename();
  my $appdir    =   "$installdir/$version/conf/app";
  my $format    =   "yaml";

  $self->logDebug("Doing loadAppFiles");
	print "App load failed\n" and return 0 if not $self->loadAppFiles($username, $packagename, $installdir, $appdir, $format);

  $self->logDebug("Doing loadWorkflows");
  print "Workflow load failed\n" and return 0 if not $self->loadWorkflows($installdir, $version);

  $self->logDebug("Doing loadSampleData");
  print "Sample load failed\n" and return 0 if not $self->loadSampleData($installdir, $version);

  # return 0 if not $self->loadData($installdir, $version);
  
  
  return $version;
}

method loadWorkflows ($installdir, $version) {
  $self->logDebug("installdir", $installdir);
  $self->logDebug("version", $version);
  
  my $basedir =   $self->conf()->getKey("core:INSTALLDIR");
  my $username  =   $self->username();
  $self->logDebug("basedir", $basedir);
  $self->logDebug("username", $username);
  
  #### ADD WORKFLOWS
  my $projects = [
    {
      project =>  "Align",
      workflows   =>  [
        "Bwa"
      ]
    }
    ,
    {
      project =>  "DnaSeq",
      workflows   =>  [
        "FixMates",
        "FilterReads",
        "MarkDuplicates",
        "AddReadGroups",
        "QualityFilter",
        "IndelRealignment",
        "BaseRecalibration",
        "HaplotypeCaller"
      ]
    }
    ,
    {
      project =>  "Fork",
      workflows   =>  [
        "FastQcFork",
        "HetHomFork",
        "TsTvFork",
        "RelatednessFork"
      ]
    }
    ,
    {
      project =>  "QC",
      workflows   =>  [
        "All"
      ]
    }
  ];
  
  
  foreach my $project ( @$projects ) {
    my $projectname   =   $project->{project};
    my $subfolder = lc($projectname);
    print "Loading workflows for project '$projectname'\n";
    $self->logDebug("projectname", $projectname);

    #### CREATE PROJECT
    my ($query, $success);
    $query = "DELETE FROM project
WHERE username='$username'
AND projectname='$projectname'";
    $self->logDebug("query", $query);
    $success = $self->table()->db()->do( $query );
    $self->logDebug("success", $success);

    $query = "INSERT INTO project (username, projectname)
VALUES ( '$username', '$projectname' )";
    $success = $self->table()->db()->do( $query );
    $self->logDebug("success", $success);

    #### ADD WORKFLOWS TO PROJECT
    my $workflownames   =   $project->{workflows};
    my $table = "workflow";
    my $requiredfields = [ "username", "projectname", "workflowname" ];
    my $workflownumber = 1;
    foreach my $workflowname ( @$workflownames ) {
      my $inputfile = "$installdir/$version/conf/work/$subfolder/$workflowname.work";
      $self->logDebug("inputfile", $inputfile);
      my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;
      my $object   =   $$yaml[0];
      my $fields = $self->table()->db()->fields( $table );
      $self->logDebug("fields", $fields);
      my $workflow = {};
      foreach my $field ( @$fields ) {
        if ( exists $object->{$field} and $object->{$field} ) {
          $workflow->{$field} = $object->{$field};
        }
      }
      $workflow->{username} = $username;
      $workflow->{projectname} = $projectname;
      $workflow->{workflownumber} = $workflownumber;
      $workflownumber++;
      $self->logDebug("workflow", $workflow);

      $self->table()->_removeWorkflow( $workflow );

      $success = $self->table()->_addToTable( $table, $workflow, $requiredfields, $fields );
      $self->logDebug("success", $success);


      my $stagehashes = $object->{apps};
      # $self->logDebug("stagehashes", $stagehashes);
      my $stagefields = $self->table()->db()->fields( "stage" );
      $self->logDebug("stagefields", $stagefields);

      my $ordinal = 1;
      foreach my $stagehash ( @$stagehashes ) {
        $self->logDebug("stagehash", $stagehash);
        my $stage = {};
        foreach my $stagefield ( @$stagefields ) {
          if ( exists $stagehash->{$stagefield} and $stagehash->{$stagefield} ) {
            $stage->{$stagefield} = $stagehash->{$stagefield};
          }
        }

        $stage->{appnumber} = $ordinal;
        $ordinal++;
        $stage->{packagename} = "dnaseq";
        $stage->{installdir} = "$installdir/$version";
        $stage->{version} = $version;
        $stage->{username} = $username;
        $stage->{projectname} = $projectname;
        $stage->{workflowname} = $workflowname;
        $stage->{workflownumber} = $workflownumber;
        $self->logDebug("stage", $stage);

        $stage = $self->replaceAppFields( $stage );
        $self->logDebug("stage", $stage);

        #### REMOVE APP
        $self->table()->_deleteStage( $stage );
        my $result = $self->table()->_addStage( $stage );
        $self->logDebug("result", $result);
        $self->logWarning("failed to add stage: $stage->{appname}") and return 0 if not $result;
      

        #### CREATE PARAMETERS
        $self->logDebug("Loading parameters");
        my $parameterhashes = $stagehash->{parameters};
        my $paramfields = $self->table()->db()->fields( "stageparameter" );
        $self->logDebug("paramfields", $paramfields);

        my $parameters = [];
        foreach my $paramhash ( @$parameterhashes ) {
          $self->logDebug("paramhash", $paramhash);

          my $parameter = {};
          foreach my $paramfield ( @$paramfields ) {
            if ( exists $paramhash->{$paramfield} and $paramhash->{$paramfield} ) {
              $parameter->{$paramfield} = $paramhash->{$paramfield};
            }
          }

          push @$parameters, $parameter;
        }

        $self->logDebug("parameters", $parameters);

        my $paramnumber = 1;
        foreach my $parameter (@$parameters) {
          $self->logDebug("parameter", $parameter);

          $parameter->{username} = $username;
          $parameter->{projectname} = $projectname;
          $parameter->{workflowname} = $workflowname;
          $parameter->{appname} = $stage->{appname};
          $parameter->{appnumber} = $stage->{appnumber};
          $parameter->{paramnumber} = $paramnumber;
          $paramnumber++;

          #### REMOVE PARAMETER
          $self->table()->_deleteStageParameter($parameter);

          #### ADD PARAMETER
          my $success = $self->table()->_addStageParameter($parameter);
          $self->logDebug("success", $success);
          $self->logWarning("success", $success) and return 0 if not $success;
        }
      }
    }
  }

  return 1;
}

method loadSampleData ($installdir, $version) {
  # print "Loading samples\n";
  $self->logDebug("installdir", $installdir);
  $self->logDebug("version", $version);

  my $basedir =   $self->conf()->getKey("core:INSTALLDIR");
  my $username  =   $self->username();
  $self->logDebug("basedir", $basedir);
  $self->logDebug("username", $username);

  my $tables   =   {
    clinical97  => [
      {
        project => "QC",
        workflow => "All"
      }
    ]
  };

  foreach my $table ( keys %$tables ) {
    $self->logDebug("table", $table);
    print "Loading sample table: $table\n";
    
    my $projects = $tables->{$table};
    foreach my $project ( @$projects ) {
      my $projectname = $project->{project};
      my $workflowname = $project->{workflow};
      my $sqlfile = "$installdir/$version/data/sql/$table.sql";
      my $tsvfile = "$installdir/$version/data/tsv/$table.tsv";
      my $success = $self->loadSamples( $username, $projectname, $table, $sqlfile, $tsvfile );
      $self->logDebug("success", $success);
      # return 0 if not $success;
    }
  }

  return 1;
}

method loadData ($installdir, $version) {
  print "Loading samples\n";
  $self->logDebug("installdir", $installdir);
  $self->logDebug("version", $version);

  my $basedir =   $self->conf()->getKey("core:INSTALLDIR");
  my $username  =   $self->username();
  $self->logDebug("basedir", $basedir);
  $self->logDebug("username", $username);

  my $database  =   $self->conf()->getKey("database:DATABASE");
  my $tables   =   [
    "cluster",
    "instancetype"
  ];

  foreach my $table ( @$tables ) {
    $self->logDebug("table", $table);
    my $tsvfile = "$installdir/$version/data/tsv/$table.tsv";
    
    #### LOAD SAMPLES
    my $command   =   "$basedir/bin/scripts/loadTable.pl --db $database --table $table --tsvfile $installdir/$version/data/tsv/$table.tsv";
    $self->logDebug("command", $command);
    $self->runCommand($command);
  }

  print "Completed loading data\n\n";
}

method loadApp ( $inputfile ) {
  
  my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;
  my $object   =   $$yaml[0];
  my $appfields = $self->table()->db()->fields( "app" );
  $self->logDebug("appfields", $appfields);
  my $application = {};
  foreach my $appfield ( @$appfields ) {
    if ( exists $object->{$appfield} and $object->{$appfield} ) {
      $application->{$appfield} = $object->{$appfield};
    }
  }

  #### CREATE PARAMETERS
  $self->logDebug("Loading parameters");
  my $parameterhashes = $object->{parameters};
  my $paramfields = $self->table()->db()->fields( "parameter" );
  $self->logDebug("paramfields", $paramfields);

  my $parameters = [];
  foreach my $paramhash ( @$parameterhashes ) {
    $self->logDebug("paramhash", $paramhash);

    my $parameter = {};
    foreach my $paramfield ( @$paramfields ) {
      if ( exists $paramhash->{$paramfield} and $paramhash->{$paramfield} ) {
        $parameter->{$paramfield} = $paramhash->{$paramfield};
      }
    }

    push @$parameters, $parameter;
  }

  return $application, $parameters;
}

method getDirs ($directory) {
  $self->logDebug("directory", $directory);
  
  opendir(DIR, $directory) or $self->logError("Can't open directory: $directory") and exit;
  my $dirs;
  @$dirs = readdir(DIR);
  closedir(DIR) or die "Can't close directory: $directory";
  $self->logNote("RAW dirs", $dirs);
  
  for ( my $i = 0; $i < @$dirs; $i++ ) {
    if ( $$dirs[$i] =~ /^\.+$/ ) {
      splice @$dirs, $i, 1;
      $i--;
    }
  }
  
  for ( my $i = 0; $i < @$dirs; $i++ ) {
    last if scalar(@$dirs) == 0 or $dirs == [];
    my $filepath = "$directory/$$dirs[$i]";
    if ( not -d $filepath ) {
      splice @$dirs, $i, 1;
      $i--;
    }
  }
  $self->logNote("FINAL dirs", $dirs);
  
  return $dirs;   
}

method getFiles ($directory) {
  opendir(DIR, $directory) or $self->logDebug("Can't open directory", $directory);
  my $files;
  @$files = readdir(DIR);
  closedir(DIR) or $self->logDebug("Can't close directory", $directory);

  for ( my $i = 0; $i < @$files; $i++ ) {
    if ( $$files[$i] =~ /^\.+$/ ) {
      splice @$files, $i, 1;
      $i--;
    }
  }

  for ( my $i = 0; $i < @$files; $i++ ) {
    my $filepath = "$directory/$$files[$i]";
    if ( not -f $filepath ) {
      splice @$files, $i, 1;
      $i-- 
    }
  }

  return $files;
}

method loadAppFiles ($username, $packagename, $installdir, $appdir, $format) {  
  # require Flow::App;
  $self->logDebug("username", $username);
  $self->logDebug("package", $packagename);
  $self->logDebug("installdir", $installdir);
  $self->logDebug("appdir", $appdir);
  $self->logDebug("format", $format);
  
  my $typedirs = $self->getDirs($appdir);
  @$typedirs = sort @$typedirs;
  $self->logDebug("typedirs", $typedirs);
  
  foreach my $typedir ( @$typedirs ) {
    print "Loading application type: $typedir\n";

    my $subdir = "$appdir/$typedir";
    my $appfiles = $self->getFiles($subdir);
    @$appfiles  =   sort @$appfiles;
    $self->logDebug("typedir '$typedir' appfiles: @$appfiles") if defined $appfiles;
    
    foreach my $appfile ( @$appfiles ) {
      next if not $appfile =~ /\.app$/;

      my $inputfile = "$subdir/$appfile";
      $self->logDebug("inputfile", $inputfile);
      my ( $application, $parameters )  = $self->loadApp( $inputfile );

      $application = $self->replaceAppFields( $application );
      $self->logDebug("application", $application);
      
      my $appname = $application->{appname};
      $self->logDebug("appname", $appname);

      #### REMOVE APP
      $self->table()->_removeApp( $application );

      #### ADD APP
      my $result = $self->table()->_addApp( $application );
      $self->logDebug("result", $result);
      $self->logWarning("failed to add application: $appname") and return 0 if not $result;

      next if scalar(@$parameters) == 0;
      
      my $owner = $application->{owner};
      $self->logDebug("owner", $owner);

      $parameters = $self->replaceParamFields( $parameters, $owner, $username, $packagename, $installdir, $application );
      $self->logDebug("parameters", $parameters);

      foreach my $parameter (@$parameters) {
        $self->logDebug("parameter", $parameter);

        #### REMOVE PARAMETER
        $self->table()->_removeParameter($parameter);

        #### ADD PARAMETER
        my $success = $self->table()->_addParameter($parameter);
        $self->logDebug("success", $success);
        $self->logWarning("success", $success) and return 0 if not $success;
      }
    }
  }

  return 1;
}

method replaceParamFields ( $parameters, $owner, $username, $packagename, $installdir, $application ) {
  $self->logDebug("parameters", $parameters);
  $self->logDebug("application", $application);

  my $userhome = $self->conf()->getKey( "core:USERDIR" ) . "/$username";
  $self->logDebug("userhome", $userhome);

  foreach my $parameter (@$parameters) {
    $self->logDebug("parameter", $parameter);

    $parameter->{owner}     =   $owner;
    $parameter->{username}    =   $username;
    $parameter->{package}     =   $packagename;
    $parameter->{installdir}  =   $installdir;
    $parameter->{appname}     =   $application->{appname};
    $parameter->{apptype}     =   $application->{apptype};
    $parameter->{version}     =   $application->{version};

    if ( defined $parameter->{value} ) {
      $parameter->{value} =~ s/<USERHOME>/$userhome/g;
    }
  }

  return $parameters;
}

method replaceAppFields ( $application ) {

  if ( $application->{installdir} =~ /<DEPENDENCY/ ) {
    $self->logDebug("application", $application);
    my ($dependencyname) = $application->{installdir} =~ /<DEPENDENCY:(.+)>/;
    $self->logDebug("dependencyname", $dependencyname);
    my $dependency = $self->dependencies()->{$dependencyname};
    $application->{installdir} = $dependency->{installdir};
    $application->{version} = $dependency->{version};
  }

  if ( defined $application->{executor} ) {
    my ($dependencyname) = $application->{executor} =~ /<DEPENDENCY:(.+)>/;
    $self->logDebug("dependencyname", $dependencyname);
    if ( defined $dependencyname ) {
      my $dependency = $self->dependencies()->{$dependencyname};

      $application->{executor} =~ s/<DEPENDENCY:.+?>/$dependency->{installdir}/;      
    }
  }

  return $application;
}

method parameterToDatabase ($owner, $username, $package, $installdir, $application, $parameter) {
  my $paramdata = $parameter->exportData();
  #$self->logDebug("BEFORE paramdata", $paramdata);   
  $paramdata->{name}      =   $paramdata->{param};
  $paramdata->{owner}     =   $owner;
  $paramdata->{username}    =   $username;
  $paramdata->{package}     =   $package;
  $paramdata->{installdir}  =   $installdir;
  $paramdata->{appname}     =   $application->appname(),
  $paramdata->{apptype}     =   $application->type(),
  $paramdata->{version}     =   $application->version(),
  #$self->logDebug("AFTER paramdata", $paramdata);  

  #### REMOVE PARAMETER
  $self->_removeParameter($paramdata);

  #### ADD PARAMETER
  return $self->_addParameter($paramdata);
}

1;