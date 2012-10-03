"use strict";
/** @suppress {duplicate}*/var redsys;
if (typeof(redsys)=="undefined") {redsys = {};}

redsys.InitClient = PROTO.Message("redsys.InitClient",{
	name: {
		options: {},
		multiplicity: PROTO.optional,
		type: function(){return PROTO.string;},
		id: 1
	}});
