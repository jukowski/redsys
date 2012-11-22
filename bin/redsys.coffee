sharejs = require("share").server;
http = require('http')
async = require("async");
localfs = require("vfs-local")
extend = require("deep-extend")
path = require("path")
express = require('express');

shareBC = require('share/src/server/browserchannel.coffee');

app = express();

latexml = require("../stex/latexml")

createFS = (options) ->
  return switch options.type
    when "local" then localfs(options);
    else throw new Error "Cannot init VFS type '#{options.type}'";

module.exports = (_opt) ->
  options = 
    db : 
      type: "none",
    fs :
      type: "local",
      root: path.resolve("./fs")
  extend(options, _opt);
  model = sharejs.createModel(options)

  vfs = createFS(options.fs)
  return {
      getFile : (filePath) ->
        console.log(filePath);
    }

options =
  db: {type: 'none'},
  browserChannel : null,

model = sharejs.createModel(options)

updateCallback = (name) ->
  return (data)->
    async.waterfall([
      (callback) -> model.getSnapshot(name, callback),
      (doc, callback) -> latexml.onChange(doc, data.op, null, callback),
    ]);

createCallback = (name, type, meta) ->
  if (/\.omdoc/.exec(name))
    # we're already in the omdoc file
    return;
  v = 0;
  async.waterfall([
    (callback) -> setTimeout(callback, 500),
    (callback) -> model.getSnapshot(name, callback),
    (doc, callback) -> v = doc.v; latexml.onInit(doc, "235fsdgsd", callback),
    (callback) -> model.listen(name, v, updateCallback(name), callback)
    ], (err) ->
      console.log(err) if err;
      );

options.createCallback = createCallback;
shareAgent = require('./redsys_agent.coffee') model, options
latexml.setup(model);

server = http.createServer(app);
app.use(express.static('../public'));

sharejs.attach(app, options, model);
app.use shareBC(shareAgent, {server: app});

server.listen(8002);