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
    console.log(data);
    req = request(connOpts, (err, _, body) ->
        if err
            return callback(err);
        running = false;
        result = JSON.parse(body);
        if typeof result.result == "undefined"
            result.result ="";
        if typeof result.log == "undefined"
            result.log ="";
        if typeof result.status == "undefined"
            result.status ="";
        callback(err, result);
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

updateOutput = (text, infile, callback) ->
    if running
        return callback();
    omdocFile = infile+".omdoc";
    errFile = infile+".err";
    running = true;
    omdocSnap = null;
    errSnap = null;
    result = null;

    pm = /^([\s\S]*)\\begin{document}([\s\S]*)\\end{document}([\s\S]*)$/.exec(text);
    if (pm.length > 0)
        preamble = pm[1];
        text = pm[2];
    else
        preamble = "";
    console.log("running");
    async.waterfall([
        (callback) -> getOrCreate(omdocFile, callback),
        (snapshot, callback) -> omdocSnap = snapshot; getOrCreate(errFile, callback),
        (snapshot, callback) -> errSnap = snapshot; sendRequest({tex: text, preamble : "literal:"+preamble, profile:"stex-module"}, callback), 
        (newRes, callback) -> result = newRes; diffChangeset(getDocText(omdocSnap), result.result, callback),
        (omdocChange, callback) -> model.applyOp(omdocFile, {"op": {"changeset": omdocChange, "pool": new AttributePool()}, "v": omdocSnap.v}, callback),
        (newVer, callback) -> err = result.status+"\n"+result.log; console.log("err=",err); diffChangeset(getDocText(errSnap), err, callback),
        (errChange, callback) -> model.applyOp(errFile, {"op": {"changeset": errChange, "pool": new AttributePool()}, "v": errSnap.v}, callback),
        (newVer, callback) ->  callback()
    ], (err) ->
        if err
            console.log("Error found ", err);
        console.log("/running");
        running = false;
        callback(err));

exports.onInit = (doc, id, callback) ->
    infile = "test:doc"
    updateOutput(getDocText(doc), infile, callback);
        
exports.onEvent = (doc, name, evt) ->

    
exports.onChange = (doc, op, oldSnapshot, callback) ->
    infile = "test:doc"
    updateOutput(getDocText(doc), infile, callback);

_test = () ->
    sharejs = require("share").server;

    options = 
        db : 
            type: "none",
    
    model = sharejs.createModel(options)
    exports.setup(model);
    initText = "\\documentclass{omdoc}\n\\usepackage{stex}\n\\usepackage{eurosym,amssymb,amstext,url}\n\\defpath{STC}{..\x2F..\x2F..}\n\\defpath{KWARCslides}{\\STC{slides}}\n\\defpath{SiSsI}{\\STC{sissi}}\n%\\input{\\STC{lib\x2FWApersons}}\n\n\\begin{document}\n\\baseURI[\x2Fsissi\x2Fwinograd\x2Fcds]{http:\x2F\x2F192.168.111.130\x2Fstc\x2Fsissi\x2Fwinograd\x2Fcds}\n\n\n\\end{document}\n% LocalWords:  omgroup linearextrapolation.omdoc miko omtext omtext symboldec\n% LocalWords:  linearextrapolation lagrangeinterpolation lagrangeinterpolation\n% LocalWords:  symtype sts fntype atimes aminus tassign prognosisfunction";
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

_test();