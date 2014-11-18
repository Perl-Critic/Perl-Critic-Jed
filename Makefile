
#-----------------------------------------------------------------------------
# Safety checks...

ifndef PCJD_MODE
PCJD_MODE = development
endif

ifeq ($(PCJD_MODE), production)
$(error Refusing to run in production environment)
endif

#-----------------------------------------------------------------------------

APP      = pcjd
PORT     = 5555
CPAN     = cpan
LOCAL    = $(PWD)/local
PROVE    = prove
PINTO    = pinto
PERL     = perl
REPLY    = reply
IDE      = '/Applications/Sublime Text.app'

PLACKUP            = plackup
PLACK_FLAG_PORT    = -port $(PORT) 
PLACK_FLAG_SERVER  = -server HTTP::Server::PSGI
PLACK_FLAGS        = $(PLACK_FLAG_PORT) $(PLACK_FLAG_SERVER)

MORBO              = $(LOCAL)/bin/morbo
MORBO_FLAG_LISTEN  = --listen http://*:$(PORT)
MORBO_FLAG_VERBOSE = --verbose
MORBO_FLAG_WATCH   =
MORBO_FLAGS        = $(MORBO_FLAG_LISTEN) $(MORBO_FLAG_WATCH) $(MORBO_FLAG_VERBOSE)

CPANM                = cpanm
CPANM_FLAG_MIRROR    = --mirror-only --mirror file://$(PWD)/cpan
CPANM_FLAG_LOCAL_LIB = --local-lib-contained $(LOCAL)
CPANM_FLAG_CPANFILE  = --cpanfile etc/cpanfile
CPANM_FLAGS          = $(CPANM_FLAG_MIRROR) $(CPANM_FLAG_LOCAL_LIB) $(CPANM_FLAG_CPANFILE)

MOJO_MODE = $(PCJD_MODE)

#-----------------------------------------------------------------------------

export MOJO_MODE  := $(MOJO_MODE)
export PERL5LIB   := $(PWD)/lib:$(LOCAL)/lib/perl5
export MANPATH    := $(LOCAL)/man:$(MANPATH)
export PATH       := $(LOCAL)/bin:$(PATH)

unexport PINTO_HOME
unexport PERL_CPANM_OPT

#-----------------------------------------------------------------------------

help:
	@echo Available targets are:
	@echo 'all                     Does dependencies, database, test, start'
	@echo 'clean                   Deletes all application data'
	@echo 'debug                   Starts the app under debugger (perl -d)'
	@echo 'dependencies            Does all dependency targets (run, test, develop)'
	@echo 'dependencies-run        Installs prerequisite Perl modules for runtime into local/'
	@echo 'dependencies-test       Installs prerequisite Perl modules for testing into local/'
	@echo 'dependencies-develop    Installs prerequisite Perl modules for development into local/'
	@echo 'ide                     Spawn an editor ($$IDE) with the application environment'
	@echo 'help                    Display this lovely message'
	@echo 'realclean               Restore everything to a pristine state'
	@echo 'shell                   Spawn a shell ($$SHELL) with the application environment'
	@echo 'start                   Launches the app under morbo'
	@echo 'reply                   Load app in a read-eval-print loop'
	@echo 'test                    Runs unit tests'

#-----------------------------------------------------------------------------

all: dependencies test start

#-----------------------------------------------------------------------------

shell:
	-@$(SHELL)

#-----------------------------------------------------------------------------

dependencies-run:
	$(CPANM) $(CPANM_FLAGS) --notest --quiet --installdeps .

#-----------------------------------------------------------------------------

dependencies-test:
	$(CPANM) $(CPANM_FLAGS) --quiet --installdeps .

#-----------------------------------------------------------------------------

dependencies-develop:
	$(CPANM) $(CPANM_FLAGS) --notest --with-develop --quiet --installdeps .

#-----------------------------------------------------------------------------

dependencies: dependencies-test dependencies-develop

#-----------------------------------------------------------------------------

start:
	$(MORBO) $(MORBO_FLAGS) bin/$(APP)

#-----------------------------------------------------------------------------

debug:
	$(PERL) -d -S $(PLACKUP) $(PLACK_FLAGS) bin/$(APP)

#-----------------------------------------------------------------------------

test: dependencies-test
	$(PERL) -MCarp::Always -S $(PROVE) --color -r test

#-----------------------------------------------------------------------------

clean:
	rm -rf log/*
	rm -rf tmp/*

#-----------------------------------------------------------------------------

realclean: clean
	rm -rf $(LOCAL)

#-----------------------------------------------------------------------------

reply:
	$(REPLY) -MCarp::Always -MPerl::Critic::Jed

#-----------------------------------------------------------------------------

ide:
	open $(IDE)

