NAME=sensu
VERSION=6.9.0
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
	rm -rf /install-web
	rm -f $(NAME)-*-$(VERSION)-*.rpm
	rm -rf vendor/
	#rm -rf /usr/local/go

.PHONY: deps
deps:
	dnf module reset ruby -y
	dnf install -y @ruby:2.7
	dnf install -y gcc rpm-build git yarn curl golang
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
	# web
	mkdir -p /install-web/opt/sensu/web
	mkdir -p /install-web/opt/sensu/yarn/node_modules
	mkdir -p /install-web/lib/systemd/system
	mkdir -p /install-web/var/lib/sensu/.cache/yarn
	git clone -b v$(WEBVERSION) https://github.com/sensu/web.git vendor/sensu-web
	cp sensu-web.service /install-web/lib/systemd/system
	cd vendor/sensu-web; yarn install #--modules-folder /install-web/opt/sensu/yarn/node_modules --ignore-scripts
	rsync -ah --exclude='.cache/' --exclude='.git*' vendor/sensu-web/ /install-web/opt/sensu/web

.PHONY: rpm
rpm:
	fpm -s dir -t rpm \
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
	fpm -s dir -t rpm \
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
	fpm -s dir -t rpm \
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
	fpm -s dir -t rpm \
    -n $(NAME)-web \
    -v $(WEBVERSION) \
    --iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
    --description "Sensu Go Web" \
    --url "$(shelpl cat $(URL))" \
    --maintainer "$(MAINTAINER)" \
		--before-install preinstall.sh \
    --after-install postinstall-web.sh \
		--rpm-tag '%define _build_id_links none' \
		--rpm-tag '%undefine _missing_build_ids_terminate_build' \
    -C /install-web/ \
		.
