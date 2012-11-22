#!/usr/bin/env coffee
# :tabSize=2:indentSize=2:
etherpad = require('share').types.etherpad

async = require("async");
Changeset = etherpad.Changeset
AttributePool = etherpad.AttributePool
request = require('request');
diff = require('diff');

# (for now) statis constants
connOpts = {
    uri: 'http://192.168.111.130:3000/convert',
    method: 'POST'
}

connid = "";
model = null;

running = false;

exports.getServiceURI = () -> "latexml";
           
getDocText = (doc) ->
    return doc.snapshot.text


sendRequest = (data, callback) ->
    req = request(connOpts, (err, _, body) ->
        if err
            return callback(err);
        running = false;
        result = JSON.parse(body);
        callback(err, result.result);
        ).form(data);
    return;

diffChangeset = (d1, d2, callback) ->
    builder = Changeset.builder(d1.length);
    for cs in diff.diffChars(d1, d2)
        if (cs.added)
            builder.insert(cs.value);
        else if (cs.removed)
            builder.remove(cs.value.length);
        else
            builder.keep(cs.value.length);
    callback(null, builder.toString());

exports.setup = (_model) ->
    model = _model;

getOrCreate = (docName, callback) ->
    model.getSnapshot(docName, (err, doc) ->
        if err
            model.create(docName, "etherpad", {}, (err) ->
                return callback(err) if err;
                model.getSnapshot(docName, callback);
                )
        else
            callback(null, doc);
        )

updateOutput = (text, outfile, callback) ->
    if running
        return callback();
    running = true;
    _snap = null;
    _newRes = null;
    async.waterfall([
        (callback) -> getOrCreate(outfile, callback),
        (snapshot, callback) -> _snap = snapshot; sendRequest({tex: text, profile:"planetmath"}, callback),
        (newRes, callback) -> _newRes = newRes; getOrCreate(outfile, callback),
        (snapshot, callback) -> _snap = snapshot; diffChangeset(getDocText(_snap), _newRes, callback),
        (change, callback) -> model.applyOp(outfile, {"op": {"changeset": change, "pool": new AttributePool()}, "v": _snap.v}, callback),
        (newVer, callback) ->  callback()
    ], (err) ->
        running = false;
        callback(err));

exports.onInit = (doc, id, callback) ->
    outfile = "test:doc.omdoc"
    updateOutput(getDocText(doc), outfile, callback);
        
exports.onEvent = (doc, name, evt) ->

    
exports.onChange = (doc, op, oldSnapshot, callback) ->
    outfile = "test:doc.omdoc"
    updateOutput(getDocText(doc), outfile, callback);

_test = () ->
    sharejs = require("share").server;

    options = 
        db : 
            type: "none",
    
    model = sharejs.createModel(options)
    exports.setup(model);
    initText = "\\section{Testing}";
    cs = Changeset.builder(0).insert(initText).toString();
    cs1 = Changeset.builder(initText.length).keep(10).insert("x").toString();
    ap = new AttributePool();

    async.waterfall([
        (callback) -> model.create("test:doc", "etherpad", {}, callback),
        (callback) -> model.applyOp("test:doc", {op : {"changeset": cs, "pool": ap}, "v": 0}, callback),
        (newVer, callback) -> model.getSnapshot("test:doc", callback),
        (doc, callback) -> exports.onInit(doc, "235fsdgsd", callback),
        (callback) -> model.getSnapshot("test:doc.omdoc", callback),
        (doc, callback) -> console.log("before change", getDocText(doc)); model.applyOp("test:doc", {op : {"changeset": cs1, "pool": ap}, "v": 1}, callback),
        (newVer, callback) -> model.getSnapshot("test:doc", callback),
        (doc, callback) -> exports.onChange(doc, null, null, callback),
        (callback) -> model.getSnapshot("test:doc.omdoc", callback),
        (doc, callback) -> console.log("after change", getDocText(doc));  callback();
        ], (err) ->
            console.log(err) if err;
        );

#_test();