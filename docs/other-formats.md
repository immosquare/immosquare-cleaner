---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# CSS, YAML, JSON and other formats

Besides its dedicated processors, immosquare-cleaner formats stylesheets, YAML, Vue, GraphQL and Handlebars files with Prettier, and JSON files with a built-in formatter. This page covers the Prettier configuration, the JSON layout, and what happens to a file no formatter claims.

## Files formatted by Prettier

Prettier formats every file that no dedicated processor claims. In a repository clean, only the extensions Prettier knows out of the box are sent to it: `.css`, `.scss`, `.less`, `.yml`, `.yaml`, `.vue`, `.graphql`, `.gql`, `.hbs` and `.handlebars`. A `.yml` file inside a `locales` folder is the exception: it is a translation file, formatted by immosquare-yaml (see [Ruby, ERB and YAML locales](ruby-erb.md)).

Prettier runs with the shared configuration [`linters/prettier.yml`](../linters/prettier.yml):

| Option          | Value      | Effect                                                         |
| --------------- | ---------- | -------------------------------------------------------------- |
| `printWidth`    | `10000`    | Lines are never wrapped                                        |
| `tabWidth`      | `2`        | 2-space indentation, no tabs                                   |
| `semi`          | `false`    | No semicolons in embedded scripts                              |
| `singleQuote`   | `false`    | Double quotes                                                  |
| `trailingComma` | `"none"`   | No trailing commas                                             |
| `arrowParens`   | `"always"` | Parentheses around arrow function parameters                   |
| `endOfLine`     | `"lf"`     | Unix line endings                                              |

A stylesheet and a YAML file before and after:

```diff
-.card{color:red;padding:0 4px}
-.card .title{font-weight:bold;margin:0}
+.card {
+  color: red;
+  padding: 0 4px;
+}
+.card .title {
+  font-weight: bold;
+  margin: 0;
+}
```

```diff
 services:
-    web:
-        image: 'nginx:latest'
-        ports: [ "80:80" ]
+  web:
+    image: "nginx:latest"
+    ports: ["80:80"]
```

## JSON files: built-in formatter with aligned values

`.json` files are parsed and rewritten by a built-in formatter rather than Prettier: 2-space indentation, and the values of each object aligned on one column. Keys keep their order. A file that is not valid JSON raises a parse error and is left untouched.

```diff
-{"name":"demo","version":"1.0.0","scripts":{"build":"vite build","test":"vitest"}}
+{
+  "name":    "demo",
+  "version": "1.0.0",
+  "scripts": {
+    "build": "vite build",
+    "test":  "vitest"
+  }
+}
```

## Files no formatter claims

When a single file is given on the command line, any extension without a dedicated processor falls back to Prettier, which formats it if it recognizes the language and prints an error otherwise. A repository clean and the agent hook are stricter: they only send a file to Prettier when its extension is in the list above, so `LICENSE`, `.env`, images, lock files and other unknown files are never touched.
