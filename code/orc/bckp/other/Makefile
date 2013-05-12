###############################################################################
#  File:   Generic Makefile                                                   #
#  Author: Javier Arranz Richart                                              #
#  Customised for MPI and openMP: Borja López Fernández                       #
###############################################################################

# This is a general purpose Makefile that works on a filesystem following a 
# particular generic structure.
# The project directory shall be routed on the $HOME directory of the user
# that wants to use it. The project directory shall contain 'inc', 'src', 'bin' and 'lib' subdirectories for the Makefile to work
#
# It's recommended that sources for building a library be under 'src/lib'
# whereas the ones for building an executable be under 'src/bin'
#


PROJECTNAME=$(shell echo `pwd | sed -e 's:$(HOME)/::g' | sed -e 's:/.*::g'`)
PROJECT=$(HOME)/$(PROJECTNAME)

COMPONENT=$(shell echo `pwd | sed -e 's:/ut::' | sed -e 's:/src::' | sed -e 's:^.*/::'`)
TYPE=$(shell echo `pwd | sed -e 's:^.*src/::' | sed -e 's:/.*::'`)
LIBPATH = $(PROJECT)/lib
EXENAME = $(PROJECT)/bin/$(COMPONENT)
DLIBNAME = lib$(COMPONENT).so

COMPILER=g++

FLAGS = -g -D_UNIX_ -Dlinux

INC_INCL=/usr/local/include/mysql++

INC_INCL2=-I/usr/local/include/mysql

INC_INCL3=-I/usr/local/include/

#INC_LIBS=mysqlpp_excommon
INC_LIBS2=-lmysqlpp -lmysqlclient


INCLUDE= -I. -I$(PROJECT)/inc $(patsubst %, -I%, $(INC_INCL)) $(MYINCS) $(INC_INCL2) $(INC_INCL3)
LIBS=$(patsubst %, -L%, $(INC_LIBSPATH)) $(patsubst %, -l%, $(INC_LIBS)) $(INC_LIBS2)
LIBS32= -L. -L/usr/lib -lc -lm
MYLIBS= -L$(LIBPATH)

DIRSCPP=
DIRSCC=
DIRSC=

INC_LIBSPATH=


-include $(PROJECT)/Makefile.incl Makefile.incl $(PROJECT)/Makefile.f


.SUFFIXES:


vpath %h $(PROJECT)/inc 


OBJ:=$(patsubst %.cpp,%.o,$(wildcard *.cpp)) $(patsubst %.cpp,%.o, $(foreach i, $(DIRSCPP), $(wildcard $i/*cpp)))

OBJ2:=$(patsubst %.cc,%.o,$(wildcard *.cc)) $(patsubst %.cc,%.o, $(foreach i, $(DIRSCC), $(wildcard $i/*cc)))

OBJ3:=$(patsubst %.c,%.o,$(wildcard *.c) $(foreach i, $(DIRSC), $(wildcard $i/*c)))



default:
	@echo "--->> Project " $(PROJECT) "<<---"
	@echo "--->> Target " $(COMPONENT) "<<---"
	@echo "--->> Type " $(TYPE) "<<---"
	@make $(TYPE)

%.h:
	@true

%.o:%.cpp %.h 
	@echo $(COMPONENT) ": compiling" $< "..."
	$(COMPILER) $(FLAGS)  -fpic  $(INCLUDE) $< -o $*.o

%.o:%.cc %.h 
	@echo $(COMPONENT) ": compiling" $< "..."
	@$(COMPILER) $(FLAGS)  -fpic -c $(INCLUDE) $< -o $*.o

%.o:%.c %.h 
	@echo $(COMPONENT) ": compiling" $< "..."
	@$(COMPILER) $(FLAGS)  -fpic -c $(INCLUDE) $< -o $*.o

out_text:
	@echo "--->> Component" $(COMPONENT) "<<---"

lib: out_text $(OBJ) $(OBJ2) $(OBJ3)
	@echo "creating dynamic library" $(DLIBNAME) "..."
	@$(COMPILER) -Wl,-rpath,$(LIBPATH) $(FLAGS32) -shared -o $(LIBPATH)/$(DLIBNAME) $(OBJ) $(OBJ2) $(OBJ3) $(LIBS)
	@echo "done!!!"

bin: out_text $(OBJ) $(OBJ2) $(OBJ3)
	@echo "linking executable file" $(COMPONENT) "..."
	$(COMPILER) -Wl,-rpath,$(LIBPATH) $(OBJ) $(OBJ2) $(OBJ3) $(FLAGS) $(MYLIBS) $(LIBS) -o $(COMPONENT)

all: bin
	@echo "Target 'all' for building executables is deprecated: try using 'bin' instead"

gall: bin
	@echo "installing executable file" $(EXENAME) "..."
	@mv -f $(COMPONENT) $(EXENAME)
	@echo "done!!!"

test:
	@$(PROJECT)/code/scripts/make_test.sh -c "`pwd`"
	@echo "done!!!"


clean:
	@find . -name "*.o" -exec rm -f {} \;
