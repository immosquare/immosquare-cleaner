# Contributing to immosquare-cleaner

Bug reports and pull requests are welcome on [GitHub](https://github.com/immosquare/immosquare-cleaner). This page covers what you need to work on the gem itself: setting up the repository, running the test suite, and the maintenance notes that explain choices which look odd at first sight.

## Setting up the repository

The repository needs Ruby 3.2.6+, [bun](https://bun.sh/), and the external formatters of the formats you touch: shfmt (`brew install shfmt`), rustfmt (`rustup component add rustfmt`), gofmt (`brew install go`) and taplo (`brew install taplo`).

```bash
bundle install
bun install
```

Each format has its processor in `lib/immosquare-cleaner/processors/`. A processor exposes `match?(file_path)` and `run`, and is registered in the `PROCESSORS` list of `lib/immosquare-cleaner.rb`, where order matters: the first processor whose `match?` returns true wins, and Prettier is the fallback.

## Running the test suite and its CI

The test suite of the immosquare-cleaner repository runs through rake:

```bash
bundle exec rake test
```

Coverage is off by default, so a local run stays fast and leaves no `coverage/` directory behind. Set `COVERAGE=true` to get an HTML report plus `coverage/lcov.info`:

```bash
COVERAGE=true bundle exec rake test
```

The CI runs the suite on every build through `bin/ci`, which is a repository script and is not shipped with the gem:

```bash
bin/ci init   # bundle install && bun install --frozen-lockfile
bin/ci test   # bundle exec rake test
bin/ci        # both, in that order (the default, `all`)
```

`bin/ci init` installs the JS toolchain too: the JS, Prettier and Markdown tests call the library directly rather than the `immosquare-cleaner` executable, so nothing provisions `node_modules/` for them. Both sub-commands skip the `development` bundler group — anything the suite needs belongs to the `test` group of the `Gemfile`. The script provisions no Ruby of its own — the CI runner selects it from `.ruby-version` and `.ruby-gemset` beforehand — so `bin/ci` behaves the same on a laptop. It also defaults `COVERAGE` to `true`, and the CI collects `coverage/lcov.info`.

## Why TypeScript is pinned to the 6.0.3 tarball

TypeScript 7 is installed as `@typescript/native`, but TypeScript 7.0 does not expose the stable programmatic API required by `typescript-eslint` and SonarJS. The `typescript` dependency therefore resolves to the fixed 6.0.3 npm tarball; using the tarball prevents `bun update --latest` from replacing the linter API. Remove this compatibility lock when `typescript-eslint` supports the TypeScript 7.1 API.
