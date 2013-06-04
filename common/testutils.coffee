path = require("path")
shareDir = path.dirname(require.resolve('share'));
etherpad = require(shareDir+"/src/types/etherpad-api").etherpad
MicroEvent = require shareDir+'/src/client/microevent'

Doc = (data) ->
  @snapshot = data ? etherpad.create()
  @type = etherpad
  @submitOp = (op) ->
    @snapshot = etherpad.apply @snapshot, op
    @emit 'change', op
  @_register()
Doc.prototype = etherpad.api
MicroEvent.mixin Doc

exports.createIdentity = (len) ->
	return {
		pool : new etherpad.AttributePool()
		changeset: etherpad.Changeset.identity(len)
	}

exports.doc = Doc
exports.etherpad = etherpad
