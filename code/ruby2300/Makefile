
SHELL = /bin/sh

#### Start of system configuration section. ####

srcdir = .
topdir = /opt/local/lib/ruby/1.8/i686-darwin10
hdrdir = $(topdir)
VPATH = $(srcdir):$(topdir):$(hdrdir)
prefix = $(DESTDIR)/opt/local
exec_prefix = $(prefix)
libdir = $(exec_prefix)/lib
datadir = $(datarootdir)
oldincludedir = $(DESTDIR)/usr/include
libexecdir = $(exec_prefix)/libexec
sitearchdir = $(sitelibdir)/$(sitearch)
rubylibdir = $(libdir)/ruby/$(ruby_version)
htmldir = $(docdir)
vendorlibdir = $(vendordir)/$(ruby_version)
datarootdir = $(prefix)/share
dvidir = $(docdir)
archdir = $(rubylibdir)/$(arch)
mandir = $(DESTDIR)/opt/local/share/man
vendordir = $(DESTDIR)/opt/local/lib/ruby/vendor_ruby
sitelibdir = $(sitedir)/$(ruby_version)
infodir = $(datarootdir)/info
sharedstatedir = $(prefix)/com
localedir = $(datarootdir)/locale
includedir = $(prefix)/include
bindir = $(exec_prefix)/bin
localstatedir = $(prefix)/var
vendorarchdir = $(vendorlibdir)/$(sitearch)
sbindir = $(exec_prefix)/sbin
docdir = $(datarootdir)/doc/$(PACKAGE)
pdfdir = $(docdir)
sysconfdir = $(prefix)/etc
psdir = $(docdir)
sitedir = $(libdir)/ruby/site_ruby

CC = /usr/bin/gcc-4.2
LIBRUBY = $(LIBRUBY_SO)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)-static

RUBY_EXTCONF_H = 
CFLAGS   =  -fno-common -pipe -O2 -arch x86_64  -fno-common -pipe -fno-common $(cflags) -arch x86_64
INCFLAGS = -I. -I. -I/opt/local/lib/ruby/1.8/i686-darwin10 -I.
DEFS     = 
CPPFLAGS =  -I/Users/borja/Projects/dec/code/ruby2300 -I/opt/local/include -D_XOPEN_SOURCE -D_DARWIN_C_SOURCE  -I/opt/local/include
CXXFLAGS = $(CFLAGS) 
ldflags  = -L. -L/opt/local/lib -arch x86_64 -Wl,-rpath,/Users/borja/Projects/dec/code/ruby2300
dldflags = 
archflag = -arch x86_64
DLDFLAGS = $(ldflags) $(dldflags) $(archflag)
LDSHARED = $(CC) -dynamic -bundle -undefined suppress -flat_namespace
AR = ar
EXEEXT = 

RUBY_INSTALL_NAME = ruby
RUBY_SO_NAME = ruby
arch = i686-darwin10
sitearch = i686-darwin10
ruby_version = 1.8
ruby = /opt/local/bin/ruby
RUBY = $(ruby)
RM = rm -f
MAKEDIRS = mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp

#### End of system configuration section. ####

preload = 

libpath = . $(libdir) /Users/borja/Projects/dec/code/ruby2300 /opt/local/lib
LIBPATH =  -L. -L$(libdir) -L/Users/borja/Projects/dec/code/ruby2300 -L/opt/local/lib
DEFFILE = 

CLEANFILES = mkmf.log
DISTCLEANFILES = 

extout = 
extout_prefix = 
target_prefix = 
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED) -lopen2300  -lpthread -ldl -lobjc  
SRCS = ruby2300.c
OBJS = ruby2300.o
TARGET = ruby2300
DLLIB = $(TARGET).bundle
EXTSTATIC = 
STATIC_LIB = 

BINDIR        = $(bindir)
RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR    = $(sitelibdir)$(target_prefix)
RUBYARCHDIR   = $(sitearchdir)$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).bundle $(TARGET).il? $(TARGET).tds $(TARGET).map
CLEANOBJS     = *.o *.a *.s[ol] *.pdb *.exp *.bak

all:		$(DLLIB)
static:		$(STATIC_LIB)

clean:
		@-$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES)

distclean:	clean
		@-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		@-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)

realclean:	distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
	$(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
$(RUBYARCHDIR):
	$(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .cxx .cpp .C .o

.cc.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cxx.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cpp.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.C.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.c.o:
	$(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -c $<

$(DLLIB): $(OBJS) Makefile
	@-$(RM) $@
	$(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)



$(OBJS): ruby.h defines.h
