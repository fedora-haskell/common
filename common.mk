-include ../common/local.mk

NAME = $(shell rpmspec -q --qf "%{name}" --srpm *.spec)

NVR= $(shell rpmspec -q --qf "%{name}-%{version}-%{release}" --srpm $(NAME).spec)

SRPM = $(NVR).src.rpm

URL = "http://$(FEDORA_USER).fedorapeople.org/copr/$(SRPM)"

help:
	@echo "targets: prep srpm local mock install-short upload copr koji verrel"

verrel:
	@echo $(NVR)

srpm: $(SRPM)

prep: $(NAME).spec
	rpmbuild -bp --nodeps $(NAME).spec

$(SRPM): $(NAME).spec
	rpmbuild -bs $(NAME).spec

local: $(NAME).spec
	rpmbuild -ba $(NAME).spec

install-short: $(NAME).spec
	rpmbuild -bi --short-circuit $(NAME).spec

koji: $(SRPM)
	koji build --scratch rawhide $(SRPM)

mock: $(SRPM)
	mock $(SRPM)

ifneq ($(FEDORA_USER),)
upload: $(SRPM)
	scp $(SRPM) $(FEDORA_USER)@fedorapeople.org:copr/
	@echo $(URL)

copr:
	copr-cli build $(COPR_REPO) $(URL)
endif
