//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectHTTP
import PerfectHTTPServer
import PerfectLib
import PerfectCSQLite3
import PerfectSQLite
import PerfectCRUD

let dbPath = "./webroot/word.db"

let apipath = "/api"
let version = "v1"

//let db = Database(configuration: try SQLiteDatabaseConfiguration("testDBName"))

//第一版API

extension String {
    static let main = "/"
}

//DJ音标  ["type": "audio" / "video", "name": "e"]
//["type": "audio", "name": "e"]
//["type": "video", "name": "e"]
func djps(request: HTTPRequest, response: HTTPResponse) {
    let docRoot = request.documentRoot
    print(request.queryParams)
    let type = request.param(name: "type") ?? ""
    let name = request.param(name: "name") ?? ""
    var exten = ""
    switch type {
    case "audio":
        exten = "mp3"
    case "video":
        exten = "mp4"
    default: break
    }
    let filePath = "\(docRoot)" + request.path + "/\(type)/\(name).\(exten)"
    print(filePath)
    do {
        let file = File(filePath)
        let size = file.size
        let bytes = try file.readSomeBytes(count: size)
        response.setHeader(.contentType, value: MimeType.init(extension: exten).description)
        response.setHeader(.contentLength, value: "\(bytes.count)")
        response.setBody(bytes: bytes)
        response.isStreaming = false
    } catch {
        response.status = .internalServerError
        response.setBody(string: "请求处理出现错误：\(error)")
    }
    response.completed()
}

var serverRoutes = Routes()
serverRoutes.add(method: .get, uri: "/") { (req, res) in
    res.setHeader(.contentType, value: "text/html")
    res.appendBody(string: "<html><title>Hello, word!</title><body>Hello, !</body></html>")
    res.completed()
}
serverRoutes.add(uri: "/**", handler: StaticFileHandler.init(documentRoot: "./webroot").handleRequest)

serverRoutes.add(WordApi().routes)
serverRoutes.add(PriceHistoryApi().routes)
//serverRoutes.add(api2Routes)
//serverRoutes.add(webRoutes)

let server = HTTPServer.Server.init(name: "localhost", port: 8181, routes: serverRoutes)

do {
    try HTTPServer.launch(server)
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}

