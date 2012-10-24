#!/usr/bin/env coffee
# :tabSize=4:indentSize=4:
#etherpad = require('share').types.etherpad

#Changeset = etherpad.Changeset
#AttributePool = etherpad.AttributePool

hat = require('hat');
assert = require 'assert'
nodeunit = require('nodeunit')

initText = "The \\termref{cd=physics-energy, name=grav-potential}{gravitational \n potential energy} \\termref{cd=physics-constants,\n
 name=grav-constant}{gravitational constant}";

# Motivation:
# many times editing services are only interested in a very limited part of the
# document and remain agnostic of changes happening in the rest of the document

# Hence it is common, that upon receiving a Changeset, services first need to see
# if "their" ranges got changed in any way. If not, then they just ignore the change.

# Some services also need to persistently store information in the document model
# corresponding to some range. 

# 


# we might need a RangeManager class that can expose a more highlevel view
# over changes done in a document

# expand/retract itself as user updates text
# createRange(doc, start, length) - returns an int - the ID of the range
# ranges can overlap

# this updates the range in the document with an attribute (range-#uid, "1");
# meaning that it is part of range with that id
# this will create an 
# the range module needs to listen to document changes and update it 
# QUESTION: should the range module already support read-onlyness?



# createMode(doc, start, length)
# creates a viewing mode from the range start->length



class Range
	constructor: (@from, @to) ->
		@id = hat();

	getid : () -> @id

	overlap : (y) ->
		return @from < y.to && @to > y.from;

	leq : (y) ->
		return @from <= y.from;

	contains : (pos) ->
		return @from <= pos && pos < @to;

	split : (pos) ->
		oldTo = @to
		@to = pos
		return new Range(pos, oldTo);

	rightof : (pos) ->
		return pos < @to;
		
	incLength : (delta) ->
	    @to += delta;
	 
	move : (delta) ->
	    @from += delta;
	    @to += delta;

	toString : () ->
		sb = "("+@from+","+@to+")";
		return sb;

class RangeManager
	constructor : () ->
		@ranges = [];
		@id2obj = {};

	addRange : (rng) ->
		@ranges.push(rng);
		n = @ranges.length - 1
		while (n > 0 && @ranges[n].leq(@ranges[n-1]))
			if @ranges[n].overlap(@ranges[n-1])
				console.log("Ranges ", @ranges[n].toString(), " ", @ranges[n-1].toString(), "overlap :(");
			t = @ranges[n-1];
			@ranges[n-1] = @ranges[n];
			@ranges[n] = t;
			n--;
		@id2obj[rng.getid()] = rng;

	# creates a new range with limits [from, to]. Returns it's ID
	markRange : (from, to) ->
		rng = new Range(from, to);
		@addRange(rng);
		return rng.getid()

	# finds the left most segment closing after pos
	# returns []
	findLeftGreater : (pos) ->
		index = 0;
		for range in @ranges 
			if (range.contains(pos))
				return [range.getid(), true];
			if (range.rightof(pos))
				return [range.getid(), false];
			index++;
		return [null, null];
	
	shiftRight : (idx, len) ->
		for i in [idx..(@ranges.length-1)]
			@ranges[i].move(len);
		return

	getIndexById : (id) ->
		rng = @id2obj[id];
		idx = 0
		for range in @ranges
			if rng == range
				return idx
			idx++;
		return null
	
	incLength : (id, len) ->
		idx = @getIndexById(id);
		@ranges[idx].incLength(len);
		@shiftRight(idx+1, len);

	split : (pos) ->
		for range in @ranges
			if (range.contains(pos))
				newRange = range.split(pos);
				@addRange(newRange);
				return newRange.getid();


	toString : () ->
		sb = "{";
		for range in @ranges 
			sb += range.toString() + " ";
		sb += "}";
		return sb;

# converts from offset <-> (row, col)
class LineManager

	computeLen = (line) ->
		lines = line.split("\n");
		if (lines.length == 0)
			return [];
		if (lines.length == 1)
			return [lines[0].length];
		res=[];
		for idx in [0..(lines.length-2)]
			res.push(lines[idx].length+1);
		lastlen = lines[lines.length-1].length
		if (lastlen > 0)
			res.push(lastlen)
		return res

	constructor : (initText = "") ->
		@rm = new RangeManager();
		loff = 0;
		lens = computeLen(initText);
		for len in lens
			@rm.markRange(loff, loff+len);
			loff += len;

	insert : (pos, str) ->
		lens = computeLen(str);
		return if lens.length == 0
		[id, inside] = @rm.findLeftGreater(pos)
		# we can assert this because LineManager manages the whole interval
		assert(id!=null && inside);
		@rm.incLength(id, lens[0]);
		done = lens[0];
		lastSegment = id;
		for lidx in [1..(lens.length-1)]
			nid = @rm.split(pos+done);
			@rm.incLength(nid, lens[lidx])
			done += lens[lidx];

	toString : () ->
		return @rm.toString()

exports.Test1 = (test) ->
	rm = new RangeManager();
	id0 = rm.markRange(30, 40);
	id1 = rm.markRange(3, 20);
	id2 = rm.markRange(70, 90);
	id3 = rm.markRange(45, 60);

	[index, inside] = rm.findLeftGreater(3);
	test.equal(index, id1); test.equal(inside, true);
	[index, inside] = rm.findLeftGreater(1);
	test.equal(index, id1); test.equal(inside, false);
	[index, inside] = rm.findLeftGreater(20);
	test.equal(index, id0); test.equal(inside, false);
	[index, inside] = rm.findLeftGreater(61);
	test.equal(index, id2); test.equal(inside, false);
	[index, inside] = rm.findLeftGreater(59);
	test.equal(index, id3); test.equal(inside, true);
	[index, inside] = rm.findLeftGreater(91);
	test.equal(index, null); test.equal(inside, null);
	test.done();

Test2 = (test) ->
	lm = new LineManager("blah\n\ntest\n");
	console.log("before", lm.toString());
	lm.insert(1, "qw\nt\ny");
	lm.insert(6, "a");
	console.log(lm.toString());
	#test.done();

Test2();
#cs = Changeset.unpack(Changeset.builder(0).insert(initText).toString());
#snapshot = { text: cs.charBank, attribs: cs.ops, pool: new AttributePool() }

#doc = {};
#doc.snapshot = snapshot;
#doc.submitOp = (op) ->
#	oldSnapshot = doc.snapshot
#	doc.snapshot = etherpad.apply(doc.snapshot, op);
#console.log("test");
#exports.onInit(doc)
#console.log doc.snapshot
#exports.toggleHider(doc, 5)
#console.log "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx"
#exports.onInit(doc)
#console.log doc.snapshot

#op = { changeset: Changeset.builder(doc.snapshot.text.length).keep(6).insert("e").toString(),
#	pool: new AttributePool() };
#doc.submitOp(op);

