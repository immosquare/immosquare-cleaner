import js from "@eslint/js"

export default [
  js.configs.recommended,
  {
    ignores: ["package.json"],
    rules:   {
      indent:                    [2, 2],
      quotes:                    [2, "double"],
      semi:                      [2,"never"],
      camelcase:                 0,
      "no-console":              0,
      "no-restricted-globals":   0,
      "no-multi-spaces":         0,
      "no-undef":                0,
      radix:                     0,
      "key-spacing":             [2, { align: "value" }],
      "max-len":                 0,
      "no-unused-expressions":   0,
      "padded-blocks":           0,
      "no-multiple-empty-lines": 0,
      "default-case":            0,
      "no-alert":                0,
      "no-lonely-if":            0,
      "no-nested-ternary":       0,
      "no-param-reassign":       [2, { props: false }],
      "comma-dangle":            [2, "never"]
    }
  }
]
