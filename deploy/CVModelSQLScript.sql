CREATE EXTENSION postgis;

CREATE SCHEMA aioutputmodelschema CREATE TABLE cvmodel (id VARCHAR(40), probability NUMERIC, tagid text, tagname text, tagtype text, tile text);

ALTER TABLE aioutputmodelschema.cvmodel ADD COLUMN location geometry(Polygon, 4326);