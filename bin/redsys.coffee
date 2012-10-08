sharejs = require("share").server;
http = require('http')
async = require("async");
localfs = require("vfs-local")
extend = require("deep-extend")
path = require("path")
express = require('express');
app = express();

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
  browserChannel: {cors: '*'},

server = http.createServer(app);
app.use(express.static('../public'));
sharejs.attach(app, options);

server.listen(8002);
