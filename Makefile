deps:
	sudo pacman -Syu --needed docker
	sudo systemctl enable docker.service # set the docker service to auto start
	sudo systemctl start docker.service # startup the docker service immediately
	sudo chown $(USER) /var/run/docker.sock # for development purposes only. for prod, create a docker user and run docker images as that user
	go install sigs.k8s.io/kind@v0.20.0 && kind create cluster
