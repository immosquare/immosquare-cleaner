require "json"

module ImmosquareCleaner
  ##============================================================##
  ## `immosquare-cleaner --hook` : the file to clean comes from the
  ## JSON an AI agent pipes on stdin after an edit, not from ARGV.
  ##
  ## Each agent nests the edited path differently:
  ## - Claude Code, Gemini CLI : tool_input.file_path
  ## - Kimi Code               : tool_input.path
  ## - Grok                    : toolInput.file_path
  ## - Cursor (afterFileEdit)  : file_path at the top level
  ## A relative path is resolved against the payload's `cwd`.
  ##
  ## A hook must never block the agent: anything that is not a
  ## supported file (no path, deleted file, directory, LICENSE,
  ## .env...) is skipped instead of reported.
  ##============================================================##
  module Hook
    PAYLOAD_KEYS = ["tool_input", "toolInput"].freeze
    PATH_KEYS    = ["file_path", "path", "target_file"].freeze

    def self.file_path(raw_payload)
      payload = JSON.parse(raw_payload.to_s)
      return if !payload.is_a?(Hash)

      sources = PAYLOAD_KEYS.map {|key| payload[key] }.grep(Hash) + [payload]
      path    = sources.lazy.flat_map {|source| PATH_KEYS.map {|key| source[key] } }.find {|value| value.is_a?(String) && !value.empty? }
      return if path.nil?

      path = File.expand_path(path, payload["cwd"].is_a?(String) ? payload["cwd"] : Dir.pwd)
      path if File.file?(path) && ImmosquareCleaner.supported?(path)
    rescue JSON::ParserError
      nil
    end
  end
end
