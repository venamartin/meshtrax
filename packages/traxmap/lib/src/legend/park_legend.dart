import 'legend_symbol.dart';

/// The park and trail features the OSM styles draw as icons, for a legend:
/// each is drawn from [sample], a feature as the style's layer draws it.
/// The app supplies the words.
enum ParkLegendItem {
  campsite(LegendSample('poi-icon', {'class': 'campsite'})),
  picnicSite(LegendSample('poi-icon', {'class': 'picnic_site'})),
  shelter(LegendSample('poi-icon', {'class': 'shelter'})),
  toilets(LegendSample('poi-icon', {'class': 'toilets'})),
  drinkingWater(LegendSample('poi-icon', {'class': 'drinking_water'})),
  parking(LegendSample('poi-icon', {'class': 'parking'})),
  viewpoint(
    LegendSample('poi-icon', {'class': 'attraction', 'subclass': 'viewpoint'}),
  ),
  attraction(LegendSample('poi-icon', {'class': 'attraction'})),
  gate(LegendSample('poi-icon-minor', {'class': 'gate'})),
  telephone(LegendSample('poi-icon-minor', {'class': 'telephone'})),
  information(
    LegendSample('poi-icon-minor', {
      'class': 'information',
      'subclass': 'board',
    }),
  ),
  guidepost(
    LegendSample('poi-icon-minor', {
      'class': 'information',
      'subclass': 'guidepost',
    }),
  );

  final LegendSample sample;

  const ParkLegendItem(this.sample);
}

/// What park legend samples are drawn on: the map's background.
const parkLegendGround = LegendSample('background');
