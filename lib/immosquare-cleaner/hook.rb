require "json"

module ImmosquareCleaner
  ##============================================================##
  ## `immosquare-cleaner --hook` : the files to clean come from the
  ## JSON an AI agent pipes on stdin after an edit, not from ARGV.
  ##
  ## Each agent describes the edit differently:
  ## - Claude Code, Gemini CLI : tool_input.file_path
  ## - Kimi Code               : tool_input.path
  ## - Grok                    : toolInput.file_path
  ## - Cursor (afterFileEdit)  : file_path at the top level
  ## - Codex (apply_patch)     : tool_input.command holds the patch,
  ##                             one `*** Update File: <path>` (or
  ##                             Add File / Move to) line per file
  ## Relative paths are resolved against tool_input.workdir (Codex),
  ## then the payload's `cwd`.
  ##
  ## A hook must never block the agent: anything that is not a
  ## supported file (deleted file, directory, symlink, LICENSE,
  ## .env...) is dropped instead of reported. A symlink is never
  ## followed, so an edit cannot reformat a file outside the project.
  ##============================================================##
  module Hook
    PAYLOAD_KEYS = ["tool_input", "toolInput"].freeze
    PATH_KEYS    = ["file_path", "path", "target_file"].freeze
    PATCH_LINE   = /^\*\*\* (?:Add File|Update File|Move to): (.+)$/

    def self.file_paths(raw_payload)
      payload = JSON.parse(raw_payload.to_s)
      return [] if !payload.is_a?(Hash)

      sources  = PAYLOAD_KEYS.map {|key| payload[key] }.grep(Hash)
      cwd      = payload["cwd"].is_a?(String) && !payload["cwd"].empty? ? payload["cwd"] : Dir.pwd
      workdir  = sources.map {|source| source["workdir"] }.find {|value| value.is_a?(String) && !value.empty? }
      base_dir = workdir ? File.expand_path(workdir, cwd) : cwd

      paths = patch_paths(sources)
      paths = [direct_path(sources + [payload])].compact if paths.empty?
      paths.map {|path| File.expand_path(path, base_dir) }.uniq.select {|path| File.file?(path) && !File.symlink?(path) && ImmosquareCleaner.supported?(path) }
    rescue JSON::ParserError
      []
    end

    def self.direct_path(sources)
      sources.lazy.flat_map {|source| PATH_KEYS.map {|key| source[key] } }.find {|value| value.is_a?(String) && !value.empty? }
    end

    ##============================================================##
    ## Codex sends the patch as a string, older versions as an argv
    ## array (`["apply_patch", "*** Begin Patch..."]`)
    ##============================================================##
    def self.patch_paths(sources)
      patch = sources.map {|source| source["command"] }.find {|value| value.is_a?(String) || value.is_a?(Array) }
      Array(patch).grep(String).join("\n").scan(PATCH_LINE).flatten.map(&:strip)
    end

    private_class_method(:direct_path, :patch_paths)
  end
end
