
###############################################################################
##                                                                           ##
##    Copyright (c) 1998 by Steffen Beyer. All rights reserved.              ##
##                                                                           ##
##    This "Makefile.PL" is intended for creating a source distribution      ##
##    file for "Build'n'Play" only; additionally you can use it to install   ##
##    the "BnP.pm" module into your Perl installation tree in order to be    ##
##    able to use it in other Perl applications of your own (other than      ##
##    "Build'n'Play").                                                       ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl, i.e., either            ##
##    the "Artistic License" or the "GNU General Public License".            ##
##                                                                           ##
###############################################################################

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'BnP',
    'VERSION'           => '2.1.0',
    'LIBS'              => [''],   # e.g., '-lm'
    'DEFINE'            => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'               => '',     # e.g., '-I/usr/include/other'
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

