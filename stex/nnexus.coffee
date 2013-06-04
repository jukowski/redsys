http = require('http');
querystring = require('querystring');
utils = require('../common/testutils.coffee')
Doc = utils.doc;
Changeset = utils.etherpad.Changeset
etherpad = utils.etherpad

sendToNNexus = (text, callback) -> 
	post_data = querystring.stringify
		embed : 0,
		annotation : "json",
		body: text

	post_options = {
		host: '127.0.0.1',
		port: '3000',
		path: '/linkentry',
		method: 'POST',
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded',
			'Content-Length': post_data.length
		}
	};

	post_req = http.request post_options, (res) ->
		res.setEncoding('utf8');
		data = "";

		res.on 'data', (chunk) ->
			data += chunk;

		res.on 'end', () ->
			result = JSON.parse(data);
			return callback(null, JSON.parse(result.payload)) if (result.status == "OK")
			return callback(result.message)

	post_req.on 'error', (err) ->
		callback(err.toString());

	post_req.write(post_data);
	post_req.end();


class NNexus
	constructor : (@doc) ->
		@doc.on("change", @change);

		@update();

	makeSubmit : (op) ->
		@doc.submitOp(op);

	update : () ->
		# create an empty changeset
		ops = utils.createIdentity(@doc.getLength());
		_this = @;

		# make a clone of the document snapshot
		_doc = new Doc(@doc.snapshot);
		_doc.on "change", (op) ->
			ops = etherpad.compose(ops, op);

		sendToNNexus _doc.getText(), (err, links) ->
			return console.log(err) if err?
			for link in links
				_doc.setAttributes(link.offset_begin, link.offset_end-link.offset_begin, [["nnexus", true]]);
			_this.makeSubmit(ops);


	# original file changed
	change : (op) ->
		console.log(op);


exports.service = NNexus;
