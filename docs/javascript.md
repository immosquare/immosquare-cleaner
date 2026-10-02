---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# JavaScript and TypeScript formatting with ESLint

immosquare-cleaner formats JavaScript and TypeScript files with ESLint and its own configuration, after framing standalone comments with borders. This page lists the files concerned, the rules applied and fixed automatically, and what stays reported without being fixed.

## Which JavaScript and TypeScript files are formatted

The JavaScript processor handles `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts` and `.tsx` files. Two steps run on each of them:

1. **Comment normalization**: every standalone `//` comment, or block of consecutive ones, is framed by `//====...====//` borders. Trailing comments at the end of a code line are left alone.
2. **ESLint with `--fix`**, using [`linters/eslint.config.mjs`](../linters/eslint.config.mjs). TypeScript files go through `@typescript-eslint/parser`.

JavaScript templates with an `.erb` extension (`.js.erb`, `.ts.erb`, `.jsx.erb`, `.tsx.erb`, `.mjs.erb`, `.cjs.erb`, `.coffee.erb`) are formatted by erb_lint with a JavaScript-specific configuration instead, so that HTML-oriented ERB rules never touch the JavaScript around the tags. They are described with the other ERB files in [Ruby, ERB and YAML locales](ruby-erb.md).

ESLint runs from bun, so `bun` must be installed; the ESLint packages are installed into the gem on first run.

## ESLint rules fixed automatically by immosquare-cleaner

The configuration starts from ESLint's recommended rules and adds the immosquare style. The rules below are fixed on every run:

| Rule                                 | Effect                                                                                           |
| ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `indent`                             | 2-space indentation                                                                              |
| `quotes`                             | Double quotes for strings                                                                        |
| `semi`                               | No semicolons                                                                                    |
| `comma-dangle`                       | No trailing comma in objects and arrays                                                          |
| `comma-spacing`                      | One space after a comma, none before                                                             |
| `key-spacing` (`align: "value"`)     | Values of a multi-line object literal aligned on one column                                      |
| `align-assignments`                  | `=` of consecutive assignments aligned, logical assignments such as `&&=` and `??=` included     |
| `align-import`                       | `from` of consecutive imports aligned                                                            |
| `arrow-parens`, `arrow-spacing`      | Parentheses around arrow function parameters, spaces around `=>`                                 |
| `arrow-body-style`                   | No braces around an arrow function body that is a single expression                              |
| `prefer-arrow-callback`              | Callbacks written as arrow functions                                                             |
| `unused-imports/no-unused-imports`   | Unused imports removed                                                                           |
| `sonarjs/prefer-immediate-return`    | A variable assigned only to be returned on the next line is returned directly                    |
| `prefer-destructuring`               | `const name = user.name` becomes `const {name} = user` when the variable has the property's name |

Before and after, on a TypeScript file:

```diff
-import {User} from './types'
-import {request} from './http'
-// Load a user by id
+import {User}    from "./types"
+import {request} from "./http"
+//============================================================//
+// Load a user by id
+//============================================================//
 export const getUser = async (id: number): Promise<User> => {
-    const options = {method: 'GET', retries: 3};
-    let response = await request(`/users/${id}`, options);
-    return response as User;
+  const options = {method: "GET", retries: 3}
+  let response  = await request(`/users/${id}`, options)
+  return response as User
 }
```

## ESLint rules reported but not fixed

Some rules have no safe automatic fix. ESLint prints them on stderr and leaves the code as written, so the developer, or the agent reading the hook output, decides:

| Rule                                                                                                     | What it asks for                                                                                               |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `prefer-arrow/prefer-arrow-functions`                                                                    | Arrow functions instead of `function` declarations                                                             |
| `no-unused-vars`                                                                                         | Unused variables; in TypeScript, the TypeScript-aware version, which ignores parameter names of function types |
| `@typescript-eslint/no-explicit-any`                                                                     | A warning on each `any`                                                                                        |
| `sonarjs/no-small-switch`, `sonarjs/no-nested-template-literals`, `sonarjs/prefer-single-boolean-return` | Simpler control flow                                                                                           |

`no-undef` is off: browser and framework globals would otherwise be reported everywhere, and TypeScript already checks undefined names.

## Known limits of the JavaScript formatting

The ESLint configuration fixes style, not every spacing detail. Spaces inside parentheses (`console.log( x )`), around `+`, and around `:` in type annotations are left as written, and JSX attribute quotes (`className='card'`) are not converted, since the `quotes` rule does not apply to JSX. A file ESLint cannot parse is left untouched and the parse error is printed.

In `.jsx` and `.tsx` files, components used only in JSX (`<Button />`) count as used and their imports are kept. A default `import React from "react"` that nothing references is removed as unused: this is correct with the automatic JSX runtime (React 17+, the default in Vite and Next.js), but a project still on the classic runtime needs that import, and should exclude its JSX files or switch runtime.
