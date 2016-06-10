#!/usr/local/bin/perl
# Copyright [2009-2016] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;
use LibDirs;
use LoadPlugins;

my $webroot = $LibDirs::WEBROOT;
my @dirs = ($webroot, @{$SiteDefs::ENSEMBL_PLUGINS || []});
my @patterns = ("use Inline", "require Inline");

foreach my $dir ( @dirs ) {
  next unless -d $dir;
  my $modules_dir = "$dir/modules";
  next unless -d $modules_dir;

  foreach my $pattern ( @patterns ) {
    chomp $pattern;

    # Get all the files that contain Inline codes.
    my $cmd_grep_inline = 'grep -r "' . $pattern . '" ' . $modules_dir . ' | awk -F ":" \'{print $1}\' | sort | uniq';
    my @files = `$cmd_grep_inline`; 

    foreach my $file ( @files ) {
      chomp $file;

      # Get the package name.
      my $cmd_grep_package = "grep -oP \'(?<=package ).*(?=;)\' $file";
      my $pkg_name = `$cmd_grep_package`;

      if ( $pkg_name ) {
        chomp $pkg_name;

        # Evaluate the package so that Inline code can be compiled.
        eval qq(use $pkg_name);
        error("Error loading:\n$@") if $@;
      }
    }
  }
}

1;