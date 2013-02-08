AceAlexTextAdaptor = (sallyInstance, aceInstance) ->
	aceInstance.on("click", (ev)->
		_pos = new sally.ScreenCoordinates
		_pos.x = ev.x; _pos.y = ev.y;
		msg = new sally.TextDocClick;
		msg.line = 0;
		msg.col = 2;
		msg.position = _pos;
		msg.fileName = "blah";
		sallyInstance.sendMessage("/service/alex/rightclick", msg);
		)

if window.Sally?
	window.Sally.aceAlexTextAdaptor = AceAlexTextAdaptor