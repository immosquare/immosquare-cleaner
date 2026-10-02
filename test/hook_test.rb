# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "json"
require "open3"
require "tmpdir"

class HookTest < Test::Unit::TestCase

  BIN = File.expand_path("../bin/immosquare-cleaner", __dir__)
  LIB = File.expand_path("../lib", __dir__)

  def setup
    @tmp_dir = Dir.mktmpdir("immosquare_cleaner_hook_test")
    @rb_file = File.join(@tmp_dir, "user.rb")
    File.write(@rb_file, "puts 'hello'\n")
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## Each agent nests the edited path in its own field: all of
  ## them must resolve to the same file
  ##============================================================##
  def test_file_path_from_each_agent_payload
    {
      "Claude Code / Gemini CLI" => {"tool_input" => {"file_path" => @rb_file}},
      "Kimi Code"                => {"tool_input" => {"path" => @rb_file}},
      "Grok"                     => {"toolInput" => {"file_path" => @rb_file}},
      "Cursor"                   => {"file_path" => @rb_file}
    }.each do |agent, payload|
      assert_equal(@rb_file, ImmosquareCleaner::Hook.file_path(payload.to_json), agent)
    end
  end

  def test_relative_path_resolved_against_payload_cwd
    payload = {"cwd" => @tmp_dir, "tool_input" => {"file_path" => "user.rb"}}

    assert_equal(@rb_file, ImmosquareCleaner::Hook.file_path(payload.to_json))
  end

  ##============================================================##
  ## Anything that is not a supported existing file is skipped:
  ## the hook must never hand the CLI a path it would fail on
  ##============================================================##
  def test_unsupported_or_missing_targets_are_skipped
    env_file = File.join(@tmp_dir, ".env")
    File.write(env_file, "KEY=value\n")

    [
      {"tool_input" => {"file_path" => env_file}},
      {"tool_input" => {"file_path" => File.join(@tmp_dir, "deleted.rb")}},
      {"tool_input" => {"file_path" => @tmp_dir}},
      {"tool_input" => {"file_path" => ""}},
      {"tool_input" => {"command" => "ls"}}
    ].each do |payload|
      assert_nil(ImmosquareCleaner::Hook.file_path(payload.to_json), payload.inspect)
    end
  end

  def test_invalid_payloads_are_skipped
    ["", "not json", "[1, 2]", "null", "{\"tool_input\": \"oops\"}"].each do |raw|
      assert_nil(ImmosquareCleaner::Hook.file_path(raw), raw.inspect)
    end
  end

  ##============================================================##
  ## End to end through the executable: the file is cleaned,
  ## stdout stays empty (Gemini CLI parses it as JSON) and the
  ## exit status is 0 even when there is nothing to clean
  ##============================================================##
  def test_cli_hook_cleans_the_file_with_an_empty_stdout
    omit("bun not installed") if !system("which bun > /dev/null 2>&1")

    json_file = File.join(@tmp_dir, "data.json")
    File.write(json_file, "{\"b\":1,\"a\":2}")

    stdout, _stderr, status = run_hook({"tool_input" => {"file_path" => json_file}}.to_json)

    assert_equal("", stdout)
    assert_true(status.success?)
    assert_not_equal("{\"b\":1,\"a\":2}", File.read(json_file))
  end

  def test_cli_hook_exits_zero_on_unusable_payloads
    omit("bun not installed") if !system("which bun > /dev/null 2>&1")

    ["", "not json", {"tool_input" => {"file_path" => "/nope/missing.rb"}}.to_json].each do |raw|
      stdout, _stderr, status = run_hook(raw)

      assert_equal("", stdout, raw.inspect)
      assert_true(status.success?, raw.inspect)
    end
  end

  private

  def run_hook(stdin_data)
    Open3.capture3(RbConfig.ruby, "-I#{LIB}", BIN, "--hook", :stdin_data => stdin_data, :chdir => @tmp_dir)
  end

end
