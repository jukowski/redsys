#!/usr/bin/env coffee
# :tabSize=4:indentSize=4:

etherpad = require('share').types.etherpad

Changeset = etherpad.Changeset
AttributePool = etherpad.AttributePool
# modes = require('modes')

hideReg = /(\\STR(label|copy)(?:\[([a-zA-Z0-9_-]+)\])?\s*\{)([^}]+)(\})/g;

connid = "";

exports.getServiceURI = () -> "label";

exports.replaceTermrefs = (doc) ->
	text = doc.snapshot.text;
	builder = Changeset.builder(text.length)
	pool = new AttributePool()
	iter = Changeset.opIterator(doc.snapshot.attribs)
	o = iter.next() unless !iter.hasNext()
	changed = false
	last = 0
	offset = 0
	exp = "\\*"+Changeset.numToString(doc.snapshot.pool.putAttrib(["label.expanded",1], true));
	map = {}

	text.replace(hideReg, (match...) ->
		changed = true
		console.log match
		idx = match[6]
		if (o)
			while offset + o.chars <= idx && iter.hasNext()
				offset += o.chars
				o = iter.next()
				# should touch expanded label
				if (o.attribs.match(exp))
					console.log("will not touch expanded termref");
					return match[0];

		if (match[2]=="label")
			map[match[3]]=match[4];
		
			i1 = "*"+Changeset.numToString(pool.putAttrib(["range.prefix",match[1]]))
			i2 = "*"+Changeset.numToString(pool.putAttrib(["range.suffix",match[5]]))
			i3 = "*"+Changeset.numToString(pool.putAttrib(["range.start",1]))
			i4 = "*"+Changeset.numToString(pool.putAttrib(["range.end",1]))
			i5 = "*"+Changeset.numToString(pool.putAttrib(["dblClick",connid]))
			i6 = "*"+Changeset.numToString(pool.putAttrib(["label",1]))
			builder.keep(idx-last, 0)
			builder.remove(match[1].length)
			if (match[4].length > 2)
				builder.keep(1, 0, i1+i2+i3+i5+i6, pool);
				builder.keep(match[4].length-2);
				builder.keep(1, 0, i1+i2+i4+i5+i6, pool);
			else
				builder.keep(1, 0, i1+i2+i3+i4+i5+i6, pool);
				
			builder.remove(match[5].length);
			last=idx+match[0].length
			return match[3];
		else
			# we are in STRCopy
			if (typeof map[match[4]] == "undefined")
				return match[0];
			i1 = "*"+Changeset.numToString(pool.putAttrib(["range.readonly",1]))
			i2 = "*"+Changeset.numToString(pool.putAttrib(["range.start",1]))
			i3 = "*"+Changeset.numToString(pool.putAttrib(["range.end",1]))
			i4 = "*"+Changeset.numToString(pool.putAttrib(["dblClick",connid]))
			i5 = "*"+Changeset.numToString(pool.putAttrib(["ref",1]))
			i6 = "*"+Changeset.numToString(pool.putAttrib(["refvar",match[4]]))
			builder.keep(idx-last, 0)
			builder.remove(match[0].length)
			toInsert = map[match[4]]
			if (toInsert.length > 2)
				builder.insert(toInsert[0], i1+i2+i4+i5+i6, pool);
				builder.insert(toInsert.slice(1,-1));
				builder.insert(toInsert.slice(-1), i1+i3+i4+i5+i6, pool);
			else
				builder.insert(toInsert, i1+i2+i3+i4+i5+i6, pool);
			last=idx+match[0].length
			return match[0] 
	)
	
	if (changed) 
		result = {};
		result.pool = pool;
		result.changeset = builder.toString();
		return result
	else
		return false

exports.onInit = (doc, id) ->
	connid = id+".label";
	cs = exports.replaceTermrefs(doc)
	if cs
		doc.submitOp(cs)
		
exports.toggleHider = (doc, tOffset) ->
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
	prefix = suffix = "";
	Changeset.eachAttribNumber(rangeStartOp, (x) ->
		attrib = pool.getAttrib(x)
		if attrib[0]=="range.prefix"
			prefix = attrib[1]
		if attrib[0]=="label.expanded"
			expanded = true
		)
	Changeset.eachAttribNumber(rangeEndOp, (x) ->
		attrib = pool.getAttrib(x)
		if attrib[0]=="range.suffix"
			suffix = attrib[1]
		)
	if expanded
		builder = Changeset.builder(doc.snapshot.text.length);
		pool = new AttributePool()
		i1 = "*"+Changeset.numToString(pool.putAttrib(["range.prefix",""]))
		i2 = "*"+Changeset.numToString(pool.putAttrib(["range.suffix",""]))
		i3 = "*"+Changeset.numToString(pool.putAttrib(["dblClick",""]))
		i4 = "*"+Changeset.numToString(pool.putAttrib(["label.expanded",""]))
		i5 = "*"+Changeset.numToString(pool.putAttrib(["range.start",]))
		i6 = "*"+Changeset.numToString(pool.putAttrib(["range.end",]))
		builder.keep(rangeStarted, 0, "", pool);
		builder.keep(rangeEnded-rangeStarted, 0, i1+i2+i3+i4+i5+i6, pool);
		result = {};
		result.pool = pool;
		result.changeset = builder.toString();
		doc2 = {snapshot : etherpad.apply(doc.snapshot, result) };
		cs2 = exports.replaceTermrefs(doc2);
		if cs2
			result = etherpad.compose(result, cs2)
		return result
	builder = Changeset.builder(doc.snapshot.text.length);
	pool = new AttributePool()
	i1 = "*"+Changeset.numToString(pool.putAttrib(["range.prefix",""]))
	i2 = "*"+Changeset.numToString(pool.putAttrib(["range.suffix",""]))
	i3 = "*"+Changeset.numToString(pool.putAttrib(["range.start","1"]))
	i4 = "*"+Changeset.numToString(pool.putAttrib(["range.end","1"]))
	i5 = "*"+Changeset.numToString(pool.putAttrib(["dblClick",connid]))
	i6 = "*"+Changeset.numToString(pool.putAttrib(["label.expanded",1]))
	i7 = "*"+Changeset.numToString(pool.putAttrib(["range.start",]))
	i8 = "*"+Changeset.numToString(pool.putAttrib(["range.end",]))
	
	builder.keep(rangeStarted, 0, "", pool);
	builder.insert(prefix[0], i3+i6+i5, pool);
	builder.insert(prefix.slice(1), i5+i6, pool);	
	builder.keep(rangeEnded-rangeStarted, 0, i1+i2+i7+i8+i6+i5, pool);
	builder.insert(suffix.slice(0, -1), i5+i6, pool);
	builder.insert(suffix.slice(-1), i4+i5+i6, pool);
	
	result = {};
	result.pool = pool;
	result.changeset = builder.toString();
	return result
	
exports.onEvent = (doc, name, evt) ->
	# toggle the state of the label
	if (name == "dblClick")
		cs = exports.toggleHider(doc, evt.param.offset);
		if (cs)
			doc.submitOp(cs)

consume = (op, chars) ->
	op.chars = op.chars - chars;
	if (op.chars == 0)
		op.opcode=''

times = 0
# op1 - change that just came in
# op2 - operation from snapshot attribs (has form *0*1+4)
# pool - common attribute pool
updateZip = (op1, op2, opOut, labelAttID, oldPool, newPool) ->
	if (times++ > 100)
		op1.opcode='';
		op2.opcode='';
	op1code = op1.opcode;
	# changes are finished, so we also can finish
	if op1.opcode == ''
		opOut.opcode = '';
		op2.opcode = '';
	if op2.opcode == ''
		opOut.opcode = '';
		op1.opcode = '';
	
	# while everything equal - stay this way
	if op1code == '=' 
		opOut.opcode = '=';
		opOut.chars = chars = Math.min(op1.chars, op2.chars);
		consume(op1, chars);
		consume(op2, chars);
		return;

	# deleting is ok 
	if op1code == '-'
		opOut.opcode = '';
		op1.opcode='';
		return;

	# adding new character
	if op1code == '+'
		opOut.attribs = '';
		if op2.attribs.match("\\*"+labelAttID)
			Changeset.eachAttribNumber(op2.attribs, (id) ->
				attID = newPool.putAttrib(oldPool.getAttrib(id))
				opOut.attribs += "*"+Changeset.numToString(attID);
				)
		opOut.opcode='=';
		opOut.chars = chars = Math.min(op1.chars, op2.chars);
		consume(op1, chars);
		consume(op2, chars);
		return

exports.updateRange = (op, oldSnapshot, doc) ->
	unpacked = Changeset.unpack(op.changeset);
	labelAttID = doc.snapshot.pool.putAttrib(["label",1], true)
	newPool = new AttributePool();

	ops = Changeset.applyZip(unpacked.ops, 0, oldSnapshot.attribs, 0, (op1, op2, opOut) ->
		updateZip(op1, op2, opOut, labelAttID, doc.snapshot.pool, newPool);
	);

	newOp={};
	newOp.changeset = Changeset.pack(unpacked.newLen, unpacked.newLen, ops, "");
	newOp.pool = newPool
	if (newOp.pool.nextNum > 0)
		doc.submitOp(newOp, (params...) ->
		)

	
exports.onChange = (doc, op, oldSnapshot) ->
	console.log("on change");
	exports.updateRange(op, oldSnapshot, doc);
	exports.replaceTermrefs(doc)

initText = "$\\STRlabel[r]{r}$ using \\termref{cd=physics-constants,";

cs = Changeset.unpack(Changeset.builder(0).insert(initText).toString());
snapshot = { text: cs.charBank, attribs: cs.ops, pool: new AttributePool() }

doc = {};
doc.snapshot = snapshot;
doc.submitOp = (op) ->
	oldSnapshot = doc.snapshot
	doc.snapshot = etherpad.apply(doc.snapshot, op);
	
#exports.onInit(doc)
#console.log doc.snapshot
#exports.toggleHider(doc, 5)
#console.log "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx"
#exports.onInit(doc)
#console.log doc.snapshot

#op = { changeset: Changeset.builder(doc.snapshot.text.length).keep(6).insert("e").toString(),
#	pool: new AttributePool() };
#doc.submitOp(op);

