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
	connection = null

	redsys.getConnection = (callback) ->
		return callback(null, connection) if connection != null
		connection = new sharejs.Connection(redsys.url)
		retry = 5
		retryFunc = () ->
			return callback("Connection to server failed") if retry == 0;
			return callback(null, connection) if connection.id?
			retry--;
			setTimeout(retryFunc, 200);

		setTimeout(retryFunc, 200);

	redsys.call = (action, data, callback) ->
		async.waterfall [
			(callback) -> redsys.getConnection(callback)
			(conn, callback) -> 
				data.client = connection.id
				$.ajax(
					url: "/"+action,
					type: "POST",
					data: data,
				).done((data) ->
					result = JSON.parse(data);
					if (result.status == "ok")
						callback(null);
					else
						callback(result.message);
				)
		], callback

	redsys.setProject = (project, callback) ->
		async.waterfall [
			(callback) -> redsys.call  "setProject", { project_id : project }, callback,
			(callback) -> redsys.project = project; callback()
		], callback;
	redsys