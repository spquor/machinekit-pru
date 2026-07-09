# machinekit-pru
Machinekit HAL driver for the TI Programmable Realtime Unit used

Succesfully compiles with modern LinuxCNC on BeagleBone

## Building from source
Run make && make install inside src dir. Useful environment variables:

DESTDIR - root dir for binaries install

INCLUDE_PREFIX - full path to LinuxCNC include files

Contains two driver varians, hal and halv2. hal directory is original driver. halv2 contains updated driver with bbai support.

### Help available at: [hal_pru_generic.asciidoc](https://github.com/spquor/machinekit-pru/blob/main/hal_pru_generic.asciidoc)
