package tools;
use strict;
use warnings;
use Config::IniFiles;

use Exporter;

our @EXPORT_OK = qw(read_conf run_cmd);

sub run_cmd{
  my $cmd = shift;
  my $output = qx{$cmd 2>&1};
  my_exit("Execution of $cmd is failed \n" .
          " due to:\n$output",$?) if $? != 0;
  return $output;
}

sub read_conf{
  my $file = shift;
  my $configfile = Config::IniFiles->new( -file => $file );
  my %cfg = ();

  for my $section ($configfile->Sections()){
    my %opt = ();

    for my $param ($configfile->Parameters($section)){
       $opt{$param} = $configfile->val($section,$param);
    }

    $cfg{$section} = \%opt;
  }
  return %cfg;
}

sub my_exit{
  my ($msg, $ec) = @_ ;
  $ec = 1 if ! defined $ec;
  $msg = "Unknow exit reason" if ! defined $msg;
  $ec == 0 ? print STDOUT $msg: print STDERR $msg;

  exit $ec;
}

1;
