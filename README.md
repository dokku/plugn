# plugn [![Build Status](https://img.shields.io/circleci/project/dokku/plugn/master.svg?style=flat-square "Build Status")](https://circleci.com/gh/dokku/plugn/tree/master)

Hook system that lets users extend your application with plugins

## Installation

```shell
wget -qO /tmp/plugn_latest.tgz https://github.com/dokku/plugn/releases/download/v0.8.2/plugn_0.8.2_linux_amd64.tgz
tar xzf /tmp/plugn_latest.tgz -C /usr/local/bin
```

## Usage
```
$ PLUGIN_PATH=/var/lib/dokku/plugins plugn

Available commands:
  config                       Plugin configuration
  disable                      Disable a plugin
  enable                       Enable a plugin
  help                         Shows help information for a command
  init                         Initialize an empty plugin path
  install                      Install a new plugin from a Git URL
  list                         List all local plugins
  source                       Source commands for sourcable plugins
  trigger                      Triggers hook in enabled plugins
  uninstall                    Remove plugin from available plugins
  update                       Update plugin and optionally pin to commit/tag/branch
  version                      Show version
```

## Building & Testing (in docker)
```
$ docker-machine create -d virtualbox plugn-dev
$ eval $(docker-machine env plugn-dev)
$ make build-in-docker
$ make test
```

## Plugin directory structure example
```
ps (plugin name)
├── [-rw-r--r--]  plugin.toml (metadata)
├── [-rwxr-xr-x]  post-deploy (trigger)
├── [-rwxr-xr-x]  post-stop  (trigger)
└── [-rwxr-xr-x]  pre-deploy (trigger)
```

## plugin.toml format example
```
[plugin name]
description = "plugin description"
version = "0.1.0"
```

## Releases

Anybody can propose a release. First bump the version in `Makefile`, make sure `CHANGELOG.md` is up to date, and make sure tests are passing. Then open a Pull Request from `master` into the `release` branch. Once a maintainer approves and merges, CircleCI will build a release and upload it to Github.

## License

BSD
