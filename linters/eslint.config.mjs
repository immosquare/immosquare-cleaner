import js               from "@eslint/js"
import preferArrow      from "eslint-plugin-prefer-arrow"
import sonarjs          from "eslint-plugin-sonarjs"
import alignAssignments from "eslint-plugin-align-assignments"
import alignImport      from "eslint-plugin-align-import"

export default [
  js.configs.recommended, js.configs.recommended,
  {
    ignores: ["package.json"],
    plugins: {
      "prefer-arrow":      preferArrow,
      "sonarjs":           sonarjs,
      "align-assignments": alignAssignments,
      "align-import":      alignImport
    },
    rules: {
      // ============================================================##
      // Indentation rule: enforces consistent indentation of 2 spaces
      // ============================================================##
      indent:                                [2, 2],
      // ============================================================##
      // Quotes rule: enforces the use of double quotes for strings
      // ============================================================##
      quotes:                                [2, "double"],
      // ============================================================##
      // Semicolon rule: disallows the use of semicolons
      // ============================================================##
      semi:                                  [2, "never"],
      // ============================================================##
      // Undefined variables rule: disables the restriction 
      // on using undefined variables
      // ============================================================##
      "no-undef":                            0,
      // ============================================================##
      // Key spacing rule: enforces consistent spacing between 
      // keys and values in object literals
      // ============================================================##
      "key-spacing":                         [2, { align: "value" }],
      // ============================================================##
      // Parameter reassignment rule: allows the reassignment 
      // of function parameters, except for properties
      // ============================================================##
      "no-param-reassign":                   [2, { props: false }],
      // ============================================================##
      // Comma dangle rule: disallows trailing commas 
      // in object and array literals
      // ============================================================##
      "comma-dangle":                        [2, "never"],
      // ============================================================##
      // Prefer destructuring rule: enforces the use of 
      // object destructuring over direct assignments
      // ============================================================##
      "prefer-destructuring":                [2, {"VariableDeclarator": { "array": false, "object": true}, "AssignmentExpression": { "array": false, "object": true} }, {"enforceForRenamedProperties": false}],
      // ============================================================##
      // Comma spacing rule: enforces consistent 
      // spacing before and after commas
      // ============================================================##
      "comma-spacing":                       [2, {"before": false, "after": true}],
      // ============================================================##
      // Prefer arrow functions rule: enforces the use of 
      // arrow functions over traditional functions
      // ============================================================##
      "prefer-arrow-callback":               [2],
      "prefer-arrow/prefer-arrow-functions": [
        2,
        {
          "disallowPrototype":      true,
          "singleReturnOnly":       false,
          "classPropertiesAllowed": false
        }
      ],
      // ============================================================##
      // SonarJS rules to encourage concise and clear code
      // ============================================================##
      "sonarjs/no-small-switch":              [2],
      "sonarjs/no-nested-template-literals":  [2],
      "sonarjs/prefer-single-boolean-return": [2],
      "sonarjs/prefer-immediate-return":      [2],
      // ============================================================##
      // Align assignments rule: enforces alignment of assignments
      // ============================================================##
      "align-assignments/align-assignments":  [2],
      // ============================================================##
      // Align imports rule: enforces alignment of import statements
      // ============================================================##
      "align-import/align-import":            [2]
    }
  }
]
