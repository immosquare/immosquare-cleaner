//============================================================//
// ESLint 10 compatibility shim for unmaintained plugins.
//
// Context: we rely on two npm plugins to enforce our JS style
// (see rules/javascript.md — alignment of assignments and
// imports is mandatory):
// - eslint-plugin-align-assignments (last release: 2019)
// - eslint-plugin-align-import      (last release: 2020)
//
// Both plugins call `context.getSourceCode()` inside their
// rule `create()`. ESLint 10 removed that method: the source
// code is now exposed as the `context.sourceCode` property.
// Loading either plugin as-is throws:
// TypeError: context.getSourceCode is not a function
//
// Since neither plugin is maintained and no drop-in
// replacement exists (Prettier/Biome don't align `=`), we wrap
// each rule with a Proxy that re-injects `getSourceCode()` on
// the context before delegating to the original `create()`.
// The upstream packages stay untouched — when a maintained
// alternative surfaces, delete this file and import directly.
//============================================================//
import alignAssignmentsPlugin from "eslint-plugin-align-assignments"
import alignImportPlugin      from "eslint-plugin-align-import"


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
    "align-assignments": withLegacyContext(alignAssignmentsPlugin.rules["align-assignments"])
  }
}

export const alignImport = {
  rules: {
    "align-import": withLegacyContext(alignImportPlugin.rules["align-import"]),
    "trim-import":  withLegacyContext(alignImportPlugin.rules["trim-import"])
  }
}
