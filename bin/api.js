"use strict";
.InitClient = PROTO.Message(".InitClient",{
	name: {
		options: {},
		multiplicity: PROTO.optional,
		type: function(){return PROTO.string;},
		id: 1
	}});
