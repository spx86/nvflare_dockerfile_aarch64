# nvflare_dockerfile_aarch64
Docker image package file for arm64 of nvflare, running on arm64 architecture machine

##RUN on x86_64
```shell
# AMD64 or Other x86_64 architecture machine
ARCH=amd64 docker-compose up --build -d
```

##RUN on aarch64
```shell 
# Arm64 or Other aarch64 architecture machine
ARCH=arm64 docker-compose up --build -d
```

##Enter the container
```shell
docker-compose exec nvflare /bin/bash
```

