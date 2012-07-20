#!/usr/bin/env coffee
# :tabSize=4:indentSize=4:

Changeset = require('../../webclient/Changeset')
AttributePool = require('../../webclient/AttributePool')
etherpad = require('../types/etherpad')
http = require("http");
https = require("https");
temp = require("temp")
fs   = require('fs')
execSync = require('execSync');
async = require('async')

message = {};
connid = "";

exports.initMessages = () ->
	fs.readFile("mizar.msg", "utf8", (err, data) ->
		data.replace(/\# (\d*)[^\n]*\n([^\n]*)/g, (match...) ->
			message[match[1]]=match[2];
		);
	)

exports.compile = (text, callback) ->
	dirPath = "";
	type = "";
	data = "";
	
	async.waterfall([
		# try create a temp directory
		(callback) -> temp.mkdir('mizar', callback),
		(_dirPath, callback) -> 
			dirPath = _dirPath;
			fs.writeFile(dirPath+"/text.miz", text, callback)
		,
		(callback) ->
			execSync.stdout('export MIZFILES=/usr/local/share/mizar; cd '+dirPath+";accom text.miz");
			fs.stat(dirPath+"/text.err", callback)
		,
		(stats, callback) ->
			if stats.size > 0
				type = "syntax"
				fs.readFile(dirPath+"/text.err", "utf8", callback)
			else
				type = "parse"
				execSync.stdout('export MIZFILES=/usr/local/share/mizar; cd '+dirPath+";wsmparser text.miz");
				fs.readFile(dirPath+"/text.wsx", "utf8", callback)
		,
		(_data, callback) ->
			data = _data
			#execSync.stdout('cd '+dirPath+";rm *");
			callback();
	], (err, result) ->
		callback(err, type, data)		
	);

exports.getServiceURI = () -> "mizar_syntax";

exports.parseErrors = (errFileData) ->
	errors = [];
	for errorLine in errFileData.split("\n")
		[line, col, code] = errorLine.split(" ")
		if (typeof code == "undefined")
			continue;
		errors.push({line:parseInt(line), col:parseInt(col), message:message[code]});
	return errors

# obviously very efficient :)
exports.getOffsetFromLineCol = (text, line, col) ->
	offset = 0; line--
	for cLine,i in text.split("\n")
		if (i<line)
			offset += cLine.length+1
			continue;
		offset += col
		break
	return offset

exports.highlight = (doc, text) ->
	if text.length < 10
		return
	exports.compile(text, (err, type, data) ->
		# there is syntax error
		pool = new AttributePool()
		if type == "syntax"
			errors = exports.parseErrors(data)
		errors ?={}
		builder = Changeset.builder(text.length)
		lastOffset = 0
		clear = [["range.start",""],["range.end",""],["error",""]];
		for error in errors
			console.log(error)
			offset = exports.getOffsetFromLineCol(text, error.line, error.col)
			beginOffset = Math.max(offset-1,0)
			while beginOffset>0 && text[beginOffset].match("[a-zA-Z_0-9]")
				beginOffset--
			beginOffset+=2
			txt = error.message
			if beginOffset < offset
				builder.keep(beginOffset-lastOffset-1, 0, clear, pool)
				builder.keep(1, 0, [["range.start",1],["error", true], ["error_msg", txt], ["leftClick",connid]], pool)
				builder.keep(offset-beginOffset-1, 0, clear, pool)
				builder.keep(1, 0, [["range.end",1],["error", true], ["error_msg", txt], ["leftClick",connid]], pool)
			else
				builder.keep(Math.max(beginOffset-lastOffset-1,0), 0, clear, pool)
				builder.keep(1, 0, [["range.start",1],["range.end",1],["error", true], ["error_msg", txt], ["leftClick",connid]], pool)
			lastOffset = offset
		result = {};
		result.pool = pool;
		result.changeset = builder.toString();
		doc.submitOp(result)
	)
	

exports.onInit = (doc, id) ->
	connid = id+"."+exports.getServiceURI();
	exports.highlight(doc, doc.snapshot.text);
	
exports.errorFinder = (doc, tOffset) ->
	labelBegin = doc.snapshot.pool.putAttrib(["range.start",1], true)
	labelEnd = doc.snapshot.pool.putAttrib(["range.end",1], true)
	labelExpand = doc.snapshot.pool.putAttrib(["label.expand",1], true)
	iter = Changeset.opIterator(doc.snapshot.attribs)
	offset = 0;
	inRange = false;
	rangeStarted = rangeEnded = -1;
	rangeStartOp = rangeEndOp = null
	pool = doc.snapshot.pool
	while iter.hasNext()
		o = iter.next()
		# nothing to toggle
		if offset >= tOffset && inRange == false
			console.log("nothing to toggle");
			return
		if (o.attribs.match("\\*"+labelBegin))
			rangeStarted = offset
			rangeStartOp = o.attribs
			inRange = true
		if (o.attribs.match("\\*"+labelEnd))
			if (offset >= tOffset)
				rangeEnded = offset + o.chars
				rangeEndOp = o.attribs
				break
			rangeStarted = -1
			inRange = false
		offset += o.chars
	
	expanded = false
	msg = "";
	Changeset.eachAttribNumber(rangeStartOp, (x) ->
		attrib = pool.getAttrib(x)
		if attrib[0]=="error_msg"
			msg = attrib[1]
		)
	return msg
	
exports.onEvent = (doc, name, evt) ->
	console.log(name, evt)
	if name=="leftClick"
		console.log("searcgubg ", evt);
		msg = exports.errorFinder(doc, evt.param.offset)
	
exports.onChange = (doc, op, oldSnapshot) ->
	exports.highlight(doc, doc.snapshot.text);
		
exports.initMessages()

initText = ':: Numerals - Requirements\n::  by Library Committee\n::\n:: Received February 27, 2003\n:: Copyright (c) 2003 Association of Mizar Users\n\nenviron\n\n vocabularies ORDINAL2, BOOLE;\n notations XBOOLE_0, SUBSET_1, ORDINAL1;\n constructors SUBSET_1, ORDINAL1;\n requirements BOOLE;\n theorems SUBSET_1, ORDINAL1;\n\nbegin\n\n:: This file contains statements which are obvious for Mizar checker if\n:: \"requirements NUMERALS\" is included in the environment description\n:: of an article. They are published for testing purposes only.\n:: Users should use appropriate requirements instead of referencing\n:: to these theorems.\n:: Some of these items need also other requirements for proper work.\n:: Statements which cannot be expressed in Mizar language are commented out.\n\ntheorem  :: \"requirements SUBSET\" needed\n  {} is Element of omega\nproof\n  {} in omega by ORDINAL1:def 12;\n  hence thesis by SUBSET_1:def 2;\nend;\n\n::theorem \n::  numeral(X) implies X is Element of omega; \n::theorem \n::  numeral(X) implies succ(X) = X + 1; \n';
cs = Changeset.unpack(Changeset.builder(0).insert(initText).toString());
snapshot = { text: cs.charBank, attribs: cs.ops, pool: new AttributePool() }

doc = {};
doc.snapshot = snapshot;
doc.submitOp = (op) ->
	oldSnapshot = doc.snapshot
	doc.snapshot = etherpad.apply(doc.snapshot, op);
#exports.onInit(doc)

