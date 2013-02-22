rewire = require "rewire"
redsys = rewire "./redsys.coffee"

options =
  db: {type: 'none'},
  browserChannel: null,

mockApp = {
	on: () ->
	use: () ->
	};

redsys.attach(mockApp, options);

vfs = 
	stat : (file, opt, callback) -> callback("not found" if not file in ["test1.tex", "test2.txt"]);
	read : (file, opt, callback) -> callback("not found" if not file in ["test1.tex", "test2.txt"]);

redsys.createProject(vfs, "testproject");

agent1 = { headers: { cookie : "abc1" } }
agent2 = { headers: { cookie : "abc2" } }


doc1 = 
	docName : "testproject/test1.tex",
	type: "read"

docred = 
	docName : "__REDSYS__",
	op : [
		{ i: JSON.stringify( { action: "setProject", project_id: "testproject"} ) }
	]
	accept: () ->
	reject: () -> 

options.auth agent2, docred

exports.test_open_without_project = (test)->
	doc1.accept = () -> test.ok(false, "false");
	doc1.reject = () -> test.ok(true, "true");
	options.auth agent1, doc1
	test.done();

exports.test_open_with_project = (test)->
	doc1.accept = () -> test.ok(true, "true");
	doc1.reject = () -> test.ok(false, "false");
	options.auth agent2, doc1
	test.done();