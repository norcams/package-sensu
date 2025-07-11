NAME=sensu
VERSION=6.13.1
PACKAGE_VERSION=1
DESCRIPTION=package.description
URL=package.url
MAINTAINER="https://github.com/norcams"
RELVERSION=8
WEBVERSION=1.2.1

.PHONY: default
default: deps build rpm
package: rpm

.PHONY: clean
clean:
	rm -rf /install-ctl
	rm -rf /install-agent
	rm -rf /install-backend
	rm -f $(NAME)-*-$(VERSION)-*.rpm
	rm -rf vendor/

.PHONY: deps
deps:
	dnf module reset ruby -y
	dnf install -y @ruby:3.1
	dnf install -y gcc rpm-build ruby-devel git curl golang
	gem install -N fpm

.PHONY: build
build:
	mkdir -p vendor/
	git clone -b v$(VERSION) https://github.com/sensu/sensu-go.git vendor/sensu-go
	# Agent
	mkdir -p /install-agent/usr/sbin
	mkdir -p /install-agent/etc/sensu
	mkdir -p /install-agent/etc/rsyslog.d
	mkdir -p /install-agent/etc/logrotate.d
	mkdir -p /install-agent/lib/systemd/system
	mkdir -p /install-agent/var/run/sensu
	mkdir -p /install-agent/var/log/sensu
	mkdir -p /install-agent/var/lib/sensu/sensu-agent
	mkdir -p /install-agent/var/cache/sensu/sensu-agent
	cp sensu-agent.service /install-agent/lib/systemd/system
	cp rsyslog/99-sensu-agent.conf /install-agent/etc/rsyslog.d/99-sensu-agent.conf
	cp logrotate/sensu-agent /install-agent/etc/logrotate.d/sensu-agent
	cd vendor/sensu-go; go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-agent/usr/sbin/sensu-agent ./cmd/sensu-agent
	# Backend
	mkdir -p /install-backend/usr/sbin
	mkdir -p /install-backend/etc/sensu
	mkdir -p /install-agent/etc/rsyslog.d
	mkdir -p /install-backend/lib/systemd/system
	mkdir -p /install-backend/var/run/sensu
	mkdir -p /install-backend/var/log/sensu
	mkdir -p /install-backend/var/lib/sensu/sensu-backend
	mkdir -p /install-backend/var/cache/sensu/sensu-backend
	cp sensu-backend.service /install-backend/lib/systemd/system
	cp rsyslog/99-sensu-backend.conf /install-agent/etc/rsyslog.d/99-sensu-backend.conf
	cd vendor/sensu-go; go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-backend/usr/sbin/sensu-backend ./cmd/sensu-backend
	# cli
	mkdir -p /install-ctl/usr/sbin
	cd vendor/sensu-go; go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-ctl/usr/sbin/sensuctl ./cmd/sensuctl

.PHONY: rpm
rpm:
	/usr/local/bin/fpm -s dir -t rpm \
		-n $(NAME)-agent \
		-v $(VERSION) \
		--iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
		--description "Sensu Go Agent" \
		--url "$(shelpl cat $(URL))" \
		--depends logrotate \
		--maintainer "$(MAINTAINER)" \
		--before-install preinstall.sh \
		--after-install postinstall-agent.sh \
		-C /install-agent/ \
		--rpm-tag '%define _build_id_links none' \
		--rpm-tag '%undefine _missing_build_ids_terminate_build' \
		.
	/usr/local/bin/fpm -s dir -t rpm \
		-n $(NAME)-backend \
		-v $(VERSION) \
    	--iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
    	--description "Sensu Go Backend" \
    	--url "$(shelpl cat $(URL))" \
    	--maintainer "$(MAINTAINER)" \
    	--before-install preinstall.sh \
    	--after-install postinstall-backend.sh \
    	-C /install-backend/ \
		--rpm-tag '%define _build_id_links none' \
		--rpm-tag '%undefine _missing_build_ids_terminate_build' \
		.
	/usr/local/bin/fpm -s dir -t rpm \
    	-n $(NAME)-cli \
    	-v $(VERSION) \
    	--iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
    	--description "Sensu Go Cli" \
    	--url "$(shelpl cat $(URL))" \
    	--maintainer "$(MAINTAINER)" \
    	-C /install-ctl/ \
		--rpm-tag '%define _build_id_links none' \
		--rpm-tag '%undefine _missing_build_ids_terminate_build' \
		.

.PHONY: deb
deb:
	/usr/local/bin/fpm -s dir -t deb \
		-n $(NAME)-agent \
		-v $(VERSION) \
		--description "Sensu Go Agent" \
		--url "$(shelpl cat $(URL))" \
		--depends logrotate \
		--maintainer "$(MAINTAINER)" \
		--before-install preinstall.sh \
		--after-install postinstall-agent.sh \
		-C /install-agent/ \
		--deb-no-default-config-files \
		.
	/usr/local/bin/fpm -s dir -t deb \
    	-n $(NAME)-cli \
    	-v $(VERSION) \
    	--description "Sensu Go Cli" \
    	--url "$(shelpl cat $(URL))" \
    	--maintainer "$(MAINTAINER)" \
    	-C /install-ctl/ \
		--deb-no-default-config-files \
		.
