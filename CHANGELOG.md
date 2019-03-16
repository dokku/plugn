# Change Log
All notable changes to this project will be documented in this file.

## [0.3.2] - 2019-03-16
### Added
- @josegonzalez Add missing SYSTEM_NAME to Makefile #30

## [0.3.1] - 2019-03-15
### Added
- @josegonzalez Store builds as CI artifacts #28

### Changed
- @josegonzalez Allow specifying a custom bashPath via environment variable #27

## [0.3.0] - 2017-03-19
### Added
- @josegonzalez Add support for downloading via tar.gz #19

## [0.2.2] - 2016-09-16
### Fixed
- @michaelshobbs bring back bindata.go
- @michaelshobbs updated bindata.go

### Changed
- @michaelshobbs [ci skip] documentation update pass. closes #5
- @michaelshobbs use docker 1.12.1
- @michaelshobbs use dokku fork of duplex and vendor deps. closes #16

## [0.2.1] - 2015-12-24
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

## [0.1.0] - 2014-11-02
### Fixed
- @progrium fix newline issie

### Changed
- @progrium rename to plugn

[unreleased]: https://github.com/dokku/plugn/compare/v0.3.2...HEAD
[0.3.2]: https://github.com/dokku/plugn/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/dokku/plugn/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/dokku/plugn/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/dokku/plugn/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/dokku/plugn/compare/v0.1.0...v0.2.1
[0.1.0]: https://github.com/dokku/plugn/compare/ae7f4c92579ec64d7cf3d3bd76cb6207dd8d3ed9...v0.1.0
