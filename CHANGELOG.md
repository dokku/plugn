# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased][unreleased]
### Fixed

### Added

### Removed

### Changed

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
- fix newline issie

### Changed
- rename to plugn

[unreleased]: https://github.com/dokku/plugn/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/dokku/plugn/compare/v0.1.0...v0.2.1
[0.1.0]: https://github.com/dokku/plugn/compare/ae7f4c92579ec64d7cf3d3bd76cb6207dd8d3ed9...v0.1.0
