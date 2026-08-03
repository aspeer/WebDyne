.PHONY : all build docker

THIS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT ?= $(abspath $(THIS_DIR)/../..)

PSP_DIR := $(REPO_ROOT)/doc/example
PSP_FILES := $(shell find $(PSP_DIR) -type f -name '*.psp')

DOCKER_IMAGE ?= webdyne-demo:latest
DOCKERFILE := $(THIS_DIR)/Dockerfile.alpine
DOCKER_STAMP := $(THIS_DIR)/.built
DOCKER_INPUTS := $(DOCKERFILE) $(THIS_DIR)/cpanfile $(THIS_DIR)/webdyne.conf.pl $(PSP_FILES)

all	: build

build docker: $(DOCKER_STAMP)

$(DOCKER_STAMP) : $(DOCKER_INPUTS)
	docker build -t $(DOCKER_IMAGE) -f $(DOCKERFILE) $(REPO_ROOT)
	touch $(DOCKER_STAMP)
