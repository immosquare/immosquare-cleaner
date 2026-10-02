# CLAUDE.md

Gem de formatting/linting multi-format, pour tout dépôt (app Rails, gem, app Rust/Tauri, module Go, package JS). Points d'entrée : `ImmosquareCleaner.clean(file_path)` et `ImmosquareCleaner.clean_directory(root)` dans `lib/immosquare-cleaner.rb`.

## Architecture

Un processor par type de fichier dans `lib/immosquare-cleaner/processors/` — chaque classe expose `match?(file_path)` + `run`. `ImmosquareCleaner.processor_for` scanne le registre `PROCESSORS` (ordre significatif : `Erb` avant `Javascript`, `Ruby` avant `Shell` pour les shebangs) et tombe sur `Processors::Prettier` en fallback.

`ImmosquareCleaner.clean_directory(root)` (`lib/immosquare-cleaner/directory_cleaner.rb`) nettoie tout un dépôt, quelle que soit sa stack : fichiers issus de `git ls-files` (dépôts imbriqués et submodules parcourus avec leur propre listing, `Dir.glob` hors git), exclusions en dur (`EXCLUDED_DIRS` à toute profondeur, `EXCLUDED_PATHS` depuis la racine de chaque dépôt), et seulement les fichiers qu'un processor gère ou dont Prettier connaît l'extension (`Prettier::EXTENSIONS`, via `ImmosquareCleaner.supported?`).

| Processor                | Extension                                                                            | Outil                                                                             |
| ------------------------ | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `Processors::Ruby`       | `.rb`, `.rake`, Gemfile et autres (cf. `RUBY_FILES`) + shebang `#!/usr/bin/env ruby` | RuboCop                                                                           |
| `Processors::Erb`        | `.html.erb`, `.html`                                                                 | htmlbeautifier + erb_lint                                                         |
| `Processors::Yaml`       | `.yml` dans `locales/`                                                               | ImmosquareYaml                                                                    |
| `Processors::Javascript` | `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.{js,mjs,cjs,jsx,ts,tsx,coffee}.erb`  | ESLint + normalize-comments.mjs (ou erb_lint pour les `.erb`)                     |
| `Processors::Json`       | `.json`                                                                              | ImmosquareExtensions                                                              |
| `Processors::Markdown`   | `.md`, `.md.erb`                                                                     | `ImmosquareCleaner::Markdown.clean` (tables + listes ; frontmatter YAML verbatim) |
| `Processors::Shell`      | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                  | shfmt                                                                             |
| `Processors::Rust`       | `.rs`                                                                                | rustfmt via stdin (édition et `rustfmt.toml` lus dans le projet)                  |
| `Processors::Go`         | `.go`                                                                                | `gofmt -s` (indentation en tabulations : gofmt n'a pas d'option)                  |
| `Processors::Toml`       | `.toml`                                                                              | taplo                                                                             |
| `Processors::Prettier`   | Fallback (tout le reste)                                                             | Prettier                                                                          |

## Commandes

```bash
bundle exec rake test                              # Tests
bundle exec ruby -Itest test/xxx_test.rb           # Test unique
bundle exec immosquare-cleaner path/to/file        # Nettoyer un fichier
bundle exec immosquare-cleaner path/to/repo        # Tout un dépôt, toute stack (parallèle, CLEANER_THREADS=N pour override)
COVERAGE=true bundle exec rake test                # Tests + rapport HTML et coverage/lcov.info
bin/ci                                             # Point d'entrée CI (bundle + bun install, puis la suite)
```

## Custom Linters

**RuboCop** (`linters/rubocop/cop/custom_cops/style/`) :
- `CommentNormalization` : Bordures autour des commentaires
- `FontAwesomeNormalization` : `fas`/`far` → `fa-solid`/`fa-regular`
- `AlignAssignments` : Aligne les `=` consécutifs (désactivé par défaut)
- `InlineMultilineCalls` : `link_to(...)` multi-ligne → single-line (skip si commentaire/string multi-ligne dans l'appel)
- `KwargPriorityOrder` : Réordonne les kwargs de `link_to` pour mettre `:remote` puis `:method` en premier (configurable)

**RuboCop** (`linters/rubocop/cop/style/`) :
- `MethodCallWithArgsParentheses` override : Autorise l'omission des parenthèses dans les blocs/fichiers Jbuilder (`json.field "value"`)

**erb_lint** (`linters/erb_lint/`) :
- `CustomSingleLineIfModifier` : `<% if x %><%= y %><% end %>` → `<%= y if x %>`
- `CustomHtmlToContentTag` : `<div class="x"><%= y %></div>` → `<%= content_tag(:div, y, :class => "x") %>`
- `CustomAlignConsecutiveCalls` : Aligne les colonnes des `link_to` consécutifs (même arity + mêmes clés kwargs) via padding après la virgule

**JS** (`linters/normalize-comments.mjs`) :
- Ajoute bordures `//====...====//` autour des commentaires standalone

**Shim ESLint 10** (`linters/eslint-plugins/eslint10-compat.mjs`) :
- Wrappe `eslint-plugin-align-import` (non maintenu, dernière release 2020) pour re-injecter `context.getSourceCode()` supprimé par ESLint 10. À supprimer dès qu'une alternative maintenue émerge.
- `align-assignments` est un fork local (`linters/eslint-plugins/align-assignments.mjs`, MIT, notice d'origine en tête de fichier) : lit `context.sourceCode` et gère `||=`, `&&=`, `??=` — sans eux, l'autofix ne converge jamais (« Circular fixes detected »).

## Points critiques

- **Symlink erb_lint** : `.erb_linters -> linters/erb_lint` requis (chemin hardcodé par erb_lint)
- **ESLint 10** : Fichiers copiés dans `tmp/` avant lint puis recopiés (workaround "outside of base path", cf. `eslint/eslint#19118`). Plugins legacy adaptés via le shim `eslint10-compat.mjs`.
- **TypeScript 7** : Le compilateur natif est installé sous `@typescript/native`, tandis qu'ESLint résout `typescript` vers le tarball 6.0.3. TypeScript 7.0 n'expose pas l'API requise par `typescript-eslint`/SonarJS et l'URL empêche `bun update --latest` de casser le lint ; supprimer ce verrou quand `typescript-eslint` supportera l'API TypeScript 7.1.
- **Configs versionnées** : `rubocop-{VERSION}.yml` + `erb-lint-{VERSION}.yml` + `js-erb-lint-{VERSION}.yml` générés au premier run. Supprimer pour forcer régénération
- **Parser Ruby** : `parser_prism` (Ruby 3.3+) ou `parser_whitequark` (versions antérieures)
- **Exécution** : Commandes lancées depuis la racine du gem via `system(cmd, :chdir => gem_root)` (thread-safe ; pas `Dir.chdir`)
- **`bin/ci` non packagé** : le gemspec liste `bin/` fichier par fichier (`bin/immosquare-cleaner` seul) — `bin/ci` est le point d'entrée CI et n'a rien à faire chez qui installe la gem
- **Couverture** : `test/coverage_helper.rb` est chargé par `ruby_opts` du Rakefile, avant la lib — sinon un fichier déjà requis échappe à la mesure. No-op sans `COVERAGE=true`
- **`--hook` CLI** : `bin/immosquare-cleaner --hook` lit le fichier édité dans le JSON qu'un agent IA envoie sur stdin (`ImmosquareCleaner::Hook.file_path`, `lib/immosquare-cleaner/hook.rb` : `tool_input.file_path`, `tool_input.path`, `toolInput.file_path` ou `file_path` racine, relatif résolu contre `cwd`). Fichier absent ou non `supported?` → sortie 0 sans rien faire ; stdout redirigé vers stderr car Gemini CLI parse le stdout d'un hook comme du JSON. Ne jamais faire sortir ce mode en non-zéro : il bloquerait l'agent
- **`-p` CLI** : `bin/immosquare-cleaner -p` clean une copie `/tmp` après 2s d'attente et n'écrit que si l'original n'a pas bougé — pour cohabiter avec un IDE qui sauvegarde en parallèle. Le chemin d'origine est passé en `origin_path` (`Processors::Base`) : un processor qui lit la config du projet (`Cargo.toml`, `rustfmt.toml`) la cherche depuis l'original, pas depuis `/tmp`
- **rustfmt via stdin** : lancé sur un chemin, rustfmt réécrit aussi les modules enfants (`mod foo;`) ; `skip_children` est nightly only

## Prérequis

Bun, Ruby 3.2.6+, shfmt (`brew install shfmt`) ; rustfmt (`rustup component add rustfmt`), gofmt (`brew install go`) et taplo (`brew install taplo`) pour les fichiers Rust, Go et TOML
