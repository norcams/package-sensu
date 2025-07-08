# Package Sensu Go

Makefile to build a rpm packages for the sensu-go OSS version.
Uses `fpm` to create these packages:

* sensu-agent.el9.x86_64
* sensu-backend.el9.x86_64
* sensu-cli.el9.x86_64
* sensu-web.el9.x86_64


## Example

Run on a el9 build machine (e.g. vagrant-sensugo-01):

```
make deps
make build
make rpm
```

# Package ruby plugin dependencies

Use `fpm` in vagrant to build these (change `rpm` to `deb` for Debian packages).

```
gem install fpm
dnf install -y rpm-build ruby-devel
fpm -a native -s gem -t rpm --iteration "1.el9" sensu-plugin
fpm -a native -s gem -t rpm --iteration "1.el9" --version 1.7.0 mixlib-cli
```
