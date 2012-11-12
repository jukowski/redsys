sharejs = require("share").server;
http = require('http')
async = require("async");
localfs = require("vfs-local")
extend = require("deep-extend")
path = require("path")
express = require('express');
app = express();
bcadapter = require('./bcadapter.coffee');
useragentgen = require('share/src/server/useragent.coffee');

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
  browserChannel: null,

server = http.createServer(app);
app.use(express.static('../public'));
sharejs.attach(app, options);

model = sharejs.createModel(options)
useragent = useragentgen(model, options);

options.browserChannel ?= {}
options.browserChannel.server = app
app.use bcadapter(useragent, options.browserChannel)

server.listen(8002);