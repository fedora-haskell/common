-include ../common/local.mk

NAME := $(shell rpmspec -q --qf "%{name}" --srpm *.spec)
VERSION := $(shell rpmspec -q --qf "%{version}" --srpm *.spec)

NVR := $(shell rpmspec -q --qf "%{name}-%{version}-%{release}" --srpm $(NAME).spec)

SRPM = $(NVR).src.rpm

PATCH := $(shell rpmspec -q --qf "%{patch}" --srpm $(NAME).spec | grep -v "(none)")

ifndef NO_TARBALL
ifndef TARBALL
ifdef PKG
TARBALL := $(PKG)-$(VERSION).tar.gz
else
TARBALL := $(NAME)-$(VERSION).tar.gz
endif
endif
endif

SRPM_URL = "http://$(FEDORA_USER).fedorapeople.org/copr/$(SRPM)"

RPMBUILD = rpmbuild --define '_specdir $(PWD)' --define '_sourcedir $(PWD)'

help:
	@echo "targets: prep srpm local mock short upload copr koji verrel"

verrel:
	@echo $(NVR)

srpm: $(SRPM)

prep: $(NAME).spec $(TARBALL)
	$(RPMBUILD) -bp --nodeps $(NAME).spec

$(SRPM): $(NAME).spec $(TARBALL) $(PATCH)
	$(RPMBUILD) --define 'dist %{nil}' -bs $(NAME).spec

ifdef TARBALL
$(TARBALL):
	wget -nv http://hackage.haskell.org/package/$(NAME)-$(VERSION)/$(TARBALL)
endif

local: $(NAME).spec $(TARBALL)
	$(RPMBUILD) -ba $(NAME).spec

short: $(NAME).spec $(TARBALL)
	$(RPMBUILD) -bi --short-circuit $(NAME).spec

koji: $(SRPM)
	koji build --scratch rawhide $(SRPM)

mock: $(SRPM)
	mock -r fedora-rawhide-x86_64 $(SRPM)

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
