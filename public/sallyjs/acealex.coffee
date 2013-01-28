AceAlexTextAdaptor = (sallyInstance, aceInstance) ->
	aceInstance.on("click", (ev)->
		_range = new sally.RangeSelection
		_range.startRow = _range.startCol = _range.endRow = _range.endCol = 1;
		_pos = new sally.ScreenCoordinates
		_pos.x = ev.x; _pos.y = ev.y;
		msg = new sally.AlexClick;
		msg.Sheet = "blah";
		msg.range = _range;
		msg.position = _pos;
		msg.fileName = "blah";
		sallyInstance.sendMessage("/service/alex/selectRange", msg);
		)

if window.Sally?
	window.Sally.aceAlexTextAdaptor = AceAlexTextAdaptor