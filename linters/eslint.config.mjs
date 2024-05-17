import js from "@eslint/js"

export default [
  js.configs.recommended,
  {
    ignores: ["package.json"],
    rules:   {
      // ============================================================##
      // Indentation rule: enforces consistent indentation of 2 spaces
      // ============================================================##
      indent:                    [2, 2],
      // ============================================================##
      // Quotes rule: enforces the use of double quotes for strings
      // ============================================================##
      quotes:                    [2, "double"],
      // ============================================================##
      // Semicolon rule: disallows the use of semicolons
      // ============================================================##
      semi:                      [2, "never"],
      // ============================================================##
      // Camelcase rule: disables the camelcase naming convention
      // ============================================================##
      camelcase:                 0,
      // ============================================================##
      // Console rule: allows the use of console statements
      // ============================================================##
      "no-console":              0,
      // ============================================================##
      // Restricted globals rule: allows the use of 
      // certain global variables
      // ============================================================##
      "no-restricted-globals":   0,
      // ============================================================##
      // Multiple spaces rule: disables the restriction 
      // on multiple spaces
      // ============================================================##
      "no-multi-spaces":         0,
      // ============================================================##
      // Undefined variables rule: disables the restriction 
      // on using undefined variables
      // ============================================================##
      "no-undef":                0,
      // ============================================================##
      // Radix rule: disables the requirement to specify the 
      // radix parameter in parseInt
      // ============================================================##
      radix:                     0,
      // ============================================================##
      // Key spacing rule: enforces consistent spacing between 
      // keys and values in object literals
      // ============================================================##
      "key-spacing":             [2, { align: "value" }],
      // ============================================================##
      // Maximum line length rule: disables 
      // the restriction on maximum line length
      // ============================================================##
      "max-len":                 0,
      // ============================================================##
      // Unused expressions rule: disables the 
      // restriction on unused expressions
      // ============================================================##
      "no-unused-expressions":   0,
      // ============================================================##
      // Padded blocks rule: disables 
      // the restriction on padded blocks
      // ============================================================##
      "padded-blocks":           0,
      // ============================================================##
      // Multiple empty lines rule: 
      // disables the restriction on multiple empty lines
      // ============================================================##
      "no-multiple-empty-lines": 0,
      // ============================================================##
      // Default case rule: disables the requirement for 
      // a default case in switch statements
      // ============================================================##
      "default-case":            0,
      // ============================================================##
      // Alert rule: allows the use of alert statements
      // ============================================================##
      "no-alert":                0,
      // ============================================================##
      // Lonely if rule: allows the use of if statements as 
      // the only statement in an else block
      // ============================================================##
      "no-lonely-if":            0,
      // ============================================================##
      // Nested ternary rule: allows the use of nested 
      // ternary expressions
      // ============================================================##
      "no-nested-ternary":       0,
      // ============================================================##
      // Parameter reassignment rule: allows the reassignment 
      // of function parameters, except for properties
      // ============================================================##
      "no-param-reassign":       [2, { props: false }],
      // ============================================================##
      // Comma dangle rule: disallows trailing commas 
      // in object and array literals
      // ============================================================##
      "comma-dangle":            [2, "never"],
      // ============================================================##
      // Prefer destructuring rule: enforces the use of 
      // object destructuring over direct assignments
      // ============================================================##
      "prefer-destructuring":    [2, {"VariableDeclarator": { "array": false, "object": true}, "AssignmentExpression": { "array": false, "object": true} }, {"enforceForRenamedProperties": false}],
      // ============================================================##
      // Comma spacing rule: enforces consistent 
      // spacing before and after commas
      // ============================================================##
      "comma-spacing":           [2, {"before": false, "after": true}]
    }
  }
]
