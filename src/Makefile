# see http://www.cmcrossroads.com/ask-mr-make/6535-tracing-rule-execution-in-gnu-make
# to trace make execution of make in more detail:
#     make VV=1
ifeq ("$(origin VV)", "command line")
    OLD_SHELL := $(SHELL)
    SHELL = $(warning Building $@$(if $<, (from $<))$(if $?, ($? newer)))$(OLD_SHELL)
endif
# Delete the default suffix rules
.SUFFIXES:
.PHONY: default userspace modules clean modclean depclean docclean install

# A "trivial build" is one which should not include dependency information
# either because it should be usable before dependency information can be
# generated or when it is invalid (clean, docclean) or when running as root
# when the user must guarantee in advance that everything is built
# (setuid, install)
ifeq ($(MAKECMDGOALS),)
TRIVIAL_BUILD=no
else
ifeq ($(filter-out clean setuid install tags swish,$(MAKECMDGOALS)),)
TRIVIAL_BUILD=yes
else
TRIVIAL_BUILD=no
endif
endif

# Beautify output
# ---------------------------------------------------------------------------
#
# A simple variant is to prefix commands with $(Q) - that's useful
# for commands that shall be hidden in non-verbose mode.
#
#	$(Q)ln $@ :<
#
# If BUILD_VERBOSE equals 0 then the above command will be hidden.
# If BUILD_VERBOSE equals 1 then the above command is displayed.

ifeq ("$(origin V)", "command line")
  BUILD_VERBOSE = $(V)
endif
ifndef BUILD_VERBOSE
  BUILD_VERBOSE = 0
endif

ifeq ($(BUILD_VERBOSE),1)
  Q =
else
  Q = @
endif

ifeq "$(findstring s,$(MAKEFLAGS))" ""
ECHO=@echo
VECHO=echo
else
ECHO=@true
VECHO=true
endif

# default target:  put before everything else
default:

#############################################################################################

OBJDIR := objects/modules
DEPDIR := depends/modules
RTLIBDIR := ../rtlib/modules

DEP = $(1) $(CPPFLAGS) -MM -MG -MT "$(2)" $(4) -o $(3).tmp && \
	mv -f "$(3)".tmp "$(3)"

cc-option = $(shell \
    if $(CC) $(CPPFLAGS) $(CFLAGS) $(1) -S -o /dev/null -xc /dev/null \
	    > /dev/null 2>&1; then \
	echo "$(1)"; \
    else \
	echo "$(2)"; \
    fi ;)

#############################################################################################


default: userspace modules

# Print 'entering' all the time
MAKEFLAGS += w

# Create the variables with := so that subsequent += alterations keep it
# as a "substitute at assignment time" variable
TARGETS :=

# Submakefiles from each of these directories will be included if they exist
SUBDIRS := \
	\
	hal/support \
	hal/drivers/hal_pru_generic \
    \

# moved to src/rtapi/Submakefile
# ULAPISRCS := rtapi/$(RTPREFIX)_ulapi.c

# Each item in INCLUDES is transformed into a -I directive later on
# The top directory is always included
INCLUDES := .

USERSRCS :=
RTSRCS :=
PROGRAMS :=

# When used like $(call TOxxx, ...) these turn a list of source files
# into the corresponding list of object files, dependency files,
# or both.  When a source file has to be compiled with special flags,
# TOOBJSDEPS is used.  Confusingly, TOOBJSDEPS includes preprocessed source
# file names, but this is what allows 'make src.i' to produce proper
# preprocessed source when src.c needs a customized compile flag.
# See Submakefile.skel for an example.
TOOBJS = $(patsubst %.cc,objects/%$(2).o,$(patsubst %.c,objects/%$(2).o,$(1)))
TODEPS = $(patsubst %.cc,depends/%$(2).d,$(patsubst %.c,depends/%$(2).d,$(1)))
#-not sure, something fishy here -mah
#TODEPS = $(patsubst %.cc,objects/%.d,$(patsubst %.c,objects/%.d,$(1)))

TOOBJSDEPS = $(call TOOBJS,$(1),$(2)) $(call TODEPS, $(1),$(2))

# Same, but for RT objects in OBJDIR, compiled with -DRTAPI
TORTOBJS = $(patsubst %.cc,$(OBJDIR)/%$(2).o,$(patsubst %.c,$(OBJDIR)/%$(2).o,$(1)))

# This macro generates build rules for C components
# Example call & resulting rules:
# $$(eval $(call c_comp_build_rules,hal/components/encoder.o,hal/components/othersrc.o))
# obj-m += encoder.o
# encoder-objs := hal/components/encoder.o hal/components/othersrc.o
# $(RTLIBDIR)/encoder.so: \
#     hal/components/encoder.o hal/components/othersrc.o
define c_comp_build_rules
obj-m += $$(patsubst $$(dir $(1))%.o,%.o,$(1))
$$(patsubst $$(dir $(1))%.o,%-objs,$(1)) += $(1) $(2)
$$(patsubst $$(dir $(1))%.o,$(RTLIBDIR)/%.so,$(1)): \
    $$(addprefix $(OBJDIR)/,$(1) $(2))

endef

###############################################################################

SUBMAKEFILES := $(patsubst %,%/Submakefile,$(SUBDIRS))
#$(info SUBMAKEFILES=$(SUBMAKEFILES))
-include $(wildcard $(SUBMAKEFILES))
$(info All Submakefiles included)

# This checks that all the things listed in USERSRCS are either C files
# or C++ files
ASSERT_EMPTY = $(if $(1), $(error "Should be empty but is not: $(1)"))
ifdef TARGET_PLATFORM_BEAGLEBONE
# the beaglebone port adds .p (PRU assembly) source files, see hal/components
$(call ASSERT_EMPTY,$(filter-out %.c %.cc %.p %.js  %.ph %.proto, $(USERSRCS)))
else
$(call ASSERT_EMPTY,$(filter-out %.c %.cc %.js %.proto, $(USERSRCS)))
endif
$(call ASSERT_EMPTY,$(filter-out %.c, $(RTSRCS)))

# Find the list of object files for each type of source file
CUSERSRCS := $(filter %.c,$(USERSRCS))
CXXUSERSRCS := $(filter %.cc,$(USERSRCS))
CUSEROBJS = $(call TOOBJS,$(CUSERSRCS))
CXXUSEROBJS += $(call TOOBJS,$(CXXUSERSRCS))

# Find the list of build-arch object files for C sources
CUSERSRCS_BUILD := $(filter %.c,$(USERSRCS_BUILD))
CUSEROBJS_BUILD := $(call TOOBJS,$(CUSERSRCS_BUILD),_build)

ifeq ($(TRIVIAL_BUILD),no)

ifeq ($(USE_PROTOBUF),yes)
# force create of %.proto-dependent files and their deps
Makefile: $(GENERATED) $(PROTO_DEPS)
-include $(PROTO_DEPS)
endif

ifdef TARGET_PLATFORM_BEAGLEBONE
ifneq ($(PRU_DEPS),)
Makefile: $(PRU_DEPS)
READ_PRU_DEPS = $(wildcard $(PRU_DEPS))
$(shell echo 1>&2 Reading $(words $(READ_PRU_DEPS))/$(words $(PRU_DEPS)) PRU dependency files)
-include $(wildcard $(READ_PRU_DEPS))
endif
endif

# Find the dependency filenames, then include them all
DEPS := $(sort $(patsubst %.o,%.d,$(CUSEROBJS) $(CXXUSEROBJS) \
	$(CUSEROBJS_BUILD)))
READ_DEPS = $(wildcard $(DEPS))
$(shell echo 1>&2 Reading $(words $(READ_DEPS))/$(words $(DEPS)) dependency files)
-include $(READ_DEPS)
UNREAD_DEPS = $(filter-out $(READ_DEPS), $(DEPS))
LEGACY_DEPS = $(patsubst objects/%, depends/%, $(UNREAD_DEPS))
READ_LEGACY_DEPS = $(wildcard $(LEGACY_DEPS))
ifneq ($(READ_LEGACY_DEPS),)
$(shell echo 1>&2 Reading $(words $(READ_LEGACY_DEPS)) old-style dependency files)
-include $(READ_LEGACY_DEPS)
endif
$(shell echo 1>&2 Done reading dependencies)
endif

# Compilation options.	Perhaps some of these should come from Makefile.inc? (CXXFLAGS now does)
INTEGER_OVERFLOW_FLAGS := $(call cc-option,-fwrapv) $(call cc-option, -fno-strict-overflow)
OPT :=  $(INTEGER_OVERFLOW_FLAGS)
DEBUG := -g -Wall -funwind-tables
INCLUDE := $(patsubst %,-I%, $(INCLUDES))
PROFILE_CFLAGS :=
PROFILE_LDFLAGS :=

CFLAGS := $(INCLUDE) $(OPT) $(DEBUG) $(DPKG_CFLAGS) $(PROFILE_CFLAGS) \
	-DULAPI $(call cc-option,-std=gnu99 -fgnu89-inline)

# if not initialised use innocuous switch to prevent errors
ifeq ($(ARCH_CFLAGS),@ARCH_CFLAGS@)
ARCH_CFLAGS := -Wunused
endif

BASE_CXXFLAGS:= $(INCLUDE) $(CXXFLAGS) \
		$(DEBUG) $(DPKG_CFLAGS) $(OPT) \
		$(PROFILE_CFLAGS) \
		$(ARCH_CFLAGS)

CXXFLAGS :=   $(BASE_CXXFLAGS) -DULAPI
RT_CXXFLAGS :=   $(BASE_CXXFLAGS)

ifeq ($(RUN_IN_PLACE),yes)
LDFLAGS += -L$(LIB_DIR) -Wl,-rpath,$(LIB_DIR)
else
LDFLAGS += -Wl,-rpath-link,../lib
endif
LDFLAGS += -Wl,--no-as-needed

# Rules to make .o (object) files
$(sort $(CUSEROBJS)) : objects/%.o: %.c
	$(ECHO) Compiling $<
	@mkdir -p $(dir $@)
	@rm -f $@
	$(Q)$(CC) -c $(CPPFLAGS) $(CFLAGS) $(EXTRAFLAGS) \
		-MP -MD -MF "${@:.o=.d}" -MT "$@" \
		$< -o $@

# Rules to make .o (object) files, build arch
$(sort $(CUSEROBJS_BUILD)) : objects/%_build.o: %.c
	$(ECHO) Compiling $<
	@mkdir -p $(dir $@)
	@rm -f $@
	$(Q)$(CC_FOR_BUILD) -c $(CFLAGS) $(EXTRAFLAGS) \
		-MP -MD -MF "${@:.o=.d}" -MT "$@" \
		$< -o $@

$(sort $(CXXUSEROBJS)) : objects/%.o: %.cc
	$(ECHO) Compiling ++ $<
	@mkdir -p $(dir $@)
	@rm -f $@
	$(Q)$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $(EXTRAFLAGS) \
		-MP -MD -MF "${@:.o=.d}" -MT "$@" \
		$< -o $@

# And make userspace depend on $(TARGETS)
userspace: $(TARGETS)

# These rules clean things up.	'modclean' cleans files generated by 'modules'
# (except that it doesn't remove the modules that were copied to rtlib)
# 'clean' cleans everything but dependency files, and 'depclean' cleans them
# too.
modclean:
	-rm -f $(RTLIBDIR)/*.so

depclean:
	-rm -rf depends

docclean:
	-rm -f ../man/man9/*.9icomp
	-rm -f ../man/doc/man9/*.asciidoc

clean: depclean modclean docclean
	find . -name '*.o' |xargs rm -f
	-rm -rf objects
	-rm -f $(TARGETS)
	-rm -rf ../rtlib ../libexec
	rm -f ../etc/machinekit/*.ini
	rm -f ../etc/machinekit/*.conf
	-rm -f $(COPY_CONFIGS)
	-rm -f $(RTLIBDIR)/*.so
	-rm -f hal/components/conv_*.comp
	-rm -f hal/i_components/conv_*.icomp
	-rm -f hal/components/*_bin.h   # generated by pasm for bb platform
	-rm -rf ../libexec
	-rm -f ../include/*.hh ../include/*.h

# So that nothing is built as root, this rule does not depend on the touched
# files (Note that files in depends/ might be rebuilt, and there's little that
# can be done about it)
fix_perms = test ! -f $(1) || (chown root $(1) && chmod 4750 $(1))

ifeq ($(BUILD_DRIVERS),yes)
setuid:
ifeq ($(HAVE_SYS_IO),yes)
	$(call fix_perms,../libexec/pci_read)
	$(call fix_perms,../libexec/pci_write)
endif
	$(call fix_perms,../libexec/rtapi_app)
else
setuid:
	@echo "'make setuid' is not needed if hardware drivers are not used"
endif

# These rules allows a header file from this directory to be installed into
# ../include.  A pair of rules like these will exist in the Submakefile
# of each file that contains headers.
../include/%.h: %.h
	$(ECHO) Copying header file $@
	@mkdir -p $(dir $@)
	$(Q)-cp $^ $@
../include/%.hh: %.hh
	$(ECHO) Copying header file $@
	@mkdir -p $(dir $@)
	$(Q)-cp $^ $@


DIR=install -d -m 0755 -o root
FILE=install -m 0644 -o root
TREE=cp -dR
CONFIGFILE=install -m 0644
EXE=install -m 0755 -o root
SETUID=install -m 4755 -o root
GLOB=$(wildcard $(1))

ifeq ($(RUN_IN_PLACE),yes)
define ERROR_MESSAGE
You configured run-in-place, but are trying to install.
For an installable version, run configure without --enable-run-in-place
and rebuild
endef
install:
	$(error $(ERROR_MESSAGE))

else  ## ifeq($(RUN_IN_PLACE),yes)

DOCS_HELP=$(call GLOB,../help/*)
NC_FILES=$(filter-out %/butterfly.ngc,$(call GLOB,../nc_files/*))

install: install-kernel-dep install-kernel-indep
	$(ECHO) "Installed in $(DESTDIR) with prefix $(prefix)"

install-dirs:
	$(DIR)  $(DESTDIR)$(HAL_RTLIB_DIR) \
		$(DESTDIR)$(sysconfdir)/machinekit $(DESTDIR)$(bindir) \
		$(DESTDIR)$(includedir)/machinekit \
		$(DESTDIR)$(docdir) $(DESTDIR)$(ncfilesdir) \
		$(DESTDIR)$(HAL_LIBEXEC_DIR) \
		$(DESTDIR)$(mandir)/man1 \
		$(DESTDIR)$(mandir)/man3 \
		$(DESTDIR)$(mandir)/man9 \
		$(DESTDIR)$(sysconfdir)/rsyslog.d \
		$(DESTDIR)$(sysconfdir)/security/limits.d \
		$(DESTDIR)$(sysconfdir)/udev/rules.d \
		$(DESTDIR)$(sampleconfsdir) \
		$(DESTDIR)$(datadir)/machinekit \
		$(DESTDIR)$(datadir)/pkgconfig
	$(DIR)	$(DESTDIR)$(includedir)/machinekit/userpci

install-kernel-indep: install-dirs
	$(EXE) ../scripts/realtime $(DESTDIR)$(bindir)
	$(EXE) ../scripts/halrun $(DESTDIR)$(bindir)
	$(EXE) ../scripts/runtests $(DESTDIR)$(bindir)
	$(EXE) $(filter ../bin/%,$(TARGETS)) $(DESTDIR)$(bindir)
	$(FILE) $(filter ../lib/%.a ../lib/%.so.0,$(TARGETS)) $(DESTDIR)$(libdir)
	cp --no-dereference $(filter ../lib/%.so, $(TARGETS)) $(DESTDIR)$(libdir)
#	# don't run ldconfig under fakeroot (silence dpkg-build warning)
	-test -n "$$FAKED_MODE" || ldconfig $(DESTDIR)$(libdir)
	$(FILE) $(HEADERS) $(DESTDIR)$(includedir)/machinekit/
	$(FILE) $(USERPCI_HEADERS) $(DESTDIR)$(includedir)/machinekit/userpci
	$(FILE) Makefile.modinc $(DESTDIR)$(datadir)/machinekit
	$(FILE) Makefile.inc $(DESTDIR)$(datadir)/machinekit
	$(FILE) ../share/pkgconfig/machinekit-hal.pc \
	    $(DESTDIR)$(datadir)/pkgconfig

	$(FILE) rtapi/rsyslogd-hal.conf $(DESTDIR)$(sysconfdir)/rsyslog.d/hal.conf
	$(FILE) rtapi/shmdrv/limits.d-machinekit.conf \
		$(DESTDIR)$(sysconfdir)/security/limits.d/machinekit.conf
	$(FILE) ../etc/machinekit/machinekit.ini $(DESTDIR)$(sysconfdir)/machinekit
	$(EXE) ../bin/mank $(DESTDIR)$(bindir)

install-kernel-dep: install-dirs
	$(SETUID) ../libexec/rtapi_app $(DESTDIR)$(HAL_LIBEXEC_DIR)
ifeq ($(BUILD_DRIVERS),yes)
ifeq ($(HAVE_SYS_IO),yes)
	$(SETUID) ../libexec/pci_write $(DESTDIR)$(HAL_LIBEXEC_DIR)
	$(SETUID) ../libexec/pci_read $(DESTDIR)$(HAL_LIBEXEC_DIR)
endif
endif
	$(EXE) ../libexec/inivar $(DESTDIR)$(HAL_LIBEXEC_DIR)
	$(EXE) ../libexec/rtapi_msgd $(DESTDIR)$(HAL_LIBEXEC_DIR)
	$(FILE) ../etc/machinekit/rtapi.ini $(DESTDIR)$(sysconfdir)/machinekit

	# RTAPI modules:  install userland flavor .so modules into
	# e.g. /usr/lib/machinekit/modules

	echo Installing modules
	$(DIR) $(DESTDIR)$(HAL_RTLIB_BASE_DIR)/modules
	$(FILE) ../rtlib/modules/* \
		    $(DESTDIR)$(HAL_RTLIB_BASE_DIR)/modules

endif # ! RUN_IN_PLACE

CONF=../configs
COMMON=$(CONF)/common
CONFILES=$(addsuffix /$(1), $(filter-out $(COMMON) $(CONF),\
                                         ${shell find ${CONF} -type d -print}))

#################################################################################################################

EXTRA_CFLAGS += \
        $(ARCH_CFLAGS) \
	-D__MODULE__ \
    -I$(INCLUDE_PREFIX) \
    -I./hal/support/pru \
	-DSEQUENTIAL_SUPPORT -DHAL_SUPPORT -DDYNAMIC_PLCSIZE -DRT_SUPPORT \
	-DOLD_TIMERS_MONOS_SUPPORT -DMODBUS_IO_MASTER \
	$(call cc-option,-mieee-fp) \
	$(KERNEL_MATH_CFLAGS)

################################################################################
# Misc C components in directories with no Submakefile
TOCOMPRTOBJS = $(foreach file,$($(patsubst %.o,%,$(1))-objs), $(OBJDIR)/$(file))

#######################################################################################################

# Module building
EXTRA_CFLAGS += -fPIC

# Non-module RT objects
RTOBJS = $(call TORTOBJS,$(RTSRCS))
# Module RT objects
RTOBJS += $(sort $(foreach mod,$(obj-m),$(call TOCOMPRTOBJS,$(mod))))

RTDEPS := $(sort $(patsubst $(OBJDIR)/%.o,$(DEPDIR)/%.d, $(RTOBJS)))

# this arcane step warrants some explanation.

# this is about linking userland RT modules to be loaded by rtapi_app
# Those modules are supposed to behave the same as kernel RT modules as far as
# symbol visibility goes. Other than in plain C, in-kernel symbol
# export is explicitly controlled by the EXPORT_SYMBOL(sym) macro.
# only variables and functions tagged such will be visible to the rest of the kernel
# and other modules.
# See http://stackoverflow.com/questions/9836467/whats-meaning-of-export-symbol-in-linux-kernel-code
# for an explanation and use.
#
# userland RT modules need to follow the same visibility rules as kernel modules
# to prevent accidential spillover of symbols between components (which does not happen
# in kernel space).
#
# The kernel behavior of EXPORT_SYMBOL is emulated as follows:
# rtapi_export.h defines
# #define EXPORT_SYMBOL(x) __attribute__((section(".rtapi_export"))) \
#    char rtapi_exported_##x[] = #x;
#
# This means any symbol 'foo' exported as EXPORT_SYMBOL(foo) will:
# - have a variable defined which looks like so:
#   char rtapi_exported_foo = "foo";
# - have put this variable put in the .rtapi_export section of the object file.
#   (see http://wiki.osdev.org/ELF_Tutorial#The_String_Table)
# - this string table is different from the default string table named .srtab.
#
# Hence, the .rtapi_export section of a RT module is a pure string table; no other
# variables live there. The strings in this table is the set of symbols exported by
# this module.
#
# Now, during linking, all symbols which are NOT in this set need to be removed.
#
# to do so, first the .rtapi_export section (the string table) is extracted and stored
# in a file - one can reproduce with:
#
# objcopy -j .rtapi_export -O binary objects/posix/hal_lib.tmp /dev/stdout | strings
# rtapi_info_author
# rtapi_info_description
# rtapi_info_license
# rtapi_app_main
# rtapi_app_exit
# hal_init
# hal_xinit
# hal_xinitf
# hal_ready
# ....
#
# In the second objcopy step, all symbols not in this set are removed. This is done
# by determining the list of symbols to be kept, and generating a list of lines like
# -G <symbol>
# which is the objcopy option for removing all other symbols not in this list:
# -G symbolname
# --keep-global-symbol=symbolname
#   Keep only symbol symbolname global.  Make all other symbols local to the file, so that they are not
#   visible externally.  This option may be given more than once.
# This objcopy step is in-place, i.e. overwriting the .tmp file.
#
# The final linking step uses the -Bsymbolic flag - what this does is:
#
# This element's presence in a shared object library alters the dynamic linker's symbol resolution
# algorithm for references within the library. Instead of starting a symbol search with the
# executable file, the dynamic linker starts from the shared object itself. If the shared object
# fails to supply the referenced symbol, the dynamic linker then searches the executable
# file and other shared objects as usual.
# (from https://www.technovelty.org/c/what-exactly-does-bsymblic-do.html)
#
# this is important for symbol resolution when the .so is loaded within rtapi_app:
# it means that symbols referenced are resolved within the object first, instead of looking
# at any symbols exported (maybe by accident) by rtap_app proper.
#

modules:
ifeq ($(RUN_IN_PLACE)+$(BUILD_DRIVERS),yes+yes)
	@test -f ../libexec/rtapi_app -a \
	    \( 0`stat -c %u ../libexec/rtapi_app 2>/dev/null` \
			-ne 0 -o ! -u ../libexec/rtapi_app \) \
		&& need_setuid=1; \
	test "$$need_setuid" = 1 && \
	    $(VECHO) -n "You now need to run 'sudo make setuid' " && \
	    $(VECHO) "in order to run in place." || true
endif

modules: $(patsubst %.o,$(RTLIBDIR)/%.so,$(obj-m))
$(RTLIBDIR)/%.so:
	$(ECHO) Linking realtime $(notdir $@)
	@mkdir -p $(dir $@)
	@# link all objects files into a single .so
	$(Q)$(LD) -d -r -o $(OBJDIR)/$*.tmp $^
	@# use the .rtapi_export string table to generate a ld version script
	@# explicitly defining the EXPORT_SYMBOL syms as global, and everything else as local:
	$(Q)$(OBJCOPY) -j .rtapi_export -O binary $(OBJDIR)/$*.tmp $(OBJDIR)/$*.exported
	$(Q)(echo '{ global : ';  tr -s '\0' <$(OBJDIR)/$*.exported | xargs -r0 printf '%s;\n' | grep .; echo 'local : * ; };') > $(OBJDIR)/$*.ver
	@# link the final object using this version script:
	$(Q)$(CC) -shared -Bsymbolic $(LDFLAGS) -Wl,--version-script,$(OBJDIR)/$*.ver -o $@ $^ $(EXTRA_LDFLAGS)

$(sort $(RTDEPS)): $(DEPDIR)/%.d: %.c
	@mkdir -p $(dir $@)
	$(ECHO) Depending realtime $<
	$(Q)$(call DEP,$(CC),$@ \
		$(patsubst depends/%.d,objects/%.o,$@),$@,$(OPT) \
		$(DEBUG) $(CPPFLAGS) $(EXTRA_CFLAGS) $<)

# Rules to make .o (object) files
$(sort $(RTOBJS)) : $(OBJDIR)/%.o : %.c $(DEPDIR)/%.d
	$(ECHO) Compiling realtime $<
	@rm -f $@
	@mkdir -p $(dir $@)
	$(Q)$(CC) -c $(OPT) $(DPKG_CFLAGS) $(DEBUG) $(CPPFLAGS) \
	    $(EXTRA_CFLAGS) $< -o $@

# Rules to make .o (object) files from .cc
$(sort $(CXXRTOBJS)) : $(OBJDIR)/%.o : %.cc $(DEPDIR)/%.d
	$(ECHO) Compiling realtime++ $<
	@rm -f $@
	@mkdir -p $(dir $@)
	$(Q)$(CXX) -c $(OPT) $(DEBUG) $(RT_CXXFLAGS) $(CPPFLAGS) \
	    $(EXTRA_CFLAGS) $< -o $@



# When you depend on objects/var-ZZZ you are depending on the contents of the
# variable ZZZ, which is assumed to depend on a Makefile, a Submakefile, or
# Makefile.inc
objects/var-%: Makefile $(wildcard $(SUBMAKEFILES)) Makefile.inc
	@mkdir -p $(dir $@)
	@echo $($*) > $@.tmp
	@sh move-if-change $@.tmp $@

# Link shared libs
../lib/%.so: ../lib/%.so.0
	$(ECHO) Symlinking $(notdir $<) to $(notdir $@)
	$(Q)ln -sf $(notdir $<) $@
# - Be sure the setuid message comes last
ALL_SHLIBS=$(filter ../%.so.0,$(TARGETS)) $(filter ../%.so,$(TARGETS))
modules: $(ALL_SHLIBS)
