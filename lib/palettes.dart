enum TextColour {
  black("000000"),
  white("FFFFFF");

  final String colour;
  const TextColour(this.colour);
}

enum TramPalette {
  route1("B5BD00", TextColour.black),
  route3("8DC8E8", TextColour.black),
  route5("D50032", TextColour.white),
  route6("01426A", TextColour.white),
  route11("6ECEB2", TextColour.black),
  route12("007E92", TextColour.white),

  route16("FBD872", TextColour.black),
  route19("8A1B61", TextColour.white),
  route30("534F96", TextColour.white),
  route35("6B3529", TextColour.white),
  route48("333434", TextColour.white),
  route57("00C1D5", TextColour.black),

  route58("969696", TextColour.white),
  route59("00653A", TextColour.white),
  route64("00AB8E", TextColour.white),
  route67("956C58", TextColour.white),
  route70("F59BBB", TextColour.black),
  route72("9ABEAA", TextColour.black),

  route75("00A9E0", TextColour.black),
  route78("A0A0D6", TextColour.black),
  route82("D2D755", TextColour.black),
  route86("FFB500", TextColour.black),
  route96("C6007E", TextColour.white),
  route109("E87722", TextColour.black),

  routeDefault("78BE20", TextColour.white);

  final String colour;
  final TextColour textColour;
  const TramPalette(this.colour, this.textColour);
}

enum TrainPalette {
  sandringham("F178AF", TextColour.black),

  frankston("028430", TextColour.white),
  werribee("028430", TextColour.white),
  williamstown("028430", TextColour.white),

  cranbourne("279FD5", TextColour.black),
  pakenham("279FD5", TextColour.black),

  belgrave("152C6B", TextColour.white),
  lilydale("152C6B", TextColour.white),
  alamein("152C6B", TextColour.white),
  glenwaverley("152C6B", TextColour.white),

  sunbury("FFBE00", TextColour.black),
  craigieburn("FFBE00", TextColour.black),
  upfield("FFBE00", TextColour.black),

  mernda("BE1014", TextColour.white),
  hurstbridge("BE1014", TextColour.white),

  showgrounds("95979A", TextColour.black),
  flemingtonracecourse("95979A", TextColour.black),

  routeDefault("0072CE", TextColour.black);

  final String colour;
  final TextColour textColour;
  const TrainPalette(this.colour, this.textColour);
}

enum BusPalette {
  routeDefault("F47920", TextColour.black);

  final String colour;
  final TextColour textColour;
  const BusPalette(this.colour, this.textColour);
}

enum VLine {
  routeDefault("8F1A95", TextColour.white);

  final String colour;
  final TextColour textColour;
  const VLine(this.colour, this.textColour);
}

enum FallbackColour {
  routeDefault("707372", TextColour.white);

  final String colour;
  final TextColour textColour;
  const FallbackColour(this.colour, this.textColour);
}
