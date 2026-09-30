//============================================================//
// ESLint 10 compatibility shim for unmaintained plugins.
//
// Context: alignment of imports is mandatory in our JS style
// (see rules/javascript.md) and relies on
// eslint-plugin-align-import (last release: 2020). Assignment
// alignment uses the local fork in ./align-assignments.mjs.
//
// The plugin calls `context.getSourceCode()` inside its rules'
// `create()`. ESLint 10 removed that method: the source code
// is now exposed as the `context.sourceCode` property.
// Loading it as-is throws:
// TypeError: context.getSourceCode is not a function
//
// Since it is not maintained and no drop-in replacement
// exists, we wrap each rule with a Proxy that re-injects
// `getSourceCode()` on the context before delegating to the
// original `create()`.
// The upstream package stays untouched — when a maintained
// alternative surfaces, delete this file and import directly.
//============================================================//
import alignAssignmentsRule from "./align-assignments.mjs"
import alignImportPlugin    from "eslint-plugin-align-import"


const withLegacyContext = (rule) => ({
  ...rule,
  create: (context) => rule.create(new Proxy(context, {
    get: (target, prop) => (prop === "getSourceCode"
      ? () => target.sourceCode
      : target[prop])
  }))
})

export const alignAssignments = {
  rules: {
    "align-assignments": alignAssignmentsRule
  }
}

export const alignImport = {
  rules: {
    "align-import": withLegacyContext(alignImportPlugin.rules["align-import"]),
    "trim-import":  withLegacyContext(alignImportPlugin.rules["trim-import"])
  }
}
