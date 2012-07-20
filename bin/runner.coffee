#!/usr/bin/env coffee
# :tabSize=4:indentSize=4:

docName = "test-doc";

require('coffee-script')
etherpad = require('../types/etherpad')
hider = require('./hider.coffee')
transclusion = require('./transclusion.coffee')

Connection = require("../client/connection").Connection

conn = new Connection("http://localhost:8000/channel") 
Doc = null

services = [hider, transclusion];

newChange = (op, oldSnapshot) ->
	op = etherpad.tryDeserializeOp(op)
	for service in services
		# this is incorrect :( one needs to change the 
		service.onChange(Doc, op, oldSnapshot)

conn.open docName, "etherpad", (error, doc) ->
	if (error)
		console.log error
	else
		Doc = doc
		Doc.snapshot = etherpad.tryDeserializeSnapshot(Doc.snapshot)

		for service in services
			service.onInit(Doc, conn.id)
		Doc.on("remoteop", newChange);
		Doc.on("error", (x) -> console.log("Error:",x))
		Doc.on("forward", (evt) ->
			for service in services
				if evt.param.service[0] == service.getServiceURI()
					service.onEvent(Doc, evt.event, evt))
