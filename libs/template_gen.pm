package template_gen;
use strict;
use warnings;
use JSON::Parse qw(read_json);
use File::Path qw(rmtree);
use File::Copy 'move';
use Template;
use Data::Dumper;
use Cwd;

my $HOME;
BEGIN {
  $HOME = cwd();
}

my $TEMPLATES_DIR = "$HOME/templates";
my $TMP_DIR ="/tmp/pbs_template_files";

my ( $TT );

sub _my_exit{
    my $message = shift;
    print STDERR "template_gen.pm error. ".$message."\n";
    exit 1;
}

sub _prepeare_tmp_dir{
    unless(mkdir $TMP_DIR){
        _my_exit "Can't create temporary directory for templates";
    }
    return $TMP_DIR;
}

sub template_init{
    my $result_dir = shift;
    my $templates_dir = shift;

    if( defined $templates_dir ){
        $TEMPLATES_DIR=$templates_dir;
    }

    if( ! -d $result_dir ){
        _my_exit "Directory doesn't exist: $result_dir";
    } elsif ( ! -d $TEMPLATES_DIR ){
        $TEMPLATES_DIR = _prepeare_tmp_dir;
    }

    $TT = Template->new({
         "INCLUDE_PATH" => $TEMPLATES_DIR,
         "OUTPUT_PATH"  => $result_dir,
    }) or die $Template::ERROR ;
}

sub _template_clean{
    if(-d $TMP_DIR){
        rmtree $TMP_DIR;
    }
}

sub get_config_files{
    my @configs = @{$_[0]};
    my $result_dir = $TT->{OUTPUT_PATH};
    my $values;

    if( defined $result_dir && ! defined $TT ){
        template_init $result_dir;
    }
    for my $config (@configs){
        $values = _get_values($config);
        $TT->process($config->{template}, $values, $config->{name})
            or die $!;

        if(exists $config->{location})
        {
            move(
                "$result_dir/$config->{name}",
                "$config->{location}/$config->{name}"
            ) or die "File not found: $result_dir/$config->{name}";
        }
    }
    _template_clean();
}

sub _get_values{
    my $config = shift;
    my %values;
    my $value_dir;
    my %values_tmp;

    if(exists $config->{value_dir}){
      $value_dir = $config->{value_dir};
    } else {
      $value_dir = $TEMPLATES_DIR;
    }

    if(exists $config->{values}){
        for my $file (@{$config->{values}}){
            %values_tmp = %{read_json("$value_dir/$file")};
            for my $key ( keys %values_tmp){
                if(! exists $values{$key}){
                    $values{$key} = $values_tmp{$key};
                }else{
                    print(
                        "Warning: Found a duplicate of template mark.".
                        "Value is not changed"
                    );
                }
            }
        }
    }elsif(exists $config->{value}){
        %values = %{read_json "$value_dir/$config->{value}";}
    }else{
        _my_exit("Files(s) with template values is unknown");
    }

    return \%values;
}

1;
