## [0.1.72] - 2025-07-21
- Improve AlignAssignments cop

## [0.1.71] - 2025-07-20
- Add new custom cop : AlignAssignments
- Update gems + packages

## [0.1.70] - 2025-04-08
- improve immosquare-cleaner bin script :
  - add -h option to show help
  - allow relative & absolute paths

## [0.1.69] - 2025-03-14
- node-modules folder is dynamically created if it does not exist

## [0.1.68] - 2025-03-14
- missing eslint-plugin-erb in compiled node_modules folder

## [0.1.67] - 2025-03-14
- prevent occasional "invalid byte sequence in US-ASCII" error

## [0.1.66] - 2025-03-13
- add strategy for .js.erb files (erb_lint + eslint)

## [0.1.65] - 2025-03-13
- we use the eslint-plugin-prefer-arrow plugin instead of jscodeshift

## [0.1.64] - 2025-03-13
- Remove some remaining tmp files (bug with htmlbeautifier or erb_lint)
- add new custom cop : font_awesome_normalization

## [0.1.63] - 2025-03-06
- update gems + bundler + packages
- dynamic erb-lint.yml with ruby version

## [0.1.62] - 2025-01-07
- Rewrite MarkdownLinting

## [0.1.61] - 2025-01-06
- Improve CommentNormalization + Update Eslint setting

## [0.1.60] - 2025-01-06
- load config from immosquare-cleaner.rb initializer

## [0.1.59] - 2025-01-06
- Improve CommentNormalization

## [0.1.58] - 2025-01-06
- Improve CommentNormalization

## [0.1.57] - 2024-12-24
- Improve UseCredentialsInsteadOfEnv

## [0.1.56] - 2024-12-23
- erb_lint : Fix Calling `erblint` is deprecated, please call the renamed executable `erb_lint` instead.

## [0.1.55] - 2024-12-23
- Rubocop : Improve CommentNormalization cop

## [0.1.54] - 2024-12-22
- Rubocop : Add new custom cop : CommentNormalization to normalize comments in the codebase

## [0.1.53] - 2024-12-20
- Rubocop : Add new custom cop : UseCredentialsInsteadOfEnv to replace ENV variables with Rails.credentials

## [0.1.52] - 2024-11-27
- Update rubocop version + Prettier (https://prettier.io/blog/2024/11/26/3.4.0.html)

## [0.1.51] - 2024-10-24
- Add new rule setting for Style/CombinableLoops

## [0.1.50] - 2024-10-18
- Update packges + gems

## [0.1.49] - 2024-10-15
- Revert Rubocop Improve rule for Style/ConditionalAssignment:

## [0.1.48] - 2024-10-15
- Rubocop Improve rule for Style/ConditionalAssignment:

## [0.1.47] - 2024-09-20
- Update dig rule for Rubocop

## [0.1.46] - 2024-09-02
- Update rubocop version

## [0.1.45] - 2024-08-26
- Update eslint-plugin-sonarjs (1.x => 2.x)

## [0.1.44] - 2024-08-14
- Update jscodeshift version

## [0.1.43] - 2024-08-02
- Update erblint & eslint

## [0.1.42] - 2024-07-26
- Improve rubocop rules for rails (AllCops:ActiveSupportExtensionsEnabled)

## [0.1.41] - 2024-07-15
- Update eslint, prettier & rubocop versions

## [0.1.40] - 2024-06-25
- Update eslint, prettier & jscodeshift versions

## [0.1.39] - 2024-06-04
- Upgrade eslint + prettier

## [0.1.38] - 2024-05-31
- Improve arrow functions parser (jscodeshift)

## [0.1.37] - 2024-05-20
- Add jscodeshift processor (+ eslint upgrade 9.2 => 9.3)

## [0.1.36] - 2024-05-16
- Fix for eslint v9

## [0.1.35] - 2024-05-16
- Update eslint Config files for v9

## [0.1.34] - 2024-05-10
- setup MinNameLength to 1 in rubocop.yml

## [0.1.33] - 2024-05-09
- bump to eslint v9.x

## [0.1.32] - 2024-03-20
- add missing require JSON

## [0.1.31] - 2024-03-18
- add missing require YAML

## [0.1.30] - 2024-03-14
- bump immosquare-yaml gem version

## [0.1.29] - 2024-03-14
- bump immosquare-exentension gem version

## [0.1.28] - 2024-02-06
- bump immosquare-exentension gem version

## [0.1.27] - 2024-02-05
- bump immosquare gems to the most recent versions

## [0.1.26] - 2024-02-05
- File.normalize_last_line from immosquare-extensions gem

## [0.1.25] - 2024-02-02
- Fix spec.files for linters subfolders

## [0.1.24] - 2024-02-02
- Jbuilder Custom Style

## [0.1.23] - 2024-01-15
- Bump Prettier Version

## [0.1.22] - 2024-01-15
- Bump Rubocop Version

## [0.1.21] - 2023-12-01
- Fix issue with css/scss files

## [0.1.20] - 2023-12-01
- Bump Rubocop Version

## [0.1.19] - 2023-12-01
- Bump Rubocop Version

## [0.1.18] - 2023-11-26
- Dynamic RubVersion for Rubocop

## [0.1.17] - 2023-11-25
- Update rubocop min version

## [0.1.16] - 2023-10-10
- Add support for html file

## [0.1.15] - 2023-10-10
- Update dependencies

## [0.1.14] - 2023-10-04
- Update dependencies

## [0.1.13] - 2023-10-01
- Style/FormatStringToken : template

## [0.1.12] - 2023-10-01
- Add vendor folder into task

## [0.1.11] - 2023-09-29
- Add custom Mardown cleaner

## [0.1.10] - 2023-09-29
- Change JSON dumper

## [0.1.9] - 2023-09-29
- Rubocop : Naming/FileName: false

## [0.1.8] - 2023-09-29
- fix Tasks

## [0.1.7] - 2023-09-29
- Add node_modules./bin +  package.json into the build

## [0.1.6] - 2023-09-29
- Test export node_modules

## [0.1.5] - 2023-09-29
- Add new linters for JS & JSON

## [0.1.4] - 2023-09-29
- Improve rails Task

## [0.1.3] - 2023-09-29
- Fix for erb_lint --config

## [0.1.0] - 2023-09-29
- Initial release
