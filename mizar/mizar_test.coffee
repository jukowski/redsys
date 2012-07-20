# :tabSize=4:indentSize=4:
execSync = require('execSync');
user = execSync.stdout('echo $USER');

temp = require("temp")
fs   = require('fs')

text = ":: Numerals - Requirements\n::  by Library Committee\n::\n:: Received February 27, 2003\n:: Copyright (c) 2003 Association of Mizar Users\n\nenviron\n\n vocabularies ORDINAL2, BOOLE;\n notations XBOOLE_0, SUBSET_1, ORDINAL1;\n constructors SUBSET_1, ORDINAL1;\n requirements BOOLE;\n theorems SUBSET_1, ORDINAL1;\n\nbegin\n\n:: This file contains statements which are obvious for Mizar checker if\n:: \"requirements NUMERALS\" is included in the environment description\n:: of an article. They are published for testing purposes only.\n:: Users should use appropriate requirements instead of referencing\n:: to these theorems.\n:: Some of these items need also other requirements for proper work.\n:: Statements which cannot be expressed in Mizar language are commented out.\n\ntheorem  :: \"requirements SUBSET\" needed\n  {} is Element of omega\nproof\n  {} in omega by ORDINAL1:def 12;\n  hence thesis by SUBSET_1:def 2;\nend;\n\n::theorem \n::  numeral(X) implies X is Element of omega; \n::theorem \n::  numeral(X) implies succ(X) = X + 1; \n";

compile = (code, callback) ->
	temp.mkdir('pdfcreator', (err, dirPath) ->
		fs.writeFile(dirPath+"/text.miz", text, (err) ->
			execSync.stdout('export MIZFILES=/usr/local/share/mizar; cd '+dirPath+";accom text.miz");
			execSync.stdout('export MIZFILES=/usr/local/share/mizar; cd '+dirPath+";wsmparser text.miz");
			fs.readFile(dirPath+"/text.wsx", "utf8", (err, data) ->
				if err
					console.log(err);
				callback(data)
			);
			execSync.stdout('cd '+dirPath+"; rm *");
		)
	)

compile text, (result) ->
	console.log(result)
