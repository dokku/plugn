# Change Log
All notable changes to this project will be documented in this file.

## [0.9.1](https://github.com/dokku/plugn/compare/v0.9.0...v0.9.1) - 2022-05-10

### Changed

- @josegonzalez Revert "chore(deps): bump golang from 1.13.0-buster to 1.18.1-buster" #83

## [0.9.0](https://github.com/dokku/plugn/compare/v0.8.2...v0.9.0) - 2022-05-10

### Changed

- #79 @dependabot chore(deps): bump github.com/BurntSushi/toml from 1.0.0 to 1.1.0
- #80 @dependabot  chore(deps): bump golang from 1.13.0-buster to 1.18.1-buster

### Added

- #77 @josegonzalez Publish armhf package to ubuntu/focal
- #81 @josegonzalez Publish package for Ubuntu 22.04

## [0.8.2](https://github.com/dokku/plugn/compare/v0.8.1...v0.8.2) - 2022-03-05

### Changed

- @RyanGaudion Switch to golang 1.13 to fix SIGURG issue #74

## [0.8.1](https://github.com/dokku/plugn/compare/v0.8.0...v0.8.1) - 2022-03-05

### Added

- @RyanGaudion Add Raspbian Bullseye #70

### Changed

- @dependabot chore(deps): bump golang from 1.17.6-buster to 1.17.7-buster #69

## [0.8.0](https://github.com/dokku/plugn/compare/v0.7.1...v0.8.0) - 2022-01-31

### Added

- @josegonzalez Update the release name and body after creation #60
- @josegonzalez Add arm64 support #63
- @josegonzalez Add dependabot for docker #64

### Fixed

- @josegonzalez Add jq to build environment #67

### Changed

- @josegonzalez Upgrade ci builder to ubuntu 20.04 #61
- @josegonzalez Update dockerfile to newer base image #66
- @dependabot chore(deps): bump github.com/BurntSushi/toml from 0.4.1 to 1.0.0 #62
- @dependabot chore(deps): bump golang from 1.12.0-stretch to 1.17.6-stretch #65

## [0.7.1](https://github.com/dokku/plugn/compare/v0.7.0...v0.7.1) - 2021-10-28

### Fixed

- @josegonzalez Downgrade golang to avoid spurious SIGURG signals #58

## [0.7.0](https://github.com/dokku/plugn/compare/v0.6.1...v0.7.0) - 2021-10-27

### Added

- @adam12 Add bullseye to deb release task #55
- @josegonzalez Add arm support #56

### Changed

- @dependabot-preview Upgrade to GitHub-native Dependabot 
- @dependabot chore(deps): bump github.com/BurntSushi/toml from 0.3.1 to 0.4.1 #54

## [0.6.1](https://github.com/dokku/plugn/compare/v0.6.0...v0.6.1) - 2021-01-10

### Changed

- @josegonzalez Upgrade go-basher to add support for bash functions in the environment

## [0.6.0](https://github.com/dokku/plugn/compare/v0.5.1...v0.6.0) - 2020-12-20

### Changed

- @josegonzalez upgrade to uncompressed bash 5.1-patch4

## [0.5.1](https://github.com/dokku/plugn/compare/v0.5.0...v0.5.1) - 2020-12-05

### Changed
- @josegonzalez Update progrium/go-basher from v4 to v5
- @dependabot-preview chore(deps): bump github.com/pborman/uuid from 1.2.0 to 1.2.1

## [0.5.0](https://github.com/dokku/plugn/compare/v0.4.0...v0.5.0) - 2020-05-07

### Changed
- @josegonzalez Upgraded go-basher (includes bash upgrade)

## [0.4.0](https://github.com/dokku/plugn/compare/v0.3.2...v0.4.0) - 2020-05-06
### Added
- @josegonzalez Release packages for focal #37

### Changed
- @josegonzalez drop releases for old operating systems #35
- @josegonzalez upgrade go-basher #36

### Fixed
- @josegonzalez Corrected the package description

## [0.3.2](https://github.com/dokku/plugn/compare/v0.3.1...v0.3.2) - 2019-03-16
### Added
- @josegonzalez Add missing SYSTEM_NAME to Makefile #30

## [0.3.1](https://github.com/dokku/plugn/compare/v0.3.0...v0.3.1) - 2019-03-15
### Added
- @josegonzalez Store builds as CI artifacts #28

### Changed
- @josegonzalez Allow specifying a custom bashPath via environment variable #27

## [0.3.0](https://github.com/dokku/plugn/compare/v0.2.2...v0.3.0) - 2017-03-19
### Added
- @josegonzalez Add support for downloading via tar.gz #19

## [0.2.2](https://github.com/dokku/plugn/compare/v0.2.1...v0.2.2) - 2016-09-16
### Fixed
- @michaelshobbs bring back bindata.go
- @michaelshobbs updated bindata.go

### Changed
- @michaelshobbs [ci skip] documentation update pass. closes #5
- @michaelshobbs use docker 1.12.1
- @michaelshobbs use dokku fork of duplex and vendor deps. closes #16

## [0.2.1](https://github.com/dokku/plugn/compare/v0.1.0...v0.2.1) - 2015-12-24
### Fixed
- @lalyos Fix missing newlines
- @spesnova Fix typo
- @michaelshobbs git 1.5 complains about -X main.Version missing equals sign. add clean target

### Added
- @spesnova Enable example plugins to trigger it
- @progrium updating project
- @progrium updated go-basher usage, added gateway and coproc package, replaced shitty example with a working toy example
- @michaelshobbs initial pass at circleci tests
- @michaelshobbs implement plugn update <repo_url> [<committish>]
- @michaelshobbs support updating branches
- @michaelshobbs fix typo and add test
- @michaelshobbs add version command

### Changed
- @progrium output all to stdout in gateway for now
- @progrium using new coproc lib and changed remote example to only provide items hook
- @tombell Update to latest go-basher api
- @josegonzalez Make it possible to run `plugn init` multiple times

## [0.1.0](https://github.com/dokku/plugn/compare/ae7f4c92579ec64d7cf3d3bd76cb6207dd8d3ed9...v0.1.0) - 2014-11-02
### Fixed
- @progrium fix newline issie

### Changed
- @progrium rename to plugn
