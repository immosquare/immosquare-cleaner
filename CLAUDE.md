# CLAUDE.md

Gem de formatting/linting multi-format pour Rails. Point d'entrée : `ImmosquareCleaner.clean(file_path)` dans `lib/immosquare-cleaner.rb`.

## Architecture

Un processor par type de fichier dans `lib/immosquare-cleaner/processors/` — chaque classe expose `match?(file_path)` + `run`. `ImmosquareCleaner.processor_for` scanne le registre `PROCESSORS` (ordre significatif : `Erb` avant `Javascript`, `Ruby` avant `Shell` pour les shebangs) et tombe sur `Processors::Prettier` en fallback.

| Processor                | Extension                                                                            | Outil                                                         |
| ------------------------ | ------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| `Processors::Ruby`       | `.rb`, `.rake`, Gemfile et autres (cf. `RUBY_FILES`) + shebang `#!/usr/bin/env ruby` | RuboCop                                                       |
| `Processors::Erb`        | `.html.erb`, `.html`                                                                 | htmlbeautifier + erb_lint                                     |
| `Processors::Yaml`       | `.yml` dans `locales/`                                                               | ImmosquareYaml                                                |
| `Processors::Javascript` | `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.{js,mjs,cjs,jsx,ts,tsx,coffee}.erb`  | ESLint + normalize-comments.mjs (ou erb_lint pour les `.erb`) |
| `Processors::Json`       | `.json`                                                                              | ImmosquareExtensions                                          |
| `Processors::Markdown`   | `.md`, `.md.erb`                                                                     | `ImmosquareCleaner::Markdown.clean` (tables + listes)         |
| `Processors::Shell`      | `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                  | shfmt                                                         |
| `Processors::Prettier`   | Fallback (tout le reste)                                                             | Prettier                                                      |

## Commandes

```bash
bundle exec rake test                              # Tests
bundle exec ruby -Itest test/xxx_test.rb           # Test unique
bundle exec immosquare-cleaner path/to/file        # Nettoyer un fichier
bundle exec rake immosquare_cleaner:clean_app      # Bulk d'une app Rails (parallèle, CLEANER_THREADS=N pour override)
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
- Wrappe `eslint-plugin-align-assignments` et `eslint-plugin-align-import` (non maintenus, derniers releases 2019-2020) pour re-injecter `context.getSourceCode()` supprimé par ESLint 10. À supprimer dès qu'une alternative maintenue émerge.

## Points critiques

- **Symlink erb_lint** : `.erb_linters -> linters/erb_lint` requis (chemin hardcodé par erb_lint)
- **ESLint 10** : Fichiers copiés dans `tmp/` avant lint puis recopiés (workaround "outside of base path", cf. `eslint/eslint#19118`). Plugins legacy adaptés via le shim `eslint10-compat.mjs`.
- **Configs versionnées** : `rubocop-{VERSION}.yml` + `erb-lint-{VERSION}.yml` + `js-erb-lint-{VERSION}.yml` générés au premier run. Supprimer pour forcer régénération
- **Parser Ruby** : `parser_prism` (Ruby 3.3+) ou `parser_whitequark` (versions antérieures)
- **Exécution** : Commandes lancées depuis la racine du gem via `system(cmd, :chdir => gem_root)` (thread-safe ; pas `Dir.chdir`)
- **`-p` CLI** : `bin/immosquare-cleaner -p` clean une copie `/tmp` après 2s d'attente et n'écrit que si l'original n'a pas bougé — pour cohabiter avec un IDE qui sauvegarde en parallèle

## Prérequis

Bun, Ruby 3.2.6+, shfmt (`brew install shfmt`)
