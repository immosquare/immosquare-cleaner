module RuboCop
  module Cop
    module CustomCops
      module Style
        class CommentNormalization < Base

          extend AutoCorrector

          MSG              = "Comments should be normalized with the standard format if start with ##".freeze
          BORDER_LINE      = "###{"=" * 60}##".freeze
          INSIDE_SEPARATOR = "## ---------".freeze
          BLANK_LINE       = "##".freeze
          EMPTY_BODY       = "## ...".freeze
          SPACE            = " ".freeze

          ##============================================================##
          ## Patterns détectés ligne par ligne dans un bloc :
          ## - STRUCTURED_LINE : puces, citations, listes numérotées
          ## - INDENTED_LINE   : indentation explicite (3+ espaces après ##)
          ## - RAW_LINE        : ligne préservée telle quelle (## | ...)
          ## - FENCE_LINE      : ouverture/fermeture d'un bloc de code (## ```)
          ## - USER_SEPARATOR  : séparateur explicite (## ---, ===, ___)
          ##============================================================##
          STRUCTURED_LINE = /\A##\s+([-*+>]|\d+[.)])\s/
          INDENTED_LINE   = /\A##\s{3,}\S/
          RAW_LINE        = /\A##\s*\|/
          FENCE_LINE      = /\A##\s*```/
          USER_SEPARATOR  = /\A##\s*[-=_]{3,}\s*\z/

          def on_new_investigation
            return if @investigation_in_progress

            @investigation_in_progress = true

            find_comment_blocks(processed_source.comments).each do |block|
              normalized = normalize_comment_block(block)
              next if !needs_correction?(block, normalized)

              range = block_range(block)
              ignore_node(range)
              add_offense(block.first) do |corrector|
                corrector.replace(range, normalized)
              end
            end
          end

          private

          ##============================================================##
          ## On ne traite que les commentaires qui commencent en début de
          ## ligne par "##" (pas les commentaires de fin de ligne ruby).
          ## Les blocs sont des suites de lignes contiguës.
          ##============================================================##
          def find_comment_blocks(comments)
            standalone = comments.select do |comment|
              processed_source.lines[comment.location.line - 1].lstrip.start_with?("##")
            end

            standalone.slice_when {|prev, nxt| nxt.location.line != prev.location.line + 1 }.to_a
          end

          def block_range(block)
            buffer    = processed_source.buffer
            start_pos = buffer.line_range(block.first.location.line).begin_pos
            end_pos   = buffer.line_range(block.last.location.line).end_pos
            Parser::Source::Range.new(buffer, start_pos, end_pos)
          end

          ##============================================================##
          ## Encadre le body avec BORDER_LINE et indente toutes les lignes
          ## sur la colonne du bloc original. Le range remplacé démarre en
          ## colonne 0, donc la première ligne doit aussi recevoir le pad.
          ##============================================================##
          def normalize_comment_block(block)
            body = build_body(block)
            body = [EMPTY_BODY] if body.empty?

            pad = SPACE * indent_level(block.first)
            [BORDER_LINE, *body, BORDER_LINE].map {|line| "#{pad}#{line}" }.join("\n")
          end

          ##============================================================##
          ## Transforme chaque ligne du bloc :
          ## - bordures existantes        → ignorées
          ## - lignes vides en tête       → ignorées (avant tout contenu)
          ## - fenced code blocks (## ```)→ contenu préservé tel quel
          ## - lignes "raw" (## | ...)    → préservées
          ## - listes / indentation 3+    → préservées
          ## - séparateurs (## ---)       → INSIDE_SEPARATOR
          ## - lignes "##" seules         → conservées comme ligne vide
          ## - texte normal               → nettoyé via #cleaned_line
          ##============================================================##
          def build_body(block)
            body         = []
            in_code      = false
            content_seen = false

            block.each do |comment|
              text = comment.text.to_s.rstrip

              if text == BORDER_LINE
                next
              elsif text.match?(FENCE_LINE)
                in_code = !in_code
                body << text
                content_seen = true
              elsif in_code || text.match?(RAW_LINE)
                body << text
                content_seen = true
              elsif text == BLANK_LINE
                body << BLANK_LINE if content_seen
              elsif text.match?(USER_SEPARATOR)
                body << INSIDE_SEPARATOR if content_seen
              elsif text.match?(STRUCTURED_LINE) || text.match?(INDENTED_LINE)
                body << text
                content_seen = true
              else
                body << cleaned_line(text)
                content_seen = true
              end
            end

            body
          end

          ##============================================================##
          ## Nettoie une ligne de texte standard :
          ## - "### foo"  → "## foo"  (collapse les # répétés)
          ## - "##  foo"  → "## foo"  (un seul espace après ##)
          ## NB : les lignes avec 3+ espaces volontaires sont déjà
          ## interceptées en amont par INDENTED_LINE.
          ##============================================================##
          def cleaned_line(text)
            text.sub(/\A##\s*#+\s*(?=\S)/, "## ").sub(/\A##\s+(?=\S)/, "## ")
          end

          def indent_level(comment)
            processed_source.lines[comment.location.line - 1][/\A */].size
          end

          ##============================================================##
          ## Compare en strippant chaque ligne : on ignore les différences
          ## d'indentation puisque le range cible déjà la bonne colonne.
          ##============================================================##
          def needs_correction?(block, normalized)
            current_lines    = block.map {|c| c.text.to_s.strip }
            normalized_lines = normalized.split("\n").map(&:strip)
            current_lines != normalized_lines
          end

        end
      end
    end
  end
end
