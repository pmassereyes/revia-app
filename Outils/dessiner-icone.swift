//
//  dessiner-icone.swift
//  RevIA
//
//  Usage : swiftc -o /tmp/dessiner-icone Outils/dessiner-icone.swift && /tmp/dessiner-icone RevIA/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//

// Icône provisoire de RevIA : trois cartes empilées (les boîtes de Leitner) et une coche, sur un dégradé.
// Dessinée en Core Graphics, sans symbole SF (interdit dans une icône d'app). Image opaque, comme l'exige l'App Store.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let taille = 1024
let espace = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: taille, height: taille, bitsPerComponent: 8, bytesPerRow: 0,
                    space: espace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let bleu = CGColor(srgbRed: 0.16, green: 0.40, blue: 0.98, alpha: 1)
let violet = CGColor(srgbRed: 0.47, green: 0.25, blue: 0.96, alpha: 1)
let degrade = CGGradient(colorsSpace: espace, colors: [bleu, violet] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(degrade, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])

func carte(centre: CGPoint, angle: CGFloat, opacite: CGFloat) {
    ctx.saveGState()
    ctx.translateBy(x: centre.x, y: centre.y)
    ctx.rotate(by: angle)
    let chemin = CGPath(roundedRect: CGRect(x: -235, y: -300, width: 470, height: 600), cornerWidth: 64, cornerHeight: 64, transform: nil)
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 44, color: CGColor(gray: 0, alpha: 0.22))
    ctx.setFillColor(CGColor(gray: 1, alpha: opacite))
    ctx.addPath(chemin)
    ctx.fillPath()
    ctx.restoreGState()
}
carte(centre: CGPoint(x: 572, y: 540), angle: -0.22, opacite: 0.32)
carte(centre: CGPoint(x: 542, y: 522), angle: -0.11, opacite: 0.58)
carte(centre: CGPoint(x: 512, y: 504), angle: 0, opacite: 1)

ctx.setStrokeColor(bleu)
ctx.setLineWidth(72)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: 390, y: 512))
ctx.addLine(to: CGPoint(x: 480, y: 418))
ctx.addLine(to: CGPoint(x: 648, y: 616))
ctx.strokePath()

let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("écriture impossible") }
