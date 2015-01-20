use 5.019005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

`yapp -o lib/WDL.pm lib/WDL.yp`;

WriteMakefile(
    NAME              => 'WDL::Processor',
    VERSION_FROM      => 'lib/WDL/Processor.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                      Graph => 0.96,
                      'Set::Scalar' => 1.29,
                      GraphViz => 2.15,
                      'Log::Log4perl' => 1.44,
    },
    'EXE_FILES'       => [ "bin/wdl_tool_checker","bin/wdl" ],
    ABSTRACT_FROM     => 'lib/WDL/Processor.pm', # retrieve abstract from module
    AUTHOR            => 'Rui Brito <rmb@local>',
    clean             =>  { FILES => "lib/WDL.pm" },
    OPTIMIZE          => '-g'
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);


sub MY::postamble {
"
lib/WDL.pm: lib/WDL.yp
	yapp -o lib/WDL.pm lib/WDL.yp
";
}
