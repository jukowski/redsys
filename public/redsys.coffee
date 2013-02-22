define (require) ->
	require "/channel/bcsocket.js"
	require "/share/AttributePool.js" 
	require "/share/Changeset.js" 
	require "/share/share.uncompressed.js" 
	async = require "/lib/async.js" 

	redsys = {};
	redsys.project = "";
	redsys.doc = null;
	redsys.url = location.protocol + "//" + location.host + "/channel";

	redsys.getDoc = (callback) ->
		callback(null, @doc) if @doc != null
		connection = new sharejs.Connection(redsys.url)
		connection.open "__REDSYS__", "text", (error, doc) ->
			redsys.doc = doc;
			callback(error, doc);

	redsys.call = (action, callback) ->
		async.waterfall [
			(callback) -> redsys.getDoc(callback),
			(doc, callback) -> doc.insert(0, JSON.stringify(action), (err) ->
					callback();
				); 
		], callback;


	redsys.setProject = (project, callback) ->
		async.waterfall [
			(callback) -> redsys.call { action : "setProject", project_id : project }, callback,
		], callback;
	redsys