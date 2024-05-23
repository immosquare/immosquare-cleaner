module.exports = (fileInfo, api) => {
  const j    = api.jscodeshift
  const root = j(fileInfo.source)

  // Find all function declarations
  const functions = root.find(j.FunctionDeclaration)

  // Log details of the found functions
  functions.forEach((path) => {
    const { id, generator, async, loc } = path.value
    console.log("Function found:", {
      id:  id ? id.name : "anonymous",
      generator,
      async,
      loc: loc.start
    })
  })

  // Filter non-generator, non-async functions
  const functionsToTransform = functions.filter((path) => {
    const { generator, async } = path.value
    return !generator && !async
  })

  // Log the number of functions to be transformed
  console.log("Functions to be transformed:", functionsToTransform.size())

  // Transform to arrow functions and preserve comments
  functionsToTransform.replaceWith((path) => {
    const { id, params, body, async, comments } = path.value
    const arrowFunction                         = j.variableDeclaration("const", [
      j.variableDeclarator(
        j.identifier(id.name),
        j.arrowFunctionExpression(params, body, async)
      )
    ])
    arrowFunction.comments                      = comments
    return arrowFunction
  })

  return root.toSource()
}
