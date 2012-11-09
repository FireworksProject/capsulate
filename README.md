Capsulate
=========
Capsulate is an Object validation and managment tool for the Node.js (V8)
JavaScript Environment. The goal is to provide a set of functional tools that
make it easier to safely work with JavaScript objects on a server.

## Installation
Capsulate is designed to be installed by including it in the package.json
dependencies list for your web project.  Follow the
[npm documentation for package.json](https://npmjs.org/doc/json.html)
if you don't already know how to do that.

Once you have it listed in the package.json for your project, just run

    npm install

from the root of your project.

## Usage
Load Capsulate into a Node.js module by requiring it.

```JavaScript
    var CAP = require('capsulate');
```

Create prototypes to use.
```JavaScript
var Person = CAP.extend({
	firstName: {
		name: 'first name',
		type: String,
		defaultValue: '',
		tags: ['safe'],
		validators: [string, required]
	},
	lastName: {
		name: 'last name',
		type: String,
		defaultValue: '',
		tags: ['safe'],
		validators: [string, required]
	},
	age: {
		type: Number,
		defaultValue: 0,
		tags: ['safe'],
	  validators: [number]
	},
	affilations: {
		type: Array,
		defaultValue: Array,
		validators: [affiliations]
	},
  address: {
		type: Address, // Another capsule object
		defaultValue: function () { return Object.create(null); },
    validators: [address]
	}
});

var Buyer = Person.extend({
	purchases: {
		type: Array,
		defaultValue: Array,
		validators: [purchases]
	}
});
```
Then easily manage and validate your objects.

```JavaScript
var john = Buyer.create({tags: [safe]});

var jane = Buyer.clean(formData);

jane = Buyer.coerce(jane);

var errors = Buyer.validate(jane);

```


Copyright and License
---------------------
Copyright: (c) 2012 by The Fireworks Project (http://www.fireworksproject.com)

Unless otherwise indicated, all source code is licensed under the MIT license. See MIT-LICENSE for details.
