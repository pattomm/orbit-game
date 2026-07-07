// Generates the ORBIT app icon (1024x1024, opaque, no alpha channel).
// Usage: swift GenerateIcon.swift /path/to/AppIcon.png
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("no context") }

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}
let c = CGPoint(x: 512, y: 512)

// fondo: radial tinta profunda
let bg = CGGradient(colorsSpace: space, colors: [rgba(15, 18, 44), rgba(7, 11, 24)] as CFArray, locations: [0, 1])!
ctx.setFillColor(rgba(7, 11, 24))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: 512, y: 580), startRadius: 0, endCenter: c, endRadius: 780, options: [])

// estrellas de fondo (deterministas)
srand48(7)
for _ in 0..<90 {
    let x = drand48() * 1024, y = drand48() * 1024
    let r = drand48() * 2.4 + 0.8, a = drand48() * 0.45 + 0.12
    ctx.setFillColor(rgba(207, 228, 255, a))
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
}

// anillo orbital punteado
ctx.setStrokeColor(rgba(255, 255, 255, 0.42))
ctx.setLineWidth(14)
ctx.setLineCap(.round)
ctx.setLineDash(phase: 0, lengths: [24, 46])
ctx.strokeEllipse(in: CGRect(x: 512 - 342, y: 512 - 342, width: 684, height: 684))
ctx.setLineDash(phase: 0, lengths: [])

// brillo del planeta
let glow = CGGradient(colorsSpace: space, colors: [rgba(255, 201, 77, 0.5), rgba(255, 201, 77, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: c, startRadius: 0, endCenter: c, endRadius: 430, options: [])

// planeta dorado + luz
ctx.setFillColor(rgba(255, 201, 77))
ctx.fillEllipse(in: CGRect(x: 512 - 220, y: 512 - 220, width: 440, height: 440))
ctx.setFillColor(rgba(255, 236, 180, 0.55))
ctx.fillEllipse(in: CGRect(x: 512 - 150, y: 512 + 10, width: 200, height: 200))

// estela del cometa sobre el anillo
let ang: CGFloat = .pi * 0.24
let px = 512 + cos(ang) * 342, py = 512 + sin(ang) * 342
ctx.setStrokeColor(rgba(107, 247, 255, 0.85))
ctx.setLineWidth(30)
ctx.setLineCap(.round)
ctx.addArc(center: c, radius: 342, startAngle: ang - 0.5, endAngle: ang, clockwise: false)
ctx.strokePath()

// cometa
let cg = CGGradient(colorsSpace: space, colors: [rgba(107, 247, 255, 0.95), rgba(107, 247, 255, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(cg, startCenter: CGPoint(x: px, y: py), startRadius: 0, endCenter: CGPoint(x: px, y: py), endRadius: 130, options: [])
ctx.setFillColor(rgba(255, 255, 255))
ctx.fillEllipse(in: CGRect(x: px - 48, y: py - 48, width: 96, height: 96))

let img = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("write failed") }
print("icon → \(out.path)")
