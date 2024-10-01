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

import FirebaseCore
import FirebaseVertexAI
import XCTest
#if canImport(AppKit)
  import AppKit // For NSImage extensions.
#elseif canImport(UIKit)
  import UIKit // For UIImage extensions.
#endif

@available(iOS 15.0, macOS 11.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
final class VertexAIAPITests: XCTestCase {
  func codeSamples() async throws {
    let app = FirebaseApp.app()
    let config = GenerationConfig(temperature: 0.2,
                                  topP: 0.1,
                                  topK: 16,
                                  candidateCount: 4,
                                  maxOutputTokens: 256,
                                  stopSequences: ["..."],
                                  responseMIMEType: "text/plain")
    let filters = [SafetySetting(harmCategory: .dangerousContent, threshold: .blockOnlyHigh)]
    let systemInstruction = ModelContent(
      role: "system",
      parts: [TextPart(text: "Talk like a pirate.")]
    )

    // Instantiate Vertex AI SDK - Default App
    let vertexAI = VertexAI.vertexAI()
    let _ = VertexAI.vertexAI(location: "my-location")

    // Instantiate Vertex AI SDK - Custom App
    let _ = VertexAI.vertexAI(app: app!)
    let _ = VertexAI.vertexAI(app: app!, location: "my-location")

    // Permutations without optional arguments.

    let _ = vertexAI.generativeModel(modelName: "gemini-1.0-pro")

    let _ = vertexAI.generativeModel(
      modelName: "gemini-1.0-pro",
      safetySettings: filters
    )

    let _ = vertexAI.generativeModel(
      modelName: "gemini-1.0-pro",
      generationConfig: config
    )

    let _ = vertexAI.generativeModel(
      modelName: "gemini-1.0-pro",
      systemInstruction: systemInstruction
    )

    // All arguments passed.
    let genAI = vertexAI.generativeModel(
      modelName: "gemini-1.0-pro",
      generationConfig: config, // Optional
      safetySettings: filters, // Optional
      systemInstruction: systemInstruction // Optional
    )

    // Full Typed Usage
    let pngData = Data() // ....
    let contents = [ModelContent(role: "user",
                                 parts: [
                                   TextPart(text: "Is it a cat?"),
                                   InlineDataPart(data: pngData, mimeType: "image/png"),
                                 ])]

    do {
      let response = try await genAI.generateContent(contents)
      print(response.text ?? "Couldn't get text... check status")
    } catch {
      print("Error generating content: \(error)")
    }

    // Content input combinations.
    let _ = try await genAI.generateContent("Constant String")
    let str = "String Variable"
    let _ = try await genAI.generateContent(str)
    let _ = try await genAI.generateContent([str])
    let _ = try await genAI.generateContent(str, "abc", "def")
//    let _ = try await genAI.generateContent(
//      str,
//      // TODO: Argument type 'FileDataPart' does not conform to expected type
//      /'ThrowingPartsRepresentable'
//      FileDataPart(uri: "gs://test-bucket/image.jpg", mimeType: "image/jpeg")
//    )
    #if canImport(UIKit)
      _ = try await genAI.generateContent(UIImage())
      _ = try await genAI.generateContent([UIImage()])
      // TODO: Type of expression is ambiguous without a type annotation
//      _ = try await genAI
//      .generateContent([str, UIImage(), TextPart(text:str)])
      _ = try await genAI.generateContent(str, UIImage(), "def", UIImage())
      _ = try await genAI.generateContent([str, UIImage(), "def", UIImage()])
      _ = try await genAI.generateContent([ModelContent("def", UIImage()),
                                           ModelContent("def", UIImage())])
    #elseif canImport(AppKit)
      _ = try await genAI.generateContent(NSImage())
      _ = try await genAI.generateContent([NSImage()])
      _ = try await genAI.generateContent(str, NSImage(), "def", NSImage())
      _ = try await genAI.generateContent([str, NSImage(), "def", NSImage()])
    #endif

    // ThrowingPartsRepresentable combinations.
    let _ = ModelContent(parts: [TextPart(text: str)])
    let _ = ModelContent(role: "model", parts: [TextPart(text: str)])
    let _ = ModelContent(parts: "Constant String")
    let _ = ModelContent(parts: str)
    // Note: This requires the `try` for some reason. Casting to explicit [PartsRepresentable] also
    // doesn't work.
    let _ = try ModelContent(parts: [str])
    // Note: without `as [any ThrowingPartsRepresentable]` this will fail to compile with "Cannot
    // convert value of type 'String' to expected element type
    // 'Array<ModelContent.Part>.ArrayLiteralElement'. Not sure if there's a way we can get it to
    // work.

    // TODO: Type of expression is ambiguous without a type annotation
    //  let _ = try ModelContent(parts: [str, InlineDataPart(
    //    data: Data(),
    //    mimeType: "foo"
    //  )] as [any ThrowingPartsRepresentable])
    #if canImport(UIKit)
      _ = try ModelContent(role: "user", parts: UIImage())
      _ = try ModelContent(role: "user", parts: [UIImage()])
      // Note: without `as [any ThrowingPartsRepresentable]` this will fail to compile with "Cannot
      // convert value of type `[Any]` to expected type `[any ThrowingPartsRepresentable]`. Not
      // sure if there's a way we can get it to work.
      _ = try ModelContent(parts: [str, UIImage()] as [any ThrowingPartsRepresentable])
      // Alternatively, you can explicitly declare the type in a variable and pass it in.
      let representable2: [any ThrowingPartsRepresentable] = [str, UIImage()]
      _ = try ModelContent(parts: representable2)
    // TODO: Type of expression is ambiguous without a type annotation
    //  _ = try ModelContent(parts: [str, UIImage(),
    //                               TextPart(text: str)] as [any
    //                               ThrowingPartsRepresentable])
    #elseif canImport(AppKit)
      _ = try ModelContent(role: "user", parts: NSImage())
      _ = try ModelContent(role: "user", parts: [NSImage()])
      // Note: without `as [any ThrowingPartsRepresentable]` this will fail to compile with "Cannot
      // convert value of type `[Any]` to expected type `[any ThrowingPartsRepresentable]`. Not sure
      // if there's a way we can get it to work.
      _ = try ModelContent(parts: [str, NSImage()] as [any ThrowingPartsRepresentable])
      // Alternatively, you can explicitly declare the type in a variable and pass it in.
      let representable2: [any ThrowingPartsRepresentable] = [str, NSImage()]
      _ = try ModelContent(parts: representable2)
      _ =
        try ModelContent(parts: [str, NSImage(),
                                 ModelContent.Part.text(str)] as [any ThrowingPartsRepresentable])
    #endif

    // countTokens API
    let _: CountTokensResponse = try await genAI.countTokens("What color is the Sky?")
    #if canImport(UIKit)
      let _: CountTokensResponse = try await genAI.countTokens("What color is the Sky?",
                                                               UIImage())
      let _: CountTokensResponse = try await genAI.countTokens([
        ModelContent("What color is the Sky?", UIImage()),
        ModelContent(UIImage(), "What color is the Sky?", UIImage()),
      ])
    #endif

    // Chat
    _ = genAI.startChat()
    _ = genAI.startChat(history: [ModelContent(parts: "abc")])
  }

  // Public API tests for GenerateContentResponse.
  func generateContentResponseAPI() {
    let response = GenerateContentResponse(candidates: [])

    let _: [CandidateResponse] = response.candidates
    let _: PromptFeedback? = response.promptFeedback

    // Usage Metadata
    guard let usageMetadata = response.usageMetadata else { fatalError() }
    let _: Int = usageMetadata.promptTokenCount
    let _: Int = usageMetadata.candidatesTokenCount
    let _: Int = usageMetadata.totalTokenCount

    // Computed Properties
    let _: String? = response.text
    let _: [FunctionCall] = response.functionCalls
  }

  // Result builder alternative

  /*
   let pngData = Data() // ....
   let contents = [GenAIContent(role: "user",
                                parts: [
                                 .text("Is it a cat?"),
                                 .png(pngData)
                                ])]

   // Turns into...

   let contents = GenAIContent {
     Role("user") {
       Text("Is this a cat?")
       Image(png: pngData)
     }
   }

   GenAIContent {
     ForEach(myInput) { input in
       Role(input.role) {
         input.contents
       }
     }
   }

   // Thoughts: this looks great from a code demo, but since I assume most content will be
   // user generated, the result builder may not be the best API.
   */
}
