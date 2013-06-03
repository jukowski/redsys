define (require) ->
	require "channel/bcsocket"
	require "share/AttributePool"
	require "share/Changeset"
	require "share/share.uncompressed" 
	async = require "lib/async"

	redsys = {};
	redsys.project = "";
	redsys.doc = null;
#	redsys.root = require.toUrl(""); 
#	redsys.url = require.toUrl("channel");
	redsys.root = "http://localhost:8002"; 
	redsys.url = "http://localhost:8002/channel";
	connection = null

	redsys.getConnection = (callback) ->
		return callback(null, connection) if connection != null
		connection = new sharejs.Connection(redsys.url)
		retry = 5
		retryFunc = () ->
			console.log(connection);
			return callback("Connection to server failed") if retry == 0;
			return callback(null, connection) if connection.id?
			retry--;
			setTimeout(retryFunc, 200);

		setTimeout(retryFunc, 200);

	redsys.call = (action, data, callback, method="POST") ->
		async.waterfall [
			(callback) -> redsys.getConnection(callback)
			(conn, callback) -> 
				console.log("conn = "+conn);
				data.client = connection.id
				$.ajax(
					url: redsys.root+action,
					type: method,
					data: data,
					dataType: "json"
				).done((data) ->
					result = JSON.parse(data);
					if (result.status == "ok")
						callback(null);
					else
						callback(result.message);
				)
		], callback

	redsys.getList = (path, callback) ->
		async.waterfall [
			(callback) -> redsys.call  "list", { path : path }, callback, "GET"
			(data, callback) ->
				console.log(data);
				callback();
		], callback;


	redsys.setProject = (project, callback) ->
		async.waterfall [
			(callback) -> redsys.call  "setProject", { project_id : project }, callback,
			(callback) -> redsys.project = project; callback()
		], callback;
	redsys