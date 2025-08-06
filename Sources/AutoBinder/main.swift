// The Swift Programming Language
// https://docs.swift.org/swift-book

import FoundationXML
import Foundation

import Guides
import Vala
import KhronosRegistry

let doc = try XMLDocument(
    contentsOf: URL(filePath: "./xml/cl.xml"),
    options: XMLNode.Options.nodePreserveWhitespace
)
let root = doc.rootElement()!
let reg = Registry(root)
let manager = FileManager.default

try manager.createDirectory(
    atPath: "./vapi",
    withIntermediateDirectories: true
)

guard manager.createFile(
    atPath: "./vapi/cl.vapi",
    contents: nil
) else {
    fatalError("")
}

let res = URL(filePath: "./vapi/cl.vapi")

let srcWrite = SourceWriter()
srcWrite.write(writer: res, registry: reg)
