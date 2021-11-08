# Default value for environment variable. Can be overridden by setting the
# environment variable.
export DOCKER_CONTENT_TRUST := 0
export DOCKER_CLI_EXPERIMENTAL := enabled

# image suffix lookup
IS_java8 := java8
IS_nodejs10x := nodejs10.x
IS_provided := provided
IS_python27 := python2.7
IS_python36 := python3.6
IS_python37 := python3.7
IS_ruby25 := ruby2.5
IS_go1x := go1.x
IS_dotnetcore31 := dotnetcore3.1
IS_java8-al2 := java8.al2
IS_java11 := java11
IS_nodejs12x := nodejs12.x
IS_nodejs14x := nodejs14.x
IS_provided-al2 := provided.al2
IS_python38 := python3.8
IS_python39 := python3.9
IS_ruby27 := ruby2.7

# architecture platform lookup
AP_x86_64 := linux/amd64
AP_arm64 := linux/arm64

# aws cli arch lookup
AWS_CLI_ARCH_x86_64 = x86_64
AWS_CLI_ARCH_arm64 = aarch64


init:
	pip install -Ur requirements.txt

build:
	cd build-image-src && ./build_all_images.sh

pre-build-multi-arch:
ifeq ($(strip $(ARCHITECTURE)),)
	exit 1
else
	@echo "Architecture $(ARCHITECTURE)"
endif

pre-build:
ifeq ($(strip $(SAM_CLI_VERSION)),)
	exit 1
else
	@echo "SAM CLI VERSION $(SAM_CLI_VERSION)"
endif

ifeq ($(strip $(RUNTIME)),)
	exit 1
else
	@echo "Building runtime $(RUNTIME)"
endif

build-single-arch: pre-build
	docker build -f build-image-src/Dockerfile-$(RUNTIME) -t amazon/aws-sam-cli-build-image-$(IS_$(RUNTIME)):x86_64 --build-arg SAM_CLI_VERSION=$(SAM_CLI_VERSION) ./build-image-src

build-multi-arch: pre-build pre-build-multi-arch
	docker build -f build-image-src/Dockerfile-$(RUNTIME) -t amazon/aws-sam-cli-build-image-$(IS_$(RUNTIME)):$(ARCHITECTURE) --platform $(AP_$(ARCHITECTURE)) --build-arg SAM_CLI_VERSION=$(SAM_CLI_VERSION) --build-arg AWS_CLI_ARCH=$(AWS_CLI_ARCH_$(ARCHITECTURE)) --build-arg IMAGE_ARCH=$(ARCHITECTURE) ./build-image-src

test-single-arch: pre-build
	pytest tests -m $(RUNTIME)

test-multi-arch: pre-build pre-build-multi-arch
	pytest tests -m $(RUNTIME)_$(ARCHITECTURE)

lint:
	# Linter performs static analysis to catch latent bugs
	pylint --rcfile .pylintrc tests
	# mypy performs type check
	mypy tests/*.py

dev: lint test

black:
	black tests

black-check:
	black --check tests

# Verifications to run before sending a pull request
pr: init build black-check dev
