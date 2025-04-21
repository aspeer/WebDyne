cp ../examples/server_time.psp .
cp ../packer/webdyne.psgi.pp .
docker build -t webdyne -f ./Dockerfile .
