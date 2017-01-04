//
//  main.swift
//  Na4lapyAPI
//
//  Created by Andrzej Butkiewicz on 22.12.2016.
//  Copyright © 2016 Stowarzyszenie Na4Łapy. All rights reserved.
//

import Kitura
import HeliumLogger
import LoggerAPI
import Foundation
import Na4lapyCore

HeliumLogger.use()

var dbconfig = DBConfig()
var animalBackend: Model
let defaultListenPort = 8123
var defaultImagesPath = "/Users/scoot/images/"
var listenPort: Int = defaultListenPort

if let imagesPath = getenv("N4L_API_IMAGES_PATH") {
    defaultImagesPath = String(cString: imagesPath)
    Log.info("Ścieżka do zdjęć: \(defaultImagesPath)")
}
if let dbuser = getenv("N4L_API_DATABASE_USER") {
    dbconfig.user = String(cString: dbuser)
}
if let dbpass = getenv("N4L_API_DATABASE_PASS") {
    dbconfig.password = String(cString: dbpass)
}
if let oldapi = getenv("N4L_OLDAPI_IMAGES_URL") {
    dbconfig.oldapiUrl = String(cString: oldapi)
}
if let apiport = getenv("N4L_API_LISTEN_PORT") {
    listenPort = String(cString: apiport).int ?? defaultListenPort
}

let db = DBLayer(config: dbconfig)

if let oldapi = getenv("N4L_OLDAPI_IMAGES_URL") {
    Log.info("Uruchomienie w trybie OLD_API, url: \(dbconfig.oldapiUrl)")
    animalBackend = AnimalBackend_oldapi(db: db)
} else {
    animalBackend = AnimalBackend(db: db)
}

let animalController = Controller(backend: animalBackend)
let filesController = FilesController(path: defaultImagesPath)
let loginController = LoginController()

let mainRouter = Router()
mainRouter.get("/") {
    request, response, next in
    next()
}

mainRouter.all("animals", middleware: animalController.router)
mainRouter.all("files", middleware: filesController.router)
mainRouter.all("login", middleware: loginController.router)


//  an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: listenPort, with: mainRouter)

// Start the Kitura runloop (this call never returns)
Kitura.run()

