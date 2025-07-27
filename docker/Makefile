.PHONY: Dockerfile ghcr

Dockerfile:
	#docker build --no-cache -t webdyne:latest -f ./Dockerfile
    docker buildx build --platform linux/amd64,linux/arm64 --push -t ghcr.io/aspeer/webdyne:latest -f ./Dockerfile .

	
ghcr:
	docker tag webdyne:latest ghcr.io/aspeer/webdyne:latest
	docker push ghcr.io/aspeer/webdyne:latest
