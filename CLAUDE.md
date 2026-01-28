# CLAUDE.md

Gem de formatting/linting multi-format pour Rails. Point d'entrée : `ImmosquareCleaner.clean(file_path)` dans `lib/immosquare-cleaner.rb`.

## Processors par extension

| Extension | Processor |
|-----------|-----------|
| `.rb`, `.rake`, Gemfile | RuboCop |
| `.html.erb`, `.html` | htmlbeautifier + erb_lint |
| `.js`, `.mjs`, `.jsx`, `.ts`, `.tsx` | ESLint + normalize-comments.mjs |
| `.json` | ImmosquareExtensions |
| `.yml` (locales/) | ImmosquareYaml |
| `.md` | Custom markdown processor |
| `.sh`, `bash`, `zsh` | shfmt |
| Autres | Prettier |

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

**erb_lint** (`linters/erb_lint/`) :
- `CustomSingleLineIfModifier` : `<% if x %><%= y %><% end %>` → `<%= y if x %>`
- `CustomHtmlToContentTag` : `<div class="x"><%= y %></div>` → `<%= content_tag(:div, y, :class => "x") %>`

**JS** (`linters/normalize-comments.mjs`) :
- Ajoute bordures `//====...====//` autour des commentaires standalone

## Points critiques

- **Symlink erb_lint** : `.erb_linters -> linters/erb_lint` requis (chemin hardcodé par erb_lint)
- **ESLint V9+** : Fichiers copiés dans `tmp/` avant lint puis recopiés (workaround "outside of base path")
- **Configs versionnées** : `rubocop-{VERSION}.yml` générés au premier run. Supprimer pour forcer régénération
- **Parser Ruby** : `parser_prism` (Ruby 3.3+) ou `parser_whitequark` (versions antérieures)
- **Exécution** : Commandes exécutées depuis la racine du gem via `Dir.chdir(gem_root)`

## Prérequis

Bun, Ruby 3.2.6+, shfmt (`brew install shfmt`)