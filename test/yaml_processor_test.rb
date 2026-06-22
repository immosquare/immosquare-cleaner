# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "yaml"
require "fileutils"

class YamlProcessorTest < Test::Unit::TestCase

  def setup
    @tmp_dir     = "test/tmp_yaml_processor_test"
    @locales_dir = File.join(@tmp_dir, "locales")
    FileUtils.mkdir_p(@locales_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## A locale YAML file (path under locales/) is normalized by
  ## ImmosquareYaml: keys are sorted alphabetically at every level
  ## and superfluous quotes are stripped from simple scalars.
  ##============================================================##
  def test_keys_sorted_and_quotes_stripped
    file_path = locale_file("fr.yml")
    File.write(file_path, <<~YAML)
      en:
        zebra: 'single quoted'
        apple: "double quoted"
        nested:
          gamma: value gamma
          alpha: 1
        plain: hello
      fr:
        bonjour: monde
    YAML

    ImmosquareCleaner.clean(file_path)

    expected = <<~YAML
      en:
        apple: double quoted
        nested:
          alpha: 1
          gamma: value gamma
        plain: hello
        zebra: single quoted
      fr:
        bonjour: monde
    YAML

    assert_equal(expected, File.read(file_path))
  end

  ##============================================================##
  ## The cleaned file must remain valid YAML and preserve every
  ## original key/value (no data loss through normalization).
  ##============================================================##
  def test_valid_yaml_and_no_data_loss
    file_path = locale_file("en.yml")
    File.write(file_path, <<~YAML)
      en:
        zebra: 'single quoted'
        apple: "double quoted"
        nested:
          gamma: value gamma
          alpha: 1
        plain: hello
      fr:
        bonjour: monde
    YAML

    ImmosquareCleaner.clean(file_path)

    loaded = YAML.load_file(file_path)
    assert_equal(
      {
        "en" => {
          "apple"  => "double quoted",
          "nested" => {"alpha" => 1, "gamma" => "value gamma"},
          "plain"  => "hello",
          "zebra"  => "single quoted"
        },
        "fr" => {"bonjour" => "monde"}
      },
      loaded
    )
  end

  ##============================================================##
  ## Cleaning an already-cleaned file produces byte-identical
  ## output — the normalization is a fixed point (idempotent).
  ##============================================================##
  def test_idempotent
    file_path = locale_file("idempotent.yml")
    File.write(file_path, <<~YAML)
      fr:
        greeting: "Bonjour, %{name}"
        colon_value: "key: value"
        nested:
          b: beta
          a: alpha
      en:
        hello: world
    YAML

    ImmosquareCleaner.clean(file_path)
    once = File.read(file_path)

    ImmosquareCleaner.clean(file_path)
    twice = File.read(file_path)

    assert_equal(once, twice)
  end

  ##============================================================##
  ## Quotes that are required for YAML safety are preserved:
  ## a colon-space inside the value and the boolean-like literal
  ## "yes" both stay quoted, otherwise the value would change
  ## meaning on reload.
  ##============================================================##
  def test_unsafe_scalars_stay_quoted
    file_path = locale_file("unsafe.yml")
    File.write(file_path, <<~YAML)
      fr:
        colon_value: "key: value"
        yes_word: "yes"
        greeting: "Bonjour, %{name}"
    YAML

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_match(/^  colon_value: "key: value"$/, content)
    assert_match(/^  yes_word: "yes"$/, content)
    ##============================================================##
    ## A plain interpolation needs no quotes once normalized.
    ##============================================================##
    assert_match(/^  greeting: Bonjour, %\{name\}$/, content)
  end

  ##============================================================##
  ## A YAML file NOT under locales/ is not handled by the Yaml
  ## processor — it falls through to the Prettier fallback.
  ##============================================================##
  def test_non_locale_yaml_dispatched_to_prettier
    assert_equal(
      ImmosquareCleaner::Processors::Yaml,
      ImmosquareCleaner.send(:processor_for, "config/locales/fr.yml")
    )
    assert_equal(
      ImmosquareCleaner::Processors::Prettier,
      ImmosquareCleaner.send(:processor_for, "config/database.yml")
    )
  end

  private

  def locale_file(name)
    File.join(@locales_dir, name)
  end

end
