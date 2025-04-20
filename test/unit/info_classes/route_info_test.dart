// import 'package:flutter_project/palettes.dart';
// import 'package:flutter_project/domain/route_info.dart';
// import 'package:flutter_project/domain/route_type_info.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   late Route route;
//   late RouteType trainType;
//   late RouteType tramType;
//   late RouteType busType;
//   late RouteType vLineType;
//
//   setUp(() {
//     trainType = RouteType.fromName("train");
//     tramType = RouteType.fromName("tram");
//     busType = RouteType.fromName("bus");
//     vLineType = RouteType.fromName("vLine");
//   });
//
//   // test each transport type, to see if they match
//   // test fallback values, if there is a transport type match, but unknown id or name or number
//
//   group("setRouteColour() function", () {
//     group("Correct transport types and matching routes", () {
//       test("Train: Upfield", () {
//         route = Route(id: 15, name: "Upfield", number: "", type: trainType);
//         String? colour = route.colour;
//         String? textColour = route.textColour;
//
//         expect(colour, "FFBE00");
//         expect(textColour, TextColour.black.colour);
//       });
//
//       test("Tram: 59", () {
//         route = Route(
//             id: 897,
//             name: "Airport West - Flinders St",
//             number: "59",
//             type: tramType);
//         String? colour = route.colour;
//         String? textColour = route.textColour;
//
//         expect(colour, "00653A");
//         expect(textColour, TextColour.white.colour);
//       });
//
//       test("Bus: 250", () {
//         route = Route(
//             id: 8135,
//             name: "City (Queen St) - La Trobe University",
//             number: "250",
//             type: busType);
//         String? colour = route.colour;
//         String? textColour = route.textColour;
//
//         expect(colour, "F47920");
//         expect(textColour, TextColour.black.colour);
//       });
//
//       test("vLine: Warrnambool", () {
//         route =
//             Route(id: 1512, name: "Warrnambool", number: "", type: vLineType);
//         String? colour = route.colour;
//         String? textColour = route.textColour;
//
//         expect(colour, "8F1A95");
//         expect(textColour, TextColour.white.colour);
//       });
//     });
//
//     group("Route Defaults and Fallbacks", () {
//       test("Train: Unknown", () {
//         route = Route(id: 15, name: "Unknown", number: "", type: trainType);
//         String? colour = route.colour;
//         String? textColour = route.textColour;
//
//         expect(colour, "0072CE");
//         expect(textColour, TextColour.black.colour);
//       });
//
//       test("Tram: Unknown", () {
//         route = Route(
//             id: 897,
//             name: "Airport West - Flinders St",
//             number: "Unknown",
//             type: tramType);
//         String? colour = route.colour;
//         String? textColour = route.textColour;
//
//         expect(colour, "78BE20");
//         expect(textColour, TextColour.white.colour);
//       });
//
//       // todo: add a test for the Fallback Colour, but this may be impossible since RouteType is an enum
//       // todo: so it might be impossible to even reach it, since an error will be brought up an initialisation
//     });
//   });
// }
