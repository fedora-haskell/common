-include ../common/local.mk

NAME = $(shell rpmspec -q --qf "%{name}" --srpm *.spec)

NVR= $(shell rpmspec -q --qf "%{name}-%{version}-%{release}" --srpm $(NAME).spec)

SRPM = $(NVR).src.rpm

URL = "http://$(FEDORA_USER).fedorapeople.org/uploads/$(SRPM)"

help:
	@echo "targets: prep srpm local upload copr koji verrel"

verrel:
	@echo $(NVR)

srpm: $(SRPM)

prep: $(NAME).spec
	rpmbuild -bp $(NAME).spec

$(SRPM): $(NAME).spec
	rpmbuild -bs $(NAME).spec

local: $(NAME).spec
	rpmbuild -ba $(NAME).spec

upload: $(SRPM)
	scp $(SRPM) $(FEDORA_USER)@fedorapeople.org:uploads/
	@echo $(URL)

koji: $(SRPM)
	koji build --scratch rawhide $(SRPM)

copr:
	copr-cli build $(COPR_REPO) $(URL)
