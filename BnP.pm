
require 5.000;

###############################################################################
##                                                                           ##
##    This is the "BnP.pm" Perl module of "Build'n'Play" (BnP).              ##
##                                                                           ##
##    (The library for software package installation with automatic          ##
##    recovery, i.e., the installation will resume at the exact location     ##
##    in the installation script where the previous installation attempt     ##
##    aborted after an error.)                                               ##
##                                                                           ##
##    Copyright (c) 1998 by Steffen Beyer. All rights reserved.              ##
##                                                                           ##
##    This module is a complete rewrite of a module initially written        ##
##    by Ralf S. Engelschall.                                                ##
##                                                                           ##
##    Copyright (c) 1996 - 1998 by Ralf S. Engelschall.                      ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This module is free software; you can redistribute it                  ##
##    and/or modify it under the same terms as Perl, i.e., either            ##
##    the "Artistic License" or the "GNU General Public License".            ##
##                                                                           ##
###############################################################################

###############################################################################
##                                                                           ##
##    This version of "BnP.pm" was developed with support from O'Reilly      ##
##    Verlag and was first published on the CD-ROM accompanying the book     ##
##    "Programmieren mit Perl-Modulen" (O'Reilly Verlag 1999).               ##
##                                                                           ##
##    Diese Version von "BnP.pm" entstand mit Unterstuetzung des O'Reilly    ##
##    Verlag und wurde erstmalig auf der CD-ROM zum Buch "Programmieren      ##
##    mit Perl-Modulen" (O'Reilly Verlag 1999) veroeffentlicht.              ##
##                                                                           ##
###############################################################################

package BnP;

##
## Note that we cannot use "use" here at all, because in most cases, this will
## require the "Exporter" module, which miniperl (used for bootstrapping) does
## not provide (nor any other module)!
##

BEGIN  ##  Define aliases for subroutine names:
{
    *_reset_   = \&_chdir_;
    *_back_    = \&_chdir_;
    *terminate = \&DESTROY;
}

##
## Internal identification constant(s):
##

$VERSION = "2.1.0 (09-Nov-1998)";  ##  no 'my' for MakeMaker!

##
## Initialization of global constants and variables:
##

$NULL  =   '/dev/null';
$NULL1 =  '>/dev/null';
$NULL2 = '2>/dev/null';

my @DOWNLOAD_TOOLS =
(
    'snarf' => sub  ##  nice tool for non-interactive downloading - try first!
               {
                   my($url,$file) = @_;
                   return(system("snarf '$url' '$file' $NULL2") == 0);
               },
    'lynx'  => sub  ##  needs a dirty kludge for checking for success/failure:
               {
                   my($url,$file) = @_;
                   return
                   (
                       (system("lynx -source '$url' >'$file' $NULL2") == 0)
                       && -f $file
                       && -B $file
                   );
               }
);

my $FILE_COUNTER = '000';

##
## Export some useful functions and constants (without using "Exporter.pm"!):
##

sub import
{
    my($self) = @_;
    my($caller) = caller;
    my($symbol);

    foreach $symbol (qw( info alert fatal find indispensable
                         normalize follow absolute expand ))
    {
        *{"${caller}::$symbol"}  = \&{"${self}::$symbol"};
    }

    foreach $symbol (qw( NULL NULL1 NULL2 ))
    {
        *{"${caller}::$symbol"}  = \${"${self}::$symbol"};
    }
}

##
## Messaging functions:
##

sub info
{
    my($temp);

    $temp = $|;
    $| = 1;
    print "BnP:   " . join('', @_) . "\n";
    $| = $temp;
}

sub alert
{
    warn  "BnP: ! " . join('', @_) . "\n";
}

sub fatal
{
    die   "BnP: ! " . join('', @_) . "\n";
}

##
## Useful helper functions:
##

sub find
{
    my($file,$path) = @_;
    my($item,$dir,$candidate);

    $path =~ s!::+!:.:!g;
    $path =~ s!^:!.:!;
    $path =~ s!:$!:.!;
    foreach $item (split(':', $path))
    {
        $dir = $item;
        $dir =~ s!//+!/!g;
        $dir =~ s!/$!!;
        $candidate = "$dir/$file";
        if (-f $candidate && -r $candidate && -s $candidate)
        {
            return $candidate;
        }
    }
    return '';
}

sub indispensable
{
    my($item);

    foreach $item (@_)
    {
        if (find($item, $ENV{'PATH'}) eq '')
        {
            fatal "Can't find the indispensable tool '$item'!";
        }
    }
}

sub normalize
{
    my($file) = @_;
    my($flag);

    $file =~ m!^(/?)!;
    $flag = $1;
    $file =~ s!//+!/!g;
    $file =~ s!/(?:\./)+!/!g;
    $file =~ s!^\./!!;
    $file =~ s!/\.$!!;
    $file =~ s!^/!!;
    $file =~ s!/$!!;
    $file =~ s!^\.$!!;
    $file = "/$file/";
    while ($file =~ s!/(?:\.*[^\./][^/]*|\.\.\.+)/\.\./!/!g) { }
    $file =~ s!^/!!;
    $file =~ s!/$!!;
    return "$flag$file";
}

sub follow
{
    my($file) = @_;
    my($link);

    $file = normalize($file);
    while (-l $file)
    {
        $link = readlink($file);
        if ($link =~ m!^/!)
        {
            $file = $link;
        }
        else
        {
            $file =~ s![^/]+$!$link!;
        }
        $file = normalize($file);
    }
    return $file;
}

sub absolute
{
    my($file) = @_;
    my($path);

    unless ($file =~ m!^/!)
    {
        chomp($path = `/bin/pwd`);
        $file = "$path/$file";
    }
    return($file);
}

sub expand
{
    my($path) = @_;
    my($accu,$item,$temp,$link);

    $path = absolute($path);
    $path = normalize($path);
    $path =~ s!^/!!;
    $accu = '';
    while ($path ne '')
    {
        ($item,$path) = split('/', $path, 2);
        $temp = "$accu/$item";
        if (($item ne '..') && (-l $temp))
        {
            $link = readlink($temp);
            if ($link =~ m!^/!) { $accu = ''; }
            $path = normalize("$link/$path");
            $path =~ s!^/!!;
        }
        else { $accu = $temp; }
    }
    return normalize("/$accu");
}

##
## Methods to access internal attributes of general interest:
##

sub target
{
    my($project) = @_;
    return $project->{'TARGET'};
}

sub subset
{
    my($project) = @_;
    return $project->{'SUBSET'};
}

sub prefix
{
    my($project) = @_;
    return $project->{'PREFIX'};
}

sub homedir
{
    my($project) = @_;
    return $project->{'HOMEDIR'};
}

sub workspace
{
    my($project) = @_;
    return $project->{'WORKSPACE'};
}

sub path
{
    my($project) = shift;
    my($list,$item,$path);

    if (scalar(@_))
    {
        $project->{'PATH'} = [ ];
        $list = join(':', @_);
        $list =~ s!::+!:!g;
        $list =~ s!^:!!;
        $list =~ s!:$!!;
        foreach $item (split(/:/, $list))
        {
            $path = $item;
            $path =~ s!//+!/!g;
            $path =~ s!(.)/$!$1!;
            push( @{$project->{'PATH'}}, $path );
        }
    }
    return( @{$project->{'PATH'}} );
}

sub stub
{
    my($project) = shift;
    my($item,$stub);

    if (scalar(@_))
    {
        $project->{'STUB'} = [ ];
        foreach $item (split(' ', join(' ', @_)))
        {
            $stub = $item;
            $stub =~ s!//+!/!g;
            $stub =~ s!^/!!;
            $stub =~ s!/$!!;
            push( @{$project->{'STUB'}}, $stub );
        }
    }
    return( @{$project->{'STUB'}} );
}

sub url
{
    my($project) = shift;

    if (scalar(@_))
    {
        @{$project->{'URL'}} = split(' ', join(' ', @_));
    }
    return( @{$project->{'URL'}} );
}

##
## Object constructor and destructor:
##

sub initialize
{
    my($project) = @_;

    delete $project->{'COMMANDLIST'};
    $project->{'SECTIONS'} = { };
    $project->{'COUNTER'}  = 0;
    $project->{'IGNORE'}   = 0;
    $project->{'ACTIVE'}   = 0;
    $project->{'FORCE'}    = 0;
    $project->{'SKIP'}     = 0;
    $project->{'PATH'}     = [ ];
    $project->{'STUB'}     = [ ];
    $project->{'URL'}      = [ ];
}

sub new
{
    my($class,$target,$subset,$prefix,$homedir,$workspace) = @_;
    my($project,$symbol);

    $project = bless( { }, ref($class) || $class || 'BnP' );

    $subset =~ s!\s+!!g;
    $subset =~ s!\.+!.!g;
    $subset =~ s!^\.!!;
    $subset =~ s!\.$!!;

    if ($prefix =~ /^\s*$/)
    {
        $prefix = '/usr/local';
    }

    $prefix    =~ s!/+$!!;
    $homedir   =~ s!/+$!!;
    $workspace =~ s!/+$!!;

    $symbol = 'RECOVERY_FILE_' . $FILE_COUNTER++;

    $project->{'TARGET'}     = $target;
    $project->{'SUBSET'}     = $subset;
    $project->{'PREFIX'}     = $prefix;
    $project->{'HOMEDIR'}    = $homedir;
    $project->{'WORKSPACE'}  = $workspace;
    $project->{'BASENAME'}   = "$homedir/recover";
    $project->{'FILEHANDLE'} = \*{"BnP::$symbol"};
    $project->{'FILEOPEN'}   = 0;

    $project->initialize();

    return $project;
}

sub DESTROY
{
    my($project) = @_;

    if ($project->{'FILEOPEN'})
    {
        if (close($project->{'FILEHANDLE'}))
        {
            $project->{'FILEOPEN'} = 0;
        }
        else
        {
            fatal "Can't close automatic recovery file '" .
                $project->{'BASENAME'} . ".bnp': $!";
        }
    }
}

##
## Meta-command methods:
##

sub begin
{
    my($project) = @_;
    my($filehandle,$basename,$recover,$backup,$suffix,$target,$subset);

    $project->terminate();
    $project->initialize();

    $filehandle = $project->{'FILEHANDLE'};
    $basename   = $project->{'BASENAME'};
    $recover    = "$basename.bnp";

    if (-f $recover)
    {
        unless (open($filehandle, "<$recover"))
        {
            fatal "Can't read automatic recovery file '$recover': $!";
        }
        $project->{'COMMANDLIST'} = [ ];
        chomp(@{$project->{'COMMANDLIST'}} = <$filehandle>);
        unless (close($filehandle))
        {
            fatal "Can't close automatic recovery file '$recover': $!";
        }
        #
        $suffix = '000';
        $backup = "$basename.$suffix";
        while (-e $backup || -l $backup)
        {
            $suffix++;
            $backup = "$basename.$suffix";
        }
        unless (rename($recover,$backup))
        {
            fatal "Can't 'rename(\"$recover\",\"$backup\")': $!";
        }
    }
    unless (open($filehandle, ">$recover"))
    {
        fatal "Can't write automatic recovery file '$recover': $!";
    }
    $project->{'FILEOPEN'} = 1;

    $target = $project->{'TARGET'};
    $subset = $project->{'SUBSET'};
    info "This is \"Build'n'Play\" (BnP) version $VERSION";
    if ($subset eq '')
    {
        info "Building target '$target'...";
    }
    else
    {
        info "Building subset '$subset' of target '$target'...";
    }

    $project->{'ACTIVE'} = 1;
    $project->reset();
    if ($subset ne '')
    {
        $project->{'ACTIVE'} = 0;
    }
}

sub end
{
    my($project) = @_;
    my($target,$subset);

    $project->terminate();
    $project->initialize();

    $target = $project->{'TARGET'};
    $subset = $project->{'SUBSET'};
    if ($subset eq '')
    {
        info "Installation of target '$target' succeeded!";
    }
    else
    {
        info
      "Installation of subset '$subset' for target '$target' succeeded!";
    }
    info "Use 'build clean' to clean up!";
}

sub begin_section
{
    my($project) = shift;
    my($subset) = $project->{'SUBSET'};
    my($item,$section);

    if ($subset ne '')
    {
        foreach $item (@_)
        {
            $section = $item;
            $section =~ s!\s+!!g;
            $section =~ s!\.+!!g;
            if (index(".$subset.", ".$section.") >= $[)
            {
                unless ($project->{'SECTIONS'}{$section} & 1)
                {
                    $project->{'SECTIONS'}{$section} |= 1;
                    $project->{'ACTIVE'}++;
                }
            }
        }
    }
}

sub end_section
{
    my($project) = shift;
    my($item,$section);

    if ($project->{'SUBSET'} ne '')
    {
        foreach $item (@_)
        {
            $section = $item;
            $section =~ s!\s+!!g;
            $section =~ s!\.+!!g;
            if ($project->{'SECTIONS'}{$section} & 1)
            {
                $project->{'SECTIONS'}{$section} &= ~1;
                $project->{'ACTIVE'}--;
            }
        }
    }
}

sub begin_must_section
{
    my($project) = @_;

    unless ($project->{'SECTIONS'}{'.'})
    {
        $project->{'SECTIONS'}{'.'} = 1;
        $project->{'FORCE'}++;
    }
}

sub end_must_section
{
    my($project) = @_;

    if ($project->{'SECTIONS'}{'.'})
    {
        $project->{'SECTIONS'}{'.'} = 0;
        $project->{'FORCE'}--;
    }
}

sub begin_lazy_section
{
    my($project) = shift;
    my($subset) = $project->{'SUBSET'};
    my($item,$section);

    foreach $item (@_)
    {
        $section = $item;
        $section =~ s!\s+!!g;
        $section =~ s!\.+!!g;
        unless ($project->{'SECTIONS'}{$section} & 6)
        {
            if (($subset ne '') && (index(".$subset.", ".$section.") >= $[))
            {
                $project->{'SECTIONS'}{$section} |= 4;
                $project->{'FORCE'}++;
            }
            else
            {
                $project->{'SECTIONS'}{$section} |= 2;
                $project->{'SKIP'}++;
            }
        }
    }
}

sub end_lazy_section
{
    my($project) = shift;
    my($item,$section);

    foreach $item (@_)
    {
        $section = $item;
        $section =~ s!\s+!!g;
        $section =~ s!\.+!!g;
        if ($project->{'SECTIONS'}{$section} & 6)
        {
            if ($project->{'SECTIONS'}{$section} & 4)
            {
                $project->{'FORCE'}--;
            }
            else
            {
                $project->{'SKIP'}--;
            }
            $project->{'SECTIONS'}{$section} &= ~6;
        }
    }
}

sub ignore
{
    my($project) = @_;
    $project->{'IGNORE'} = 1;
}

sub resume
{
    my($project) = @_;
    $project->{'IGNORE'} = 0;
}

##
## Internal low-level methods called by the dispatcher method:
## (Do NOT call from anywhere else!)
##

sub _chdir_
{
    my($project,$path) = @_;

    unless (chdir($path))
    {
        fatal "Can't 'chdir(\"$path\")': $!";
    }
}

sub _mkdir_
{
    my($project,$path) = @_;
    my($dir,$item);

    $path = normalize($path);
    if (-e $path || -l $path)
    {
        unless (-d $path)
        {
            fatal "Can't 'mkdir(\"$path\")': Different object already exists!";
        }
    }
    else
    {
        $path =~ s!^(/?)!!;
        $dir = $1;
        foreach $item (split('/', $path))
        {
            $dir = "${dir}${item}";
            unless (-d $dir)
            {
                unless (mkdir($dir,0777))
                {
                    fatal "Can't 'mkdir(\"$dir\")': $!";
                }
            }
            $dir = "$dir/";
        }
    }
}

sub _fetch_
{
    my($project,$file,$relative,$source) = @_;
    my($targetfile,$candidate,$found,$path,$stub,$item,$name,$tool,$url);

    $source =~ s!//+!/!g;
    $source =~ s!/$!!;
    $targetfile = "$source/$file";
    unless (-f $targetfile && -r $targetfile && -s $targetfile)
    {
        if (-f $targetfile || -l $targetfile)
        {
            unless (unlink($targetfile) == 1)
            {
                fatal "Can't 'unlink(\"$targetfile\")'!";
            }
        }
        $relative =~ s!//+!/!g;
        $relative =~ s!^/!!;
        $relative =~ s!/$!!;
        $found = 0;
        PATH:
        foreach $path (@{$project->{'PATH'}})
        {
            foreach $stub ('', @{$project->{'STUB'}})
            {
                foreach $item ('', $relative)
                {
                    $candidate = "$path/$stub/$item/$file";
                    $candidate = normalize($candidate);
                    if (-f $candidate && -r $candidate && -s $candidate)
                    {
                        $found = 1;
                        last PATH;
                    }
                }
            }
        }
        if ($found)
        {
            unless ((system("ln -s '$candidate' '$targetfile'") == 0) &&
                (-f $targetfile && -r $targetfile && -s $targetfile))
            {
                unlink($targetfile);
                unless ((system("cp -p '$candidate' '$source'") == 0) &&
                    (-f $targetfile && -r $targetfile && -s $targetfile))
                {
                    unlink($targetfile);
                    fatal "Can't copy '$candidate' to '$source'!";
                }
            }
        }
        else
        {
            for ( $item = 0; $item < scalar(@DOWNLOAD_TOOLS); $item++ )
            {
                $name = $DOWNLOAD_TOOLS[$item++];
                if ((($tool = find($name, $ENV{'PATH'})) ne '') && -x $tool)
                {
                    $tool = $DOWNLOAD_TOOLS[$item];
                    $found = 1;
                    last;
                }
            }
            if ($found)
            {
                $found = 0;
                info "Downloading '$file' with '$name'...";
                foreach $item (@{$project->{'URL'}})
                {
                    $url = $item;
                    $url =~ s!/+$!!;
                    if ($relative ne '')
                    {
                        $url .= "/$relative";
                    }
                    $url .= "/$file";
                    info "Trying '$url'...";
                    if (( &{$tool}($url,$targetfile) ) &&
                        (-f $targetfile && -r $targetfile && -s $targetfile))
                    {
                        $found = 1;
                        last;
                    }
                }
                unless ($found)
                {
                    fatal "Download of '$file' with '$name' failed!";
                }
            }
            else
            {
                fatal "Can't find any tool (",
                    join(', ', map(ref($_)?():$_, @DOWNLOAD_TOOLS)),
                    ") for downloading!";
            }
        }
    }
}

sub _system_
{
    my($project) = shift;
    my($command) = join(' ', @_);

    if (system($command) != 0)
    {
        fatal "Command 'system(\"$command\")' failed!";
    }
}

sub _patch_
{
    my($project) = shift;
    my($file)    = shift;
    my($backup,$result,$suffix,$command,$mode,$uid,$gid);

    $suffix = '000';
    $backup = "$file.$suffix";
    while (-e $backup || -l $backup)
    {
        $suffix++;
        $backup = "$file.$suffix";
    }
    $suffix++;
    $result = "$file.$suffix";
    while (-e $result || -l $result)
    {
        $suffix++;
        $result = "$file.$suffix";
    }
    unless (open(IN, "<$file"))
    {
        fatal "Can't read file '$file': $!";
    }
    unless (open(OUT, ">$result"))
    {
        fatal "Can't write file '$result': $!";
    }
    while (<IN>)
    {
        foreach $command (@_)
        {
            eval $command;
            if ($@)
            {
                close(IN);
                close(OUT);
                unlink($result);
                chomp($@);
                $@ =~ s!\s+at\s+\(eval.*$!!;
                fatal "$@ in patch command!";
            }
        }
        print OUT;
    }
    unless (close(IN))
    {
        fatal "Can't close file '$file': $!";
    }
    unless (close(OUT))
    {
        fatal "Can't close file '$result': $!";
    }
    unless (($mode,$uid,$gid) = (stat($file))[2,4,5])
    {
        fatal "Can't 'stat(\"$file\")': $!";
    }
    unless (chmod($mode,$result) == 1)
    {
        fatal "Can't 'chmod($mode,\"$result\")': $!";
    }
    unless (chown($uid,$gid,$result) == 1)
    {
        alert "Can't 'chown($uid,$gid,\"$result\")': $!";
    }
    unless (rename($file,$backup))
    {
        fatal "Can't 'rename(\"$file\",\"$backup\")': $!";
    }
    unless (rename($result,$file))
    {
        fatal "Can't 'rename(\"$result\",\"$file\")': $!";
    }
}

##
## Method indicating wether commands are currently being executed or ignored:
##

sub active
{
    my($project) = @_;

    return
    (
        !$project->{'IGNORE'} &&
        (
            $project->{'FORCE'} ||
            ( !$project->{'SKIP'} && $project->{'ACTIVE'} )
        )
    );
}

##
## *THE* big central dispatcher method:
##

sub dispatch
{
    my($project) = shift;
    my($force)   = shift;
    my($caller,$command,$counter,$execute,$method,$temp);

    if ($project->active())
    {
        $caller = (caller(1))[3];
        $caller =~ s!^.*::!!;
        $command = join(' ', $caller, @_);
        $counter = $project->{'COUNTER'};
        $execute = 1;
        if (defined $project->{'COMMANDLIST'})
        {
            if ($counter < scalar(@{$project->{'COMMANDLIST'}}))
            {
                if ($project->{'COMMANDLIST'}[$counter] eq $command)
                {
                    $execute = 0 unless ($force); ## we have done it before!
                }
                else ## we are leaving the area of matching commands:
                {
            alert "Next command deviates from the automatic recovery file -";
            alert "discarding the remainder of the automatic recovery file!";
                    delete $project->{'COMMANDLIST'};
                }
            }
            else ## we read the whole recovery file, now we're on our own:
            {
                delete $project->{'COMMANDLIST'};
            }
        }
        $temp = $|;
        $| = 1;
        if ($execute)
        {
            printf("BnP:   %04d %-60.60s (exec)\n", $counter, $command);
            $method = "_${caller}_";
            $project->$method(@_);
        }
        else
        {
            printf("BnP:   %04d %-60.60s (skip)\n", $counter, $command);
        }
        $| = $temp;
        #
        $temp = select($project->{'FILEHANDLE'});
        $| = 1;
        print "$command\n";
        select($temp);
        #
        $project->{'COUNTER'}++;
    }
}

##
## General utility methods, all going via the dispatcher method:
##

sub reset  ##  dispatched to "_chdir_" via alias "_reset_"!
{
    my($project) = @_;
    $project->dispatch(1, $project->{'WORKSPACE'});
}

sub back  ##  dispatched to "_chdir_" via alias "_back_"!
{
    my($project,$count) = @_;
    $count = 1 unless ((defined $count) && ($count > 0));
    $project->dispatch(1, '../' x $count);
}

sub chdir
{
    my($project) = shift;
    $project->dispatch(1, @_);
}

sub mkdir
{
    my($project) = shift;
    $project->dispatch(0, @_);
}

sub fetch
{
    my($project)  = shift;
    $project->dispatch(0, @_);
}

sub system
{
    my($project) = shift;
    $project->dispatch(0, @_);
}

sub patch
{
    my($project) = shift;
    $project->dispatch(0, @_);
}

1;

__END__

=head1 NAME

BnP - implements the automatic recovery mechanism of "Build'n'Play"

=head1 PREFACE

This module provides an automatic recovery mechanism for installation
scripts (for installing any kind of Unix software package) written in
Perl.

A special log file (called the "automatic recovery file") is used by this
module in which all the commands (i.e., method calls of command methods
provided by this module) are recorded which have been executed successfully.

When you restart your installation script later, the commands found in
this automatic recovery file will not be executed again.

The module provides a comprehensive set of command methods for fetching
source distribution files automatically, for manipulating (e.g., unpacking
and building) them in every possible way (using "C<system()>" calls), for
making and changing directories, for patching files (in a manner resembling
the Unix tool "C<sed>"), for defining subsections in your installation scripts
and for commenting out certain parts, plus some functions of general utility.

=head1 SYNOPSIS

  use BnP;

=head2 Functions:

  info
      info "MESSAGE", ...;  #  print

  alert
      alert "MESSAGE", ...;  #  warn

  fatal
      fatal "MESSAGE", ...;  #  die

  find
      $path = find("FILENAME", "SEARCHPATH");

  indispensable
      indispensable("FILENAME", ...);

  normalize
      $file = normalize("FILENAME");

  follow
      $file = follow("FILENAME");

  absolute
      $file = absolute("FILENAME");

  expand
      $file = expand("FILENAME");

=head2 Methods:

  new
      $BnP = BnP->new($target,$subset,$prefix,$homedir,$workspace);

  target
      $target = $BnP->target();

  subset
      $subset = $BnP->subset();

  prefix
      $prefix = $BnP->prefix();

  homedir
      $homedir = $BnP->homedir();

  workspace
      $workspace = $BnP->workspace();

  path
      [ @path = ] $BnP->path( @path );
      @path = $BnP->path();

  stub
      [ @stub = ] $BnP->stub( @stub );
      @stub = $BnP->stub();

  url
      [ @url = ] $BnP->url( @url );
      @url = $BnP->url();

  begin
      $BnP->begin();

  end
      $BnP->end();

  begin_section
      $BnP->begin_section("NAME", ...);

  end_section
      $BnP->end_section("NAME", ...);

  begin_must_section
      $BnP->begin_must_section();

  end_must_section
      $BnP->end_must_section();

  begin_lazy_section
      $BnP->begin_lazy_section("NAME", ...);

  end_lazy_section
      $BnP->end_lazy_section("NAME", ...);

  ignore
      $BnP->ignore();

  resume
      $BnP->resume();

  active
      $flag = $BnP->active();

  reset
      $BnP->reset();

  back
      $BnP->back();
      $BnP->back(COUNT);

  chdir
      $BnP->chdir("DIR");

  mkdir
      $BnP->mkdir("DIR");

  fetch
      $BnP->fetch("FILENAME", "RELPATH", "SOURCEDIR");

  system
      $BnP->system("COMMAND", ...);

  patch
      $BnP->patch("FILENAME", "PERLEXPR", ...);

=head1 DESCRIPTION

=head2 Functions:

=over 2

=item *

C<info "MESSAGE", ...;>  #  print

This function can be used to print informational messages to STDOUT
(or to whatever file handle your program has currently "select"ed).

All parameters of this function are concatenated without any
intervening characters (i.e., without adding any spaces).

A prefix of S<"BnP:   "> and a trailing "\n" is added automatically.

Moreover, the output is written unbuffered, i.e., even if it is not
sent to a terminal, the output should appear immediately in the
corresponding file or pipe.

=item *

C<alert "MESSAGE", ...;>  #  warn

This function can be used to print warning messages to STDERR
(using "warn", internally).

All parameters of this function are concatenated without any
intervening characters (i.e., without adding any spaces).

A prefix of S<"BnP: ! "> and a trailing "\n" is added automatically.

=item *

C<fatal "MESSAGE", ...;>  #  die

This function can be used to print an error message to STDERR, with
immediately ensuing program abortion (using "die", internally).

All parameters of this function are concatenated without any
intervening characters (i.e., without adding any spaces).

A prefix of S<"BnP: ! "> and a trailing "\n" is added automatically.

=item *

C<$path = find("FILENAME", "SEARCHPATH");>

This function can be used to find any readable (operator "C<-r>") and
non-empty (operator "C<-s>") file in a given searchpath (i.e., a list
of directories concatenated with "C<:>") whose filename is given.

The function returns the absolute path of the requested file if the
file was found in the given searchpath, or an empty string otherwise.

For example:

    $shell = find('sh', $ENV{'PATH'});

This should return "/bin/sh".

=item *

C<indispensable("FILENAME", ...);>

This function checks wether all the files whose filenames are given can
be found in the current "C<$PATH>" environment variable ("C<$ENV{'PATH'}>")
using the function "C<find()>" (see above) internally.

An error message is printed and program execution is aborted if any of
the files in the list cannot be found.

The function returns silently if all the files have been found.

=item *

C<$file = normalize("FILENAME");>

This function "normalizes" a given filename, i.e., it reduces consecutive
slashes ("C</>") and consecutive terms of the form "C</./>" to a single slash,
and removes a dot-slash ("C<./>") at the beginning and a slash-dot ("C</.>")
or slash ("C</>") at the end.

Moreover, terms of the form "C</dir/../>" (where "C<dir>" is not an empty
string, contains no slashes and is not equal to "C<..>") are iteratively
reduced to a single slash each, until no more terms of this kind can be found.

=item *

C<$file = follow("FILENAME");>

If the given filename (given as an absolute path or as a path relative to
the current working directory) is a symbolic link, this function follows
this symbolic link iteratively, as long as the resulting filename is also
a symbolic link, until the end of the chain of symbolic links is reached.

This last filename is then returned.

If the given filename is not a symbolic link, it is simply "normalized"
using the function "C<normalize()>" (see above) and then returned.

=item *

C<$file = absolute("FILENAME");>

If the given filename is an absolute path, it is returned unchanged.

Otherwise the output of "C</bin/pwd>" is prepended to it and the new
filename is returned.

=item *

C<$file = expand("FILENAME");>

While the function "C<follow()>" (see above) only expands the "basename" part
of a given filename if it is a symbolic link (whereas the "dirname" part
remains unchanged), this function expands ALL symbolic links encountered in
a given filename, yielding the true physical (absolute) path of the file or
directory in question.

If the given filename is relative, it is first converted into an absolute
path using the function "C<absolute()>" (see above).

If a file or directory of the given name does not exist, all symbolic links
are expanded as far as possible (as far as the leading (left) part of the
given filename matches existing directories and symbolic links).

=back

=head2 Methods:

=over 2

=item *

C<$BnP = BnP-E<gt>new($target,$subset,$prefix,$homedir,$workspace);>

This is the "Build'n'Play" installation project constructor method.

In theory you can perform several installations simultaneously; each
installation thereby has a variable space of its own, which is stored
in the object returned by this method.

=back

=over 5

=item S<  ->

The parameter "C<$target>" specifies a name for the installation project.
This name has only informational character in this module, though.

=item S<  ->

The parameter "C<$subset>" specifies a list of subtargets (as a single
string, in which the different elements are concatenated with "C<.>")
which enable the corresponding sections in your installation script
as defined by the "C<begin_section()>", "C<end_section()>",
"C<begin_lazy_section()>" and "C<end_lazy_section()>" method calls
in your script (see further below for a description of these methods).

=item S<  ->

The parameter "C<$prefix>" specifies the installation prefix,
e.g. "C</usr/local>", "C</opt/pkg/E<lt>targetE<gt>>" etc.

If this parameter is empty or contains only whitespace, the prefix
is set to "C</usr/local>" by default.

=item S<  ->

The parameter "C<$homedir>" specifies the home directory of the
installation project, i.e., the directory where the automatic
recovery file ("C<recover.bnp>") for this project will be stored.

A subdirectory named "src" in this directory is usually the place
where all the necessary source distribution files are stored, but
this is something controlled entirely by your installation script.

Note that simultaneous installations must have different home
directories, otherwise they will overwrite each other's automatic
recovery file ("C<recover.bnp>") in that directory.

=item S<  ->

The parameter "C<$workspace>" specifies a directory where the
source distribution files can be temporarily unpacked and compiled.

This is also the directory the method "C<reset()>" (see further below)
performs a "C<chdir()>" to.

=back

=over 2

=item

Note that it is technically possible to subclass the class implemented
in this module and to inherit this constructor method.

=item *

C<$target = $BnP-E<gt>target();>

This method returns the name of the current installation project as
defined in the call of the installation project constructor method
"C<new()>" (see above for details).

=item *

C<$subset = $BnP-E<gt>subset();>

This method returns the string containing the names of the sections in
your installation script to be processed, as defined in the call of the
installation project constructor method "C<new()>" (see above for details).

=item *

C<$prefix = $BnP-E<gt>prefix();>

This method returns the prefix of the current installation project
as defined in the call of the installation project constructor method
"C<new()>" (see above for details).

=item *

C<$homedir = $BnP-E<gt>homedir();>

This method returns the home directory of the current installation project
as defined in the call of the installation project constructor method
"C<new()>" (see above for details).

=item *

C<$workspace = $BnP-E<gt>workspace();>

This method returns the directory used as a temporary workspace by the
current installation project (several simultaneous installations may use
the same workspace directory, unless they try to unpack distributions
which result in a distribution directory of exactly the same name), as
defined in the call of the installation project constructor method
"C<new()>" (see above for details).

Note also that provisions need to be made (i.e., an appropriate subdirectory
has to be created first) if you unpack any misbehaving distributions which do
not create a distribution directory first themselves but simply spill their
contents into the current working directory.

=item *

C<[ @path = ] $BnP-E<gt>path( @path );>

=item *

C<@path = $BnP-E<gt>path();>

This method allows you to define a number of base directories where to
search for source distribution files (see also the description of the
method "C<fetch()>" further below) in your local file system (e.g.,
on your hard disk, on a CD-ROM, etc.).

Several directory names may be concatenated with "C<:>" to form a single
argument, or they can be passed as separate arguments. You can also
mix these two forms.

Note that any previous setting is REPLACED by the given arguments, i.e.,
this method is NOT accumulative.

The method returns a list with all the directory names that have been
passed to it (previously, or in the current call).

If you call this method without parameters, the current setting is
returned but not changed.

Example:

    $BnP->path( '/mirrors:/cdrom', `pwd` );

Trailing slashes ("C</>") will be removed automatically.

Note that these directories must be given by their absolute path, because
the current directory will usually change frequently over the course of
your installation.

Note also that these directories will always be searched in the given order
(from left to right).

Finally, note that this setting is cleared by the "C<begin()>" and "C<end()>"
methods (see further below).

(This setting is initialized to an empty list by the constructor method
"C<new()>".)

=item *

C<[ @stub = ] $BnP-E<gt>stub( @stub );>

=item *

C<@stub = $BnP-E<gt>stub();>

This method allows you to define a number of subdirectories where to
search for source distribution files (see also the description of the
method "C<fetch()>" further below) in your local file system (e.g.,
on your hard disk, on a CD-ROM, etc.).

Several subdirectory names may be concatenated with blanks ("S< >")
to form a single argument, or they can be passed as separate
arguments. You can also mix these two forms.

Note that any previous setting is REPLACED by the given arguments,
i.e., this method is NOT accumulative.

The method returns a list with all the subdirectory names that have
been passed to it (previously, or in the current call).

If you call this method without parameters, the current setting is
returned but not changed.

Example:

    $BnP->stub( 'CPAN', 'BnP/src', 'BnP', 'src' );

Note that these subdirectories must be given as relative paths (any
leading or trailing slash ("C</>") will be stripped anyway, however).

Note also that these subdirectories will always be searched in the given
order (from left to right) and that (moreover) the subdirectory "C<.>"
is always implicitly assumed to be at the beginning of this list.

(As a consequence, if you don't need this feature of search subdirectories,
you don't need to bother with this method at all, just leave this setting
empty as it is initialized by the constructor method "C<new()>".)

When searching for a source distribution file, each of these subdirectories
will in turn be appended to every base directory as defined by the "C<path()>"
method (see above) to form the list of actual directories to be searched
(i.e., the search path is the set product of the directories defined with
the "C<path()>" method and the subdirectories defined with the "C<stub()>"
method).

Finally, note that this setting is cleared by the "C<begin()>" and "C<end()>"
methods (see further below).

=item *

C<[ @url = ] $BnP-E<gt>url( @url );>

=item *

C<@url = $BnP-E<gt>url();>

This method allows you to define a number of URLs where to download source
distribution files from which haven't been found in your local file system
(see also the description of the method "C<fetch()>" further below).

Several URLs may be concatenated using blanks ("S< >") to form a single
argument, or they can be passed as separate arguments. You can also
mix these two forms.

Note that any previous setting is REPLACED by the given arguments, i.e.,
this method is NOT accumulative.

The method returns a list with all the URLs that have been passed to it
(previously, or in the current call).

If you call this method without parameters, the current setting is
returned but not changed.

Example:

  $BnP->url
  (
      'ftp://ftp.engelschall.com/pub/bnp ftp://ftp.netsw.org/netsw'
  );

Note that these URLs should usually terminate in the name of a directory
but should nevertheless NOT have a trailing slash!

Note also that these URLs will always be searched in the given order (from
left to right).

Finally, note that this setting is cleared by the "C<begin()>" and "C<end()>"
methods (see below).

=item *

C<$BnP-E<gt>begin();>

This method call starts the actual installation.

A (possibly) still open automatic recovery file is closed, and all internal
attributes of the current installation project (except the ones which contain
the parameters passed to the installation project constructor method
"C<new()>") are reset to their default values (this is so that you can
use the same installation project object several times in sequence).

The method then checks wether an automatic recovery file "C<recover.bnp>"
already exists for the current installation project, and if so, reads it in.

(The contents of the automatic recovery file are then stored in memory in
the given installation project object for fastest possible access.)

Moreover, if it exists, this automatic recovery file is renamed (its
suffix "C<.bnp>" is thereby replaced by a 3-digit number which is the
smallest such number which hasn't been assigned yet, by starting at
"C<000>" and incrementing as necessary), and a new recovery file is
created and opened for writing.

A header line showing the name and version number of this module as well
as a confirmation for some of your calling parameters is printed to the
screen, and a "C<chdir()>" is made via the method "C<reset()>" (see also
further below) to the directory "C<$workspace>", as defined in the call
of the installation project constructor method "C<new()>" (see above
for details).

=item *

C<$BnP-E<gt>end();>

This method call terminates the actual installation.

First the automatic recovery file is closed (nothing is done if the file has
already been closed before, for instance by a previous call of this method).

Then all internal attributes of the current installation project (except
the ones which contain the parameters passed to the installation project
constructor method "C<new()>") are reset to their default values (this
is so that you can use the same installation project object several
times in sequence).

Finally, a message confirming the successful installation is printed to
the screen.

=item *

C<$BnP-E<gt>begin_section("NAME", ...);>

This method call marks the beginning of a named section in your
installation script.

You can pass several names (or "labels") to this method, which will
be treated as synonyms for the section in question.

I.e., specifying ANY of these labels from this method call in the
parameter "C<$subset>" at runtime (via the "C<new()>" constructor
method - see above) will enable the commands in the corresponding
section.

If none of the subtargets specified in the parameter "C<$subset>"
matches any of the labels in this method call, then the commands
in the corresponding section will be disabled - unless the parameter
"C<$subset>" is empty, in which case the "C<begin_section()>" and
"C<end_section()>" (see below) method calls are simply ignored
altogether.

(An empty parameter "C<$subset>" means "install ALL sections",
therefore the "C<begin_section()>" and "C<end_section()>" method
calls need not to be evaluated in such a case.)

This way you can also define the section in question as being part
of a set of sections forming a larger whole, or mark parts which
are prerequisites of other sections, as in the following example:

    $BnP->begin_section("net","mail","news");
    # install net software (prerequisite for mail and news)
    $BnP->end_section("net","mail","news");
    ...
    $BnP->begin_section("mail");
    # install mail software
    $BnP->end_section("mail");
    ...
    $BnP->begin_section("news");
    # install news software
    $BnP->end_section("news");

If the runtime parameter "C<$subset>" contains "net", only the "net" portion
will be installed. If it contains "mail", the "net" portion as well as the
"mail" part itself will be installed. If it contains "mail" AND "news",
all three parts will be installed, and so on.

=item *

C<$BnP-E<gt>end_section("NAME", ...);>

This method call marks the end of one or several named sections in
your installation script.

If any of the labels listed in this method call matches any of the
subtargets given in the runtime parameter "C<$subset>" - provided
that the latter is not empty - then the execution of all commands
following this method call is disabled.

If there is no match, the commands following this method call will
continue to be executed.

If the runtime parameter "C<$subset>" is empty, this method call is
ignored altogether.

This allows you to terminate different sections at different times,
as in the following example:

    $BnP->begin_section("net","mail");
    # install net software (prerequisite for mail)
    $BnP->end_section("net");
    # install mail software
    $BnP->end_section("mail");

If the runtime parameter "C<$subset>" contains "net", only the "net"
portion will be installed. If it contains "mail", the "net" portion
as well as the "mail" part itself will be installed.

=item *

C<$BnP-E<gt>begin_must_section();>

This method call marks the beginning of a section in your installation
script which is executed under all circumstances.

This method takes no arguments; all arguments passed to it are ignored.

This method call takes precedence over all other method calls defining the
beginning or end of any overlapping section, but it doesn't impede their
(invisible) working, as in the following example:

    $BnP->begin_section("a");
    # commands 1
    $BnP->begin_must_section();
    # commands 2
    $BnP->end_section("a");
    # commands 3
    $BnP->begin_section("b");
    # commands 4
    $BnP->end_must_section();
    # commands 5
    $BnP->end_section("b");

In this example, the commands "2", "3" and "4" are ALWAYS executed,
regardless of the contents of the runtime parameter "C<$subset>".

The commands "1" will be executed only if the runtime parameter "C<$subset>"
is empty or if it contains "a". The commands "5" will be executed only
if the runtime parameter "C<$subset>" is empty or if it contains "b".

=item *

C<$BnP-E<gt>end_must_section();>

This method call marks the end of a section in your installation script
which is executed under all circumstances.

This method takes no arguments; all arguments passed to it are ignored.

=item *

C<$BnP-E<gt>begin_lazy_section("NAME", ...);>

This method call marks the beginning of a section in your installation
script which will be executed ONLY if you specify at least ONE of the
labels listed in this method call EXPLICITLY as part of the runtime
parameter "C<$subset>", i.e., this is some kind of a "lazy" or "delayed"
evaluation section.

This method call takes precedence over any overlapping sections defined
via the "C<begin_section()>" and "C<end_section()>" pair of methods,
as shown in the following example:

    $BnP->begin_section("a");
    # commands 1
    $BnP->begin_lazy_section("x");
    # commands 2
    $BnP->end_section("a");
    # commands 3
    $BnP->begin_section("b");
    # commands 4
    $BnP->end_lazy_section("x");
    # commands 5
    $BnP->end_section("b");

In this example, the commands "2", "3" and "4" are executed if and only
if the runtime parameter "C<$subset>" contains "x".

The commands "1" will be executed only if the runtime parameter "C<$subset>"
is empty or if it contains "a". The commands "5" will be executed only
if the runtime parameter "C<$subset>" is empty or if it contains "b".

Overlapping "lazy" sections behave sligthly differently, as illustrated
in the following example:

    $BnP->begin_lazy_section("a","c");
    # commands 1
    $BnP->begin_lazy_section("b");
    # commands 2
    $BnP->end_lazy_section("a");
    # commands 3
    $BnP->end_lazy_section("b","c");

In this example, the commands "1" and "2" are executed if the runtime
parameter "C<$subset>" contains "a" (or "c").

The commands "2" and "3" are executed if the runtime parameter "C<$subset>"
contains "b" (or "c").

None of these commands is executed if the runtime parameter "C<$subset>"
contains neither "a" nor "b" (nor "c"), and all of these commands are
executed if "C<$subset>" contains "a" as well as "b" (or just "c").

=item *

C<$BnP-E<gt>end_lazy_section("NAME", ...);>

This method call marks the end of one or several named "lazy" sections
in your installation script.

=item *

C<$BnP-E<gt>ignore();>

This method call can be used to "comment out" all subsequent commands
until the next occurrence of a "C<resume()>" method call (see also below).

This method call takes precedence over all others, even "must" sections
and "lazy" sections (see also their corresponding descriptions above).

This method call does not impede the "section" method calls from working,
however, it just prevents any actions to be actually performed, as shown
in the following example:

    $BnP->begin_section("a");
    # commands 1
    $BnP->ignore();
    # commands 2
    $BnP->end_section("a");
    # commands 3
    $BnP->begin_section("b");
    # commands 4
    $BnP->resume();
    # commands 5
    $BnP->end_section("b");

In this example, the commands "2", "3" and "4" are NEVER executed,
regardless of the contents of the runtime parameter "C<$subset>".

The commands "1" will be executed only if the runtime parameter "C<$subset>"
is empty or if it contains "a". The commands "5" will be executed only
if the runtime parameter "C<$subset>" is empty or if it contains "b".

=item *

C<$BnP-E<gt>resume();>

This method call ends a section of your installation script which has been
"commented out".

Normal operation of your installation script resumes after this method call.

Note that you cannot nest "C<ignore()>" and "C<resume()>" method calls; the
first "C<ignore()>" method encountered will disable all following commands,
and the first "C<resume()>" method encountered will enable execution again:

    $BnP->ignore();
    # commands 1
    $BnP->ignore();
    # commands 2
    $BnP->resume();
    # commands 3
    $BnP->resume();
    # commands 4

In this example, the commands "1" and "2" will never be executed,
and execution resumes at commands "3", not "4" (which means that
both commands "3" and "4" are executed, in this example).

=item *

C<$flag = $BnP-E<gt>active();>

This method returns "C<true>" if it is called from within a section which
is currently being executed (for instance, this method ALWAYS returns
"C<true>" when called from within a "must" section), or "C<false>"
otherwise.

In particular, this method also reports "C<false>" if called from within
a part in your installation script that has been "commented out" with the
"C<ignore()>" and "C<resume()>" pair of methods.

=item *

C<$BnP-E<gt>reset();>

This method does nothing but a "C<chdir()>" (see below) to the directory
"C<$workspace>", as defined in the call of the installation project
constructor method "C<new()>" (see above for details).

=item *

C<$BnP-E<gt>back();>

This method is just a shorthand for "C<$BnP-E<gt>chdir('../');>".

=item *

C<$BnP-E<gt>back(COUNT);>

This method is just a shorthand for "C<S<$BnP-E<gt>chdir('../' x COUNT);>>",
where "C<COUNT>" is replaced by "1" if it is less than one.

=item *

C<$BnP-E<gt>chdir("DIR");>

This method can be used to change the current working directory for
all subsequent commands which implicitly act upon it (all Unix and Perl
commands dealing with files and directories normally do, if no absolute
paths are given).

The parameter "C<DIR>" may be an absolute or a relative path. In the
latter case this path will be relative to the current working directory
as defined previously.

At the beginning of the installation, the method "C<begin()>" sets the
current working directory to "C<$workspace>", as defined in the call
of the installation project constructor method "C<new()>" (see above
for details), using the method "C<reset()>" (see above).

=item *

C<$BnP-E<gt>mkdir("DIR");>

This method can be used to create a new directory.

If the directory's path "C<DIR>" is not absolute, it will be relative
to the current working directory, as defined previously using the methods
"C<reset()>", "C<chdir()>" and "C<back()>" (see above for details).

In contrast to the Unix or Perl "C<mkdir>" commands, this method will also
automatically and recursively create any missing intervening directories;
i.e., if the directory "/tmp" does not contain any subdirectories, then the
method call "C<$BnP-E<gt>mkdir('/tmp/bnp/hmtl/mod');>" will first create the
directory "C</tmp/bnp>", then the directory "C</tmp/bnp/html>", and finally
the directory "C</tmp/bnp/html/mod>".

The method does nothing (and does NOT produce any error message) if the
directory to be created already exists.

=item *

C<$BnP-E<gt>fetch("FILENAME", "RELPATH", "SOURCEDIR");>

This method fetches a distribution file from a predefined search path
or (if necessary) a list of URLs and puts it into the specified source
directory.

The method does nothing if the distribution file is already found in
the given source directory.

Otherwise it searches the directories which have been specified previously
by the "C<path()>" and "C<stub()>" methods (see further above), in their
given order.

The method thereby cycles through all the directories specified by "C<path()>".
It first tests any such directory wether it contains the requested distribution
file. If not, the method cycles through all the subdirectories as specified by
"C<stub()>" and tests each of these subdirectories in the currently examined
directory. If the test fails for a subdirectory, the method also tests the
subsubdirectory "RELPATH" in that subdirectory.

If the requested distribution file is found in any of these directories
or (sub-) subdirectories, the method first attempts to create a symbolic
link in the given source directory which points to the location where the
distribution file has been found.

Should this fail for some reason (e.g. if your system does not support
symbolic links), the method alternatively tries to copy the distribution
file to the specified source directory.

If this also fails (for instance in case of disk capacity overrun), the
method gives up and throws a (fatal) exception.

If the requested distribution file is not found in any of these directories,
the method tries to find a tool for the automatic download.

If none of the configured tools (currently "snarf" and "lynx") can be found
on your system, a fatal exception follows.

Otherwise the method searches the URLs which have been specified previously
by the "C<url()>" method (see further above), in the given order.

The method thereby cycles through all the URLs specified by "C<url()>", to
each of which the relative path "RELPATH" and the filename "FILENAME" is
appended (for this reason the given URLs should not end in as slash "C</>"!).

If the requested distribution file cannot be downloaded successfully from
any of these URLs, a corresponding error message is printed to the screen
and program execution is aborted.

Note that this may be due to a server being down temporarily, so sometimes
you may just need to restart your installation script in order to succeed,
or specify a different server.

If the distribution file is found on one of the specified servers, it is
downloaded into the given source directory "SOURCEDIR" and the method
returns to the caller.

=item *

C<$BnP-E<gt>system("COMMAND", ...);>

This method allows you to use any (shell) commands you may need while still
benefiting from the automatic recovery mechanism provided by this module.

All the arguments to this method are concatenated using spaces, i.e., you
don't need to include spaces at the beginning and the end of these arguments,
and you don't need to concatenate them with the "C<.>"-operator yourself
(you will have to supply those spaces yourself if you do, however).

Since all the arguments are concatenated, they form a single command line.

In order to include several different commands on that same command line,
use the semicolon ("C<;>") to separate them, as usually.

=item *

C<$BnP-E<gt>patch("FILENAME", "PERLEXPR", ...);>

This method resembles the Unix tool "C<sed>".

It allows you to apply arbitrary Perl expressions (typically substitution
commands like "C<s///>" and "C<tr///>") to the lines (or paragraphs or the
entire file at once) of the given file.

(The lines (or paragraphs or the entire file) of the file in question are
thereby successively read into the Perl variable "C<$_>".)

Before actually applying any modifications, a new filename for the original
file is generated (for later safeguarding), by appending ".000" to its name
and increasing this number if a file of that name already exists, until a
filename is found which doesn't exist yet.

Another new (temporary) filename is generated (in the same manner) for the
file which will hold the results of the "patch" operation, by using the number
found in the previous step plus one, and again by incrementing this number if
a file of that name already exists, until a filename is found which doesn't
exist yet.

Then the original file is read, all the commands given as arguments to
this method are applied successively (in the given order) to each of the
lines (or paragraphs or the entire file) being read, and the results are
written to a new file with the (temporary) filename (the second of the
two filenames generated above).

Note that you can control the "line" vs. "paragraph" vs. "entire file" mode
by setting the Perl variable "C<$/>" appropriately (see L<perlvar(1)> for
more details).

(Don't forget to reset this variable to its default value in order to avoid
unexpected results in the remaining part of your script, though.)

After reading all of the original file, and only if no errors occurred, the
original file is renamed to the first of the two new filenames generated
above, and the file containing the results of the "patch" operation is
renamed to the (original) filename of the original file.

In case of an error (most likely a Perl syntax error in one of the expressions
you supplied as arguments to this method), all files are closed, the temporary
file containing the results (if any) is deleted, an appropriate error message
is displayed and program execution is aborted.

=back

=head1 MODERATED METHODS

The following methods are subject to be switched "off" and "on" by the
methods "C<begin_section()>", "C<end_section()>", "C<begin_must_section()>",
"C<end_must_section()>", "C<begin_lazy_section()>", "C<end_lazy_section()>",
"C<ignore()>" and "C<resume()>":

  -  reset()
  -  back()
  -  chdir()
  -  mkdir()
  -  fetch()
  -  system()
  -  patch()

You can always determine wether these methods will currently (i.e., in the
current section of your installation script) be executed or ignored by
calling the method "C<active()>", which returns "C<true>" if the section
in question is "active" and "C<false>" if the commands in that section
will currently be ignored.

=head1 SEE ALSO

build(1), genopt(1), make(1), CPAN(3).

=head1 VERSION

This man page documents "BnP" version 2.1.0.

=head1 AUTHORS

  Ralf S. Engelschall - original idea and first private versions

  rse@engelschall.com
  www.engelschall.com

  Steffen Beyer       - complete rewrite and documentation
                        (first public version)

   sb@engelschall.com
  www.engelschall.com/u/sb/download/

=head1 COPYRIGHT

  Copyright (c) 1996 - 1998 by Ralf S. Engelschall.
  All rights reserved.

  Copyright (c) 1998 by Steffen Beyer.
  All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution for details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

