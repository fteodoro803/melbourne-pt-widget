// import 'package:flutter_project/domain/departure.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   late String aedt;
//   late String aest;
//
//   setUp(() {
//     aedt = "AUS Eastern Daylight Time";
//     aest = "AUS Eastern Standard Time";
//   });
//
//   group("Valid Input:", () {
//     // These wont work in CI because it's in UTC
//     // test("should initialise with scheduled and estimated departures, converting both times to a VIC Timezone", () {
//     //   DateTime scheduledUTC = DateTime.utc(2025, 1, 1, 6, 30);
//     //   DateTime estimatedUTC = DateTime.utc(2025, 1, 1, 6, 35);
//     //   String? runRef = "10";
//     //   int? stopId = 4;
//     //   Departure departure = Departure(scheduledDepartureUTC: scheduledUTC, estimatedDepartureUTC: estimatedUTC, runRef: runRef, stopId: stopId);
//     //
//     //   expect(departure.scheduledDeparture?.timeZoneName, anyOf(equals(aest), equals(aedt)));
//     //   expect(departure.estimatedDeparture?.timeZoneName, anyOf(equals(aest), equals(aedt)));
//     //   expect(departure.runRef, "10");
//     //   expect(departure.stopId, 4);
//     // });
//     //
//     // test("should initialise without stop ID, with scheduled and estimated departures, converting both to a VIC timezone", () {
//     //   DateTime scheduledUTC = DateTime.utc(2025, 1, 1, 6, 30);
//     //   DateTime estimatedUTC = DateTime.utc(2025, 1, 1, 6, 35);
//     //   String? runRef = "10";
//     //   Departure departure = Departure(scheduledDepartureUTC: scheduledUTC, estimatedDepartureUTC: estimatedUTC, runRef: runRef);
//     //
//     //   expect(departure.scheduledDeparture?.timeZoneName, anyOf(equals(aest), equals(aedt)));
//     //   expect(departure.estimatedDeparture?.timeZoneName, anyOf(equals(aest), equals(aedt)));
//     //   expect(departure.runRef, "10");
//     //   expect(departure.stopId, null);
//     // });
//     //
//     // test("should initialise without scheduled departure, while converting estimated departure to a VIC timezone", () {
//     //   DateTime? scheduledUTC;
//     //   DateTime? estimatedUTC = DateTime.utc(2025, 1, 1, 6, 30);
//     //   String? runRef = "10";
//     //   Departure departure = Departure(scheduledDepartureUTC: scheduledUTC,
//     //       estimatedDepartureUTC: estimatedUTC,
//     //       runRef: runRef);
//     //
//     //   expect(departure.scheduledDeparture?.timeZoneName, null);
//     //   expect(departure.estimatedDeparture?.timeZoneName,
//     //       anyOf(equals(aest), equals(aedt)));
//     //   expect(departure.runRef, "10");
//     // });
//     //
//     // test("should initialise without estimated departure, while converting scheduled departure to a VIC timezone", () {
//     //   DateTime? scheduledUTC = DateTime.utc(2025, 1, 1, 6, 30);
//     //   DateTime? estimatedUTC;
//     //   String? runRef = "10";
//     //   Departure departure = Departure(scheduledDepartureUTC: scheduledUTC,
//     //       estimatedDepartureUTC: estimatedUTC,
//     //       runRef: runRef);
//     //
//     //   expect(departure.scheduledDeparture?.timeZoneName, anyOf(equals(aest), equals(aedt)));
//     //   expect(departure.estimatedDeparture?.timeZoneName, null);
//     //   expect(departure.runRef, "10");
//     // });
//
//     test("should initialise with both departures being null", () {
//       DateTime? scheduledUTC;
//       DateTime? estimatedUTC;
//       String? runRef = "10";
//       Departure departure = Departure(scheduledDepartureUTC: scheduledUTC,
//           estimatedDepartureUTC: estimatedUTC,
//           runRef: runRef);
//
//       expect(departure.scheduledDeparture?.timeZoneName, null);
//       expect(departure.estimatedDeparture?.timeZoneName, null);
//       expect(departure.runRef, "10");
//     });
//   });
//
//   group("Invalid Input", () {});
//
//   group("getTime() Method", () {
//     test("00:00 / 12 midnight", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 0;
//       int minute = 0;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "12:00am");
//     });
//
//     test("12:00 / 12 noon", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 12;
//       int minute = 0;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "12:00pm");
//     });
//
//     test("15:00 / 3pm", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 15;
//       int minute = 0;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "03:00pm");
//     });
//
//     test("07:00 / 7am", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 7;
//       int minute = 0;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "07:00am");
//     });
//
//     test("single-digit minute: 15:05 / 3:05pm", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 15;
//       int minute = 5;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "03:05pm");
//     });
//
//     test("single-digit hour: 04:10 / 4:10am", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 4;
//       int minute = 10;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "04:10am");
//     });
//
//     test("double-digit minute: 17:25 / 5:25pm", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 17;
//       int minute = 25;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "05:25pm");
//     });
//
//     test("double-digit hour: 23:05 / 11:05pm", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       int hour = 23;
//       int minute = 5;
//       DateTime dateTime = DateTime(1, 1, 1, hour, minute);
//       String? time = departure.getTime(dateTime);
//
//       expect(time, "11:05pm");
//     });
//
//     test("null dateTime", () {
//       Departure departure = Departure(scheduledDepartureUTC: null, estimatedDepartureUTC: null, runRef: null);
//       String? time = departure.getTime(null);
//
//       expect(time, null);
//     });
//
//   });
// }