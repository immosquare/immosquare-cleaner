---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# Ruby, ERB and YAML locales

immosquare-cleaner started as the formatter of immosquare's Ruby on Rails apps, and still covers the whole Ruby ecosystem: Ruby files with RuboCop, ERB and HTML templates with htmlbeautifier and erb_lint, and Rails translation files with immosquare-yaml. This page gathers everything specific to Ruby projects: the style applied, the custom cops and linters, the configuration file and the Gemfile setup.

## Ruby files: RuboCop with the immosquare style

RuboCop formats `.rb`, `.rake`, `.gemspec`, `.ru`, `.jbuilder`, `.rabl`, `.thor`, `.cap`, `.axlsx`, `.podspec` files, the usual extension-less files (`Gemfile`, `Rakefile`, `Capfile`, `Brewfile`, `Guardfile`, `Podfile`, `Berksfile`, `Thorfile`, `Vagrantfile`), and any script starting with `#!/usr/bin/env ruby`. It runs with `--autocorrect-all`, so unsafe corrections are applied too, and with the configuration [`linters/rubocop.yml`](../linters/rubocop.yml):

| Style                    | Applied as                                                                       |
| ------------------------ | -------------------------------------------------------------------------------- |
| Hash syntax              | Hash rockets: `{:key => value}`, no spaces inside the braces                     |
| Strings                  | Double quotes, including in interpolation                                        |
| Word and symbol arrays   | Brackets: `["a", "b"]` and `[:a, :b]`, never `%w[]` or `%i[]`                    |
| Method calls             | Parentheses around arguments, except for macros (`validates`, `has_many`…)       |
| Numeric predicates       | Comparisons: `x > 0` rather than `x.positive?`                                   |
| Class bodies             | One blank line after `class` and before its `end`                                |
| Comments                 | Comment blocks starting with `##` framed by `##====...====##` borders            |
| Metrics, line length     | Not checked                                                                      |

```diff
 class Report
-  ## Totals are cached for an hour
+
+  ##============================================================##
+  ## Totals are cached for an hour
+  ##============================================================##
   def total
-    return 0 if items.size.zero?
-    items.map { |i| i.price }.sum
+    return 0 if items.empty?
+
+    items.map(&:price).sum
   end
+
 end
```

## Custom RuboCop cops shipped with immosquare-cleaner

On top of the stock cops, immosquare-cleaner ships its own cops:

| Cop                                         | Description                                                                        |
| ------------------------------------------- | ---------------------------------------------------------------------------------- |
| `CustomCops/Style/CommentNormalization`     | Frames `##` comment blocks with borders                                            |
| `CustomCops/Style/FontAwesomeNormalization` | Rewrites short Font Awesome prefixes to long ones (`fas` → `fa-solid`)             |
| `CustomCops/Style/AlignAssignments`         | Aligns consecutive variable assignments (disabled by default)                      |
| `CustomCops/Style/InlineMultilineCalls`     | Collapses multi-line calls (default: `link_to`) onto a single line                 |
| `CustomCops/Style/KwargPriorityOrder`       | Reorders the kwargs of `link_to` so `:remote` then `:method` come first            |
| `Style/MethodCallWithArgsParentheses`       | Allows omitting parentheses in Jbuilder blocks and `.jbuilder` files               |

## ERB and HTML templates: htmlbeautifier and erb_lint

`.html.erb` and `.html` files go through htmlbeautifier, which reindents the markup and keeps up to 4 consecutive blank lines, then through erb_lint with `--autocorrect`. erb_lint runs RuboCop on the Ruby inside the tags, plus three custom linters:

| Linter                        | Rewrite                                                                                  |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| `CustomSingleLineIfModifier`  | `<% if cond %><%= x %><% end %>` becomes `<%= x if cond %>`                              |
| `CustomHtmlToContentTag`      | `<div class="x"><%= y %></div>` becomes `<%= content_tag(:div, y, :class => "x") %>`     |
| `CustomAlignConsecutiveCalls` | Aligns the arguments of consecutive calls (default: `link_to`) when their keys match     |

```diff
-<div class="name"><%= user.name %></div>
-<% if user.admin? %><%= link_to("Admin", admin_path) %><% end %>
+<%= content_tag(:div, user.name, :class => "name") %>
+<%= link_to("Admin", admin_path) if user.admin? %>
```

JavaScript templates (`.js.erb`, `.ts.erb`, `.jsx.erb`, `.tsx.erb`, `.mjs.erb`, `.cjs.erb`, `.coffee.erb`) go through erb_lint with a JavaScript-specific configuration, which keeps the HTML-oriented linters away from the JavaScript around the tags. Rails generator templates (`generators/**/templates/`) are never formatted: they hold raw ERB behind the target file's extension, which any formatter would mangle.

## Rails translation files: immosquare-yaml

A `.yml` file inside a `locales` folder is a translation file, formatted by [immosquare-yaml](https://github.com/immosquare/immosquare-yaml) instead of Prettier: keys sorted alphabetically, 2-space indentation, quotes removed where YAML does not need them.

```diff
 fr:
   users:
-      title: 'Utilisateurs'
-      empty: Aucun utilisateur
+    empty: Aucun utilisateur
+    title: Utilisateurs
```

## Configuration file and Gemfile setup for Ruby projects

An optional configuration file, `config/initializers/immosquare-cleaner.rb`, is read from the directory immosquare-cleaner runs in. It excludes files and replaces the default options of the Ruby and ERB tools:

```ruby
ImmosquareCleaner.config do |config|
  config.exclude_files          = ["db/schema.rb", "db/seeds.rb"]
  config.rubocop_options        = "--autocorrect-all --no-parallel"
  config.htmlbeautifier_options = "--keep-blank-lines 4"
  config.erblint_options        = "--autocorrect"
end
```

| Setting                  | Default                            | Effect                                                                             |
| ------------------------ | ---------------------------------- | ---------------------------------------------------------------------------------- |
| `exclude_files`          | none                               | Paths, relative to the project root, that are never cleaned                        |
| `rubocop_options`        | `--autocorrect-all --no-parallel`  | Replaces the RuboCop options; the configuration file stays the gem's               |
| `htmlbeautifier_options` | `--keep-blank-lines 4`             | Replaces the htmlbeautifier options                                                |
| `erblint_options`        | `--autocorrect`                    | Replaces the erb_lint options; without `--autocorrect`, offenses are only reported |

In a Ruby project, add the gem to the development group of the `Gemfile` so that every developer runs the same version, and call it through Bundler:

```ruby
gem "immosquare-cleaner", :group => :development
```

```bash
bundle exec immosquare-cleaner app/models/user.rb
```

From Ruby, `ImmosquareCleaner.clean("app/models/user.rb")` cleans one file and `ImmosquareCleaner.clean_directory(Rails.root.to_s)` cleans the whole app.
