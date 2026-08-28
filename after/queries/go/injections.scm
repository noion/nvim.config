; extends

; Highlight SQL in string literals preceded by a comment containing "sql" or "postgresql"
; e.g.: // language=sql  or  // language=PostgreSQL
;
; The anchor `.` only works between children of a node, so the comment and the
; declaration are matched inside their common parent (a statement list, a block, …).
; The `*_content` nodes already exclude the quotes, so no #offset! is needed.
((_
  (comment) @_comment
  .
  (_
    (expression_list
      (interpreted_string_literal
        (interpreted_string_literal_content) @injection.content))))
  (#match? @_comment "\\c(language\\=)?(sql|postgresql)")
  (#set! injection.language "sql"))

((_
  (comment) @_comment
  .
  (_
    (expression_list
      (raw_string_literal
        (raw_string_literal_content) @injection.content))))
  (#match? @_comment "\\c(language\\=)?(sql|postgresql)")
  (#set! injection.language "sql"))

; Auto-detect SQL by keyword in string content
((interpreted_string_literal
  (interpreted_string_literal_content) @injection.content)
  (#match? @injection.content "\\c<(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)>")
  (#set! injection.language "sql"))

((raw_string_literal
  (raw_string_literal_content) @injection.content)
  (#match? @injection.content "\\c<(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)>")
  (#set! injection.language "sql"))
