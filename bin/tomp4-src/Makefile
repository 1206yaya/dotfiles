APP_NAME := tomp4

build:
	go build -o $(APP_NAME) main.go
	mv $(APP_NAME) ../
	chmod +x ../$(APP_NAME)


run:
	go run main.go

clean:
	rm -f $(APP_NAME)
