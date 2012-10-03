sharejs = require("share").server;
async = require("async");
localfs = require("vfs-local")
extend = require("deep-extend")
path = require("path")

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
