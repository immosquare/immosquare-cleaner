import js               from "@eslint/js"
import preferArrow      from "eslint-plugin-prefer-arrow"
import sonarjs          from "eslint-plugin-sonarjs"
import alignAssignments from "eslint-plugin-align-assignments"
import alignImport      from "eslint-plugin-align-import"
import erb              from "eslint-plugin-erb"
import tseslint         from "@typescript-eslint/eslint-plugin"
import tsparser         from "@typescript-eslint/parser"

// Common formatting and style rules
const commonRules = {
  // ==============================================================================================##
  // SonarJS rules to encourage concise and clear code
  // Some rules are fixable others are not
  // https://github.com/SonarSource/SonarJS/blob/master/packages/jsts/src/rules/README.md
  // ==============================================================================================##
  "sonarjs/no-small-switch":              [2],
  "sonarjs/no-nested-template-literals":  [2],
  "sonarjs/prefer-single-boolean-return": [2],
  "sonarjs/prefer-immediate-return":      [2],
  
  // ==============================================================================================##
  // Indentation rule: enforces consistent indentation of 2 spaces
  // ==============================================================================================##
  indent: [2, 2],
  
  // ==============================================================================================##
  // Quotes rule: enforces the use of double quotes for strings
  // ==============================================================================================##
  quotes: [2, "double"],
  
  // ==============================================================================================##
  // Semicolon rule: disallows the use of semicolons
  // ==============================================================================================##
  semi: [2, "never"],
  
  // ==============================================================================================##
  // Key spacing rule: enforces consistent spacing between keys and values in object literals
  // ==============================================================================================##
  "key-spacing": [2, { align: "value" }],
  
  // ==============================================================================================##
  // Parameter reassignment rule: allows the reassignment of function parameters, except for properties
  // ==============================================================================================##
  "no-param-reassign": [2, { props: false }],
  
  // ==============================================================================================##
  // Comma dangle rule: disallows trailing commas in object and array literals
  // ==============================================================================================##
  "comma-dangle": [2, "never"],
  
  // ==============================================================================================##
  // Prefer destructuring rule: enforces the use of object destructuring over direct assignments
  // ==============================================================================================##
  "prefer-destructuring": [2, { "VariableDeclarator": { "array": false, "object": true }, "AssignmentExpression": { "array": false, "object": true } }, { "enforceForRenamedProperties": false }],
  
  // ==============================================================================================##
  // Comma spacing rule: enforces consistent spacing before and after commas
  // ==============================================================================================##
  "comma-spacing": [2, { "before": false, "after": true }],
  
  // ==============================================================================================##
  // Align assignments rule: enforces alignment of assignments
  // ==============================================================================================##
  "align-assignments/align-assignments": [2],
  
  // ==============================================================================================##
  // Align imports rule: enforces alignment of import statements
  // ==============================================================================================##
  "align-import/align-import": [2],
  
  // ==============================================================================================##
  // Prefer arrow functions rule: enforces the use of arrow functions over traditional functions
  // ==============================================================================================##
  "prefer-arrow-callback":               [2],
  "prefer-arrow/prefer-arrow-functions": [2, {"disallowPrototype": true, "singleReturnOnly": false, "classPropertiesAllowed": false}],
  
  // ==============================================================================================##
  // Enforces no braces where they can be omitted
  // ==============================================================================================##
  "arrow-body-style": [2, "as-needed", { requireReturnForObjectLiteral: false }],
  
  // ==============================================================================================##
  // Require parens in arrow function arguments
  // ==============================================================================================##
  "arrow-parens": [2, "always"],
  
  // ==============================================================================================##
  // Require space before/after arrow function's arrow
  // ==============================================================================================##
  "arrow-spacing": [2, { before: true, after: true }],
  
  // ==============================================================================================##
  // Disallow arrow functions where they could be confused with comparisons
  // ==============================================================================================##
  "no-confusing-arrow": [2, { allowParens: true }],
  
  // ==============================================================================================##
  // Disallow magic numbers
  // ==============================================================================================##
  "no-magic-numbers": ["off", { ignore: [], ignoreArrayIndexes: true, enforceConst: true, detectObjects: false }]
}

// Common plugins configuration
const commonPlugins = {
  "prefer-arrow":      preferArrow,
  "sonarjs":           sonarjs,
  "align-assignments": alignAssignments,
  "align-import":      alignImport
}

export default [
  js.configs.recommended,
  {
    ignores: ["package.json"],
    plugins: commonPlugins,
    rules:   {
      ...commonRules,
      // ==============================================================================================##
      // Undefined variables rule: disables the restriction on using undefined variables
      // ==============================================================================================##
      "no-undef": 0
    }
  },
  erb.configs.recommended,
  {
    linterOptions: {
      // The "unused disable directive" is set to "warn" by default.
      // For the ERB plugin to work correctly, you must disable
      // this directive to avoid issues described here
      // https://github.com/eslint/eslint/discussions/18114
      // If you're using the CLI, you might also use the following flag:
      // --report-unused-disable-directives-severity=off
      reportUnusedDisableDirectives: "off"
    }
    // your other configuration options
  },
  // TypeScript configuration
  {
    files:           ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser:        tsparser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType:  "module"
      }
    },
    plugins: {
      "@typescript-eslint": tseslint,
      ...commonPlugins
    },
    rules: {
      // Extend base JavaScript rules
      ...js.configs.recommended.rules,
      ...commonRules,
      
      // TypeScript specific rules
      "@typescript-eslint/no-unused-vars":                [2],
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/no-explicit-any":               "warn",
      
      // TypeScript handles undefined variables
      "no-undef": "off"
    }
  }
]
