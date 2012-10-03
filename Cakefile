{exec} = require 'child_process'
fs = require 'fs'
path = require 'path'

task 'build', 'Generate the api files', (options) ->
	exec "pbj api/api.proto public/api.js", (err, stdout, stderr) ->
		throw err if err
		console.log stdout + stderr

