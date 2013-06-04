define((require) ->
	require "share/AttributePool"
	require "share/Changeset"
	require "share/ace"
	async = require "/lib/async.js" 

	class Editor
		editor = null
		editorDoc = null
		redsys = null
		currentDocName = null;
		keyHandler = null;

		constructor: (_redsys) ->
			redsys = _redsys

		addShortcut: (name, shortcut, func) ->
			cmd = {};
			cmd[name] = func;
			keyHandler.addCommands cmd
			keyHandler.bindKey shortcut, name

		save: (callback) ->
			return if not currentDocName?
			redsys.call("saveFile", {file: currentDocName}, callback);

		attach : (docName, editor, callback) ->
			currentDocName = docName;
			async.waterfall [
				(callback) -> redsys.getConnection(callback)
				(conn, callback) ->
					conn.open(docName, 'etherpad', (error, doc) ->
						return if error?;
						editorDoc = doc
						doc.attach_ace(editor);
						editor.setReadOnly(false);
						callback();
					)
			], callback


		open: (id, docName, callback) ->
			editor = ace.edit(id);
			editor.setReadOnly(true);
			editor.getSession().setUseSoftTabs(true);
			editor.getSession().setTabSize(2);
			editor.getSession().setMode(new (ace.require("ace/mode/latex").Mode));
			editor.setTheme("ace/theme/idle_fingers");
			window.keyHandler = keyHandler = ace.require("ace/keyboard/emacs").handler;
			editor.setKeyboardHandler(keyHandler);

			@attach(docName, editor, callback);


		setAttributes : (offset, length, attribs, callback) ->
			editorDoc.type.api.setAttributes.apply(editorDoc, [offset, length, attribs]);

	Editor
);