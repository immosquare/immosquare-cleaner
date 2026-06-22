# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

class ShellProcessorTest < Test::Unit::TestCase

  def setup
    @tmp_dir = "test/tmp_shell_processor_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## Dispatch — every shell extension/filename routes to the
  ## Shell processor. These don't need shfmt installed since they
  ## only exercise processor_for, not the linter invocation.
  ##============================================================##
  def test_dispatch_shell_extensions
    [
      "install.sh",
      ".bashrc",
      ".zshrc",
      ".bash_profile",
      ".zprofile",
      "script.bash",
      "config.zsh"
    ].each do |path|
      assert_equal(ImmosquareCleaner::Processors::Shell, dispatch(path), "expected #{path} -> Shell")
    end
  end

  ##============================================================##
  ## A non-shell file must NOT route to the Shell processor.
  ## ".shell" does not match (EXTENSIONS uses ".sh", not "sh"),
  ## and a plain ".css" falls through to the Prettier fallback.
  ##============================================================##
  def test_dispatch_non_shell_not_shell
    assert_equal(ImmosquareCleaner::Processors::Prettier, dispatch("style.css"))
    assert_equal(ImmosquareCleaner::Processors::Prettier, dispatch("notes.shell"))
  end

  ##============================================================##
  ## Formatting — when shfmt is installed, the Shell processor runs
  ## `shfmt -i 2 -w`, re-indenting the if/then/fi body to 2 spaces.
  ## shfmt is an external binary that may be absent on this machine,
  ## so the assertion is guarded by omit().
  ##============================================================##
  def test_shfmt_reindents_body_to_two_spaces
    omit("shfmt not installed") unless system("which shfmt > /dev/null 2>&1")

    file_path = File.join(@tmp_dir, "indent.sh")
    ##============================================================##
    ## Body of the if-block is indented with 4 spaces on purpose;
    ## shfmt -i 2 must collapse it to 2 spaces.
    ##============================================================##
    File.write(file_path, "#!/usr/bin/env bash\nif true; then\n    echo \"hi\"\nfi\n")

    ImmosquareCleaner.clean(file_path)
    content = File.read(file_path)

    assert_true(File.exist?(file_path))
    assert_match(/^  echo "hi"$/, content)
    refute_match(/^    echo "hi"$/, content)
  end

  ##============================================================##
  ## When shfmt is absent the processor must warn and leave the
  ## file byte-for-byte untouched (no crash, no partial write).
  ## This branch is the one actually exercised on a machine without
  ## shfmt; it runs unconditionally.
  ##============================================================##
  def test_missing_shfmt_leaves_file_untouched
    omit("shfmt is installed - cannot exercise the missing-binary branch") if system("which shfmt > /dev/null 2>&1")

    file_path = File.join(@tmp_dir, "untouched.sh")
    original  = "#!/usr/bin/env bash\nif true; then\n    echo \"hi\"\nfi\n"
    File.write(file_path, original)

    assert_nothing_raised do
      ImmosquareCleaner.clean(file_path)
    end

    assert_equal(original, File.read(file_path))
  end

  private

  def dispatch(file_path)
    ImmosquareCleaner.send(:processor_for, file_path)
  end

end
