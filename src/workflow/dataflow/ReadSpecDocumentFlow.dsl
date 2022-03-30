source(allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	documentForm: 'arrayOfDocuments') ~> source
source sink(allowSchemaDrift: true,
	validateSchema: false,
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	store: 'cache',
	format: 'inline',
	output: true,
	saveOrder: 1) ~> sink