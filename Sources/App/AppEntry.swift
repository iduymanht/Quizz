import Foundation

/// Single binary, two roles:
/// - `Quiz hook ...` runs the lightweight CLI helper (issue #4).
/// - no arguments launches the menu bar app.
@main
struct QuizMain {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        switch args.first {
        case "hook":
            HookCLI.run(arguments: Array(args.dropFirst()))
        case "run":
            RunCLI.run(arguments: Array(args.dropFirst()))
        default:
            QuizApp.main()
        }
    }
}
