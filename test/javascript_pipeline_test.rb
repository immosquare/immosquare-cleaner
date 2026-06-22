# frozen_string_literal: true

require "test-unit"
require_relative "../lib/immosquare-cleaner"
require "fileutils"

##============================================================##
## End-to-end tests for the JavaScript / TypeScript pipeline
## (normalize-comments.mjs + eslint --fix). Unlike the
## normalize-comments unit tests, these run the REAL
## ImmosquareCleaner.clean path, so they exercise the eslint
## flat config, the eslint10-compat shim (align-assignments /
## align-import re-injecting context.getSourceCode), sonarjs,
## and the @typescript-eslint parser. This is the regression
## net for ESLint and @babel/parser version bumps.
##============================================================##
class JavascriptPipelineTest < Test::Unit::TestCase

  BORDER_LINE = "//============================================================//"

  def setup
    @tmp_dir = "test/tmp_js_pipeline_test"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  ##============================================================##
  ## Write source to a temp file, run the real cleaner, return
  ## the resulting file content.
  ##============================================================##
  def clean(basename, source)
    file_path = File.join(@tmp_dir, basename)
    File.write(file_path, source)
    ImmosquareCleaner.clean(file_path)
    File.read(file_path)
  end

  ##============================================================##
  ## .js — normalize-comments borders the standalone comment,
  ## then eslint strips semicolons (semi: never) and aligns the
  ## assignments (align-assignments, loaded through the shim).
  ##============================================================##
  def test_js_pipeline_borders_comments_strips_semicolons_and_aligns
    content = clean("sample.js", <<~JS)
      //my header
      const x = 1;
      const yy = 2;
    JS

    expected = <<~JS
      #{BORDER_LINE}
      // my header
      #{BORDER_LINE}
      const x  = 1
      const yy = 2
    JS

    assert_equal(expected, content)
  end

  ##============================================================##
  ## .ts — the @typescript-eslint parser must accept the type
  ## annotations; types are preserved and semicolons stripped.
  ##============================================================##
  def test_ts_pipeline_preserves_types
    content = clean("sample.ts", <<~TS)
      export const count: number = 1;
      export const label: string = "hi";
    TS

    expected = <<~TS
      export const count: number = 1
      export const label: string = "hi"
    TS

    assert_equal(expected, content)
  end

  ##============================================================##
  ## .tsx — JSX + TS together; arrow-body-style collapses the
  ## block body to an expression and the JSX literal survives.
  ##============================================================##
  def test_tsx_pipeline_handles_jsx
    content = clean("sample.tsx", <<~TSX)
      export const Card = (): JSX.Element => { return <div className="card">hi</div> }
    TSX

    expected = <<~TSX
      export const Card = (): JSX.Element => <div className="card">hi</div>
    TSX

    assert_equal(expected, content)
  end

end
