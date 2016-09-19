.PHONY: build
build:
	docker build -t joseafonsopinto/android-studio:143 .
	docker tag joseafonsopinto/android-studio:143 joseafonsopinto/android-studio:latest

.PHONY: hack
hack: build
	./android-studio
