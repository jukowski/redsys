root = "http://localhost:8080/rest/";
redsys = require('./redsys_vfs')
vfs = new redsys();
vfs.registerGlobalTranslator("tex", { res: "sms", mime: "application/x-sms" });
vfs.registerGlobalTranslator("sms", { res: "rec", mime: "application/x-rec" });

# require('http').createServer(require('stack')(
#  require('vfs-http-adapter')("/rest/", vfs)
# ) ).listen(8080);

# console.log("RESTful interface at " + root);

#vfs.readdir("/", {}, (err, result) ->
#    result.stream.on("data", (item) ->
#      console.log(item);
#    )
#  );
  
vfs.readfile("/test2.rec", {}, (err, result) ->
    console.log(err, result);
  )
