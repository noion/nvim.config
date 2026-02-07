; extends

; Highlight SQL in string literals preceded by a comment containing "sql" or "postgresql"
; e.g.: // language=sql  or  // language=PostgreSQL
(comment) @_comment
(#match? @_comment "(?i)(language=)?(sql|postgresql)")
.
(_
  (interpreted_string_literal) @injection.content
  (#set! injection.language "sql")
  (#offset! @injection.content 0 1 0 -1))

(comment) @_comment
(#match? @_comment "(?i)(language=)?(sql|postgresql)")
.
(_
  (raw_string_literal) @injection.content
  (#set! injection.language "sql")
  (#offset! @injection.content 0 1 0 -1))

; Auto-detect SQL by keyword in string content
(interpreted_string_literal) @injection.content
(#match? @injection.content "(?i)\\b(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)\\b")
(#set! injection.language "sql")
(#offset! @injection.content 0 1 0 -1)

(raw_string_literal) @injection.content
(#match? @injection.content "(?i)\\b(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|MERGE INTO)\\b")
(#set! injection.language "sql")
(#offset! @injection.content 0 1 0 -1)
