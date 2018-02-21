-include ../common/local.mk

NAME := $(shell rpmspec -q --qf "%{name}" --srpm *.spec)
VERSION := $(shell rpmspec -q --qf "%{version}" --srpm *.spec)

NODIST = --undefine dist

NVR := $(shell rpmspec -q $(NODIST) --qf "%{name}-%{version}-%{release}" --srpm $(NAME).spec)

SRPM = $(NVR).src.rpm

PATCH := $(shell rpmspec -q --qf "%{patch}" --srpm $(NAME).spec | grep -v "(none)")

SRPM_URL = "http://$(FEDORA_USER).fedorapeople.org/copr/$(SRPM)"

RPMBUILD = rpmbuild --define "_specdir $(PWD)" --define "_sourcedir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)"

SOURCES = $(shell spectool -l -S $(NAME).spec | awk '{ print $$2}' | xargs basename -a)

help:
	@echo "targets: prep srpm local mock short upload copr koji verrel"

verrel:
	@echo $(NVR)

srpm: $(SRPM)

prep: $(NAME).spec $(SOURCES)
	$(RPMBUILD) -bp --nodeps $(NAME).spec

$(SRPM): $(NAME).spec $(SOURCES) $(PATCH)
	$(RPMBUILD) $(NODIST) -bs $(NAME).spec

$(SOURCES):
	spectool -g -S $(NAME).spec

local: $(NAME).spec $(SOURCES)
	$(RPMBUILD) -ba $(NAME).spec | tee .$(NVR).log

short: $(NAME).spec
	$(RPMBUILD) -bi --short-circuit $(NAME).spec

koji: $(SRPM)
	koji build --scratch rawhide $(SRPM)

mock: $(SRPM)
	mock -r fedora-rawhide-x86_64 --enable-network $(MOCK_OPTS) $(SRPM)

ifneq ($(FEDORA_USER),)
upload: $(SRPM)
	scp $(SRPM) $(FEDORA_USER)@fedorapeople.org:copr/
	@echo $(SRPM_URL)

srpm-url:
	@echo $(SRPM_URL)

copr:
	@echo "https://copr.fedoraproject.org/coprs/$(FEDORA_USER)/$(COPR_REPO)/builds/"
	copr-cli build $(COPR_REPO) $(SRPM_URL)
endif
