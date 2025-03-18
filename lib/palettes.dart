enum TramPalette {
  route1("B5BD00"),
  route3("8DC8E8"),
  route5("D50032"),
  route6("01426A"),
  route11("6ECEB2"),
  route12("007E92"),

  route16("FBD872"),
  route19("8A1B61"),
  route30("534F96"),
  route35("6B3529"),
  route48("333434"),
  route57("00C1D5"),

  route58("969696"),
  route59("00653A"),
  route64("00AB8E"),
  route67("956C58"),
  route70("F59BBB"),
  route72("9ABEAA"),

  route75("00A9E0"),
  route78("A0A0D6"),
  route82("D2D755"),
  route86("FFB500"),
  route96("C6007E"),
  route109("E87722"),

  routeDefault("78BE20");

  final String colour;
  const TramPalette(this.colour);
}

enum TrainPalette {
  sandringham("F178AF"),

  frankston("028430"),
  werribee("028430"),
  williamstown("028430"),

  cranbourne("279FD5"),
  pakenham("279FD5"),

  belgrave("152C6B"),
  lilydale("152C6B"),
  alamein("152C6B"),
  glenwaverley("152C6B"),

  sunbury("FFBE00"),
  craigieburn("FFBE00"),
  upfield("FFBE00"),

  mernda("BE1014"),
  hurstbridge("BE1014"),

  showgrounds("95979A"),
  flemingtonracecourse("95979A"),

  routeDefault("0072CE");

  final String colour;
  const TrainPalette(this.colour);
}

enum BusPalette {
  routeDefault("F47920");

  final String colour;
  const BusPalette(this.colour);
}