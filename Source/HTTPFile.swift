// FileResponder.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import File
@_exported import HTTP

public struct FileResponder: Responder {
    public enum Error : ErrorProtocol {
        case notFound(path: String)
        case isDirectory(path: String)
        case readFailure(path: String, error: ErrorProtocol)
    }

    let path: String

    public init(path: String) {
        self.path = path
    }

    public func respond(to request: Request) throws -> Response {
        if request.method != .get {
            return Response(status: .methodNotAllowed)
        }

        guard let requestPath = request.path else {
            return Response(status: .internalServerError)
        }

        var path = requestPath

        if path.ends(with: "/") {
            path += "index.html"
        }

        return try Response(status: .ok, filePath: self.path + path)
    }
}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], filePath: String) throws {
        switch (File.exists(at: filePath)) {
        case (exists: false, _):
            throw FileResponder.Error.notFound(path: filePath)
        case (_, isDirectory: true):
            throw FileResponder.Error.isDirectory(path: filePath)
        default: break
        }

        do {
            let file = try File(path: filePath, mode: .read)
            self.init(status: status, headers: headers, body: file.stream)

            if let
                fileExtension = file.fileExtension,
                mediaType = mediaType(forFileExtension: fileExtension) {
                    self.contentType = mediaType
            }

        } catch {
            throw FileResponder.Error.readFailure(path: filePath,
                                                  error: error)
        }
    }
}
