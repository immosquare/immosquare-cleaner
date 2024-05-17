module.exports = (fileInfo, api) => {
  const j    = api.jscodeshift
  const root = j(fileInfo.source)

  // Trouver toutes les expressions de fonction
  const functions = root.find(j.FunctionExpression)

  // Journal détaillé des fonctions trouvées
  functions.forEach((path) => {
    const { id, generator, async } = path.value
    console.log("Function found:", {
      id:  id ? id.name : "anonymous",
      generator,
      async,
      loc: path.value.loc.start
    })
  })

  // Filtrer les fonctions à transformer
  const functionsToTransform = functions.filter((path) => {
    const { id, generator, async } = path.value
    return !id && !generator && !async
  })

  // Log les fonctions à transformer
  console.log("Functions to be transformed:", functionsToTransform.size())

  // Appliquer la transformation
  functionsToTransform.replaceWith((path) => {
    const { params, body, async } = path.value
    return j.arrowFunctionExpression(params, body, async)
  })

  return root.toSource()
}
