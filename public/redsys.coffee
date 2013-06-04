define (require) ->
	require "channel/bcsocket"
	require "share/AttributePool"
	require "share/Changeset"
	require "share/share.uncompressed" 
	async = require "lib/async"

	redsys = {};
	redsys.project = "";
	redsys.doc = null;
	redsys.root = require.toUrl(""); 
	redsys.url = require.toUrl("channel");
	connection = null
	timeOut = 1000;
	callHash = {};

	extendedMessageHandler = (oldMessageHandler) ->
		return (msg) ->
			return oldMessageHandler(msg) if not msg.msgid?;
			callObj = callHash[msg.msgid]
			return if not callObj?;
			delete callHash[msg.msgid];
			window.clearTimeout(callObj["timeOut"]);
			if (msg.status == "ok")
				callObj["callback"](null, msg.msg);
			else
				callObj["callback"](msg.msg);


	redsys.getConnection = (callback) ->
		return callback(null, connection) if connection != null
		connection = new sharejs.Connection(redsys.url)
		msgHandler = connection.socket.onmessage;
		connection.socket.onmessage = extendedMessageHandler(msgHandler);

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
				msgID = Math.floor(Math.random()*10000000);
				data.client = connection.id;
				actionObj = 
					action: action
					data: data
					msgid : msgID;

				toObject = setTimeout(() ->
					callHash[msgID]["callback"]("Time out");
					delete callHash[msgID];
				, timeOut);

				callHash[msgID] = { "callback" : callback, "timeOut" : toObject };
				conn.send(actionObj);
		], callback

	redsys.getList = (path, callback) ->
		redsys.call "listFiles", { path : path }, callback

	redsys.getServices = (callback) ->
		redsys.call "listServices", { }, callback

	redsys.enableService = (serviceID, file, callback) ->
		redsys.call "enableService", { service: serviceID, file: file }, callback

	redsys.setProject = (project, callback) ->
		async.waterfall [
			(callback) -> redsys.call  "setProject", { project_id : project }, callback,
			(msg, callback) -> redsys.project = project; callback()
		], callback;
	redsys
