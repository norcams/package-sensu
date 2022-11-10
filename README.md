# package-sensu

Makefile to build a rpm packages for the sensu-go OSS version.
Uses `fpm` to create these packages:

* sensu-agent.el8.x86_64
* sensu-backend.el8.x86_64
* sensu-cli.el8.x86_64
* sensu-web.el8.x86_64



Example
-------

Run on a el8 build machine:

```
make deps
make build
make rpm
```
