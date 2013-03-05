default_text_format = "etherpad";

sharejs = require("share").server;
Changeset = require("share").types.etherpad.Changeset;
AttributePool = require("share").types.etherpad.AttributePool;
projects = {};
hat = require("hat");
async = require("async");
S = require("string");
stream = require "stream"

created = {};

agentToProject = {};
model = null

valid_file = (fileName, vfs, callback) ->
	vfs.stat(fileName, {}, callback);

handle_setProject = (req, res) ->
	msg = req.body;
	return res.send(JSON.stringify({status:"error", message:"Project not found" })) if not projects[msg.project_id]?;
	console.log("registering "+msg.client+" to project "+msg.project_id);
	agentToProject[msg.client] = { project: msg.project_id, vfs: projects[msg.project_id] };
	res.send JSON.stringify({status:"ok"});

handle_saveFile = (req, res) ->
	msg = req.body;
	return res.send(JSON.stringify({status:"error", message:"No file given" })) if not msg.file?;

	projectData  = agentToProject[msg.client];
	return res.send(JSON.stringify({status:"error", message:"No project opened." })) if not projectData?;

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
		return res.send JSON.stringify({status:"error", message: err}) if err?;
		res.send JSON.stringify({status:"ok"}); 
			

updateIfNecessary = (docName, initValueCallback, callback) ->
	async.waterfall [
		(callback) -> console.log("creating", docName); model.create(docName, default_text_format, {}, callback);
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
	console.log("session id=", agent.sessionId, "action=",action.name);

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
	app.post '/setProject', handle_setProject;	
	app.post '/saveFile', handle_saveFile;	

	options.auth = auth
	model = sharejs.createModel(options) if not model?
	sharejs.attach(app, options, model);

exports.createProject = (vfs, project_id = hat()) ->
	projects[project_id] = vfs
	console.log("project "+project_id+" was generated");

