import { readFileSync, writeFileSync } from "fs"
import * as babelParser from "@babel/parser"

//============================================================//
// Constants
//============================================================//
const BORDER_LINE      = "//" + "=".repeat(60) + "//"
const INSIDE_SEPARATOR = "// ---------"

//============================================================//
// Main function
//============================================================//
const normalizeComments = (filePath) => {
  const code  = readFileSync(filePath, "utf-8")
  const lines = code.split("\n")

  //============================================================//
  // Parse the code with babel to get comment positions
  //============================================================//
  const ast = babelParser.parse(code, {
    sourceType: "module",
    plugins:    ["typescript", "jsx"]
  })

  //============================================================//
  // Get all comments from the AST
  //============================================================//
  const comments = ast.comments || []

  //============================================================//
  // Group consecutive standalone line comments
  //============================================================//
  const commentBlocks = groupConsecutiveComments(comments, lines)

  //============================================================//
  // Process blocks in reverse order to avoid line number shifts
  //============================================================//
  const blocksReversed = [...commentBlocks].reverse()
  let hasChanges = false

  blocksReversed.forEach((block) => {
    const normalized = normalizeCommentBlock(block, lines)
    if (normalized) {
      const startLine = block[0].loc.start.line - 1
      const endLine   = block[block.length - 1].loc.start.line - 1

      //============================================================//
      // Replace the lines in the original array
      //============================================================//
      lines.splice(startLine, endLine - startLine + 1, ...normalized)
      hasChanges = true
    }
  })

  //============================================================//
  // Only write if there were changes
  //============================================================//
  if (hasChanges) {
    writeFileSync(filePath, lines.join("\n"))
  }
}

//============================================================//
// Group consecutive line comments together
// Only includes standalone comments (not end-of-line comments)
//============================================================//
const groupConsecutiveComments = (comments, originalLines) => {
  const blocks     = []
  let currentBlock = []
  let lastLine     = -2

  comments.forEach((comment) => {
    //============================================================//
    // Only process line comments (// style), not block comments
    //============================================================//
    if (comment.type !== "CommentLine") {
      if (currentBlock.length > 0) {
        blocks.push(currentBlock)
        currentBlock = []
      }
      lastLine = -2
      return
    }

    //============================================================//
    // Skip triple-slash comments (/// for TypeScript docs)
    //============================================================//
    if (comment.value.startsWith("/")) {
      if (currentBlock.length > 0) {
        blocks.push(currentBlock)
        currentBlock = []
      }
      lastLine = -2
      return
    }

    //============================================================//
    // Skip Sprockets directives (//= link, //= require, etc.)
    // These start with "= " followed by a directive keyword
    //============================================================//
    if (/^=\s*\w/.test(comment.value)) {
      if (currentBlock.length > 0) {
        blocks.push(currentBlock)
        currentBlock = []
      }
      lastLine = -2
      return
    }

    //============================================================//
    // Check if this is a standalone comment (line starts with //)
    // Skip end-of-line comments (e.g., const x = 1 // comment)
    //============================================================//
    const lineContent = originalLines[comment.loc.start.line - 1]
    const isStandalone = lineContent.trim().startsWith("//")

    if (!isStandalone) {
      if (currentBlock.length > 0) {
        blocks.push(currentBlock)
        currentBlock = []
      }
      lastLine = -2
      return
    }

    const currentLine = comment.loc.start.line

    if (currentLine === lastLine + 1) {
      currentBlock.push(comment)
    } else {
      if (currentBlock.length > 0) {
        blocks.push(currentBlock)
      }
      currentBlock = [comment]
    }
    lastLine = currentLine
  })

  if (currentBlock.length > 0) {
    blocks.push(currentBlock)
  }

  return blocks
}

//============================================================//
// Normalize a block of comments
// Returns an array of new lines, or null if no change needed
//============================================================//
const normalizeCommentBlock = (block, originalLines) => {
  if (block.length === 0) return null

  //============================================================//
  // Get the indentation from the first comment
  //============================================================//
  const firstLine = originalLines[block[0].loc.start.line - 1]
  const indent    = firstLine.match(/^(\s*)/)[1]

  //============================================================//
  // Extract the text content from each comment (skip borders)
  //============================================================//
  const bodyLines            = []
  let firstLineWithTextFound = false

  block.forEach((comment) => {
    const text        = comment.value.trim()
    const hasAlphaNum = /[\p{L}0-9]/u.test(text)

    if (isBorderLine(text)) {
      return
    } else if (isSeparatorLine(text)) {
      if (firstLineWithTextFound) {
        bodyLines.push(INSIDE_SEPARATOR)
      }
    } else if (hasAlphaNum) {
      firstLineWithTextFound = true
      bodyLines.push("// " + cleanedLine(text))
    } else if (firstLineWithTextFound && text === "") {
      bodyLines.push("//")
    }
  })

  //============================================================//
  // If block is empty, add a placeholder
  //============================================================//
  if (bodyLines.length === 0) {
    bodyLines.push("// ...")
  }

  //============================================================//
  // Build the new lines with borders
  //============================================================//
  const result = []
  result.push(indent + BORDER_LINE)
  bodyLines.forEach((line) => {
    result.push(indent + line)
  })
  result.push(indent + BORDER_LINE)

  //============================================================//
  // Compare with existing - skip if already correctly formatted
  //============================================================//
  const startLine     = block[0].loc.start.line - 1
  const endLine       = block[block.length - 1].loc.start.line - 1
  const existingLines = originalLines.slice(startLine, endLine + 1)

  //============================================================//
  // Check if existing lines match the result exactly
  //============================================================//
  if (existingLines.length === result.length && existingLines.every((line, i) => line === result[i])) {
    return null
  }

  return result
}

//============================================================//
// Check if a line is a border (long line of = or #)
//============================================================//
const isBorderLine = (text) => {
  const cleaned    = text.replace(/[/=\-\s#]/g, "")
  const hasEquals  = text.includes("=")
  const longEnough = text.length > 20

  return cleaned === "" && hasEquals && longEnough
}

//============================================================//
// Check if a line is an internal separator (---------)
//============================================================//
const isSeparatorLine = (text) => {
  const cleaned = text.replace(/[-\s]/g, "")
  return cleaned === "" && text.length >= 5
}

//============================================================//
// Clean a comment line
//============================================================//
const cleanedLine = (text) => {
  //============================================================//
  // Preserve lines with | (markdown tables)
  //============================================================//
  if (text.startsWith("|")) {
    return text
  }

  //============================================================//
  // Remove leading special characters and normalize
  //============================================================//
  return text.replace(/^[/=\s]*(?=[\p{L}0-9])/u, "").trim()
}

//============================================================//
// Run the script
//============================================================//
const filePath = process.argv[2]

if (!filePath) {
  console.error("Usage: bun normalize-comments.mjs <file>")
  process.exit(1)
}

normalizeComments(filePath)
