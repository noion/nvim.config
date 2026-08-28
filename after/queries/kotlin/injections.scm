; extends

; Highlight SQL in string literals preceded by a comment containing "sql" or "postgresql"
; e.g.: // language=sql  or  // language=PostgreSQL
;
; The anchor `.` only works between children of a node, so the comment and the
; declaration are matched inside their common parent (a class body, a block, …).
; `"..."` and `"""..."""` are both `string_literal` in this grammar; `string_content`
; is the text without the quotes, which is what the injected parser should see.
((_
  (line_comment) @_comment
  .
  (_
    (string_literal
      (string_content) @injection.content)))
  (#match? @_comment "\\c(language\\=)?(sql|postgresql)")
  (#set! injection.language "sql"))

; Auto-detect SQL by keyword in string content
((string_literal
  (string_content) @injection.content)
  (#match? @injection.content "\\c<(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)>")
  (#set! injection.language "sql"))
