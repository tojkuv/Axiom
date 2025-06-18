import SwiftUI
import HotReloadProtocol

public final class SwiftUIModifierApplicator {
    
    private let configuration: SwiftUIModifierConfiguration
    
    public init(configuration: SwiftUIModifierConfiguration = SwiftUIModifierConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Modifier Application
    
    public func applyModifiers(
        to view: AnyView,
        modifiers: [SwiftUIModifierJSON],
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        var modifiedView = view
        
        for modifier in modifiers {
            modifiedView = try applyModifier(modifier, to: modifiedView, stateManager: stateManager)
        }
        
        return modifiedView
    }
    
    private func applyModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let modifierName = modifier.name.lowercased()
        
        switch modifierName {
        // Frame and Layout
        case "frame":
            return try applyFrameModifier(modifier, to: view, stateManager: stateManager)
        case "padding":
            return try applyPaddingModifier(modifier, to: view, stateManager: stateManager)
        case "offset":
            return try applyOffsetModifier(modifier, to: view, stateManager: stateManager)
        case "position":
            return try applyPositionModifier(modifier, to: view, stateManager: stateManager)
            
        // Appearance
        case "background":
            return try applyBackgroundModifier(modifier, to: view, stateManager: stateManager)
        case "foregroundcolor", "foregroundstyle":
            return try applyForegroundColorModifier(modifier, to: view, stateManager: stateManager)
        case "opacity":
            return try applyOpacityModifier(modifier, to: view, stateManager: stateManager)
        case "shadow":
            return try applyShadowModifier(modifier, to: view, stateManager: stateManager)
        case "border":
            return try applyBorderModifier(modifier, to: view, stateManager: stateManager)
        case "overlay":
            return try applyOverlayModifier(modifier, to: view, stateManager: stateManager)
            
        // Transforms
        case "scaleeffect":
            return try applyScaleEffectModifier(modifier, to: view, stateManager: stateManager)
        case "rotationeffect":
            return try applyRotationEffectModifier(modifier, to: view, stateManager: stateManager)
        case "rotation3deffect":
            return try applyRotation3DEffectModifier(modifier, to: view, stateManager: stateManager)
            
        // Shape and Clipping
        case "cornerradius":
            return try applyCornerRadiusModifier(modifier, to: view, stateManager: stateManager)
        case "clipshape":
            return try applyClipShapeModifier(modifier, to: view, stateManager: stateManager)
        case "clipped":
            return AnyView(view.clipped())
        case "mask":
            return try applyMaskModifier(modifier, to: view, stateManager: stateManager)
            
        // Typography
        case "font":
            return try applyFontModifier(modifier, to: view, stateManager: stateManager)
        case "fontweight":
            return try applyFontWeightModifier(modifier, to: view, stateManager: stateManager)
        case "fontdesign":
            return try applyFontDesignModifier(modifier, to: view, stateManager: stateManager)
        case "bold":
            if #available(macOS 13.0, iOS 16.0, *) {
                return AnyView(view.bold())
            } else {
                return view // Fallback on older versions
            }
        case "italic":
            if #available(macOS 13.0, iOS 16.0, *) {
                return AnyView(view.italic())
            } else {
                return view // Fallback to original view on older versions
            }
        case "underline":
            return try applyUnderlineModifier(modifier, to: view, stateManager: stateManager)
        case "strikethrough":
            return try applyStrikethroughModifier(modifier, to: view, stateManager: stateManager)
            
        // Interaction
        case "disabled":
            return try applyDisabledModifier(modifier, to: view, stateManager: stateManager)
        case "ontapgesture":
            return try applyOnTapGestureModifier(modifier, to: view, stateManager: stateManager)
        case "onlongpressgesture":
            return try applyOnLongPressGestureModifier(modifier, to: view, stateManager: stateManager)
        case "gesture":
            return try applyGestureModifier(modifier, to: view, stateManager: stateManager)
        case "allowshittesting":
            return try applyAllowsHitTestingModifier(modifier, to: view, stateManager: stateManager)
            
        // Layout Priority and Ordering
        case "zindex":
            return try applyZIndexModifier(modifier, to: view, stateManager: stateManager)
        case "layoutpriority":
            return try applyLayoutPriorityModifier(modifier, to: view, stateManager: stateManager)
            
        // Visibility
        case "hidden":
            return try applyHiddenModifier(modifier, to: view, stateManager: stateManager)
            
        // Accessibility
        case "accessibilitylabel":
            return try applyAccessibilityLabelModifier(modifier, to: view, stateManager: stateManager)
        case "accessibilityhint":
            return try applyAccessibilityHintModifier(modifier, to: view, stateManager: stateManager)
        case "accessibilityvalue":
            return try applyAccessibilityValueModifier(modifier, to: view, stateManager: stateManager)
            
        // Lifecycle
        case "onappear":
            return try applyOnAppearModifier(modifier, to: view, stateManager: stateManager)
        case "ondisappear":
            return try applyOnDisappearModifier(modifier, to: view, stateManager: stateManager)
        case "onchange":
            return try applyOnChangeModifier(modifier, to: view, stateManager: stateManager)
            
        // Animation
        case "animation":
            return try applyAnimationModifier(modifier, to: view, stateManager: stateManager)
        case "transition":
            return try applyTransitionModifier(modifier, to: view, stateManager: stateManager)
            
        default:
            if configuration.allowUnknownModifiers {
                return view // Return unchanged for unknown modifiers
            } else {
                throw SwiftUIModifierError.unsupportedModifier(modifier.name)
            }
        }
    }
    
    // MARK: - Frame and Layout Modifiers
    
    private func applyFrameModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let width = extractOptionalCGFloat(from: modifier.parameters, key: "width")
        let height = extractOptionalCGFloat(from: modifier.parameters, key: "height")
        let minWidth = extractOptionalCGFloat(from: modifier.parameters, key: "minWidth")
        let maxWidth = extractOptionalCGFloat(from: modifier.parameters, key: "maxWidth")
        let minHeight = extractOptionalCGFloat(from: modifier.parameters, key: "minHeight")
        let maxHeight = extractOptionalCGFloat(from: modifier.parameters, key: "maxHeight")
        let alignment = extractAlignment(from: modifier.parameters) ?? .center
        
        return AnyView(
            view.frame(
                width: width,
                height: height,
                alignment: alignment
            )
            .frame(
                minWidth: minWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
                maxHeight: maxHeight
            )
        )
    }
    
    private func applyPaddingModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        if let allPadding = extractCGFloat(from: modifier.parameters, key: "all") {
            return AnyView(view.padding(allPadding))
        }
        
        if let edgeInsets = extractEdgeInsets(from: modifier.parameters) {
            return AnyView(view.padding(edgeInsets))
        }
        
        // Default padding
        return AnyView(view.padding())
    }
    
    private func applyOffsetModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let x = extractCGFloat(from: modifier.parameters, key: "x") ?? 0
        let y = extractCGFloat(from: modifier.parameters, key: "y") ?? 0
        
        return AnyView(view.offset(x: x, y: y))
    }
    
    private func applyPositionModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let x = extractCGFloat(from: modifier.parameters, key: "x") ?? 0
        let y = extractCGFloat(from: modifier.parameters, key: "y") ?? 0
        
        return AnyView(view.position(x: x, y: y))
    }
    
    // MARK: - Appearance Modifiers
    
    private func applyBackgroundModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        if let color = extractColor(from: modifier.parameters, key: "color") {
            return AnyView(view.background(color))
        }
        
        // Default background
        return AnyView(view.background(Color.clear))
    }
    
    private func applyForegroundColorModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        guard let color = extractColor(from: modifier.parameters, key: "color") else {
            return view
        }
        
        return AnyView(view.foregroundColor(color))
    }
    
    private func applyOpacityModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let opacity = extractDouble(from: modifier.parameters, key: "opacity") ?? 1.0
        return AnyView(view.opacity(opacity))
    }
    
    private func applyShadowModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let color = extractColor(from: modifier.parameters, key: "color") ?? Color.black
        let radius = extractCGFloat(from: modifier.parameters, key: "radius") ?? 10
        let x = extractCGFloat(from: modifier.parameters, key: "x") ?? 0
        let y = extractCGFloat(from: modifier.parameters, key: "y") ?? 0
        
        return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
    }
    
    private func applyBorderModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let color = extractColor(from: modifier.parameters, key: "color") ?? Color.black
        let width = extractCGFloat(from: modifier.parameters, key: "width") ?? 1
        
        return AnyView(view.border(color, width: width))
    }
    
    private func applyOverlayModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        // For simplicity, apply a basic overlay
        return AnyView(view.overlay(Rectangle().stroke(Color.gray, lineWidth: 1)))
    }
    
    // MARK: - Transform Modifiers
    
    private func applyScaleEffectModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        if let scale = extractCGFloat(from: modifier.parameters, key: "scale") {
            return AnyView(view.scaleEffect(scale))
        }
        
        let x = extractCGFloat(from: modifier.parameters, key: "x") ?? 1
        let y = extractCGFloat(from: modifier.parameters, key: "y") ?? 1
        
        return AnyView(view.scaleEffect(x: x, y: y))
    }
    
    private func applyRotationEffectModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let angle = extractDouble(from: modifier.parameters, key: "angle") ?? 0
        return AnyView(view.rotationEffect(.degrees(angle)))
    }
    
    private func applyRotation3DEffectModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let angle = extractDouble(from: modifier.parameters, key: "angle") ?? 0
        let x = extractDouble(from: modifier.parameters, key: "x") ?? 0
        let y = extractDouble(from: modifier.parameters, key: "y") ?? 0
        let z = extractDouble(from: modifier.parameters, key: "z") ?? 1
        
        return AnyView(view.rotation3DEffect(.degrees(angle), axis: (x: x, y: y, z: z)))
    }
    
    // MARK: - Shape and Clipping Modifiers
    
    private func applyCornerRadiusModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let radius = extractCGFloat(from: modifier.parameters, key: "radius") ?? 8
        return AnyView(view.cornerRadius(radius))
    }
    
    private func applyClipShapeModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let shape = extractString(from: modifier.parameters, key: "shape") ?? "rectangle"
        
        switch shape.lowercased() {
        case "circle":
            return AnyView(view.clipShape(Circle()))
        case "capsule":
            return AnyView(view.clipShape(Capsule()))
        case "ellipse":
            return AnyView(view.clipShape(Ellipse()))
        default:
            let cornerRadius = extractCGFloat(from: modifier.parameters, key: "cornerRadius") ?? 0
            return AnyView(view.clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
        }
    }
    
    private func applyMaskModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        // Basic mask implementation
        return AnyView(view.mask(Rectangle()))
    }
    
    // MARK: - Typography Modifiers
    
    private func applyFontModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        if let fontValue = extractFont(from: modifier.parameters) {
            return AnyView(view.font(fontValue))
        }
        
        return view
    }
    
    private func applyFontWeightModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        guard let weightString = extractString(from: modifier.parameters, key: "weight") else {
            return view
        }
        
        if #available(macOS 13.0, iOS 16.0, *) {
            let weight = fontWeightFromString(weightString)
            return AnyView(view.fontWeight(weight))
        } else {
            return view // Fallback on older versions
        }
    }
    
    private func applyFontDesignModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        guard let designString = extractString(from: modifier.parameters, key: "design") else {
            return view
        }
        
        if #available(macOS 13.0, iOS 16.0, *) {
            let design = fontDesignFromString(designString)
            return AnyView(view.fontDesign(design))
        } else {
            return view // Fallback on older versions
        }
    }
    
    private func applyUnderlineModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let isActive = extractBool(from: modifier.parameters, key: "active") ?? true
        let color = extractColor(from: modifier.parameters, key: "color")
        
        if #available(macOS 13.0, iOS 16.0, *) {
            return AnyView(view.underline(isActive, color: color))
        } else {
            return view // Fallback on older versions
        }
    }
    
    private func applyStrikethroughModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let isActive = extractBool(from: modifier.parameters, key: "active") ?? true
        let color = extractColor(from: modifier.parameters, key: "color")
        
        if #available(macOS 13.0, iOS 16.0, *) {
            return AnyView(view.strikethrough(isActive, color: color))
        } else {
            return view // Fallback on older versions
        }
    }
    
    // MARK: - Interaction Modifiers
    
    private func applyDisabledModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let disabled = extractBool(from: modifier.parameters, key: "disabled") ?? true
        return AnyView(view.disabled(disabled))
    }
    
    private func applyOnTapGestureModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let count = extractInt(from: modifier.parameters, key: "count") ?? 1
        
        return AnyView(
            view.onTapGesture(count: count) { [weak self] in
                // Handle tap action
                self?.handleTapAction(modifier.parameters, stateManager: stateManager)
            }
        )
    }
    
    private func applyOnLongPressGestureModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let minimumDuration = extractDouble(from: modifier.parameters, key: "minimumDuration") ?? 0.5
        
        return AnyView(
            view.onLongPressGesture(minimumDuration: minimumDuration) { [weak self] in
                // Handle long press action
                self?.handleLongPressAction(modifier.parameters, stateManager: stateManager)
            }
        )
    }
    
    private func applyGestureModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        // Basic gesture implementation
        return view
    }
    
    private func applyAllowsHitTestingModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let allowsHitTesting = extractBool(from: modifier.parameters, key: "allowsHitTesting") ?? true
        return AnyView(view.allowsHitTesting(allowsHitTesting))
    }
    
    // MARK: - Layout Priority and Ordering Modifiers
    
    private func applyZIndexModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let zIndex = extractDouble(from: modifier.parameters, key: "zIndex") ?? 0
        return AnyView(view.zIndex(zIndex))
    }
    
    private func applyLayoutPriorityModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let priority = extractDouble(from: modifier.parameters, key: "priority") ?? 0
        return AnyView(view.layoutPriority(priority))
    }
    
    // MARK: - Visibility Modifiers
    
    private func applyHiddenModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let hidden = extractBool(from: modifier.parameters, key: "hidden") ?? true
        
        if hidden {
            return AnyView(view.hidden())
        } else {
            return view
        }
    }
    
    // MARK: - Accessibility Modifiers
    
    private func applyAccessibilityLabelModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        guard let label = extractString(from: modifier.parameters, key: "label") else {
            return view
        }
        
        return AnyView(view.accessibilityLabel(label))
    }
    
    private func applyAccessibilityHintModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        guard let hint = extractString(from: modifier.parameters, key: "hint") else {
            return view
        }
        
        return AnyView(view.accessibilityHint(hint))
    }
    
    private func applyAccessibilityValueModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        guard let value = extractString(from: modifier.parameters, key: "value") else {
            return view
        }
        
        return AnyView(view.accessibilityValue(value))
    }
    
    // MARK: - Lifecycle Modifiers
    
    private func applyOnAppearModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        return AnyView(
            view.onAppear { [weak self] in
                self?.handleAppearAction(modifier.parameters, stateManager: stateManager)
            }
        )
    }
    
    private func applyOnDisappearModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        return AnyView(
            view.onDisappear { [weak self] in
                self?.handleDisappearAction(modifier.parameters, stateManager: stateManager)
            }
        )
    }
    
    private func applyOnChangeModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        // OnChange modifier implementation would require specific value watching
        return view
    }
    
    // MARK: - Animation Modifiers
    
    private func applyAnimationModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        // Basic animation implementation
        return AnyView(view.animation(.default, value: UUID()))
    }
    
    private func applyTransitionModifier(
        _ modifier: SwiftUIModifierJSON,
        to view: AnyView,
        stateManager: SwiftUIStateManager
    ) throws -> AnyView {
        let transitionType = extractString(from: modifier.parameters, key: "type") ?? "opacity"
        
        let transition: AnyTransition
        switch transitionType.lowercased() {
        case "slide":
            transition = .slide
        case "scale":
            transition = .scale
        case "move":
            transition = .move(edge: .leading)
        default:
            transition = .opacity
        }
        
        return AnyView(view.transition(transition))
    }
    
    // MARK: - Action Handlers
    
    private func handleTapAction(_ parameters: [String: PropertyValue], stateManager: SwiftUIStateManager) {
        // Handle tap action based on parameters
        if let actionType = extractString(from: parameters, key: "action") {
            print("Tap action: \(actionType)")
        }
    }
    
    private func handleLongPressAction(_ parameters: [String: PropertyValue], stateManager: SwiftUIStateManager) {
        // Handle long press action based on parameters
        if let actionType = extractString(from: parameters, key: "action") {
            print("Long press action: \(actionType)")
        }
    }
    
    private func handleAppearAction(_ parameters: [String: PropertyValue], stateManager: SwiftUIStateManager) {
        // Handle appear action based on parameters
        if let actionType = extractString(from: parameters, key: "action") {
            print("Appear action: \(actionType)")
        }
    }
    
    private func handleDisappearAction(_ parameters: [String: PropertyValue], stateManager: SwiftUIStateManager) {
        // Handle disappear action based on parameters
        if let actionType = extractString(from: parameters, key: "action") {
            print("Disappear action: \(actionType)")
        }
    }
}

// MARK: - Parameter Extraction Helpers (continued in next file)
// Due to length, will create SwiftUIModifierHelpers.swift