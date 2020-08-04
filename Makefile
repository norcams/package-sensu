NAME=sensu
VERSION=5.21.0
PACKAGE_VERSION=1
DESCRIPTION=package.description
URL=package.url
MAINTAINER="https://github.com/norcams"
RELVERSION=7
GOVERSION=1.14.6

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
	#rm -rf /usr/local/go 

.PHONY: deps
deps:
	yum install -y gcc rpm-build centos-release-scl epel-release curl git
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
	mkdir -p /install-agent/lib/systemd/system
	mkdir -p /install-agent/var/run/sensu
	mkdir -p /install-agent/var/log/sensu
	mkdir -p /install-agent/var/lib/sensu/sensu-agent
	mkdir -p /install-agent/var/cache/sensu/sensu-agent
	
	cp sensu-agent.service /install-agent/lib/systemd/system	
	cd vendor/sensu-go; /usr/local/go/bin/go run ./cmd/sensu-agent
	cd vendor/sensu-go; /usr/local/go/bin/go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-agent/usr/sbin/sensu-agent ./cmd/sensu-agent
	# Backend
	mkdir -p /install-backend/usr/sbin
	mkdir -p /install-backend/etc/sensu
	mkdir -p /install-backend/lib/systemd/system
	mkdir -p /install-backend/var/run/sensu
	mkdir -p /install-backend/var/log/sensu
	mkdir -p /install-backend/var/lib/sensu/sensu-backend
	mkdir -p /install-backend/var/cache/sensu/sensu-backend
	cp sensu-backend.service /install-backend/lib/systemd/system
	cd vendor/sensu-go; /usr/local/go/bin/go run ./cmd/sensu-backend
	cd vendor/sensu-go; /usr/local/go/bin/go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-backend/usr/sbin/sensu-backend ./cmd/sensu-backend
	# cli
	mkdir -p /install-ctl/usr/sbin	
	cd vendor/sensu-go; /usr/local/go/bin/go run ./cmd/sensuctl
	cd vendor/sensu-go; /usr/local/go/bin/go build -ldflags '-X "github.com/sensu/sensu-go/version.Version=$(VERSION)" -X "github.com/sensu/sensu-go/version.BuildDate=$(shell date +%Y-%m-%d)" -X "github.com/sensu/sensu-go/version.BuildSHA='`git rev-parse HEAD`'"' -o /install-ctl/usr/sbin/sensuctl ./cmd/sensuctl

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
