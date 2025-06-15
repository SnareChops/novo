;; AST Node Type Definitions
;; Defines all node type constants and memory layout constants for the Novo AST
;; This module exports all type constants for use by other AST modules

(module $ast_node_types
  ;; Node type constants
  ;; Type System Nodes (0-19)
  (global $TYPE_PRIMITIVE (export "TYPE_PRIMITIVE") i32 (i32.const 0))
  (global $TYPE_LIST (export "TYPE_LIST") i32 (i32.const 1))
  (global $TYPE_OPTION (export "TYPE_OPTION") i32 (i32.const 2))
  (global $TYPE_RESULT (export "TYPE_RESULT") i32 (i32.const 3))
  (global $TYPE_TUPLE (export "TYPE_TUPLE") i32 (i32.const 4))
  (global $TYPE_RECORD (export "TYPE_RECORD") i32 (i32.const 5))
  (global $TYPE_VARIANT (export "TYPE_VARIANT") i32 (i32.const 6))
  (global $TYPE_ENUM (export "TYPE_ENUM") i32 (i32.const 7))
  (global $TYPE_FLAGS (export "TYPE_FLAGS") i32 (i32.const 8))
  (global $TYPE_RESOURCE (export "TYPE_RESOURCE") i32 (i32.const 9))

  ;; Expression Nodes (20-39)
  (global $EXPR_INTEGER_LITERAL (export "EXPR_INTEGER_LITERAL") i32 (i32.const 20))
  (global $EXPR_FLOAT_LITERAL (export "EXPR_FLOAT_LITERAL") i32 (i32.const 21))
  (global $EXPR_BOOL_LITERAL (export "EXPR_BOOL_LITERAL") i32 (i32.const 22))
  (global $EXPR_STRING_LITERAL (export "EXPR_STRING_LITERAL") i32 (i32.const 23))
  (global $EXPR_IDENTIFIER (export "EXPR_IDENTIFIER") i32 (i32.const 24))
  (global $EXPR_TRADITIONAL_CALL (export "EXPR_TRADITIONAL_CALL") i32 (i32.const 25))  ;; func(arg1, arg2)
  (global $EXPR_WAT_STYLE_CALL (export "EXPR_WAT_STYLE_CALL") i32 (i32.const 26))    ;; (func arg1 arg2)
  (global $EXPR_META_CALL (export "EXPR_META_CALL") i32 (i32.const 27))         ;; value::size()
  (global $EXPR_ADD (export "EXPR_ADD") i32 (i32.const 28))
  (global $EXPR_SUB (export "EXPR_SUB") i32 (i32.const 29))
  (global $EXPR_MUL (export "EXPR_MUL") i32 (i32.const 30))
  (global $EXPR_DIV (export "EXPR_DIV") i32 (i32.const 31))
  (global $EXPR_MOD (export "EXPR_MOD") i32 (i32.const 32))
  (global $EXPR_BLOCK (export "EXPR_BLOCK") i32 (i32.const 33))

  ;; Pattern Matching Nodes (40-59)
  (global $PAT_LITERAL (export "PAT_LITERAL") i32 (i32.const 40))
  (global $PAT_VARIABLE (export "PAT_VARIABLE") i32 (i32.const 41))
  (global $PAT_TUPLE (export "PAT_TUPLE") i32 (i32.const 42))
  (global $PAT_RECORD (export "PAT_RECORD") i32 (i32.const 43))
  (global $PAT_VARIANT (export "PAT_VARIANT") i32 (i32.const 44))
  (global $PAT_OPTION_SOME (export "PAT_OPTION_SOME") i32 (i32.const 45))
  (global $PAT_OPTION_NONE (export "PAT_OPTION_NONE") i32 (i32.const 46))
  (global $PAT_RESULT_OK (export "PAT_RESULT_OK") i32 (i32.const 47))
  (global $PAT_RESULT_ERR (export "PAT_RESULT_ERR") i32 (i32.const 48))
  (global $PAT_LIST (export "PAT_LIST") i32 (i32.const 49))
  (global $PAT_WILDCARD (export "PAT_WILDCARD") i32 (i32.const 50))

  ;; Control Flow Nodes (60-79)
  (global $CTRL_IF (export "CTRL_IF") i32 (i32.const 60))
  (global $CTRL_WHILE (export "CTRL_WHILE") i32 (i32.const 61))
  (global $CTRL_BREAK (export "CTRL_BREAK") i32 (i32.const 62))
  (global $CTRL_CONTINUE (export "CTRL_CONTINUE") i32 (i32.const 63))
  (global $CTRL_RETURN (export "CTRL_RETURN") i32 (i32.const 64))
  (global $CTRL_MATCH (export "CTRL_MATCH") i32 (i32.const 65))
  (global $CTRL_MATCH_ARM (export "CTRL_MATCH_ARM") i32 (i32.const 66))

  ;; Declaration Nodes (80-99)
  (global $DECL_FUNCTION (export "DECL_FUNCTION") i32 (i32.const 80))
  (global $DECL_RECORD (export "DECL_RECORD") i32 (i32.const 81))
  (global $DECL_VARIANT (export "DECL_VARIANT") i32 (i32.const 82))
  (global $DECL_ENUM (export "DECL_ENUM") i32 (i32.const 83))
  (global $DECL_FLAGS (export "DECL_FLAGS") i32 (i32.const 84))
  (global $DECL_RESOURCE (export "DECL_RESOURCE") i32 (i32.const 85))
  (global $DECL_COMPONENT (export "DECL_COMPONENT") i32 (i32.const 86))
  (global $DECL_INTERFACE (export "DECL_INTERFACE") i32 (i32.const 87))
  (global $DECL_IMPORT (export "DECL_IMPORT") i32 (i32.const 88))
  (global $DECL_EXPORT (export "DECL_EXPORT") i32 (i32.const 89))

  ;; Node Structure Constants
  ;; Memory offset constants for node fields
  (global $NODE_TYPE_OFFSET (export "NODE_TYPE_OFFSET") i32 (i32.const 0))     ;; i32 - Which type of node
  (global $NODE_SIZE_OFFSET (export "NODE_SIZE_OFFSET") i32 (i32.const 4))     ;; i32 - Total size in bytes
  (global $NODE_NEXT_OFFSET (export "NODE_NEXT_OFFSET") i32 (i32.const 8))     ;; i32 - Next sibling pointer
  (global $NODE_CHILD_OFFSET (export "NODE_CHILD_OFFSET") i32 (i32.const 12))   ;; i32 - First child pointer
  (global $NODE_DATA_OFFSET (export "NODE_DATA_OFFSET") i32 (i32.const 16))    ;; Start of node-specific data
)
