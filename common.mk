-include ../common/local.mk

NAME := $(shell rpmspec -q --qf "%{name}" --srpm *.spec)
VERSION := $(shell rpmspec -q --qf "%{version}" --srpm *.spec)

NVR := $(shell rpmspec -q --qf "%{name}-%{version}-%{release}" --srpm $(NAME).spec)

SRPM = $(NVR).src.rpm

ifndef TARBALL
TARBALL := $(NAME)-$(VERSION).tar.gz
endif

URL = "http://$(FEDORA_USER).fedorapeople.org/copr/$(SRPM)"

help:
	@echo "targets: prep srpm local mock install-short upload copr koji verrel"

verrel:
	@echo $(NVR)

srpm: $(SRPM)

prep: $(NAME).spec $(TARBALL)
	rpmbuild -bp --nodeps $(NAME).spec

$(SRPM): $(NAME).spec $(TARBALL)
	rpmbuild -bs $(NAME).spec

$(TARBALL):
	wget -nv http://hackage.haskell.org/package/$(NAME)-$(VERSION)/$(TARBALL)

local: $(NAME).spec $(TARBALL)
	rpmbuild -ba $(NAME).spec

install-short: $(NAME).spec $(TARBALL)
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
