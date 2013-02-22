define((require) ->
	require "/lib/ace/ace.js"
	require "/lib/ace/mode-latex.js"
	require "/lib/ace/theme-idle_fingers.js"
	require "/share/ace.js"

	class Editor
		editor = null

		constructor: (@id) ->

		show: (docName) ->
			docName = docName.replace(/\//, "::");
			editor = ace.edit(@id);
			editor.setReadOnly(true);
			editor.getSession().setUseSoftTabs(true);
			editor.getSession().setTabSize(2);
			editor.getSession().setMode(new (ace.require("ace/mode/latex").Mode));
			editor.setTheme("ace/theme/idle_fingers");

			sharejs.open(docName, 'etherpad', (error, doc) ->
				console.error(error) if error
				doc.attach_ace(editor);
				editor.setReadOnly(false);
			)

	Editor
);