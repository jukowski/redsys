default_text_format = "etherpad";

sharejs = require("share").server;
Changeset = require("share").types.etherpad.Changeset;
AttributePool = require("share").types.etherpad.AttributePool;
projects = {};
hat = require("hat");
async = require("async");
S = require("string");

created = {};

agentToProject = {};
model = null

handle_redsys = (agent, msg) ->
	action = msg.action

	if (action == "setProject")
		return if not projects[msg.project_id]?
		console.log(agent.sessionId, "assigned to ", msg.project_id);
		agentToProject[agent.headers.cookie] = { project: msg.project_id, vfs: projects[msg.project_id] };

updateIfNecessary = (docName, initValueCallback, callback) ->
	async.waterfall [
		(callback) -> model.create(docName, default_text_format, {}, callback);
		(callback) -> initValueCallback(callback);
		(doc, callback) ->
			op = {};
			op.pool = new AttributePool();
			op.changeset = Changeset.builder(0).insert(doc, "", op.pool).toString()
			model.applyOp(docName, {"op": op, v:0}, callback)
	]
	callback();

valid_file = (fileName, vfs, callback) ->
	vfs.stat(fileName, {}, callback);

auth = (agent, action) ->
	# handling META messages for REDSYS
	if action.docName == "__REDSYS__"
		if action.op?
			handle_redsys(agent, JSON.parse(action.op[0].i)); 
			return action.reject();
		else
			return action.accept();

	# handling normal actions

	return action.accept() if action.name in ["connect"]

	# the rest of actions require a project
	return action.reject() if not agentToProject[agent.headers.cookie]?

	projectData = agentToProject[agent.headers.cookie];
	return action.reject() if not S(action.docName).startsWith(projectData.project);
	
	docName = action.docName.replace("::","/")[projectData.project.length..];
	vfs = projectData.vfs

	readFile = (callback)->
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

	if action.type in ["create", "read"] and not created[docName]?
		console.log("creating...");
		async.waterfall [
			(callback) -> valid_file(docName, vfs, callback)
			(stat, callback) -> updateIfNecessary(action.docName, readFile, callback);
			(callback) -> created[docName]=true; action.accept(); callback();
		], (err) ->
			action.reject() if err;
		return

	if action.type in ["update", "create", "read"]
		valid_file(docName, vfs, (err)->
			return action.reject() if err;
			action.accept()
		)
		return;

	console.log("What does ", action.type, "mean?");
	return action.reject();

exports.attach = (app, options)->
	options.auth = auth
	model = sharejs.createModel(options) if not model?
	sharejs.attach(app, options, model);

exports.createProject = (vfs, project_id = hat()) ->
	projects[project_id] = vfs
	console.log("project "+project_id+" was generated");

