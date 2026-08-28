; extends

; Highlight SQL in string literals preceded by a comment containing "sql" or "postgresql"
; e.g.: // language=sql  or  // language=PostgreSQL
;
; The anchor `.` only works between children of a node, so the comment and the
; declaration are matched inside their common parent (a class body, a block, …).
; Text blocks are `string_literal` as well, distinguished by their fragment node.
((_
  (line_comment) @_comment
  .
  (_
    (variable_declarator
      (string_literal
        (string_fragment) @injection.content))))
  (#match? @_comment "\\c(language\\=)?(sql|postgresql)")
  (#set! injection.language "sql"))

((_
  (line_comment) @_comment
  .
  (_
    (variable_declarator
      (string_literal
        (multiline_string_fragment) @injection.content))))
  (#match? @_comment "\\c(language\\=)?(sql|postgresql)")
  (#set! injection.language "sql"))

; Auto-detect SQL by keyword in string content
((string_literal
  (string_fragment) @injection.content)
  (#match? @injection.content "\\c<(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)>")
  (#set! injection.language "sql"))

((string_literal
  (multiline_string_fragment) @injection.content)
  (#match? @injection.content "\\c<(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)>")
  (#set! injection.language "sql"))
