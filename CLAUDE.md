# CLAUDE.md

Gem de formatting/linting multi-format pour Rails. Point d'entrée : `ImmosquareCleaner.clean(file_path)` dans `lib/immosquare-cleaner.rb`.

## Processors par extension

| Extension                                                                           | Processor                       |
| ----------------------------------------------------------------------------------- | ------------------------------- |
| `.rb`, `.rake`, Gemfile                                                             | RuboCop                         |
| `.html.erb`, `.html`                                                                | htmlbeautifier + erb_lint       |
| `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`, `.{js,mjs,cjs,jsx,ts,tsx,coffee}.erb` | ESLint + normalize-comments.mjs |
| `.json`                                                                             | ImmosquareExtensions            |
| `.yml` (locales/)                                                                   | ImmosquareYaml                  |
| `.md`, `.md.erb`                                                                    | Custom markdown processor       |
| `.sh`, `bash`, `zsh`, `zshrc`, `bashrc`, `bash_profile`, `zprofile`                 | shfmt                           |
| Autres                                                                              | Prettier                        |

## Commandes

```bash
bundle exec rake test                              # Tests
bundle exec ruby -Itest test/xxx_test.rb           # Test unique
bundle exec immosquare-cleaner path/to/file        # Nettoyer un fichier
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

## Points critiques

- **Symlink erb_lint** : `.erb_linters -> linters/erb_lint` requis (chemin hardcodé par erb_lint)
- **ESLint V9+** : Fichiers copiés dans `tmp/` avant lint puis recopiés (workaround "outside of base path")
- **Configs versionnées** : `rubocop-{VERSION}.yml` générés au premier run. Supprimer pour forcer régénération
- **Parser Ruby** : `parser_prism` (Ruby 3.3+) ou `parser_whitequark` (versions antérieures)
- **Exécution** : Commandes lancées depuis la racine du gem via `system(cmd, :chdir => gem_root)` (thread-safe ; pas `Dir.chdir`)

## Prérequis

Bun, Ruby 3.2.6+, shfmt (`brew install shfmt`)
