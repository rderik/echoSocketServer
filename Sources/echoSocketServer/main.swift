import Foundation

print("Welcome to our simple echo server!")

var server = Server()
server.start()

RunLoop.main.run()
exit(EXIT_SUCCESS)
