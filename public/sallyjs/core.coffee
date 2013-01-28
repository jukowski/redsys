loadFnc = (callback) ->
	() ->
		callback();


class Sally
	constructor: (@sally_url = "http://localhost:8080/sally", @debug = true) ->

	d: (msg) ->
		$("#TheoDebug").append("<pre>"+msg.toString()+"</pre>");

	sendMessage: (channel, msg) ->
		$.cometd.publish(channel, serialize(msg));

	createAlex: (callback) ->
		_this = @;
		whoami = new sally.WhoAmI;
		whoami.clientType = sally.WhoAmI.ClientType.Alex;
		whoami.environmentType = sally.WhoAmI.EnvironmentType.Web;
		whoami.documentType = sally.WhoAmI.DocType.Text;
		$.cometd.publish('/service/alex/register', serialize(whoami));
		callback();

	createNewWindow: (url, cookie, position) ->
		console.log(position);
		t = $("<div>").html("<iframe width='100%' height='100%' src=\""+url+"\"></iframe>");
		t.dialog({"position": [position.x, position.y], "height": 300});


	createTheo: (callback) ->
		_this = @;
		whoami = new sally.WhoAmI;
		whoami.clientType = sally.WhoAmI.ClientType.Theo;
		whoami.environmentType = sally.WhoAmI.EnvironmentType.Web;
		whoami.documentType = sally.WhoAmI.DocType.Text;

		$.cometd.subscribe('/service/theo/init', (msg) ->
			);

		$.cometd.subscribe('/service/theo/newWindow', (msg) ->
			msg = unserialize(msg.data.type, msg.data.s)
			_this.d("Should create new window "+msg);
			_this.createNewWindow(msg.url, msg.cookie, msg.position);
			);

		$.cometd.publish('/service/theo/register', serialize(whoami));

		@theoDialog = $("<div>").attr("id","TheoDebug").html("<pre>Theo Connection Window\n-----------------------</pre>");
		@theoDialog.dialog({position: "right bottom", title: "Theo Connection"}) if @debug;
		callback();

	_onConnect: (handshake) ->
		if (!handshake.successful) 
			return;
		whoami = new sally.WhoAmI;
		whoami.clientType = sally.WhoAmI.ClientType.Alex;
		whoami.environmentType = sally.WhoAmI.EnvironmentType.Desktop;
		whoami.documentType = sally.WhoAmI.DocType.Spreadsheet;
		$.cometd.publish('/service/alex/register', serialize(whoami));

	initConnection: (success_callback) ->
		url = @sally_url;
		_this = @;
		async.waterfall([
			(callback) -> $.getScript(url+"/jquery/json2.js").done(loadFnc(callback));
			(callback) -> $.getScript(url+"/org/cometd.js").done(loadFnc(callback));
			(callback) -> $.getScript(url+"/jquery/jquery.cometd.js").done(loadFnc(callback));
			(callback) -> $.getScript(url+"/comm/protobuf.js").done(loadFnc(callback));
			(callback) -> $.getScript(url+"/comm/common.js").done(loadFnc(callback));
			(callback) -> $.getScript(url+"/comm/util.js").done(loadFnc(callback));
			(callback) ->
				$.cometd.configure(
					url: url+"/cometd",
					logLevel: 'info'
				);

				$.cometd.addListener('/meta/handshake', (handshake) ->
					success_callback() if handshake.successful;
				);
				$.cometd.handshake();
				callback();
		], (err) ->
			success_callback(err) if err?
			);

	init: () ->
		_this = @;
		async.waterfall([
			(callback)-> _this.initConnection(callback)
			(callback)-> _this.createTheo(callback);
			(callback)-> _this.createAlex(callback);
		]);

if window?
	window.Sally = Sally