# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

for($i=0; $i -lt 2; $i++)
{
    
    $curPort = 1000 + $i
    mkdir ${pwd}/examples/out/$i
    docker run -d -u ${curPort}:${curPort} -v ${pwd}/examples/in/:/data/in -v ${pwd}/examples/out/${i}:/data/out -v ${pwd}/config.mine.json:/data/config.json custom_vision 

}
docker ps