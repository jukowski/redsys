proxyquire = require "proxyquire"
async = require "async"
stream = require "stream"

sharejsMock = {}

postMap = {};

mockApp = {
	on: () ->
	use: () ->
	post: (channel, op) -> 
		postMap[channel] = op;

	makePost: (agent, channel, obj, callback) -> 
		str = "";
		obj.client = agent.sessionId
		req = {
			body: obj
		}
		res = {
			send : (msg)  ->
				str = msg;
				callback?(null, str)
		}
		postMap[channel](req, res);
};

redsys = proxyquire "../../src/server/redsys.coffee", { "share" : sharejsMock }

sharejsMock.server.attach = () ->;

options =
  db: {type: 'none'},
  browserChannel: null,

runAuth = (agent, op, doc, callback) ->
	result = null;
	action = 
		name : op
		type : op
		docName : doc
		accept : () -> callback(null, result = "accept")
		reject : () -> callback(null, result = "reject")

	options.auth agent, action

redsys.attach(mockApp, options);

vfs = 
	stat : (file, opt, callback) -> 
		return callback("file not found ") if not file in ["test1.tex", "test2.txt"];
		return callback(null, {msg: "here"} );

	readfile : (file, opt, callback) -> 
		return callback("file cannot be read") if not file in ["test1.tex", "test2.txt"];
		q = new stream.Stream
		callback(null, {stream: q});
		q.emit('data', "some content here")
		q.emit('end')

	mkfile : (file, opt, callback) ->
		return callback("file cannot be written") if not file in ["test1.tex", "test2.txt"];
		callback();


redsys.createProject(vfs, "testproject");

agent1 = { sessionId : "abc1" }
agent2 = { sessionId : "abc2" }

mockApp.makePost(agent2, "/setProject", {project_id: "testproject"});

exports.test_open_without_project = (test)->
	runAuth agent1, "read", "test1.tex", (err, res) -> test.ok(res == "reject"); test.done();

exports.test_open_with_project = (test)->
	runAuth agent2, "read", "test1.tex", (err, res) -> test.ok(res == "accept"); test.done();

exports.test_save_file = (test) ->
	async.waterfall [
		(callback) -> mockApp.makePost(agent2, "/saveFile", {file: "test1.tex" }, callback)
		(data, callback) -> console.log(data); test.ok(data == '{"status":"ok"}'); test.done(); callback();	
	], (err) ->
		if err?
			test.fail(err);
	