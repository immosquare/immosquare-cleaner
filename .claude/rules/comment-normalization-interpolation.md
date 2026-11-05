---
paths:
  - "linters/rubocop/cop/custom_cops/style/comment_normalization.rb"
  - "test/comment_normalization_test.rb"
---

# CommentNormalization — a leading `#{` loses its `#`

- `cleaned_line` collapses every run of `#` that follows `## ` (`"### foo"` → `"## foo"`). The same substitution also eats the `#` of an interpolation placed at the start of a comment line: `## #{app_name}_ios_app` becomes `## {app_name}_ios_app`, on every run. Until the regex handles it, do not start a comment line with `#{`.
- When changing this regex, cover the `#{` case in `test/comment_normalization_test.rb`.
- When a diff shows `## #{…}` turned into `## {…}`, suspect this cop before assuming a manual edit.
