## 0.3.0

### Breaking Changes

- None

### Added

- [#30](https://github.com/IFTTT/polo/pull/30) Advanced obfuscation
- [#37](https://github.com/IFTTT/polo/pull/37) Custom adapters for Postgres and MySQL

### Fixed

- [#26](https://github.com/IFTTT/polo/pull/26) Postgres - Use ActiveRecord methods to generate INSERT SQLs
- [#25](https://github.com/IFTTT/polo/pull/25) Fix custom strategies bug
- [#28](https://github.com/IFTTT/polo/pull/28) Only obfuscate fields when they are present
- [#35](https://github.com/IFTTT/polo/pull/35) Better support for Rails 4.0
- [#31](https://github.com/IFTTT/polo/pull/31) Fix link to Code of Conduct

## 0.2.0

### Breaking Changes

- None

### Added

- [#8](https://github.com/IFTTT/polo/pull/8) Global settings
- [#17](https://github.com/IFTTT/polo/pull/17) Using random generator instead of character shuffle for data obfuscation
- [#18](https://github.com/IFTTT/polo/pull/18) Add a CHANGELOG
- [#20](https://github.com/IFTTT/polo/pull/20) Postgres Support

### Fixed

- Typo fixes on the README: [#9](https://github.com/IFTTT/polo/pull/9), [#10](https://github.com/IFTTT/polo/pull/10)
- [#11]() Some ActiveRecord classes do not use id as the primary key
- [#25](https://github.com/IFTTT/polo/pull/25) Fix Custom Strategy

## 0.1.0

### Breaking Changes

- None

### Added

- [#2](https://github.com/IFTTT/polo/pull/2) Add :ignore and :override options to deal with data collision
- [#3](https://github.com/IFTTT/polo/pull/3) Add option to obfuscate fields
- [#4](https://github.com/IFTTT/polo/pull/4) Add intro to Update / Ignore section
- [#6](https://github.com/IFTTT/polo/pull/6) Set up Appraisal to run specs across Rails 3.2 through 4.2

### Fixed

- [#7](https://github.com/IFTTT/polo/pull/7) Fix casting of values
