import Foundation

/// TODO add documentation
internal class Parser {
    let icsContent: [String]

    init(_ ics: [String]) {
        icsContent = ics
    }

    func read() throws -> [Calendar] {
        var completeCal = [Calendar?]()

        // Such state, much wow
        var inCalendar = false
        var currentCalendar: Calendar?
        var inEvent = false
        var currentEvent: Event?
        var inAlarm = false
        var currentAlarm: Alarm?
        var lastAttribute: String?

        for (_ , line) in icsContent.enumerated() {
            switch line {
            case "BEGIN:VCALENDAR":
                inCalendar = true
                currentCalendar = Calendar(withComponents: nil)
                continue
            case "END:VCALENDAR":
                inCalendar = false
                completeCal.append(currentCalendar)
                currentCalendar = nil
                continue
            case "BEGIN:VEVENT":
                inEvent = true
                currentEvent = Event()
                continue
            case "END:VEVENT":
                inEvent = false
                currentCalendar?.append(component: currentEvent)
                currentEvent = nil
                continue
            case "BEGIN:VALARM":
                inAlarm = true
                currentAlarm = Alarm()
                continue
            case "END:VALARM":
                inAlarm = false
                currentEvent?.append(component: currentAlarm)
                currentAlarm = nil
                continue
            default:
                break
            }

            if let lastAttribute = lastAttribute,
                lastAttribute == "LOCATION",
                inEvent && !inAlarm && line.count > 1 && line.prefix(1) == " "
            {
                let currentLocation = currentEvent?.location ?? ""
                currentEvent?.addAttribute(attr: lastAttribute, currentLocation + line.dropFirst())
            }

            guard let (key, value) = line.toKeyValuePair(splittingOn: ":") else {
                // print("(key, value) is nil") // DEBUG
                continue
            }

            if inCalendar && !inEvent {
                currentCalendar?.addAttribute(attr: key, value)
            }

            if inEvent && !inAlarm {
                // HACK
                if key.hasPrefix("DTSTART;TZID=") {
                    let timeZone = key.dropFirst("DTSTART;TZID=".count)
                    currentEvent?.addAttribute(attr: "DTTIMEZONE", String(timeZone))
                    currentEvent?.addAttribute(attr: "DTSTART", value)
                    lastAttribute = "DTSTART"
                } else {
                    currentEvent?.addAttribute(attr: key, value)
                    lastAttribute = key
                }
            }

            if inAlarm {
                currentAlarm?.addAttribute(attr: key, value)
            }
        }

        return completeCal.flatMap{ $0 }
    }
}
