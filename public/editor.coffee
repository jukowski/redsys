define((require) ->
	require "/lib/ace/ace.js"
	require "/lib/ace/mode-latex.js"
	require "/lib/ace/theme-idle_fingers.js"
	require "/lib/ace/keybinding-emacs.js"
	require "/share/ace.js"
	async = require "/lib/async.js" 

	class Editor
		editor = null
		editorDoc = null
		redsys = null
		currentDocName = null;
		keyHandler = null;

		constructor: (@id, _redsys) ->
			redsys = _redsys

		addShortcut: (name, shortcut, func) ->
			cmd = {};
			cmd[name] = func;
			keyHandler.addCommands cmd
			keyHandler.bindKey shortcut, name

		save: (callback) ->
			return if not currentDocName?
			redsys.call("saveFile", {file: currentDocName}, callback);

		open: (docName, callback) ->
			editor = ace.edit(@id);
			editor.setReadOnly(true);
			editor.getSession().setUseSoftTabs(true);
			editor.getSession().setTabSize(2);
			editor.getSession().setMode(new (ace.require("ace/mode/latex").Mode));
			editor.setTheme("ace/theme/idle_fingers");
			window.keyHandler = keyHandler = ace.require("ace/keyboard/emacs").handler;
			editor.setKeyboardHandler(keyHandler);

			window.editor = editor;
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

		setAttributes : (offset, length, attribs, callback) ->
			editorDoc.type.api.setAttributes.apply(editorDoc, [offset, length, attribs]);

	Editor
);