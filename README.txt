     ____          _  _      _  _         _  ____   _
    | __ )  _   _ (_)| |  __| |( ) _ __  ( )|  _ \ | |  __ _  _   _
    |  _ \ | | | || || | / _` ||/ | '_ \ |/ | |_) || | / _` || | | |
    | |_) || |_| || || || (_| |   | | | |   |  __/ | || (_| || |_| |
    |____/  \__,_||_||_| \__,_|   |_| |_|   |_|    |_| \__,_| \__, |
                                                              |___/


Installation:
=============

For installation instructions see the file "INSTALL.en" in this distribution.


What is "Build'n'Play"?
=======================

"Build'n'Play" is a batch tool intended for system administrators who
have to install the same software packages (including, but not limited
to Perl) on various Unix platforms over and over again (e.g. for perio-
dically upgrading existing or installing new machines).

The most important feature of "Build'n'Play" is its capability to automa-
tically resume the installation process at the exact position where it was
interrupted (by a compiler error, for instance) after (manually) resolving
the problem and restarting (for an overview of the other features, see
further below).

"Build'n'Play" mainly consists of three parts (plus one optional part):
A shell script used for starting the batch jobs and handling the user's
command line parameters (plus the bootstrapping of Perl if necessary),
a Perl module which implements the automatic recovery mechanism, and
Perl scripts which perform the actual installation.

Additionally, an (optional) tool is available for maintaining a clean
installation directory structure in which every software package is
installed in a separate directory subtree of its own, allowing the
(dynamic) grouping of related software packages into categories
(i.e., common subdirectories) and the easy de-installation without
any residues (as opposed to installing everything to "/usr/local",
for instance).

This latter tool (also a shell script) can also be used completely
independently from the rest of "Build'n'Play".

(For more details about this tool see the file "genopt.pod" in this
distribution or "man genopt" after the installation of "Build'n'Play".)

Note that when installing for the first time, the installation scripts
included in "Build'n'Play" will most likely need to be adjusted for the
operating system you are running it on and to suit your personal needs
(or your company's policy).

Therefore do not expect the installation to run smoothly from beginning
to end without any interruptions when you run it for the first time.

The necessary adjustments are facilitated through some "diffs" for a couple
of operating systems which are included in this distribution (at least for
the "Perl" installation script) and which can be applied using the popular
"patch" utility (another great feat from Perl's father Larry Wall).

Nevertheless this investment in fine-tuning the installation scripts appears
worthwhile only if you need to install the software packages more than once;
or if you are willing to comment out those (Perl) modules which pose problems
and to content yourself with the remaining ones (there are hundreds of them).

Since there is already a very powerful installation tool for Perl modules
(and bundles of Perl modules) called "CPAN.pm" (see the "CPAN(3)" manual
page in your Perl installation for more details), many people have asked
me "Why another tool?" and "What's the difference between the two?".

So here is a table listing some of the most prominent differences and
similarities between "Build'n'Play" and "CPAN.pm":

+-----------------------------------+----------------+----------------+
|             Feature:              | "Build'n'Play" |   "CPAN.pm"    |
+-----------------------------------+----------------+----------------+
| Installation of other software    |                |                |
| packages besides Perl and its     |       yes      |       no       |
| modules (gcc, apache, pgp, ...)   |                |                |
+-----------------------------------+----------------+----------------+
| Installation of combined C and    |                |                |
| Perl software packages (such as   |       yes      |       no       |
| Gimp and ImageMagick)             |                |                |
+-----------------------------------+----------------+----------------+
| Allows installation of software   |                |                |
| packages in a way which permits   |       yes      |       n.a.     |
| complete de-installation          |                |                |
+-----------------------------------+----------------+----------------+
| Facilities for handling packages  |                |                |
| which need to be patched before   |       yes      |       no       |
| the installation or which need    |                |                |
| other special handling            |                |                |
+-----------------------------------+----------------+----------------+
| Automatic recovery after errors   |                |                |
| (continue installation where      |       yes      |       no       |
| interrupted after manually fixing |                |                |
| the broken module or package)     |                |                |
+-----------------------------------+----------------+----------------+
| Runs out-of-the-box with a CPAN   |                |    requires    |
| snapshot on CD-ROM on hosts with- |       yes      |  tricky manual |
| out any access to a CPAN server   |                |  configuration |
+-----------------------------------+----------------+----------------+
| Runs even if there is no Perl 5   |                |                |
| installed yet on the current host |       yes      |       no       |
+-----------------------------------+----------------+----------------+
| Installation of Perl itself       |       yes      |       no       |
+-----------------------------------+----------------+----------------+
| Installation of sets of modules   |       yes      |       yes      |
+-----------------------------------+----------------+----------------+
| Automatic download of source      |                |                |
| distribution files from a server  |       yes      |       yes      |
| (LAN and/or Internet)             |                |                |
+-----------------------------------+----------------+----------------+
| Batch mode                        |       yes      |       yes      |
+-----------------------------------+----------------+----------------+
| Interactive mode                  |       no       |       yes      |
+-----------------------------------+----------------+----------------+
| Provides detailed and up-to-date  |                |                |
| information about any Perl module |       no       |       yes      |
| available from CPAN               |                |                |
+-----------------------------------+----------------+----------------+
| Automatic version control (vs.    |                |                |
| manual adjustment of version      |       no       |       yes      |
| number in installation script)    |                |                |
+-----------------------------------+----------------+----------------+
| Runs out-of-the-box (not counting | Needs more or  | LWP::UserAgent |
| command line parameters and ad-   | less intensive | may need to be |
| justing configuration constants)  |  adjustments   |  fixed first   |
+-----------------------------------+----------------+----------------+
| Automatic handling of inter-      | Only through   | Only through   |
| dependencies between Perl modules | definition of  | definition of  |
| (see also footnote below)         | proper subsets | proper bundles |
+-----------------------------------+----------------+----------------+

(The latter point has already been taken into account during the development
of the "Perl" installation script of "Build'n'Play" and should not pose any
problems. Such an automatic mechanism could (in principle) be built into the
"Perl" installation script, however.)

(The "tricky configuration" for "CPAN.pm" mentioned further above goes as
follows: Enter "perl -MCPAN -e shell", respond "no" to "Are you ready for
manual configuration?", enter some command which tries to go online such
as "i BnP", respond "no" again to "Are you ready for manual configuration?", 
and finally enter the command "o conf urllist push file:/my_cd/CPAN" (or
whatever the path to your CD-ROM drive is) - only after that you'll be in
business. Note that you cannot enter this last command successfully before
you actually tried to go online! With "Build'n'Play", just say "-s /my_cd"
on the command line if the path to your CD-ROM drive is not "/cdrom" or
"/cdrec" - in which case you don't need to do anything, just mount your
CD-ROM.)


Authors:
========

Ralf S. Engelschall - original idea and first private versions

rse@engelschall.com
www.engelschall.com

Steffen Beyer       - complete rewrite and documentation
                      (first public version)
 sb@sdm.de
 sb@engelschall.com
www.engelschall.com/u/sb/download/


Copyright:
==========

Copyright (c) 1996 - 1998 by Ralf S. Engelschall.
All rights reserved.

Copyright (c) 1998 by Steffen Beyer.
All rights reserved.


License:
========

"Build'n'Play" is free software; you can redistribute it and/or modify it
under the same terms and conditions as Perl, i.e., under either (at your
option) the "Artistic License" or the "GNU General Public License".

Please see the files "Artistic.txt" and "GNU_GPL.txt" in this distribution
for details!


Disclaimer:
===========

"Build'n'Play" is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.


Credits:
========

Special thanks go to

- Michael Gerth <mic@oreilly.de> of O'Reilly Verlag Cologne, Germany,
  who initiated this project and promoted and supported it in many ways,

- my employer, software design & management GmbH & Co. KG (http://www.sdm.de/)
  (sd&m) in Munich, Germany, especially to my head of division and subdivision,
  Ruediger Azone <azone@sdm.de> and Ulrich Bonfig <bonfig@sdm.de>, who allowed
  and facilitated this extra-professional activity of mine without any ado,

- Ralf S. Engelschall <rse@engelschall.com>,
  the original author of "Build'n'Play",

who all three made this project possible in the first place.

Moreover I am extremely grateful to the beta testers

        Marc Lehmann   <pcg@goof.com>,
        Robert Aussem  <raussem@cscploenzke.de> and
        Eike Grote     <eike.grote@btp4x8.phy.uni-bayreuth.de>

for their patience and struggling with me and this software and their
many good suggestions, many of which were incorporated into this project.

For test accounts on a Linux system and an HP I wish to thank Gottfried
Bartmuss <gob@sdm.de> and Andreas Haeusler <andreas@sdm.de> wholeheartedly.

I also owe many deeply felt thanks to the University of Zurich, Switzerland
(Eidgenoessische Technische Hochschule Zuerich ETHZ) for sponsoring us a web
server and to Ralf S. Engelschall for giving me a very comprehensive access
to it (including an account and my own WWW and FTP area).

The server with a mirror of CPAN and a CD-R writer in the same LAN as this
server (indispensable for producing the pre-master CD for the book by O'Reilly
Verlag containing the CPAN snapshot) are located at and were provided by sd&m.


Known Bugs:
===========

1) The installations of "Gimp" und "ImageMagick" succeed, but they are
   nevertheless incomplete; the support for various graphics formats is
   still lacking (the corresponding libraries are not linked in correctly).

2) The tool "bzip2" does not compile on FreeBSD (2.2.6); "ld" complains
   about: "-lbz2: no match".
   Solution: Use the older version of "bzip2" which already comes with
   the distribution of FreeBSD instead.

Any hints for how to solve these problems above are greatly appreciated!


Miscellaneous:
==============

Should you find bugs in "Build'n'Play" or need assistance, please contact
Steffen Beyer <sb@engelschall.com>.

Thank you very much!


