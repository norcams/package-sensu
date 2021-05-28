NAME=sensu
VERSION=6.3.0
PACKAGE_VERSION=1
DESCRIPTION=package.description
URL=package.url
MAINTAINER="https://github.com/norcams"
RELVERSION=7
GOVERSION=1.16.3
WEBVERSION=1.1.0

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
	yum install -y gcc rpm-build centos-release-scl epel-release curl git yarn
	yum install -y rh-ruby23 rh-ruby23-ruby-devel
	source /opt/rh/rh-ruby23/enable; gem install -N fpm
	wget -O /tmp/go$(GOVERSION).linux-amd64.tar.gz https://golang.org/dl/go$(GOVERSION).linux-amd64.tar.gz
	tar -C /usr/local -xzf /tmp/go$(GOVERSION).linux-amd64.tar.gz

.PHONY: build
build:
	mkdir -p vendor/
	git clone -b v$(VERSION) https://github.com/sensu/sensu-go.git vendor/sensu-go
	# Agent
	mkdir -p /install-agent/usr/sbin
	mkdir -p /install-agent/etc/sensu
	mkdir -p /install-agent/etc/rsyslog.d
	mkdir -p /install-agent/lib/systemd/system
	mkdir -p /install-agent/var/run/sensu
	mkdir -p /install-agent/var/log/sensu
	mkdir -p /install-agent/var/lib/sensu/sensu-agent
	mkdir -p /install-agent/var/cache/sensu/sensu-agent
	cp sensu-agent.service /install-agent/lib/systemd/system
	cp rsyslog/99-sensu-agent.conf /install-agent/etc/rsyslog.d/99-sensu-agent.conf
	cd vendor/sensu-go; /usr/local/go/bin/go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-agent/usr/sbin/sensu-agent ./cmd/sensu-agent
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
	cd vendor/sensu-go; /usr/local/go/bin/go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-backend/usr/sbin/sensu-backend ./cmd/sensu-backend
	# cli
	mkdir -p /install-ctl/usr/sbin
	cd vendor/sensu-go; /usr/local/go/bin/go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-ctl/usr/sbin/sensuctl ./cmd/sensuctl
	# web
	mkdir -p /install-web/opt/sensu/web
	mkdir -p /install-web/opt/sensu/yarn/node_modules
	mkdir -p /install-web/lib/systemd/system
	mkdir -p /install-web/var/lib/sensu/.cache/yarn
	git clone -b v$(WEBVERSION) https://github.com/sensu/web.git vendor/sensu-web
	cp sensu-web.service /install-web/lib/systemd/system
	cd vendor/sensu-web; yarn install #--modules-folder /install-web/opt/sensu/yarn/node_modules --ignore-scripts
	#rsync -avh --exclude='.git*' vendor/sensu-web/ /install-web/opt/sensu/web
	rsync -ah --exclude='.cache/' vendor/sensu-web/ /install-web/opt/sensu/web

.PHONY: rpm
rpm:
	source /opt/rh/rh-ruby23/enable; fpm -s dir -t rpm \
		-n $(NAME)-agent \
		-v $(VERSION) \
		--iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
		--description "Sensu Go Agent" \
		--url "$(shelpl cat $(URL))" \
		--maintainer "$(MAINTAINER)" \
		--before-install preinstall.sh \
		--after-install postinstall-agent.sh \
		-C /install-agent/ \
		.
	source /opt/rh/rh-ruby23/enable; fpm -s dir -t rpm \
                -n $(NAME)-backend \
                -v $(VERSION) \
                --iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
                --description "Sensu Go Backend" \
                --url "$(shelpl cat $(URL))" \
                --maintainer "$(MAINTAINER)" \
                --before-install preinstall.sh \
                --after-install postinstall-backend.sh \
                -C /install-backend/ \
		.
	source /opt/rh/rh-ruby23/enable; fpm -s dir -t rpm \
                -n $(NAME)-cli \
                -v $(VERSION) \
                --iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
                --description "Sensu Go Cli" \
                --url "$(shelpl cat $(URL))" \
                --maintainer "$(MAINTAINER)" \
                -C /install-ctl/ \
		.
		source /opt/rh/rh-ruby23/enable; fpm -s dir -t rpm \
	                -n $(NAME)-web \
	                -v $(WEBVERSION) \
	                --iteration "$(PACKAGE_VERSION).el$(RELVERSION)" \
	                --description "Sensu Go Web" \
	                --url "$(shelpl cat $(URL))" \
	                --maintainer "$(MAINTAINER)" \
									--before-install preinstall.sh \
	                --after-install postinstall-web.sh \
	                -C /install-web/ \
			.
