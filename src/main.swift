import Foundation
import ArgumentParser

setbuf(__stdoutp, nil)

extension String {
    var expandingTildeInPath: String {
        return NSString(string: self).expandingTildeInPath
    }
}

struct Speak: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Prints a string in a more human cadence.")
    
    @Argument(help: "What should be said. (File or String)")
    var phrase: String
    
    @Flag(name: .shortAndLong)
    var softly = false
    
    enum Times: UInt32 {
        // In 1/1_000_000s
        case character = 50_000
//        case word = 100_000
        case comma = 350_000
        case period = 700_000
    }
    
    mutating func run() throws {
        // Check if argument is a filename, if so set phrase to its contents
        let potentialFilePath = phrase.expandingTildeInPath
        if FileManager.default.fileExists(atPath: potentialFilePath) {
            try phrase = String(contentsOf: URL(fileURLWithPath: potentialFilePath))
        }
        
        // Spell out numbers
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .spellOut
//        let numbers = phrase
//            .components(separatedBy: CharacterSet.decimalDigits.inverted)
//            .map { formatter.string(from: NSNumber(value: Int($0)!)) }
//        print(numbers.description)
        
        usleep(Times.comma.rawValue)
        
        for character in phrase {
            print(character, terminator: "")
            
            var sleepTime: UInt32
            
            switch character {
//            case " ":
//                sleepTime = Times.word.rawValue
            case _ where [",", ";", ":", "-", "–", "—"].contains(character):
                sleepTime = Times.comma.rawValue
            case _ where [".", "?", "!"].contains(character):
                sleepTime = Times.period.rawValue
            default:
                sleepTime = Times.character.rawValue
            }
            
            if softly {
                sleepTime *= 2
            }
            
            usleep(sleepTime)
        }
        
        usleep(Times.period.rawValue)
        print("")
    }
}

// stdin handling
func readSTDIN () -> String? {
    var input: String?
    
    while let line = readLine() {
        if input == nil {
            input = line
        } else {
            input! += "\n" + line
        }
    }
    
    return input
}

var text: String?

let noPhrase = !(CommandLine.arguments.dropFirst().contains { !($0.contains("-s")) })
if noPhrase || CommandLine.arguments.last == "-" {
    if CommandLine.arguments.last == "-" { CommandLine.arguments.removeLast() }
    text = readSTDIN()
}

var arguments = Array(CommandLine.arguments.dropFirst())
if let text = text {
    arguments.insert(text, at: 0)
}

var command = Speak.parseOrExit(arguments)
do {
    try command.run()
} catch {
    Speak.exit(withError: error)
}
