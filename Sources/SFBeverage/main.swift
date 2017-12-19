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

struct BeverageEvent {
  let date: Date
  let htmlString: String
}

var dateFormatter: DateFormatter = {
  let dateFormatter = DateFormatter()
  dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
  dateFormatter.dateFormat = "EEEE MMMM d, yyy, h:mm a"

  return dateFormatter
}()

func calendar(url: URL) -> XCalendar.Calendar?
{
  let calendars: [XCalendar.Calendar]

  do {
    calendars = try iCal.load(url: url)
  } catch {
    return nil
  }

  return calendars.first
}

func upcomingBeverageEvents(calendarEvents: [XCalendar.CalendarComponent]?, preamble: String, defaultTitle: String) -> [BeverageEvent]
{
  guard let calendarEvents = calendarEvents else {
    return []
  }

  var beverageEvents: [BeverageEvent] = []

  for sub in calendarEvents {
    guard let event = sub as? XCalendar.Event,
    let startTime = event.dtstart,
    startTime > Date(timeIntervalSinceNow: -6 * 60 * 60)
    else {
      continue
    }

    let summary = event.summary ?? defaultTitle

    var eventHtml = "<p>\(preamble)<br>\n"
    eventHtml += "\(summary): \(dateFormatter.string(from: startTime))"

    if let rawLocation = event.location {
      let location = rawLocation.replacingOccurrences(of: "\\n", with: "\n")
      let displayLocation = location.replacingOccurrences(of: ", United States", with: "")
      eventHtml += "<br>at <a href=\"https://www.google.com/maps?hl=en&q=\(location)\">\(displayLocation)</a>"
    } else {
      eventHtml += ".<br>Location TBD; please check Slack for more details!"
    }
    eventHtml += "</p>\n"

    beverageEvents.append(BeverageEvent(date: startTime, htmlString: eventHtml))
  }

  return beverageEvents
}

let drop = try Droplet()

drop.get("/") { req in

  var output: String = """
  <!doctype html>
  <html>
  <head>
  <title>sf-beverage</title>
  <style type="text/css">
  body {
    margin: 3em 1em 1em 1em;
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
    font: 16px/20px "Avenir Next", Avenir, sans-serif;
    text-align: center;
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

  let beerCalendar = calendar(url: URL(string: "https://calendar.google.com/calendar/ical/phk026m02ec2htc3s4kqqtdgt4%40group.calendar.google.com/public/basic.ics")!)
  let coffeeCalendar = calendar(url: URL(string: "https://calendar.google.com/calendar/ical/ho60q57pauegr2ki4v9hhspvdo%40group.calendar.google.com/public/basic.ics")!)

  var events: [BeverageEvent] = []

  events += upcomingBeverageEvents(calendarEvents: beerCalendar?.subComponents, preamble: "🍺🍸🍹", defaultTitle: "Weekly #sf-beer")
  events += upcomingBeverageEvents(calendarEvents: coffeeCalendar?.subComponents, preamble: "☕️🍵🥐", defaultTitle: "iOS Coffee")

  for event in events.sorted(by: { $0.date < $1.date}).prefix(5) {
    output += event.htmlString
  }

  if events.count == 0 {
    output += "<p>Nothing on the schedule — or there’s a bug in the calendar fetcher.</p><p>Check again later! ☕️🍺🍵</p>"
  }

  output += """
  <div class="footer">
  Inspired by <a href="https://coffeecoffeecoffee.coffee">coffeecoffeecoffee.coffee</a> & <a href="http://beerbeerbeerbeer.beer">beerbeerbeerbeer.beer</a><br>
  Thanks to <a href="https://twitter.com/jamescmartinez">@jamescmartinez</a>, <a href="https://twitter.com/roderic">@roderic</a>, <a href="https://twitter.com/brennansv">@brennansv</a>, and <a href="https://twitter.com/schukin">@schukin</a><br>
  By <a href="https://twitter.com/gregheo">@gregheo</a>; powered by <a href="https://www.heroku.com">Heroku</a> & <a href="https://vapor.codes">Vapor</a> 💧
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
