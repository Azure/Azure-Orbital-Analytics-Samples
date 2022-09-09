# Glossary


**AOI**
Area of Interest represents the specific geographic extent used to define a focus area for your analysis.

**band**
One layer of a multispectral image representing data values for a specific range of the electromagnetic spectrum of reflected light or heat (e.g., ultraviolet, blue, green, red, near infrared, infrared, thermal, radar, etc.). Also, other user-specified values derived by manipulation of original image bands. A standard color display of a multispectral image shows 
three bands, one each for red, green and blue. Satellite imagery such as LANDSAT TM and SPOT provide multispectral images of the Earth, some containing seven or more bands. 

**coordinate**
A set of numeric quantities that describe the location of a point in a geographic reference system. A coordinate pair describes the location of a point or node in two dimensions (ususally x-y), and a coordinate triplet describes a point in three dimensions (x-y-z). A series of points (two or more) is used to describe lines and the edges of polygons or areas. Coordinates represent locations on the Earth's surface relative to other locations.

**coordinate system**
A reference system used to measure horizontal and vertical distances on a planimetric map. A coordinate system is usually defined by a map projection, a spheroid of reference, a datum, one or more standard parallels, a central meridian, and possible shifts in the x- and y-directions to locate x,y positions of point, line, and area features. A common coordinate system is used to spatially register geographic data for the same area. 

**coverage** 
1. A digital version of a map forming the basic unit of vector data storage in ARC/INFO. A coverage stores geographic features as primary features (such as arcs, nodes, polygons, and 
label points) and secondary features (such as tics, map extent, links, and annotation). Associated feature attribute tables describe and store attributes of the geographic features. 
2. A set of thematically associated data considered as a unit. A coverage usually represents a single theme such as soils, streams, roads, or land use

**datum** 
A set of parameters and control points used to accurately define the three-dimensional shape of the Earth (e.g., as a spheroid). The datum is the basis for a planar coordinate system. For 
example, the North American Datum for 1983 (NAD83) is a common datum for map projections and coordinates within the United States and throughout North America. 

**feature** 
In a GIS, a physical object or location of an event. Features can be points (a tree or a traffic accident), lines (a road or river), or areas (a forest or a parking lot).

**format** 
The pattern into which data are systematically arranged for use on a computer. A file format is the specific design of how information is organized in the file. DLG, DEM, and TIGER are geographic data sets with different file formats.

**geodatabase**
An object-based GIS data model developed by ESRI for ArcGIS that stores each feature as rows in a table. Personal geodatabases store data in a Microsoft Access .mdb file. Corporate 
geodatabases store data in a DBMS such as SQLserver or Oracle. This data structure supports rules-based topology and allows the user to assign behavior to data. 

**geometry** 
Geometry deals with the measures and properties of points, lines and surfaces. In a GIS, geometry is used to represent the spatial component of geographic features. 

**georeference** 
To establish the relationship between page coordinates on a planar map and known real-world coordinates

**latitude** 
The north/south component of a location on the surface of an ellipsoid. Latitude is an angular measurement north or south of the equator. Traditionally latitudes north of the equator are considered as positive and those south of the equator as negative.

**longitude** 
The East/West component of a location on the surface of the Earth. Longitude is usually measured as an angular value East or West of the Greenwich meridian (London, England). Traditionally longitudes East of Greenwich are considered as positive and those West of Greenwich as negative. This is a negative value in Montana. 

**map projection** 
A mathematical model that transforms the locations of features on the Earth's surface to locations on a two- dimensional surface. Because the Earth is three-dimensional, some method must be used to depict a map in two dimensions. Some projections preserve shape; others preserve accuracy of area, distance, or direction. See also coordinate system. Map projections project the Earth's surface onto a flat plane. However, any such representation distorts some parameter of the Earth's surface be it distance, area, shape, or direction. 

**map scale**
The reduction needed to display a representation of the Earth's surface on a map. A statement of a measure on the map and the equivalent measure on the Earth's surface, often expressed as a representative fraction of distance, such as 1:24,000 (one unit of distance on the map represents 24,000 of the same units of distance on the Earth). 'Large scale' refers to a large fractional value such as 1/24,000. A large-scale map shows a small geographic area in greater detail. 'Small scale' refers to a smaller fractional value such as 1/1,000,000. A small-scale map shows a large geographic area in less detail. 

**point-in-polygon**
A topological overlay procedure which determines the spatial coincidence of points and polygons. Points are assigned the attributes of the polygons within which they fall. 

**polygon** 
A coverage feature class used to represent areas. A polygon is defined by the arcs that make up its boundary and a point inside its boundary for identification.

**projection** 
See map projection. 

**raster** 
A cellular data structure composed of rows and columns for storing images. Each unit in the grid is assigned a value associating it with the corresponding attribute data. Selection of grid 
size forces a tradeoff between data resolution (and detail) and system storage requirements. Data can be converted to vector data through the process of vectorization. 

**resampling** 
The process of reducing image data set size by representing a group of pixels with a single pixel. Thus, pixel count is lowered, individual pixel size is increased, and overall image 
geographic extent is retained. Resampled images are "coarse" and have less information than the images from which they are taken. Conversely, this process can also be executed in the reverse. 

**resolution** 
1. Resolution is the accuracy at which a given map scale can depict the location and shape of geographic features. The larger the map scale, the higher the possible resolution. As map scale decreases, resolution diminishes and feature boundaries must be smoothed, simplified, or not shown at all. For example, small areas may have to be represented as points. 
2. Distance between sample points in a lattice. 
3. Size of the smallest feature that can be represented in a surface. 
4. The number of points in x and y in a grid or lattice (e.g., the resolution of a U.S. Geological Survey one-degree DEM is 1201 x 1201 mesh points).

**scale** 
See map scale.

**TlFF** 
Tagged interchange (image) file format. An industry-standard raster data format. TlFF supports black-and-white, gray-scale, pseudocolor, and true-color images, all of which can be stored in a 
compressed or uncompressed format. TlFF is commonly used in desktop publishing and serves as an interface to numerous scanners and graphic arts packages.

**transformation** 
The process that converts coordinates from one coordinate system to another through translation, rotation, and scaling. ARC/lNFO supports these transformations: similarity, affine, piecewise linear, projective, NADCON datum adjustment using minimum-derived curvature transformation, and a polynomial transformation to warp grids and images. 

**vector** 
Data type comprised of x-y coordinate representations of locations on the earth that take the form of single points, strings of points (lines or arcs) or closed lines (polygons) known as features. Each feature has an associated attribute code for identification. Data can be converted to raster data through a process know as rasterization. 

**WGS-84**
A set of parameters, established by the U.S. Defense Mapping Agency, for determining geometric and physical geodetic relationships on a global scale. The system includes a geocentric reference ellipsoid; a coordinate system; and a gravity field model.

**zoom** 
To enlarge and display greater detail of a portion of a geographic data set.