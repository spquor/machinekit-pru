TOPTARGETS := all clean install

SUBDIRS := hal/support hal/drivers/hal_pru_generic

ECHO := echo

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ -f Submakefile $(MAKECMDGOALS)

.PHONY: $(TOPTARGETS) $(SUBDIRS)
