; extends

; Highlight SQL in string literals preceded by a comment containing "sql" or "postgresql"
; e.g.: // language=sql  or  // language=PostgreSQL
(line_comment) @_comment
(#match? @_comment "(?i)(language=)?(sql|postgresql)")
.
(_
  (string_literal) @injection.content
  (#set! injection.language "sql"))

(line_comment) @_comment
(#match? @_comment "(?i)(language=)?(sql|postgresql)")
.
(_
  (multiline_string_literal
    (string_content) @injection.content)
  (#set! injection.language "sql"))

; Auto-detect SQL by keyword in string content
(string_literal) @injection.content
(#match? @injection.content "(?i)\\b(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)\\b")
(#set! injection.language "sql")

(multiline_string_literal
  (string_content) @injection.content
  (#match? @injection.content "(?i)\\b(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)\\b")
  (#set! injection.language "sql"))
