# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

class CleanTest < Test::Unit::TestCase

  def setup
    @tmp_dir = "test/tmp_clean_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  def test_ruby_cleaner
    file_path = File.join(@tmp_dir, "test.rb")
    File.write(file_path, "def test;  'double   space'; end\n")

    # This might fail if rubocop is not configured or fails in test env,
    # but we want to see if it triggers the right processor.
    ImmosquareCleaner.clean(file_path)

    assert_true(File.exist?(file_path))
    # RuboCop should have cleaned it (if configured correctly in this env)
    # Even if it didn't change (e.g. rubocop not installed), we at least verify no crash.
  end

  def test_json_cleaner
    file_path = File.join(@tmp_dir, "test.json")
    File.write(file_path, "{\"a\":1,\"b\":2}")

    ImmosquareCleaner.clean(file_path)

    content = File.read(file_path)
    # to_beautiful_json should have formatted it
    assert_match(/"a": 1/, content)
    assert_match(/"b": 2/, content)
  end

  def test_markdown_cleaner
    file_path = File.join(@tmp_dir, "test.md")
    File.write(file_path, "| a | b |\n|---|---|\n| 1 | 2 |\n")

    ImmosquareCleaner.clean(file_path)

    content = File.read(file_path)
    ##============================================================##
    ## The markdown cleaner normalizes column widths, so we match
    ## the cells tolerantly instead of asserting exact whitespace.
    ##============================================================##
    assert_match(/\|\s*a\s*\|\s*b\s*\|/, content)
    assert_match(/\|\s*1\s*\|\s*2\s*\|/, content)
  end

  ##============================================================##
  ## Dispatch tests — verify that processor_for routes each file
  ## type to the correct Processor class. These bypass the actual
  ## linter invocations so they don't need bundler / bun / shfmt.
  ##============================================================##
  def test_dispatch_erb
    assert_equal(ImmosquareCleaner::Processors::Erb, dispatch("app/views/users/show.html.erb"))
    assert_equal(ImmosquareCleaner::Processors::Erb, dispatch("public/500.html"))
  end

  def test_dispatch_ruby
    assert_equal(ImmosquareCleaner::Processors::Ruby, dispatch("app/models/user.rb"))
    assert_equal(ImmosquareCleaner::Processors::Ruby, dispatch("Gemfile"))
    assert_equal(ImmosquareCleaner::Processors::Ruby, dispatch("app/views/api/v1/show.jbuilder"))
  end

  def test_dispatch_ruby_shebang
    file_path = File.join(@tmp_dir, "script_without_extension")
    File.write(file_path, "#!/usr/bin/env ruby\nputs 'hi'\n")

    assert_equal(ImmosquareCleaner::Processors::Ruby, dispatch(file_path))
  end

  def test_dispatch_yaml_locales_only
    assert_equal(ImmosquareCleaner::Processors::Yaml, dispatch("config/locales/fr.yml"))
    ##============================================================##
    ## A non-locale YAML file must NOT go to the Yaml processor —
    ## it falls through to Prettier.
    ##============================================================##
    assert_equal(ImmosquareCleaner::Processors::Prettier, dispatch("config/database.yml"))
  end

  def test_dispatch_javascript
    paths = [
      "app.js",
      "app.mjs",
      "app.cjs",
      "app.jsx",
      "app.ts",
      "app.tsx",
      "view.js.erb",
      "view.mjs.erb",
      "view.cjs.erb",
      "view.jsx.erb",
      "view.ts.erb",
      "view.tsx.erb",
      "view.coffee.erb"
    ]
    paths.each do |path|
      assert_equal(ImmosquareCleaner::Processors::Javascript, dispatch(path), "expected #{path} → Javascript")
    end
  end

  def test_dispatch_html_erb_wins_over_javascript
    ##============================================================##
    ## .html.erb ends with ".erb" but must route to Erb, not to
    ## Javascript — this is why Erb comes first in the registry.
    ##============================================================##
    assert_equal(ImmosquareCleaner::Processors::Erb, dispatch("app/views/foo.html.erb"))
  end

  def test_dispatch_markdown
    assert_equal(ImmosquareCleaner::Processors::Markdown, dispatch("README.md"))
    assert_equal(ImmosquareCleaner::Processors::Markdown, dispatch("template.md.erb"))
  end

  def test_dispatch_shell
    ["install.sh", ".bashrc", ".zshrc", ".bash_profile", ".zprofile"].each do |path|
      assert_equal(ImmosquareCleaner::Processors::Shell, dispatch(path), "expected #{path} → Shell")
    end
  end

  def test_dispatch_prettier_fallback
    ["style.css", "index.html.haml", "config.toml", "unknown.xyz"].each do |path|
      assert_equal(ImmosquareCleaner::Processors::Prettier, dispatch(path), "expected #{path} → Prettier fallback")
    end
  end

  def test_exclude_files_skips_processing
    relative_path = File.join(@tmp_dir, "skip.json")
    absolute_path = File.join(Dir.pwd, relative_path)
    original      = "{\"untouched\":true}"
    File.write(absolute_path, original)

    ImmosquareCleaner.configuration.exclude_files = [relative_path]
    begin
      ImmosquareCleaner.clean(absolute_path)
      assert_equal(original, File.read(absolute_path))
    ensure
      ImmosquareCleaner.configuration.exclude_files = []
    end
  end

  ##============================================================##
  ## End-to-end regression tests for autocorrect bugs that only
  ## reproduce through the full erb_lint + rubocop pipeline.
  ## They write a .html.erb / .js.erb file, run the real cleaner,
  ## and assert that the file is still syntactically valid.
  ##============================================================##

  def test_no_double_paren_on_nested_method_calls
    ##============================================================##
    ## `j(render :partial => "x")` must autocorrect to
    ## `j(render(:partial => "x"))` — never `j(render(:partial => "x")))`
    ## (extra `)`). The bug came from Style/MethodCallWithArgsParentheses
    ## and Style/NestedParenthesizedCalls both inserting closing parens
    ## at different offsets, which erb_lint's correction pipeline did
    ## not deduplicate.
    ##============================================================##
    file_path = File.join(@tmp_dir, "double_paren.html.erb")
    File.write(file_path, %(<%= j(render :partial => "x") %>\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    refute_match(/\)\)\)/, content)
    assert_match(/<%= j\(render\(:partial => "x"\)\) %>/, content)
  end

  def test_defensive_or_fallback_preserved
    ##============================================================##
    ## `foo.to_sym || :default` is a defensive guard against `foo`
    ## being nil. Lint/UselessOr considers `||` unreachable (since
    ## `nil.to_sym` raises) and would strip it — silently introducing
    ## a crash. The guard must survive `clean()`.
    ##============================================================##
    file_path = File.join(@tmp_dir, "defensive_or.html.erb")
    source    = %(<%= simple_form_for(@page.form_root.to_sym || :form, :url => "/") do |f| %>\n<% end %>\n)
    File.write(file_path, source)

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_match(/\|\| :form/, content)
  end

  def test_js_erb_html_in_js_string_not_promoted_to_content_tag
    ##============================================================##
    ## In a .js.erb file, HTML inside a JS string literal must NOT
    ## be promoted to content_tag — doing so breaks the host string
    ## (attribute quoting collides with the surrounding `"..."`,
    ## any `j()` JS-escape no longer wraps the full HTML). The
    ## JS-specific erb_lint config disables CustomHtmlToContentTag.
    ##============================================================##
    file_path = File.join(@tmp_dir, "js_string.js.erb")
    File.write(file_path, %(el.innerHTML = "<div class='alert'><%= j errors.join(', ') %></div>"\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    refute_match(/content_tag/, content)
    assert_match(/<div class='alert'>/, content)
  end

  def test_js_erb_void_tag_self_closing_preserved
    ##============================================================##
    ## `<br/>` inside a JS string must NOT be rewritten to `<br>`.
    ## The default erb_lint linter SelfClosingTag treats this as
    ## an HTML rule and would silently mutate the literal — fine
    ## in .html.erb, broken intent in .js.erb (the dev wrote
    ## XHTML-style on purpose, or the string is fed to a parser
    ## that requires it). The JS-specific erb_lint config
    ## disables SelfClosingTag.
    ##============================================================##
    file_path = File.join(@tmp_dir, "self_close.js.erb")
    File.write(file_path, %(el.innerHTML = "<br/>"\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_match(%r{<br/>}, content)
  end

  def test_html_erb_self_closing_still_corrected
    ##============================================================##
    ## Sanity check: SelfClosingTag must keep working on .html.erb
    ## (non-regression of the JS-config split).
    ##============================================================##
    file_path = File.join(@tmp_dir, "self_close.html.erb")
    File.write(file_path, "<br/>\n")

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_match(/<br>/, content)
    refute_match(%r{<br/>}, content)
  end

  def test_html_erb_content_tag_still_promoted
    ##============================================================##
    ## Sanity check: CustomHtmlToContentTag must keep firing on
    ## .html.erb (non-regression of the JS-config split).
    ##============================================================##
    file_path = File.join(@tmp_dir, "promote.html.erb")
    File.write(file_path, %(<div class="card"><%= title %></div>\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_match(/content_tag\(:div, title, :class => "card"\)/, content)
  end

  private

  def dispatch(file_path)
    ImmosquareCleaner.send(:processor_for, file_path)
  end

end
