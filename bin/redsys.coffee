sharejs = require("share").server;
http = require('http')
async = require("async");
localfs = require("vfs-local")
extend = require("deep-extend")
path = require("path")
express = require('express');
app = express();

servicesToLoad = [require("../stex/outline.coffee")];
services = {};
services[service.getServiceURI()] = service for service in servicesToLoad;

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

options = 
    db : 
      type: "none"
model = sharejs.createModel(options)

app.get "/enable/:service?*", (req, res) ->
  service = req.params.service
  params = req.query;
  return res.send { error : "Service not found"} if !(services[service]?)
  service = services[service];
  try
    service.onInit(model, params, (err, context) ->
      return res.send { error : err } if err?
      return res.send { status: "ok" }    
      );
  catch error
    return res.send { error : error.toString() }
  # res.send { status: "ok" }


app.use(express.static('../public'));

sharejs.attach(app, options, model);

server.listen(8002);
