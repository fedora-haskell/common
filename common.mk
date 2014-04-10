-include ../common/local.mk

NAME = $(shell rpmspec -q --qf "%{name}" --srpm *.spec)

NVR= $(shell rpmspec -q --qf "%{name}-%{version}-%{release}" --srpm $(NAME).spec)

SRPM = $(NVR).src.rpm

URL = "http://$(FEDORA_USER).fedorapeople.org/uploads/$(SRPM)"

help:
	@echo "targets: srpm local upload copr verrel"

verrel:
	@echo $(NVR)

srpm: $(SRPM)

$(SRPM): $(NAME).spec
	rpmbuild -bs $(NAME).spec

local: $(NAME).spec
	rpmbuild -ba $(NAME).spec

upload: $(SRPM)
	scp $(SRPM) $(FEDORA_USER)@fedorapeople.org:uploads/
	@echo $(URL)

copr:
	copr-cli build $(COPR_REPO) $(URL)