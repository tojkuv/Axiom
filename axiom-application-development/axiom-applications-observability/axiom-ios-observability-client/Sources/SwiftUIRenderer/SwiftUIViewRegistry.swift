import Foundation

public struct SwiftUIViewRegistry {
    
    // MARK: - Supported Views
    
    public static let supportedViews: Set<String> = [
        // Text Views
        "text",
        
        // Layout Views
        "vstack",
        "hstack",
        "zstack",
        "lazyvstack",
        "lazyhstack",
        "group",
        
        // Interactive Views
        "button",
        "toggle",
        "slider",
        "textfield",
        "securefield",
        "picker",
        "stepper",
        "progressview",
        
        // Image Views
        "image",
        "asyncimage",
        
        // Shape Views
        "rectangle",
        "circle",
        "ellipse",
        "capsule",
        "roundedrectangle",
        "path",
        
        // Utility Views
        "spacer",
        "divider",
        "emptyview",
        "color",
        
        // List Views
        "list",
        "scrollview",
        "lazyvgrid",
        "lazyhgrid",
        "grid",
        
        // Navigation Views
        "navigationview",
        "navigationstack",
        "navigationlink",
        "tabview",
        
        // Presentation Views
        "sheet",
        "alert",
        "confirmationdialog",
        "popover",
        
        // Container Views
        "form",
        "section",
        "groupbox",
        "disclosuregroup",
        
        // Control Views
        "menu",
        "contextmenu",
        "toolbar",
        "navigationbar"
    ]
    
    // MARK: - Supported Modifiers
    
    public static let supportedModifiers: Set<String> = [
        // Frame and Layout
        "frame",
        "padding",
        "offset",
        "position",
        "layoutpriority",
        "zindex",
        "alignmentguide",
        
        // Appearance
        "background",
        "foregroundcolor",
        "foregroundstyle",
        "opacity",
        "shadow",
        "border",
        "overlay",
        "mask",
        "blur",
        "brightness",
        "contrast",
        "saturation",
        "hue",
        "grayscale",
        
        // Transforms
        "scaleeffect",
        "rotationeffect",
        "rotation3deffect",
        "transformeffect",
        "projectioneffect",
        
        // Shape and Clipping
        "cornerradius",
        "clipshape",
        "clipped",
        "contenttransition",
        
        // Typography
        "font",
        "fontweight",
        "fontwidth",
        "fontdesign",
        "bold",
        "italic",
        "underline",
        "strikethrough",
        "kerning",
        "tracking",
        "baselineoffset",
        "lineheight",
        "linelimit",
        "truncationmode",
        "textcase",
        "textselection",
        "multilinetext",
        
        // Interaction
        "disabled",
        "ontapgesture",
        "onlongpressgesture",
        "ondraggesture",
        "onmagnificationgesture",
        "onrotationgesture",
        "gesture",
        "allowshittesting",
        "deletedsabled",
        "movedsabled",
        "swipeactions",
        
        // Visibility
        "hidden",
        "redacted",
        "unredacted",
        
        // Accessibility
        "accessibilitylabel",
        "accessibilityhint",
        "accessibilityvalue",
        "accessibilityidentifier",
        "accessibilityheading",
        "accessibilityhidden",
        "accessibilityaddtraits",
        "accessibilityremovetraits",
        "accessibilitysortpriority",
        "accessibilityaction",
        "accessibilityelement",
        "accessibilitychildren",
        "accessibilityresponsibility",
        
        // Lifecycle
        "onappear",
        "ondisappear",
        "onchange",
        "task",
        "refreshable",
        
        // Animation
        "animation",
        "transition",
        "matchtransition",
        "phaseanimator",
        "keyframeanimator",
        
        // Environment
        "environment",
        "environmentobject",
        "preferredcolorscheme",
        "colorscheme",
        "dynamictypesize",
        "foregroundstyle",
        "listitemtint",
        "listrowbackground",
        "listrowseparator",
        "listrowseparatortint",
        "listrowpinheight",
        "listsectionspacing",
        "listrowspacing",
        
        // Navigation
        "navigationtitle",
        "navigationsubtitle",
        "navigationbarhidden",
        "navigationbarbackbuttonhidden",
        "navigationbartitlehidden",
        "navigationbartitledisplaymode",
        "toolbar",
        "toolbarbackground",
        "toolbarcolorscheme",
        "toolbarhidden",
        "tabitem",
        "tag",
        
        // Presentation
        "sheet",
        "fullscreencover",
        "popover",
        "alert",
        "confirmationdialog",
        "fileimporter",
        "fileexporter",
        "filedialog",
        
        // Styling
        "buttonbordershape",
        "buttonrepeatbehavior",
        "buttonstyle",
        "togglestyle",
        "pickerstyle",
        "datepickerstyle",
        "formstyle",
        "liststyle",
        "navigationviewstyle",
        "tabviewstyle",
        "progressviewstyle",
        "menustyle",
        "groupboxstyle",
        "textfieldstyle",
        "labelstyle",
        
        // Drawing and Graphics
        "drawinggroup",
        "compositinggroup",
        "blendmode",
        "colorinvert",
        "colormultiply",
        "luminancetosaturation",
        "symbolrenderingmode",
        "symbolvariant",
        "imagerendere",
        "interpolation",
        "antialiased",
        
        // Scrolling
        "scrolldisabled",
        "scrollindicators",
        "scrollcontentbackground",
        "scrollbouncebehavior",
        "scrolltargetlayout",
        "scrolltargetbehavior",
        "scrollposition",
        "scrollcliptodisabled",
        
        // Input and Focus
        "focused",
        "focusedvalue",
        "focuseffectdisabled",
        "submitlabel",
        "onsubmit",
        "keyboardtype",
        "autocorrectiondisabled",
        "textcontenttype",
        "textinputautocapitalization",
        "ondeletecommand",
        "onmovecommand",
        "oneditingchanged",
        "oncommit"
    ]
    
    // MARK: - View Type Validation
    
    public static func isViewSupported(_ viewType: String) -> Bool {
        return supportedViews.contains(viewType.lowercased())
    }
    
    public static func isModifierSupported(_ modifierName: String) -> Bool {
        return supportedModifiers.contains(modifierName.lowercased())
    }
    
    // MARK: - Layout Container Views
    
    public static let layoutContainerViews: Set<String> = [
        "vstack",
        "hstack",
        "zstack",
        "lazyvstack",
        "lazyhstack",
        "scrollview",
        "list",
        "form",
        "section",
        "group",
        "groupbox",
        "navigationview",
        "navigationstack",
        "tabview"
    ]
    
    public static func isLayoutContainer(_ viewType: String) -> Bool {
        return layoutContainerViews.contains(viewType.lowercased())
    }
    
    // MARK: - Interactive Views
    
    public static let interactiveViews: Set<String> = [
        "button",
        "toggle",
        "slider",
        "textfield",
        "securefield",
        "picker",
        "stepper",
        "navigationlink",
        "menu"
    ]
    
    public static func isInteractive(_ viewType: String) -> Bool {
        return interactiveViews.contains(viewType.lowercased())
    }
    
    // MARK: - Views Requiring State
    
    public static let statefulViews: Set<String> = [
        "toggle",
        "slider",
        "textfield",
        "securefield",
        "picker",
        "stepper"
    ]
    
    public static func requiresState(_ viewType: String) -> Bool {
        return statefulViews.contains(viewType.lowercased())
    }
    
    // MARK: - Property Validation
    
    public static func getRequiredProperties(for viewType: String) -> [String] {
        switch viewType.lowercased() {
        case "text":
            return ["content"]
        case "button":
            return ["title"]
        case "image":
            return ["source"]
        case "textfield", "securefield":
            return ["placeholder", "binding"]
        case "toggle":
            return ["title", "binding"]
        case "slider":
            return ["binding"]
        default:
            return []
        }
    }
    
    public static func getOptionalProperties(for viewType: String) -> [String] {
        switch viewType.lowercased() {
        case "vstack", "hstack":
            return ["alignment", "spacing"]
        case "zstack":
            return ["alignment"]
        case "scrollview":
            return ["axes", "showsIndicators"]
        case "slider":
            return ["min", "max", "step"]
        case "roundedrectangle":
            return ["cornerRadius"]
        default:
            return []
        }
    }
    
    // MARK: - Registry Extensions
    
    public static func getAllSupportedTypes() -> (views: [String], modifiers: [String]) {
        return (
            views: Array(supportedViews).sorted(),
            modifiers: Array(supportedModifiers).sorted()
        )
    }
    
    public static func validateViewDefinition(_ viewJSON: Any) -> [String] {
        var errors: [String] = []
        
        // Add validation logic here
        // This would check that the view JSON contains required properties
        // and that all properties are valid for the view type
        
        return errors
    }
}