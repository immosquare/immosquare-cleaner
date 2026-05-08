# frozen_string_literal: true

require "test-unit"
require "erb_lint/all"
require_relative "../linters/erb_lint/custom_html_to_content_tag"
require "better_html"
require "better_html/parser"

module TestHelper
  ##============================================================##
  ## Helper to run the linter on ERB source and return corrections
  ##============================================================##
  def run_linter(source, filename: "test.html.erb")
    buffer        = Parser::Source::Buffer.new(filename)
    buffer.source = source

    processed_source = ERBLint::ProcessedSource.new(filename, source)
    linter           = ERBLint::Linters::CustomHtmlToContentTag.new(nil, ERBLint::LinterConfig.new)

    linter.run(processed_source)
    linter.offenses
  end

  ##============================================================##
  ## Helper to autocorrect ERB source and return the result
  ##============================================================##
  def autocorrect(source, filename: "test.html.erb")
    processed_source = ERBLint::ProcessedSource.new(filename, source)
    linter         = ERBLint::Linters::CustomHtmlToContentTag.new(nil, ERBLint::LinterConfig.new)

    linter.run(processed_source)

    corrector = ERBLint::Corrector.new(processed_source, linter.offenses)
    corrector.corrected_content
  end
end
