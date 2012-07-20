http = require("http");

#msg = ':: Numerals - Requirements\n::  by Library Committee\n::\n:: Received February 27, 2003\n:: Copyright (c) 2003 Association of Mizar Users\n\nenviron\n\n vocabularies ORDINAL2, BOOLE;\n notations XBOOLE_0, SUBSET_1, ORDINAL1;\n constructors SUBSET_1, ORDINAL1;\n requirements BOOLE;\n theorems SUBSET_1, ORDINAL1;\n\nbegin\n\n:: This file contains statements which are obvious for Mizar checker if\n:: \"requirements NUMERALS\" is included in the environment description\n:: of an article. They are published for testing purposes only.\n:: Users should use appropriate requirements instead of referencing\n:: to these theorems.\n:: Some of these items need also other requirements for proper work.\n:: Statements which cannot be expressed in Mizar language are commented out.\n\ntheorem  :: \"requirements SUBSET\" needed\n  {} is Element of omega\nproof\n  {} in omega by ORDINAL1:def 12;\n  hence thesis by SUBSET_1:def 2;\nend;\n\n::theorem \n::  numeral(X) implies X is Element of omega; \n::theorem \n::  numeral(X) implies succ(X) = X + 1; \n';

msg = "";

options = {
    host: 'mizar.cs.ualberta.ca',
    port: 80,
    path: '/parsing/?strictness=none&format=xml',
#    path: '/index.php?strictness=none&format=xml',
    method: 'POST',
    headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': msg.length
    }
};

req = http.request(options, (res) ->
  console.log('STATUS: ' + res.statusCode);
  console.log('HEADERS: ' + JSON.stringify(res.headers));
  res.setEncoding('utf8');
  res.on('data', (chunk) ->
    console.log('BODY: ' + chunk);
  );
);

req.on('error', (e) ->
  console.log('problem with request: ' + e.message);
);

# write data to request body
req.write(msg);
req.end();
