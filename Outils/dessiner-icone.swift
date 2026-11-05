//
//  dessiner-icone.swift
//  RevIA
//
//  Usage : swiftc -o /tmp/dessiner-icone Outils/dessiner-icone.swift && /tmp/dessiner-icone RevIA/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//

// Icône de RevIA : avatar stylisé de l'auteur, pensif, la main au menton et le regard levé vers une bulle
// de pensée qui contient les cartes de révision. Dessinée en Core Graphics, sans symbole SF (interdit dans une icône d'app).
// Image opaque de 1024 px, comme l'exige l'App Store.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let taille = 1024
let espace = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: taille, height: taille, bitsPerComponent: 8, bytesPerRow: 0,
                    space: espace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func couleur(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let bleu = couleur(0x2966FA), violet = couleur(0x7840F5)
let fondClair = couleur(0xF4E8D6), fondFonce = couleur(0xE6D3B8), contourBulle = couleur(0xD8C2A2)
let peau = couleur(0xCC976D), peauOmbre = couleur(0xA8724D)
let cheveux = couleur(0x221A16), cheveuxReflet = couleur(0x3B2E27)
let haut = couleur(0x1C1C21), hautOmbre = couleur(0x2E2E35), manche = couleur(0x2A2A30)
let blanc = couleur(0xFFFFFF), encre = couleur(0x1E1A2E)

// Fond : dégradé beige
ctx.drawLinearGradient(CGGradient(colorsSpace: espace, colors: [fondClair, fondFonce] as CFArray, locations: [0, 1])!,
                       start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])

// Repère en haut à gauche, plus naturel pour dessiner un visage
ctx.translateBy(x: 0, y: 1024)
ctx.scaleBy(x: 1, y: -1)

func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
}

func trait(_ points: [CGPoint], _ c: CGColor, _ epaisseur: CGFloat, courbe: Bool = true) {
    ctx.setStrokeColor(c)
    ctx.setLineWidth(epaisseur)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: points[0])
    if courbe && points.count == 3 {
        ctx.addQuadCurve(to: points[2], control: points[1])
    } else {
        points.dropFirst().forEach { ctx.addLine(to: $0) }
    }
    ctx.strokePath()
}

func carte(_ cx: CGFloat, _ cy: CGFloat, _ l: CGFloat, _ h: CGFloat, _ angle: CGFloat, _ c: CGColor) {
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: angle)
    ctx.setFillColor(c)
    ctx.addPath(CGPath(roundedRect: CGRect(x: -l / 2, y: -h / 2, width: l, height: h), cornerWidth: l * 0.16, cornerHeight: l * 0.16, transform: nil))
    ctx.fillPath()
    ctx.restoreGState()
}

// Bulle de pensée, en haut à droite, avec les cartes de révision
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 30, color: couleur(0x000000, 0.18))
let cercles: [(CGFloat, CGFloat, CGFloat)] = [(705, 250, 90), (790, 195, 106), (868, 262, 86), (785, 305, 96), (705, 305, 68), (668, 418, 30), (632, 472, 17)]
ctx.beginTransparencyLayer(auxiliaryInfo: nil)
for (x, y, r) in cercles { ellipse(x, y, r + 5, r + 5, contourBulle) }
for (x, y, r) in cercles { ellipse(x, y, r, r, blanc) }
ctx.endTransparencyLayer()
ctx.restoreGState()
carte(808, 250, 112, 144, 0.22, couleur(0xB9C8FF))
carte(778, 258, 112, 144, 0, bleu)
trait([CGPoint(x: 748, y: 260), CGPoint(x: 770, y: 284), CGPoint(x: 810, y: 234)], blanc, 20, courbe: false)

// Buste
ctx.setFillColor(haut)
ctx.addPath(CGPath(roundedRect: CGRect(x: 110, y: 788, width: 600, height: 420), cornerWidth: 220, cornerHeight: 210, transform: nil))
ctx.fillPath()
ctx.setFillColor(hautOmbre)
ctx.addPath(CGPath(roundedRect: CGRect(x: 335, y: 788, width: 180, height: 62), cornerWidth: 31, cornerHeight: 35, transform: nil))
ctx.fillPath()

// Cou
ctx.setFillColor(peau)
ctx.fill(CGRect(x: 372, y: 700, width: 106, height: 125))
ellipse(425, 822, 53, 20, peau)
ellipse(425, 735, 62, 26, peauOmbre)

// Oreilles
ellipse(262, 590, 30, 44, peau)
ellipse(588, 590, 30, 44, peau)
ellipse(266, 592, 14, 24, peauOmbre)
ellipse(584, 592, 14, 24, peauOmbre)

// Tête
ellipse(425, 575, 162, 188, peau)

// Cheveux courts et frisés : une calotte, puis des boucles sur le pourtour
ellipse(425, 480, 170, 112, cheveux)
for i in 0..<17 {
    let angle = CGFloat.pi * (1.0 + CGFloat(i) / 16)
    let x = 425 + 158 * cos(angle), y = 482 + 104 * sin(angle)
    ellipse(x, y, 30, 30, cheveux)
}
ellipse(272, 535, 26, 46, cheveux)
ellipse(578, 535, 26, 46, cheveux)
for (x, y) in [(335, 410), (395, 385), (460, 383), (520, 405), (365, 445), (430, 418), (495, 442)] as [(CGFloat, CGFloat)] {
    ellipse(x, y, 12, 12, cheveuxReflet)
}
// Front : la peau redessine la ligne des cheveux
ellipse(425, 590, 148, 148, peau)
ellipse(425, 528, 128, 58, peau)

// Sourcils levés, l'un plus haut : l'air de réfléchir
trait([CGPoint(x: 335, y: 528), CGPoint(x: 370, y: 506), CGPoint(x: 405, y: 520)], cheveux, 16)
trait([CGPoint(x: 452, y: 508), CGPoint(x: 490, y: 480), CGPoint(x: 528, y: 500)], cheveux, 16)

// Yeux, regard vers le haut et vers la bulle
for (x, y) in [(372, 578), (488, 578)] as [(CGFloat, CGFloat)] {
    ellipse(x, y, 34, 32, blanc)
    ellipse(x + 10, y - 10, 18, 18, encre)
    ellipse(x + 15, y - 16, 6, 6, blanc)
}

// Nez et bouche, de côté, comme en pleine réflexion
trait([CGPoint(x: 432, y: 612), CGPoint(x: 448, y: 648), CGPoint(x: 424, y: 656)], peauOmbre, 10)
trait([CGPoint(x: 412, y: 702), CGPoint(x: 445, y: 708), CGPoint(x: 472, y: 694)], couleur(0x5A2E22), 11)

// Joues
ellipse(322, 645, 26, 16, couleur(0xE0705A, 0.28))
ellipse(530, 645, 26, 16, couleur(0xE0705A, 0.28))

// Main au menton : avant-bras dans sa manche, poing sous le menton
func forme(_ cx: CGFloat, _ cy: CGFloat, _ l: CGFloat, _ h: CGFloat, _ rayon: CGFloat, _ angle: CGFloat, _ c: CGColor, contour: CGColor? = nil) {
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: angle)
    let chemin = CGPath(roundedRect: CGRect(x: -l / 2, y: -h / 2, width: l, height: h), cornerWidth: rayon, cornerHeight: rayon, transform: nil)
    if let contour {
        ctx.setStrokeColor(contour)
        ctx.setLineWidth(10)
        ctx.addPath(chemin)
        ctx.strokePath()
    }
    ctx.setFillColor(c)
    ctx.addPath(chemin)
    ctx.fillPath()
    ctx.restoreGState()
}
// Pose du penseur : le menton repose sur le poing fermé, sans doigt tendu
forme(548, 965, 124, 250, 56, -0.42, manche)
forme(500, 872, 122, 40, 18, -0.42, hautOmbre)
forme(462, 806, 136, 104, 46, -0.08, peau, contour: peauOmbre)
// Doigts repliés : plis horizontaux sur la face du poing
for y in [790, 818, 845] as [CGFloat] {
    trait([CGPoint(x: 452, y: y), CGPoint(x: 486, y: y - 3), CGPoint(x: 516, y: y - 1)], peauOmbre, 6)
}
// Pouce, replié le long du bord gauche du poing
forme(414, 800, 36, 78, 18, 0.12, peau, contour: peauOmbre)
forme(414, 800, 36, 78, 18, 0.12, peau)

let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("écriture impossible") }
