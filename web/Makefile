NAME=sensu
VERSION=1.2.1
PACKAGE_VERSION=3
DESCRIPTION=package.description
URL=package.url
MAINTAINER="https://github.com/norcams"
RELVERSION=8

.PHONY: default
default: deps build rpm
package: rpm

.PHONY: clean
clean:
	rm -rf /install-web
	rm -f $(NAME)-*-$(VERSION)-*.rpm
	rm -rf vendor/

.PHONY: deps
deps:
	dnf module reset ruby -y
	dnf install -y @ruby:2.7
	dnf install -y @nodejs:14
	dnf install -y gcc rpm-build ruby-devel git curl
	curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
	rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
	dnf install -y yarn
	gem install -N fpm

.PHONY: build
build:
	mkdir -p vendor/
	mkdir -p /install-web/opt/sensu/web
	mkdir -p /install-web/opt/sensu/yarn/node_modules
	mkdir -p /install-web/lib/systemd/system
	mkdir -p /install-web/var/lib/sensu/.cache/yarn
	git clone -b v$(VERSION) https://github.com/sensu/web.git vendor/sensu-web
	cp sensu-web.service /install-web/lib/systemd/system
	cd vendor/sensu-web; yarn install #--modules-folder /install-web/opt/sensu/yarn/node_modules --ignore-scripts
	rsync -ah --exclude='.cache/' --exclude='.git/' vendor/sensu-web/ /install-web/opt/sensu/web
	/install-web/opt/sensu/web/.git
	cp -a vendor/sensu-web/.git/HEAD /install-web/opt/sensu/web/.git/.

.PHONY: rpm
rpm:
	/usr/local/bin/fpm -s dir -t rpm \
    	-n $(NAME)-web \
    	-v $(VERSION) \
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
