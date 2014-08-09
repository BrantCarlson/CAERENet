ifndef MODEL
MODEL = 1
# model = 1 --> ram only (default)
# 2 --> eeprom and shutdown
# 3 --> eeprom and run
endif

SC = /home/brant/software/prop/bstc.linux
#SC = /opt/parallax/bin/bstc.linux

LOAD = /opt/parallax/bin/propeller-load

SPINFLAGS = -Ogxr

SOURCE = prop.spin
EXECUTABLE = $(SOURCE:.spin=.binary)

all: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCE)
	$(SC) $(SPINFLAGS) -b $@

load: $(EXECUTABLE)
	sudo $(LOAD) -r -b c3 $(EXECUTABLE)

loadterm: $(EXECUTABLE)
	xterm -e "sudo $(LOAD) -r -b c3 -t $(EXECUTABLE); zsh"

loadsave: $(EXECUTABLE)
	sudo $(LOAD) -r -b c3 -e $(EXECUTABLE)

clean:
	rm -rf *.binary
