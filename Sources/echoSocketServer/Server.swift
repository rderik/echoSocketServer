import Foundation

class Server {

  let servicePort = "1234"

  func start() {
    print("Server starting...")

    let socketFD = socket(AF_INET6, //Domain [AF_INET,AF_INET6, AF_UNIX]
                          SOCK_STREAM, //Type [SOCK_STREAM, SOCK_DGRAM, SOCK_SEQPACKET, SOCK_RAW]
                          IPPROTO_TCP  //Protocol [IPPROTO_TCP, IPPROTO_SCTP, IPPROTO_UDP, IPPROTO_DCCP]
                          )//Return a FileDescriptor -1 = error
    if socketFD == -1 {
      print("Error creating BSD Socket")
      return
    }

    var hints = addrinfo(
      ai_flags: AI_PASSIVE,       // Assign the address of the local host to the socket structures
      ai_family: AF_UNSPEC,       // Either IPv4 or IPv6
      ai_socktype: SOCK_STREAM,   // TCP
      ai_protocol: 0,
      ai_addrlen: 0,
      ai_canonname: nil,
      ai_addr: nil,
      ai_next: nil)

    var servinfo: UnsafeMutablePointer<addrinfo>? = nil
    let addrInfoResult = getaddrinfo(
      nil,                        // Any interface
      servicePort,                   // The port on which will be listenend
      &hints,                     // Protocol configuration as per above
      &servinfo)

    if addrInfoResult != 0 {
      print("Error getting address info: \(errno)")
      return
    }

    let bindResult = bind(socketFD, servinfo!.pointee.ai_addr, socklen_t(servinfo!.pointee.ai_addrlen))

    if bindResult == -1 {
      print("Error binding socket to Address: \(errno)")
      return
    }

    let listenResult = listen(socketFD, //Socket File descriptor
                              8         // The backlog argument defines the maximum length the queue of pending connections may grow to
    )

    if listenResult == -1 {
      print("Error setting our socket to listen")
      return
    }

    while (true) {
      let MTU = 65536
      var addr = sockaddr()
      var addr_len :socklen_t = 0

      print("About to accept")
      let clientFD = accept(socketFD, &addr, &addr_len)
      print("Accepted new client with file descriptor: \(clientFD)")

      if clientFD == -1 {
        print("Error accepting connection")
      }

      var buffer = UnsafeMutableRawPointer.allocate(byteCount: MTU,alignment: MemoryLayout<CChar>.size)

      while(true) {
        let readResult = read(clientFD, &buffer, MTU)

        if (readResult == 0) {
          break;  // end of file
        } else if (readResult == -1) {
          print("Error reading form client\(clientFD) - \(errno)")
          break;  // error
        } else {
          //This is an ugly way to add the nul-terminator at the end of the buffer we just read
          withUnsafeMutablePointer(to: &buffer) {
                $0.withMemoryRebound(to: UInt8.self, capacity: readResult + 1) {
                    $0.advanced(by: readResult).assign(repeating: 0, count: 1)
                }
          }
          let strResult = withUnsafePointer(to: &buffer) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: readResult)) {
              String(cString: $0)
            }
          }
          print("Received form client(\(clientFD)): \(strResult)")
          write(clientFD, &buffer, readResult)
        }
      }
    }
  }

}
