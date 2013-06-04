testUtils = require('../common/testutils.coffee');

service = require('./nnexus.coffee').service;

Doc = testUtils.doc;
etherpad = testUtils.etherpad;

doc = new Doc();
doc.insert(0, "A directed graph is a pair ${V,E}$ such that a quartic polynomial equation. 
The origin of the Fuchsian group lies in the hypergeometric equation ");

q = new service(doc);
console.log(q.doc.snapshot);