// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public struct TextPart: ModelContent.Part {
  public let textValue: String

  public init(text: String) {
    textValue = text
  }

  public var text: String? {
    return textValue
  }
}

/// Data with a specified media type. Not all media types may be supported by the AI model.
@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public struct InlineDataPart: ModelContent.Part {
  public let data: Data
  public let mimeType: String

  public init(data: Data, mimeType: String) {
    self.mimeType = mimeType
    self.data = data
  }

  public var text: String? {
    return nil
  }
}

/// File data stored in Cloud Storage for Firebase, referenced by URI.
///
/// > Note: Supported media types depends on the model; see [media requirements
/// > ](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/send-multimodal-prompts#media_requirements)
/// > for details.
///
/// - Parameters:
///   - mimetype: The IANA standard MIME type of the uploaded file, for example, `"image/jpeg"`
///     or `"video/mp4"`; see [media requirements
///     ](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/send-multimodal-prompts#media_requirements)
///     for supported values.
///   - uri: The `"gs://"`-prefixed URI of the file in Cloud Storage for Firebase, for example,
///     `"gs://bucket-name/path/image.jpg"`.
@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public struct FileDataPart: ModelContent.Part {
  public let uri: String
  public let mimeType: String

  public init(uri: String, mimeType: String) {
    self.uri = uri
    self.mimeType = mimeType
  }

  public var text: String? {
    return nil
  }
}

/// A predicted function call returned from the model.
@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension FunctionCall: ModelContent.Part {
  public var text: String? {
    return nil
  }
}

/// A response to a function call.
@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension FunctionResponse: ModelContent.Part {
  public var text: String? {
    return nil
  }
}

@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension [any ModelContent.Part]: Equatable {
  public static func == (lhs: [any ModelContent.Part], rhs: [any ModelContent.Part]) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }

    // TODO: Implement me
    return true
  }
}

/// A type describing data in media formats interpretable by an AI model. Each generative AI
/// request or response contains an `Array` of ``ModelContent``s, and each ``ModelContent`` value
/// may comprise multiple heterogeneous ``ModelContent/Part``s.
@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
public struct ModelContent: Equatable, Sendable {
  public static func == (lhs: ModelContent, rhs: ModelContent) -> Bool {
    // TODO:
    lhs.role == rhs.role && lhs.parts == rhs.parts
  }

  /// A discrete piece of data in a media format interpretable by an AI model. Within a single value
  /// of ``Part``, different data types may not mix.
  public protocol Part: Codable, Equatable, Sendable {
    /// Returns the text contents of this ``Part``, if it contains text.
    var text: String? { get }
  }

  /// The role of the entity creating the ``ModelContent``. For user-generated client requests,
  /// for example, the role is `user`.
  public let role: String?

  /// The data parts comprising this ``ModelContent`` value.
  public let parts: [any Part]

  /// Creates a new value from any data or `Array` of data interpretable as a
  /// ``Part``. See ``ThrowingPartsRepresentable`` for types that can be interpreted as `Part`s.
  public init(role: String? = "user", parts: some ThrowingPartsRepresentable) throws {
    self.role = role
    try self.parts = parts.tryPartsValue()
  }

  /// Creates a new value from any data or `Array` of data interpretable as a
  /// ``Part``. See ``ThrowingPartsRepresentable`` for types that can be interpreted as `Part`s.
  public init(role: String? = "user", parts: some PartsRepresentable) {
    self.role = role
    self.parts = parts.partsValue
  }

  /// Creates a new value from a list of ``Part``s.
  public init(role: String? = "user", parts: [any Part]) {
    self.role = role
    self.parts = parts
  }

  /// Creates a new value from any data interpretable as a ``Part``. See
  /// ``ThrowingPartsRepresentable``
  /// for types that can be interpreted as `Part`s.
  public init(role: String? = "user", _ parts: any ThrowingPartsRepresentable...) throws {
    let content = try parts.flatMap { try $0.tryPartsValue() }
    self.init(role: role, parts: content)
  }

  /// Creates a new value from any data interpretable as a ``Part``. See
  /// ``ThrowingPartsRepresentable``
  /// for types that can be interpreted as `Part`s.
  public init(role: String? = "user", _ parts: [PartsRepresentable]) {
    let content = parts.flatMap { $0.partsValue }
    self.init(role: role, parts: content)
  }
}

// MARK: Codable Conformances

@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
extension ModelContent: Codable {
  enum CodingKeys: CodingKey {
    case role
    case parts
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    role = try container.decodeIfPresent(String.self, forKey: .role)
    let internalParts = try container.decode([InternalPart].self, forKey: .parts)
    parts = internalParts.map { $0.partValue }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(role, forKey: .role)
    let internalParts = parts.map { InternalPart(partValue: $0) }
    try container.encode(internalParts, forKey: .parts)
  }
}

@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
struct InternalPart: Codable {
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    text = try container.decodeIfPresent(String.self, forKey: .text)
    inlineData = try container.decodeIfPresent(InlineDataPart.self, forKey: .inlineData)
    fileData = try container.decodeIfPresent(FileDataPart.self, forKey: .fileData)
    functionCall = try container.decodeIfPresent(FunctionCall.self, forKey: .functionCall)
    functionResponse = try container
      .decodeIfPresent(FunctionResponse.self, forKey: .functionResponse)
  }

  enum CodingKeys: CodingKey {
    case text
    case inlineData
    case fileData
    case functionCall
    case functionResponse
  }

  let text: String?

  let inlineData: InlineDataPart?

  let fileData: FileDataPart?

  let functionCall: FunctionCall?

  let functionResponse: FunctionResponse?

  var partValue: any ModelContent.Part {
    if let text {
      return TextPart(text: text)
    } else if let inlineData {
      return inlineData
    } else if let functionCall {
      return functionCall
    } else if let functionResponse {
      return functionResponse
    }
    fatalError()
  }

  init(partValue: any ModelContent.Part) {
    switch partValue {
    case let text as TextPart:
      self.text = text.textValue
      inlineData = nil
      fileData = nil
      functionCall = nil
      functionResponse = nil
    case let inlineData as InlineDataPart:
      text = nil
      self.inlineData = inlineData
      fileData = nil
      functionCall = nil
      functionResponse = nil
    case let fileData as FileDataPart:
      text = nil
      inlineData = nil
      self.fileData = fileData
      functionCall = nil
      functionResponse = nil
    case let functionCall as FunctionCall:
      text = nil
      inlineData = nil
      fileData = nil
      self.functionCall = functionCall
      functionResponse = nil
    case let functionResponse as FunctionResponse:
      text = nil
      inlineData = nil
      fileData = nil
      functionCall = nil
      self.functionResponse = functionResponse
    default:
      fatalError()
    }
  }
}
