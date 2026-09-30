//============================================================//
// Local fork of eslint-plugin-align-assignments (v1.1.2, by
// Lucas Florio, MIT). Upstream is unmaintained since 2019.
//
// Differences with upstream:
// - reads `context.sourceCode` (ESLint 10 removed
// `context.getSourceCode()`);
// - knows the ES2021 logical assignment operators `||=`, `&&=`
// and `??=`. Without them the rule locates the `=` one column
// off, reports the group forever and its autofix never settles
// ("Circular fixes detected").
//============================================================//

//============================================================//
// MIT License
//
// Copyright (c) Lucas Florio <lucasefe@gmail.com>
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall
// be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
// KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
// OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//============================================================//
const hasRequire   = /require\(/
const spaceMatcher = /(\s*)((?:\|\||&&|\?\?|\+|-|\*|\/|%|&|\^|\||<<|>>|\*\*|>>>)?=)/

const assignmentOperators = ["=", "+=", "-=", "*=", "/=", "%=", "&=", "^=", "|=", "<<=", ">>=", "**=", ">>>=", "||=", "&&=", "??="]

const getLast = (ary) => ary[ary.length - 1]

const isAssignmentExpression = (node) => node.type === "AssignmentExpression"

const isMultiline = (firstToken, assignmentToken) => firstToken.loc.start.line !== assignmentToken.loc.start.line

const rule = {
  meta: {
    fixable: "code",
    schema:  [
      {
        type:                 "object",
        properties:           { requiresOnly: { type: "boolean" } },
        additionalProperties: false
      }
    ]
  },

  create: (context) => {
    const { options }    = context
    const requiresOnly   = options && options.length > 0 && options[0].requiresOnly
    const { sourceCode } = context
    const groups         = []
    let previousNode

    const shouldStartNewGroup = (node) => {
      //============================================================//
      // First line of all
      //============================================================//
      if (!previousNode) return true

      //============================================================//
      // Switching parent nodes
      //============================================================//
      if (node.parent !== previousNode.parent) return true

      //============================================================//
      // If previous node was a for and included the declarations,
      // new group
      //============================================================//
      if (previousNode.parent.type === "ForStatement" && previousNode.declarations) return true

      //============================================================//
      // Previous line was blank
      //============================================================//
      const lineOfNode = sourceCode.getFirstToken(node).loc.start.line
      const lineOfPrev = sourceCode.getLastToken(previousNode).loc.start.line
      return lineOfNode - lineOfPrev !== 1
    }

    const addNode = (groupNode, node) => {
      if (shouldStartNewGroup(groupNode)) groups.push([node])
      else getLast(groups).push(node)

      previousNode = groupNode
    }

    const getPrefix = (node) => {
      const nodeBefore = isAssignmentExpression(node) ? node.left : node.declarations.find((dcl) => dcl.type === "VariableDeclarator").id
      return nodeBefore.loc.end.column - nodeBefore.loc.start.column
    }

    const findAssigment = (node) => {
      const prefix = getPrefix(node)
      const source = sourceCode.getText(node)
      const match  = source.slice(prefix).match(spaceMatcher)
      return match ? match.index + prefix + match[2].length : null
    }

    const assignmentOnFirstLine = (node) => {
      if (isAssignmentExpression(node)) return node.left.loc.start.line === node.right.loc.start.line

      const source = sourceCode.getText(node)
      const lines  = source.split("\n")
      return lines[0].includes("=")
    }

    const areAligned = (maxPos, nodes) => nodes
      .filter(assignmentOnFirstLine)
      .map((node) => sourceCode.getText(node))
      .every((source) => source.charAt(maxPos) === "=")

    const getMaxPos = (nodes) => nodes
      .filter(assignmentOnFirstLine)
      .map(findAssigment)
      .reduce((last, current) => Math.max(last, current), [])

    const check = (group) => {
      const maxPos = getMaxPos(group)

      if (areAligned(maxPos, group)) return

      context.report({
        loc: {
          start: group[0].loc.start,
          end:   getLast(group).loc.end
        },
        message: "This group of assignments is not aligned",
        fix:     (fixer) => group.map((node) => {
          const tokens          = sourceCode.getTokens(node)
          const firstToken      = tokens[0]
          const assignmentToken = tokens.find((token) => assignmentOperators.includes(token.value))
          const line            = sourceCode.getText(node)
          const lineIsAligned   = line.charAt(maxPos) === "="

          if (lineIsAligned || !assignmentToken || isMultiline(firstToken, assignmentToken)) return fixer.replaceText(node, line)

          //============================================================//
          // Source line may include spaces, we need to accomodate
          // for that.
          //============================================================//
          const spacePrefix    = firstToken.loc.start.column
          const startDelimiter = assignmentToken.loc.start.column - spacePrefix
          const endDelimiter   = assignmentToken.loc.end.column - spacePrefix
          const start          = line.slice(0, startDelimiter).replace(/\s+$/m, "")
          const ending         = line.slice(endDelimiter).replace(/^\s+/m, "")
          const spacesRequired = maxPos - start.length - assignmentToken.value.length + 1
          const spaces         = " ".repeat(spacesRequired)
          return fixer.replaceText(node, `${start}${spaces}${assignmentToken.value} ${ending}`)
        })
      })
    }

    return {
      VariableDeclaration: (node) => {
        const source = sourceCode.getText(node)
        if (requiresOnly && !hasRequire.test(source)) return

        addNode(node, node)
      },

      ExpressionStatement: (node) => {
        if (node.expression.type !== "AssignmentExpression") return

        addNode(node, node.expression)
      },

      "Program:exit": () => groups.forEach(check)
    }
  }
}

export default rule
