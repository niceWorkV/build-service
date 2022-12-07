#! /usr/bin/perl

use File::Copy::Recursive qw(fcopy);
use File::Basename;
use Cwd;

use JSON::Parse qw(read_json);
use JSON qw(to_json);

use Data::Dumper;

my $home;
BEGIN {
  $home = cwd();
}

use lib "${home}/libs";
use template_gen;

use lib "${home}/libs/scheduler/perl_libs/";
use tools;

my @configs = (
    {
        "name" => "Dockerfile",
        "template" =>"BuildDockerFile",
        "values" => [ "general_docker_args.json", "builder.json" ],
        "value_dir" => "${home}/etc", "location" => "${home}/builder", },
    {
        "name" => "Dockerfile",
        "template" =>"scheduler",
        "values" => [ "general_docker_args.json", "scheduler.json" ],
        "value_dir" => "${home}/etc",
        "location" => "${home}/scheduler",
    },
    {
        "name" => "docker-compose.yml",
        "template" =>"DockerCompose",
        "values" => ["docker_compose.json","builder.json","scheduler.json"],
        "value_dir" => "${home}/etc",
        "location" => "${home}",
    },
);

my @project_structure = (
    "builder",
    "builder/bin",
    "builder/etc",
    "builder/lib",
    "builder/lib/perl_libs",
    "builder/lib/bash_libs",
    "scheduler",
    "scheduler/bin",
    "scheduler/etc",
    "scheduler/lib",
    "scheduler/lib/perl_libs",
    "scheduler/lib/bash_libs",
);

if(-d "${home}/builder" ){
  print tools::run_cmd("rm -rvf ${home}/builder");
}
if(-d "${home}/scheduler" ){
  print tools::run_cmd("rm -rvf ${home}/scheduler");
}

extend_scheduler_config();

create_dirs(\@project_structure);

copy_dir("${home}/etc/general", "${home}/builder/etc");
copy_dir("${home}/etc/general", "${home}/scheduler/etc");
copy_dir("${home}/libs/general/bash_libs", "${home}/builder/lib/bash_libs");
copy_dir("${home}/libs/general/bash_libs", "${home}/scheduler/lib/bash_libs");
copy_dir("${home}/libs/builder/bash_libs", "${home}/builder/lib/bash_libs");
copy_dir("${home}/libs/scheduler/bash_libs", "${home}/scheduler/lib/bash_libs");
copy_dir("${home}/libs/scheduler/perl_libs", "${home}/scheduler/lib/perl_libs");
copy_dir("${home}/libs/builder/perl_libs", "${home}/builder/lib/perl_libs");
copy_dir("${home}/bins/builder", "${home}/builder/bin");
copy_dir("${home}/bins/scheduler", "${home}/scheduler/bin");

template_gen::template_init("${home}/etc", "${home}/templates");
template_gen::get_config_files(\@configs);

sub create_dirs{
   my @dirs = @{$_[0]};
   for my $dir (@dirs){
       next if -d "${home}/$dir";
       unless( mkdir "${home}/$dir" ) {
         tools::my_exit("Can't create a directory: $dir. $!\n");
        }
   }
}

sub copy_dir{
    my $from_dir = shift;
    my $to = shift;

    my $dir = basename($from_dir);

    opendir(my $dir_context, $from_dir)
        or die "Can't read directory: $dir";
    my @files = readdir $dir_context;
    closedir $dir_context;

    for my $file(@files){
        next if $file =~ /^\.\.?$/;
        next if ! defined $file;
        fcopy "${from_dir}/$file", "$to/"
            or die "Can't copy $file from $dir dir: $!";
    }
}

sub extend_scheduler_config{
  my $conf_file = "${home}/etc/scheduler.json";
  %values_tmp = %{read_json($conf_file)};
  if(! exists $values_tmp{"scheduler_volumes"}){
    my @arr = (
      "${home}/scheduler/bin/:/home/test",
      "${home}/builds/sources:/mnt/sources",
      "${home}/builds/RPMs:/mnt/RPMs",
      "rpm_sources:/mnt/rpm_sources",
      "build_results:/mnt/build_results",
    );
    push @{$values_tmp{"scheduler_volumes"}}, @arr;
    my $encoded = to_json(\%values_tmp, {pretty => 1});

    open(FH, '>', $conf_file) or die $!;
    print FH $encoded;
    close(FH);
  }
}
