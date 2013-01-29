async = require("async")
cloner  = require('clone');
util = require('listish');

exports.getServiceURI = () -> "stex-outline";

regexps = [ 
	{id: "omgroup", begin: /\\begin\{omgroup\}(?:\[id=([\S]+)\])?\{([\S ]+)\}/g, end: /\\end\{omgroup\}/g },
	{id: "module", begin: /\\begin\{module\}(?:\[id=([\S]+)\])?/g, end: /\\end\{module\}/g },
	{id: "symdef", regexp: /\\symdef(?:\[title=([\S ]+)\])?/g},
]

extend = (obj, mixin) ->
  obj[name] = method for name, method of mixin        
  obj

getMatches = (text, reg) ->
	result = [];
	text.replace(reg, (match...) ->
		result.push 
			pos : match[match.length-2], 
			len : match[0].length, 
			params: match[1..match.length-3];
		return "";
		)
	result

getid = (begin, end) ->
	begin+"|"+end;

analyze_sol = (oldSol, newSol) ->
	return newSol if !(oldSol.cost?) || newSol.cost < oldSol.cost
	return oldSol


solve = (a, begin, end, cache = {}) ->
	return {cost: 0, set: {}} if (begin > end);
	return {cost: 1, set: {}} if (begin == end);
	probID = getid(begin, end);
	if cache[probID]
		return cache[probID];

	sol = {};
	if a[begin].type == "begin" && a[end].type == "end" && a[begin].id == a[end].id
		res = cloner(solve(a, begin + 1, end - 1, cache), {})
		res.set[a[begin].index] = a[end].index;
		res.set[a[end].index] = a[begin].index;
		sol = analyze_sol(sol, res);

	for s in [begin..(end-1)]
		res1 = solve(a, begin, s, cache);
		res2 = solve(a, s+1, end)
		res = 
			cost: res1.cost + res2.cost, 
			set: extend(cloner(res1.set, {}), res2.set)
		sol = analyze_sol(sol, res);

	cache[probID] = sol

getComponents = (text) ->
	components = [];
	for regexp,i in regexps
		if regexp.begin?
			components.push(extend(match, {type: "begin", id: regexp.id})) for match in getMatches(text, regexp.begin)
		if regexp.end?
			components.push(extend(match, {type: "end", id: regexp.id})) for match in getMatches(text, regexp.end)
		if regexp.regexp?
			components.push(extend(match, {type: "item", id: regexp.id})) for match in getMatches(text, regexp.regexp)
	components.sort (a, b) ->
		return a.pos >= b.pos;

assembleTree = (components) ->
	matcher = [];
	for component, i in components
		if component.type != "item"
			matcher.push({index: i, type: component.type, id: component.id});
	matchSol = solve(matcher, 0, matcher.length - 1)["set"];
	stack = new util.Stack();
	stack.push({path: "", c: []});

	for component, i in components
		component.path = stack.top.path+"/"+i
		if component.type == "begin" 
			if (matchSol[i]?)
				stack.push({ path: component.path, id: i, c: []});
			else
				stack.top.c.push(i);
		if component.type == "end"
			stack.top.c.push(i);
			if (matchSol[i]?)
				t = stack.pop();
				delete t.path
				stack.top.c.push(t);
		if component.type == "item"
			stack.top.c.push(i);
	return { components: components, tree: stack.top.c }

# returns true if tree changes are there
structChanges = (oldComponents, newComponents) ->
	return true if oldComponents.length != newComponents.length
	for component, i in oldComponents
		return true if component.type != newComponents[i].type
		return true if component.id != newComponents[i].id
	false

resetJSONFile = (model, file, contents, callback) ->
	async.waterfall [
		(callback) -> model.getSnapshot(file, callback),
		(doc, callback) -> 
			model.applyOp file, {op: [p:[], od: doc.snapshot, oi: contents], v: doc.v}, callback
		], callback 

exports.onUpdate = (context, delta) ->
	doc = context.doc;
	context.doc.snapshot = doc.type.apply(doc.snapshot, delta.op)
	text = context.doc.snapshot.text;
	components = getComponents(text)
	if (structChanges(context.components, components))
		newTree = assembleTree(components);
		resetJSONFile(context["model"], context["output"], newTree);
		context.components = components


exports.onInit = (model, params, callback) ->
	return callback("input parameter missing") if !(params["input"]?)
	return callback("output parameter missing") if !(params["output"]?)

	context = 
		input : params["input"]
		output : params["output"]
		model : model
		components : []

	async.waterfall [
		(callback) -> model.getSnapshot(context["input"], callback),
		(doc, callback) -> context.doc = doc; model.create(context["output"], "json", {}, callback)
		(doc, callback) -> model.listen(context["input"], context.doc.v + 1, (op) ->
			exports.onUpdate(context, op)
		, callback)
		], (err) ->
			return callback(err) if err?
			return callback(null, context)