default_text_format = "etherpad";
express = require('express');
sessionHandler = require('share/src/server/session').handler
sharejs = require('share').server
{EventEmitter} = require 'events'

Changeset = require("share").types.etherpad.Changeset;
AttributePool = require("share").types.etherpad.AttributePool;
projects = {};
hat = require("hat");
async = require("async");
S = require("string");
stream = require "stream"
path = require "path"
serviceManager = require "./service_manager"

browserChannel = require('browserchannel').server

created = {};

agentToProject = {};
model = null

valid_file = (fileName, vfs, callback) ->
	vfs.stat(fileName, {}, callback);

handle_action = (msg, callback) ->
	return handle_setProject(msg.data, callback) if (msg.action == "setProject");
	return handle_listFiles(msg.data, callback) if (msg.action == "listFiles");
	return handle_listServices(msg.data, callback) if (msg.action == "listServices");
	return handle_enableService(msg.data, callback) if (msg.action == "enableService");
	return callback("don't know how to handle "+msg);

handle_listServices = (msg, callback) ->
	projectData  = agentToProject[msg.client];
	return callback("No project opened.") if not projectData?;
	callback null, serviceManager.getAvailableServices()

handle_enableService = (msg, callback) ->
	projectData  = agentToProject[msg.client];
	return callback("No project opened.") if not projectData?;
	return callback("No file specified.") if not msg.file?;
	return callback("No service specified.") if not msg.service?;
	callback null, serviceManager.enableService(model, msg.service, msg.file, projectData.project)

handle_listFiles = (msg, callback) ->
	return callback("No path given" ) if not msg.path?;
	projectData  = agentToProject[msg.client];
	return callback("No project opened.") if not projectData?;
	vfs = projectData.vfs
	async.waterfall [
		(callback) -> vfs.readdir msg.path, {}, (err, meta) ->
			list = meta.stream
			result = [];
			list.on("data", (dir) ->
				result.push(dir) if dir.name?;
				)

			list.on("end", () ->
				callback(null, result);
				)
	], (err, data) ->
		return callback(err) if err?;
		console.log("returning ", data);
		callback(null, data); 


handle_setProject = (msg, callback) ->
	return callback("Project not found") if not projects[msg.project_id]?;
	agentToProject[msg.client] = { project: msg.project_id, vfs: projects[msg.project_id] };
	callback();

handle_saveFile = (msg) ->
	return callback("No file given") if not msg.file?;

	projectData  = agentToProject[msg.client];
	return callback("No project opened.") if not projectData?;

	vfs = projectData.vfs
	async.waterfall [
		(callback) -> valid_file msg.file, vfs, callback
		(stat, callback) -> model.getSnapshot msg.file, callback
		(snapshot, callback) -> 
			text = snapshot.type.api.getText.apply(snapshot); 
			q = new stream.Stream
			q.readable = true
			vfs.mkfile(msg.file, {stream: q}, callback)
			q.emit('data', text)
			q.emit('end')
	], (err) ->
		return callback(err) if err?;
		callback(); 

updateIfNecessary = (docName, initValueCallback, callback) ->
	async.waterfall [
		(callback) -> model.create(docName, default_text_format, {}, callback);
		(callback) -> initValueCallback(callback);
		(doc, callback) ->
			op = {};
			op.pool = new AttributePool();
			op.changeset = Changeset.builder(0).insert(doc, "", op.pool).toString()
			model.applyOp(docName, {"op": op, v:0}, callback)
		(ver, callback) -> callback()
	], callback;

readVFSFile = (vfs, docName, callback)->
	async.waterfall [
		(callback) -> vfs.readfile docName, {}, (err, data) ->
			return callback(err) if err?
			file = ""; 
			data.stream.on("data", (str) ->
				file += str.toString();
				)

			data.stream.on("end", () ->
				callback(null, file);
				)
	], callback

writeVFSFile = (vfs, docName, data, callback)->
	async.waterfall [
		(callback) -> vfs.readfile(docName, {}, callback),
		(data, callback) ->
			file = ""; 
			data.stream.on("data", (str) ->
				file += str.toString();
				)

			data.stream.on("end", () ->
				callback(null, file);
				)
	], callback



auth = (agent, action) ->
	# handling normal actions
	# console.log("session id=", agent.sessionId, "action=",action.name);
	# console.log("handling auth ", agent, action);

	return action.accept() if action.name in ["connect"]

	# the rest of actions require a project
	return action.reject() if not agentToProject[agent.sessionId]?

	projectData = agentToProject[agent.sessionId];
	
	docName = action.docName;
	vfs = projectData.vfs

	readFile = (callback) ->
		readVFSFile(vfs, docName, callback);

	if action.type in ["create", "read"] and not created[docName]?
		async.waterfall [
			(callback) -> valid_file(docName, vfs, callback)
			(stat, callback) -> updateIfNecessary(action.docName, readFile, callback);
			(callback) -> created[docName]=true; action.accept(); callback();
		], (msg, err) ->
			action.reject() if err?;
		return

	if action.type in ["update", "create", "read"]
		valid_file(docName, vfs, (err)->
			return action.reject() if err?;
			action.accept()
		)
		return;

	console.log("What does ", action.type, "mean?");
	return action.reject();

exports.attach = (app, options)->
	options.auth = auth
	model = sharejs.createModel(options) if not model?
	createAgent = require('share/src/server/useragent') model, options

	app.use "/share", express.static path.dirname(require.resolve("share"))+'/webclient';

	app.use browserChannel options.browserChannel, (session) ->
		sessionWrapper = new EventEmitter();

		session.on 'message', (recvMsg) ->
			if (recvMsg.action?)
				handle_action recvMsg, (err, msg) ->
					return session.send({status: "error", msg: msg, msgid: recvMsg.msgid}) if err?
					session.send({status: "ok", msg: msg, msgid: recvMsg.msgid})

			else
				sessionWrapper.emit "message", recvMsg

		session.on 'close', (reason) ->
			sessionWrapper.emit "close", reason

		sessionWrapper.ready = -> @state isnt 'closed'
		sessionWrapper.send = session.send
		sessionWrapper.flush = session.flush
		sessionWrapper.stop = session.stop
		sessionHandler sessionWrapper, createAgent



exports.createProject = (vfs, project_id = hat()) ->
	projects[project_id] = vfs
	console.log("project "+project_id+" was generated");
