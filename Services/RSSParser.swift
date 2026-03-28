//
//  RSSParser.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import Foundation

struct RSSItem {
    var guid: String = ""
    var title: String = ""
    var link: String = ""
    var pubDate: Date = Date()
    var categories: [String] = []
    var excerpt: String = ""
    var thumbnailURL: String = ""
    var audioURL: String = ""
    var audioDuration: String = ""
    var audioSize: Double = 0
    var author: String = ""
    var isPodcast: Bool { !audioURL.isEmpty }
}

// ✅ Resultado do parse inclui artwork do canal
struct RSSFeed {
    var channelArtworkURL: String = ""
    var items: [RSSItem] = []
}

final class TBXMLParser: NSObject, XMLParserDelegate {
    private var feed = RSSFeed()
    private var currentItem = RSSItem()
    private var isInsideItem = false
    private var isInsideImage = false       // <image> do canal
    private var isInsideMediaContent = false
    private var currentValue = ""
    private var currentAttributes: [String: String]?

    // ✅ Flag para não sobrescrever thumbnail de fonte confiável com fallback de HTML
    private var thumbnailFromReliableSource = false

    private let continuation: CheckedContinuation<RSSFeed, Error>

    init(continuation: CheckedContinuation<RSSFeed, Error>) {
        self.continuation = continuation
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentValue = ""

        switch elementName {
        case "item":
            isInsideItem = true
            currentItem = RSSItem()
            thumbnailFromReliableSource = false

        case "image":
            if !isInsideItem { isInsideImage = true }

        case "media:content":
            currentAttributes = attributeDict
            isInsideMediaContent = true

        case "media:thumbnail":
            // ✅ media:thumbnail pode aparecer sozinho (capa do artigo)
            // ou dentro de media:content (thumbnail do vídeo — ignoramos esse)
            if !isInsideMediaContent {
                currentAttributes = attributeDict
            }

        case "enclosure", "itunes:image":
            currentAttributes = attributeDict

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // ── Canal (fora de <item>) ────────────────────────────
        if !isInsideItem {
            switch elementName {
            case "image":
                isInsideImage = false
            case "url":
                if isInsideImage && !value.isEmpty {
                    feed.channelArtworkURL = value
                }
            case "itunes:image":
                if let href = currentAttributes?["href"], !href.isEmpty {
                    feed.channelArtworkURL = href
                }
            default:
                break
            }
            return
        }

        // ── Item ──────────────────────────────────────────────
        switch elementName {
        case "guid":
            currentItem.guid = value

        case "title":
            currentItem.title = value

        case "link":
            if value.hasPrefix("http") { currentItem.link = value }

        case "pubDate":
            currentItem.pubDate = DateParser.parse(value)

        case "category":
            currentItem.categories.append(value)

        case "description", "itunes:summary":
            if currentItem.excerpt.isEmpty {
                currentItem.excerpt = value
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Fallback HTML apenas se ainda não temos fonte confiável
            if !thumbnailFromReliableSource {
                if let url = extractImageURL(from: value) {
                    currentItem.thumbnailURL = url
                }
            }

        case "content:encoded":
            // Fallback HTML apenas se ainda não temos fonte confiável
            if !thumbnailFromReliableSource {
                if let url = extractImageURL(from: value) {
                    currentItem.thumbnailURL = url
                }
            }

        case "media:thumbnail":
            // ✅ media:thumbnail standalone (fora de media:content) = capa do artigo
            // Tem prioridade sobre qualquer fallback, mas perde para media:content com medium=image
            if !isInsideMediaContent, let url = currentAttributes?["url"], !url.isEmpty {
                if !thumbnailFromReliableSource {
                    currentItem.thumbnailURL = sanitizeThumbnailURL(url)
                    // Não marca como fonte confiável ainda — media:content image ainda pode vir
                }
            }

        case "media:content":
            // ✅ Só usa se for imagem (medium="image"), ignora vídeos (YouTube etc.)
            let medium = currentAttributes?["medium"] ?? ""
            let url = currentAttributes?["url"] ?? ""

            if medium == "image", !url.isEmpty {
                // Pega a imagem original sem sufixo de tamanho
                let cleanURL = url.replacingOccurrences(
                    of: "-\\d+x\\d+(\\.(?:jpg|jpeg|png|webp))",
                    with: "$1",
                    options: .regularExpression
                )
                // ✅ Apenas o primeiro media:content com medium=image é a capa
                if !thumbnailFromReliableSource {
                    currentItem.thumbnailURL = cleanURL
                    thumbnailFromReliableSource = true
                }
            }

            isInsideMediaContent = false

        case "itunes:image":
            if let href = currentAttributes?["href"], !href.isEmpty {
                currentItem.thumbnailURL = href
                thumbnailFromReliableSource = true
            }

        case "enclosure":
            if let url = currentAttributes?["url"] {
                currentItem.audioURL = url
                currentItem.audioSize = Double(currentAttributes?["length"] ?? "0") ?? 0
            }

        case "itunes:duration":
            currentItem.audioDuration = value

        case "dc:creator", "itunes:author":
            currentItem.author = value

        case "item":
            feed.items.append(currentItem)
            isInsideItem = false
            isInsideMediaContent = false

        default:
            break
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        continuation.resume(returning: feed)
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        continuation.resume(throwing: parseError)
    }

    // MARK: - Helpers

    /// Remove sufixos de tamanho WordPress (ex: -340x191) para obter a imagem original
    private func sanitizeThumbnailURL(_ url: String) -> String {
        url.replacingOccurrences(
            of: "-\\d+x\\d+(\\.(?:jpg|jpeg|png|webp))",
            with: "$1",
            options: .regularExpression
        )
    }

    private func extractImageURL(from html: String) -> String? {
        // 1. data-srcset 2x (maior qualidade disponível no HTML)
        let srcsetPattern = "data-srcset=\"([^\"]+)\\s+2x\""
        if let url = firstMatch(pattern: srcsetPattern, in: html) {
            return url
        }

        // 2. src do CDN do Tecnoblog — remove sufixo de tamanho
        let srcPattern = "src=\"(https://files\\.tecnoblog\\.net/[^\"]+)\""
        if let url = firstMatch(pattern: srcPattern, in: html) {
            return sanitizeThumbnailURL(url)
        }

        // 3. Fallback genérico — primeiro <img src> no HTML
        let genericPattern = "<img[^>]+src=\"([^\"]+)\""
        return firstMatch(pattern: genericPattern, in: html)
    }

    private func firstMatch(pattern: String, in html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(location: 0, length: html.utf16.count)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           let swiftRange = Range(match.range(at: 1), in: html) {
            return String(html[swiftRange])
        }
        return nil
    }
}

enum DateParser {
    static func parse(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.date(from: string) ?? Date()
    }
}
