# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

##============================================================##
## Integration tests for the monkeypatch in
## linters/rubocop/cop/style/method_call_with_args_parentheses_override.rb
## which teaches Style/MethodCallWithArgsParentheses (configured
## require_parentheses) to allow omitting parentheses in Jbuilder
## context. The patch is loaded through the rubocop config, so the
## only realistic exercise is the full clean() pipeline.
##============================================================##
class JbuilderMethodCallParenthesesTest < Test::Unit::TestCase

  def setup
    @tmp_dir = "test/tmp_jbuilder_parens_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## .jbuilder file — bare `json.method "value"` calls keep their
  ## omitted parentheses. Reason: receiver source == "json" and the
  ## buffer name ends with ".jbuilder".
  ##============================================================##
  def test_jbuilder_file_keeps_omitted_parentheses
    file_path = File.join(@tmp_dir, "show.json.jbuilder")
    File.write(file_path, %(json.first_name "Jhon"\njson.id 12\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    refute_match(/json\.first_name\(/, content)
    refute_match(/json\.id\(/, content)
    assert_match(/json\.first_name\s+"Jhon"/, content)
    assert_match(/json\.id\s+12/, content)
  end

  ##============================================================##
  ## Jbuilder.encode block in a .rb file — calls on the block
  ## parameter keep their omitted parentheses because the node has a
  ## Jbuilder.encode ancestor block.
  ##============================================================##
  def test_jbuilder_encode_block_keeps_omitted_parentheses
    file_path = File.join(@tmp_dir, "encode.rb")
    File.write(file_path, %(Jbuilder.encode do |json|\n  json.name "x"\nend\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    refute_match(/json\.name\(/, content)
    assert_match(/json\.name\s+"x"/, content)
  end

  ##============================================================##
  ## Negative control — proves the cop is actually active so the
  ## assertions above are not vacuous. An ordinary receiver.method
  ## call with a missing paren, outside any Jbuilder context and not
  ## in the AllowedMethods list, MUST gain parentheses.
  ##============================================================##
  def test_non_jbuilder_call_gains_parentheses
    file_path = File.join(@tmp_dir, "plain.rb")
    File.write(file_path, %(def call_it\n  obj.send_thing "hello"\nend\n))

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_match(/obj\.send_thing\("hello"\)/, content)
  end

end
