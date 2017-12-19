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

func reportErrorAndExit(message: String) -> Never
{
  print(message)
  exit(-1)
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

    var eventHtml = "<p>\(preamble)<br>"
    eventHtml += "\(summary): \(dateFormatter.string(from: startTime))"

    if let rawLocation = event.location {
      let location = rawLocation.replacingOccurrences(of: "\\n", with: "\n")
      let displayLocation = location.replacingOccurrences(of: ", United States", with: "")
      eventHtml += "<br>at <a href=\"https://www.google.com/maps?hl=en&q=\(location)\">\(displayLocation)</a>"
    } else {
      eventHtml += ".<br>Location TBD; please check Slack for more details!"
    }
    eventHtml += "</p>"

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

  for event in events.sorted(by: { $0.date < $1.date}) {
    output += event.htmlString
  }

  output += "</body></html>"

  return Response(
    status: .ok,
    headers: ["Content-Type": "text/html"],
    body: output
  )

}

try drop.run()
