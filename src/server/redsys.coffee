sharejs = require("share").server;
projects = {};
hat = require("hat");
async = require("async");
S = require("string");

agentToProject = {};
model = null

handle_redsys = (agent, msg) ->
	action = msg.action

	if (action == "setProject")
		return if not projects[msg.project_id]?
		console.log(agent.sessionId, "assigned to ", msg.project_id);
		agentToProject[agent.headers.cookie] = { project: msg.project_id, vfs: projects[msg.project_id] };

updateIfNecessary = (docName, initValueCallback, callback) ->
	console.log("----", docName);
	async.waterfall [
		(callback) -> model.getSnapshot(docName, callback);
		(doc, callback) -> console.log("doc=", doc); initValueCallback(callback);
		(doc, callback) -> model.applyOp(docName, {p:0, i: doc}, callback());
		(v, callback) -> console.log("v=",v); callback();
	], (err) ->
		console.log(err);


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
					callback(file);
					)
		], callback
		

	if action.type in ["create"]
		console.log("creating..")
		async.waterfall [
			(callback) -> valid_file(docName, vfs, callback)
			(stat, callback) -> action.accept(); callback();
			(callback) -> console.log("test2");updateIfNecessary(action.docName, readFile, callback);
			(callback) ->  callback();
		], (err) ->
			action.reject() if err;
		return

	if action.type in ["update", "read"]
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
	sharejs.attach(app, options);

exports.createProject = (vfs, project_id = hat()) ->
	projects[project_id] = vfs
	console.log("project "+project_id+" was generated");

