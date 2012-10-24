{exec} = require 'child_process'
fs = require 'fs'
path = require 'path'

task 'build', 'Generate the api files', (options) ->
	exec "pbj api/api.proto public/api.js", (err, stdout, stderr) ->
		throw err if err
		console.log stdout + stderr
#	exec "protoc --descriptor_set_out=api/api.desc --include_imports api/api.proto", (err, stdout, stderr) ->
#		throw err if err
#		console.log stdout + stderr
	exec "coffee -o public -c stex/transclusion.coffee", (err, stdout, stderr) ->
		throw err if err
		console.log stdout + stderr

