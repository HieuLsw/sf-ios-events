//
//  main.swift
//  SFBeverage
//
//  Created by Greg Heo on 12/12/17.
//  Copyright © 2017 Greg Heo. All rights reserved.
//

import Foundation
import XCalendar
import Vapor

/// Simple struct for a calendar of events.
struct EventCalendar {
  /// The iCal URL
  let url: String
  /// Emoji preamble to identify these events
  let preamble: String
  /// Default title for unnamed events
  let defaultTitle: String
  /// Maximum number of these events to display. Set to 0 for no limit.
  let eventLimit: Int
  /// Whether to show the location or not
  let showLocation: Bool
}

/// Simple struct for a single event.
struct BeverageEvent {
  let date: Date
  let htmlString: String
}

/// Re-used date formatter.
var dateFormatter: DateFormatter = {
  let dateFormatter = DateFormatter()
  dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
  dateFormatter.dateFormat = "EEEE MMMM d, yyy, h:mm a"

  return dateFormatter
}()

/// Creates a `Calendar` object from an iCal URL.
func loadCalendar(url: URL) -> XCalendar.Calendar?
{
  let calendars: [XCalendar.Calendar]? = try? iCal.load(url: url)

  return calendars?.first
}

/// Generates an HTML string from a single event.
func eventHtml(event: XCalendar.Event, eventCalendar: EventCalendar, summary: String) -> String
{
  var eventHtml = "<p>\(eventCalendar.preamble)\n"
  
  if let startDate = event.dtstart {
    eventHtml += "<br>\(dateFormatter.string(from: startDate))\n"
  }
  
  if !eventCalendar.showLocation, let linkUrl = event.otherAttrs["URL"] {
    eventHtml += "<br><a target=\"_top\" href=\"\(linkUrl)\">\(summary)</a>\n"
  } else {
    eventHtml += "<br>\(summary)\n"
  }

  if eventCalendar.showLocation, let rawLocation = event.location {
    let location = rawLocation.replacingOccurrences(of: "\\n", with: "\n")
    let displayLocation = location.replacingOccurrences(of: ", United States", with: "")
    let mapUrl = "https://www.google.com/maps?hl=en&q=\(location)"

    if let linkUrl = event.otherAttrs["URL"] {
      // Event has its own URL! Show it + the Google Maps link.
      eventHtml += "<br>at <a target=\"_top\" href=\"\(linkUrl)\">\(displayLocation)</a> (<a target=\"_top\" href=\"\(mapUrl)\">map</a>)"
    } else {
      // No event URL; just use the Google Maps one.
      eventHtml += "<br>at <a target=\"_top\" href=\"\(mapUrl)\">\(displayLocation)</a>"
    }
  }
  eventHtml += "</p>\n"

  return eventHtml
}

/// Given a calendar, returns an array of upcoming `BeverageEvent` instances.
func upcomingBeverageEvents(calendarEvents: [XCalendar.CalendarComponent]?, eventCalendar: EventCalendar) -> [BeverageEvent]
{
  guard let calendarEvents = calendarEvents else {
    return []
  }

  var beverageEvents: [BeverageEvent] = []

  var addedEventCount: Int = 0

  for sub in calendarEvents {
    guard let event = sub as? XCalendar.Event,
    let startTime = event.dtstart,
    startTime > Date(timeIntervalSinceNow: -6 * 60 * 60)
    else {
      continue
    }

    let summary = event.summary ?? eventCalendar.defaultTitle
    let html = eventHtml(event: event, eventCalendar: eventCalendar, summary: summary)
    
    beverageEvents.append(BeverageEvent(date: startTime, htmlString: html))

    addedEventCount += 1
    if addedEventCount == eventCalendar.eventLimit {
      break
    }
  }

  return beverageEvents
}

let drop = try Droplet()

drop.get("/") { req in

  var output: String = """
  <!doctype html>
  <html>
  <head>
  <meta charset="utf-8">
  <meta http-equiv="content-type" content="text/html; charset=UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>#sf-beverage</title>
  <style>
  body {
    margin: 3em 1em 3em 1em;
  }
  p {
    font: 24px/36px "Avenir Next", Avenir, sans-serif;
    text-align: center;
  }
  h1 {
    font: 32px/40px "SF Mono", Monaco, Menlo, Consolas, Courier;
    text-align: center;
  }
  .footer {
    margin-top: 2em;
  }
  .footer p {
    font: 16px/20px "Avenir Next", Avenir, sans-serif;
    text-align: center;
    padding: 0;
    margin-top: 0;
    margin-bottom: 6px;
  }
  a, a:visited {
    color: #C04216;
    text-decoration: none;
  }
  a:hover {
    text-decoration: underline;
  }
  </style>
  </head>
  <body>
  <h1>#sf-beverage</h1>
  """

  let eventCalendars: [EventCalendar] = [
    EventCalendar(url: "https://calendar.google.com/calendar/ical/phk026m02ec2htc3s4kqqtdgt4%40group.calendar.google.com/public/basic.ics",
                  preamble: "🍺🍸🍴",
                  defaultTitle: "Weekly #sf-beer",
                  eventLimit: 0,
                  showLocation: true),
    EventCalendar(url: "http://coffeecoffeecoffee.coffee/groups/28ef50f9-b909-4f03-9a69-a8218a8cbd99/ical",
                  preamble: "☕️🍵🥐",
                  defaultTitle: "iOS Coffee",
                  eventLimit: 0,
                  showLocation: true),
    EventCalendar(url: "https://www.meetup.com/iOS-peer-lab/events/ical/",
                  preamble: "💻🤓🤝",
                  defaultTitle: "iOS Peer Lab",
                  eventLimit: 1,
                  showLocation: false),
    EventCalendar(url: "https://www.meetup.com/nsmeetup/events/ical/",
                  preamble: "👩‍💻👨‍💻📣",
                  defaultTitle: "NSMeetup",
                  eventLimit: 1,
                  showLocation: false),
    EventCalendar(url: "https://www.meetup.com/swift-language/events/ical/",
                  preamble: "👩‍💻👨‍💻📣",
                  defaultTitle: "SLUG",
                  eventLimit: 1,
                  showLocation: false),
  ]

  var events: [BeverageEvent] = []

  for eventCalendar in eventCalendars {
    guard let url = URL(string: eventCalendar.url) else {
      continue
    }

    let calendar = loadCalendar(url: url)
    events += upcomingBeverageEvents(calendarEvents: calendar?.subComponents,
                                     eventCalendar: eventCalendar)
  }

  for event in events.sorted(by: { $0.date < $1.date}).prefix(5) {
    output += event.htmlString
  }

  if events.count == 0 {
    output += "<p>Nothing on the schedule — or there’s a bug in the calendar fetcher.</p><p>Check again later! ☕️🍺🍵</p>"
  }

  output += """
  <div class="footer">
  <p>💡 Inspired by <a target="_top" href="https://coffeecoffeecoffee.coffee">coffeecoffeecoffee.coffee</a> & <a target="_top" href="http://beerbeerbeerbeer.beer">beerbeerbeerbeer.beer</a></p>
  <p>🙏 Thanks to <a target="_top" href="https://twitter.com/jamescmartinez">@jamescmartinez</a>, <a target="_top" href="https://twitter.com/roderic">@roderic</a>, <a target="_top" href="https://twitter.com/brennansv">@brennansv</a>, and <a target="_top" href="https://twitter.com/schukin">@schukin</a></p>
  <p>👀 By <a target="_top" href="https://twitter.com/gregheo">@gregheo</a>; powered by <a target="_top" href="https://www.heroku.com">Heroku</a> & <a target="_top" href="https://vapor.codes">Vapor</a> 💧</p>
  </div>
  </body></html>
  """

  return Response(
    status: .ok,
    headers: ["Content-Type": "text/html"],
    body: output
  )

}

try drop.run()
