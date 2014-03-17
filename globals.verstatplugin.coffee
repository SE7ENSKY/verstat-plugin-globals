module.exports = (next) ->
	@config.globals = "globals" unless Object.hasOwnProperty.call @config, 'globals'

	fs = require 'fs'
	readfile = (srcFilename) => fs.readFileSync @queryFile(srcFilename: srcFilename).srcFilePath, encoding: "utf8"
	
	fetchGlobalsDepends = (file) =>
		dependsOnFiles = []
		return dependsOnFiles unless @config.globals
		globalsPaths = if typeof @config.globals is 'string' then [@config.globals] else @config.globals
		for p in globalsPaths
			files = @queryFiles
				id: $ne: file.id
				srcExtname: file.srcExtname
				dir: p
			dependsOnFiles = dependsOnFiles.concat files if files
			files = @queryFiles
				id: $ne: file.id
				srcExtname: file.srcExtname
				dir: $startsWith: p + "/"
			dependsOnFiles = dependsOnFiles.concat files if files
		dependsOnFiles

	@on "render:stylus", (file, stylus) =>
		dependsOnFiles = fetchGlobalsDepends file
		stylus.import f.fullname for f in dependsOnFiles
		@depends file, dependsOnFiles

	@on "readFile", (file) =>
		if file.srcExtname is ".jade"
			dependsOnFiles = fetchGlobalsDepends file
			for f in dependsOnFiles
				file.source = readfile(f.srcFilename) + "\n\n" + file.source
			file.source = file.source.replace ///\t///g, '  '
			@depends file, dependsOnFiles

	next()