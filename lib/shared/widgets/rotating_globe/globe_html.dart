import 'dart:convert';

/// The JavaScript escape for "<" (backslash, u, 0, 0, 3, c). Replacing every
/// "<" inside the embedded JSON with it keeps a value such as
/// `</script>` from closing the page's script tag. Built from character codes
/// so the backslash sequence is not written out in this source file.
final String _jsLessThan = '${String.fromCharCode(0x5c)}u003c';

/// Mapbox GL JS release the globe page loads. Pinned so a CDN update can't
/// change how the globe looks or behaves underneath the app.
const mapboxGlVersion = '3.9.0';

/// One place on the globe: a pin, and (for the busiest few) a callout card.
class GlobeStop {
  const GlobeStop({
    required this.city,
    required this.lat,
    required this.lng,
    required this.eventCount,
    this.title = '',
    this.imageUrl,
  });

  final String city;
  final double lat;
  final double lng;

  /// How many events happen here — the card's "38 EVENTS".
  final int eventCount;

  /// The headline event's name, shown on the card.
  final String title;
  final String? imageUrl;

  Map<String, Object?> toJson() => {
        'city': city,
        'lat': lat,
        'lng': lng,
        'count': eventCount,
        'title': title,
        'img': imageUrl,
      };
}

/// The standalone page that draws the globe — the web landing hero
/// (`JourneyHero.tsx`) for the phone: Mapbox GL JS globe projection, NASA VIIRS
/// city lights, a dusk sky with stars, event pins and callout cards, turning
/// at 5°/s.
///
/// It is one HTML document, shared by both hosts: an `<iframe srcdoc>` on
/// Flutter web and a `WebView` on Android / iOS.
///
/// - [token] is a Mapbox **public** token (`pk.…`). It is embedded in the page.
/// - [background] is the page colour behind the globe; match the surface it
///   sits on so the canvas is invisible.
/// - [bottomInset] reserves that many CSS px at the bottom (for text laid over
///   the globe) and centres the globe in what is left above it.
/// - [stops] are the pins; the first [maxCards] also get a callout card.
/// - [spin] false draws a still globe (reduced-motion users).
String buildGlobeHtml({
  required String token,
  String background = '#02040A',
  bool spin = true,
  double degreesPerSecond = 5,
  double startLng = 121,
  double startLat = 14,
  double bottomInset = 0,
  bool nightLights = true,
  List<GlobeStop> stops = const [],
  int maxCards = 2,
  bool interactive = false,
  double? zoom,
}) {
  // JSON-encode every interpolated value so nothing can break out of the
  // script, whatever the token, colour or event names contain.
  final cfg = jsonEncode({
    'token': token,
    'background': background,
    'spin': spin,
    'speed': degreesPerSecond,
    'lng': startLng,
    'lat': startLat,
    'bottom': bottomInset,
    'night': nightLights,
    'maxCards': maxCards,
    'interactive': interactive,
    'zoom': zoom,
    'stops': [for (final s in stops) s.toJson()],
  }).replaceAll('<', _jsLessThan);

  return '''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<link href="https://api.mapbox.com/mapbox-gl-js/v$mapboxGlVersion/mapbox-gl.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@700&family=Space+Mono&display=swap" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v$mapboxGlVersion/mapbox-gl.js"></script>
<style>
  html, body, #map { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
  body { background: transparent; }
  /* The globe is a backdrop, so it carries no Mapbox wordmark or (i) button. */
  .mapboxgl-ctrl-logo, .mapboxgl-ctrl-attrib { display: none !important; }
  .card {
    display: flex; gap: 8px; align-items: center;
    padding: 7px 10px 7px 7px; border-radius: 12px;
    background: rgba(15, 17, 26, 0.88); border: 1px solid #2A2D3A;
    color: #fff; font-family: 'Space Grotesk', system-ui, sans-serif;
    pointer-events: none; white-space: nowrap; max-width: 210px;
    transition: opacity 0.2s linear;
  }
  .card img { width: 34px; height: 34px; border-radius: 8px; object-fit: cover; flex: none; }
  .card .city { font: 400 9px 'Space Mono', monospace; letter-spacing: .14em;
    text-transform: uppercase; color: #CCFF00; }
  .card .title { font-weight: 700; font-size: 12px; text-transform: uppercase;
    overflow: hidden; text-overflow: ellipsis; max-width: 150px; }
  .card .meta { font: 400 8.5px 'Space Mono', monospace; letter-spacing: .1em;
    text-transform: uppercase; color: #A9ADBA; margin-top: 1px; }
</style>
</head>
<body>
<div id="map"></div>
<script>
(function () {
  var cfg = $cfg;
  document.body.style.background = cfg.background;
  mapboxgl.accessToken = cfg.token;

  var el = document.getElementById('map');
  // Fit the globe to what is left above the reserved bottom area.
  function fitZoom() {
    var w = el.clientWidth || 360;
    var h = (el.clientHeight || 640) - cfg.bottom;
    var px = Math.min(w, Math.max(h, 120));
    return Math.max(0.2, Math.log2(px / 512) + 1.15);
  }

  var map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/dark-v11',
    projection: 'globe',
    center: [cfg.lng, cfg.lat],
    zoom: cfg.zoom == null ? fitZoom() : cfg.zoom,
    interactive: cfg.interactive,   // otherwise Flutter owns the gestures
    fadeDuration: 0,
    attributionControl: false
  });
  map.setPadding({ top: 0, left: 0, right: 0, bottom: cfg.bottom });

  // The web hero's dusk sky and tints (JourneyHero.tsx TINTS.dark / DUSK_SKY).
  function paint(layer, prop, value) {
    try {
      if (map.getLayer(layer)) map.setPaintProperty(layer, prop, value);
    } catch (e) { /* a layer the style doesn't have is simply skipped */ }
  }

  map.on('style.load', function () {
    map.setFog({
      color: 'rgb(22,32,44)',
      'high-color': 'rgb(2,4,10)',
      'horizon-blend': 0.12,
      'space-color': cfg.background,
      'star-intensity': 0.35
    });
    paint('land', 'background-color', '#222d3c');
    paint('water', 'fill-color', '#0a101a');
    paint('national-park', 'fill-color', '#14251d');
    paint('landuse', 'fill-color', '#233044');

    if (cfg.night) {
      // NASA's static VIIRS composite: geographic night-light patterns.
      map.addSource('city-lights', {
        type: 'raster',
        tiles: ['https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/VIIRS_CityLights_2012/default/GoogleMapsCompatible_Level8/{z}/{y}/{x}.jpg'],
        tileSize: 256,
        maxzoom: 8,
        attribution: 'NASA Earth Observatory / NASA EOSDIS GIBS'
      });
      var firstLabel;
      var layers = (map.getStyle() || {}).layers || [];
      for (var i = 0; i < layers.length; i++) {
        if (layers[i].type === 'symbol') { firstLabel = layers[i].id; break; }
      }
      map.addLayer({
        id: 'city-light-imagery', type: 'raster', source: 'city-lights',
        paint: {
          'raster-opacity': 0.48, 'raster-fade-duration': 0,
          'raster-brightness-min': 0.02, 'raster-brightness-max': 0.9,
          'raster-contrast': 0.35, 'raster-saturation': -0.1
        }
      }, firstLabel);
    }

    // Event pins: a soft halo and a lime dot, like the web.
    var features = cfg.stops.map(function (s) {
      return { type: 'Feature', properties: { name: s.city },
               geometry: { type: 'Point', coordinates: [s.lng, s.lat] } };
    });
    map.addSource('stops', { type: 'geojson',
      data: { type: 'FeatureCollection', features: features } });
    map.addLayer({ id: 'stop-halo', type: 'circle', source: 'stops', paint: {
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 1, 8, 5, 14],
      'circle-color': '#CCFF00', 'circle-opacity': 0.16 } });
    map.addLayer({ id: 'stop-dot', type: 'circle', source: 'stops', paint: {
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 1, 2.6, 5, 5],
      'circle-color': '#CCFF00', 'circle-stroke-color': '#fff',
      'circle-stroke-width': 1.2 } });

    // A tap near a pin reports its city to the host: the WebView's FoxPin
    // channel on a phone, postMessage to the parent page on Flutter web.
    if (cfg.interactive) {
      map.on('click', function (e) {
        var r = 18;
        var hit = map.queryRenderedFeatures(
          [[e.point.x - r, e.point.y - r], [e.point.x + r, e.point.y + r]],
          { layers: ['stop-dot'] });
        if (!hit.length) return;
        var city = hit[0].properties.name;
        if (window.FoxPin && window.FoxPin.postMessage) {
          window.FoxPin.postMessage(city);
        } else {
          window.parent.postMessage(
            JSON.stringify({ fox: 'pin', city: city }), '*');
        }
      });
    }
  });

  // Callout cards, attached to the globe so they turn with it. Built with
  // DOM calls (textContent), never string-built HTML.
  var cards = [];
  cfg.stops.slice(0, cfg.maxCards).forEach(function (s, i) {
    var card = document.createElement('div');
    card.className = 'card';
    if (typeof s.img === 'string' && s.img.indexOf('https://') === 0) {
      var img = document.createElement('img');
      img.src = s.img; img.alt = '';
      card.appendChild(img);
    }
    var col = document.createElement('div');
    var city = document.createElement('div'); city.className = 'city'; city.textContent = s.city;
    var title = document.createElement('div'); title.className = 'title'; title.textContent = s.title || s.city;
    var meta = document.createElement('div'); meta.className = 'meta';
    meta.textContent = s.count + (s.count === 1 ? ' event' : ' events') + ' \\u00b7 view \\u2192';
    col.appendChild(city); col.appendChild(title); col.appendChild(meta);
    card.appendChild(col);

    // Neighbouring stops sit a few degrees apart, so alternate the corner each
    // card hangs from: up-and-left, then down-and-right, then up-and-right.
    var corner = [
      { anchor: 'bottom-right', offset: [-8, -8] },
      { anchor: 'top-left', offset: [8, 8] },
      { anchor: 'bottom-left', offset: [8, -8] }
    ][i % 3];
    new mapboxgl.Marker({
      element: card, anchor: corner.anchor, offset: corner.offset
    }).setLngLat([s.lng, s.lat]).addTo(map);
    // Which way the card extends from its pin, so it can be kept on screen.
    cards.push({
      el: card, lat: s.lat, lng: s.lng,
      extendsLeft: corner.anchor.indexOf('right') >= 0
    });
  });

  // A card shows only while its place faces the viewer (within ~72 degrees of
  // the centre, as the web does with its own dot-product test) and the whole
  // card fits on screen — it fades out rather than being clipped at an edge.
  function updateCards() {
    var c = map.getCenter(), rad = Math.PI / 180, minDot = Math.cos(72 * rad);
    var W = el.clientWidth;
    for (var i = 0; i < cards.length; i++) {
      var k = cards[i];
      var dot = Math.sin(c.lat * rad) * Math.sin(k.lat * rad) +
        Math.cos(c.lat * rad) * Math.cos(k.lat * rad) * Math.cos((k.lng - c.lng) * rad);
      var visible = dot > minDot;
      if (visible && W) {
        var p = map.project([k.lng, k.lat]);
        var w = k.el.offsetWidth + 16;
        visible = k.extendsLeft ? p.x - w > 4 : p.x + w < W - 4;
      }
      k.el.style.opacity = visible ? '1' : '0';
    }
  }

  // The container is measured before the iframe / WebView has laid out, so
  // re-fit whenever its real size arrives or changes.
  function refit() {
    map.resize();
    map.setPadding({ top: 0, left: 0, right: 0, bottom: cfg.bottom });
    if (cfg.zoom == null && !touched) map.setZoom(fitZoom());
  }
  if (window.ResizeObserver) new ResizeObserver(refit).observe(el);
  window.addEventListener('resize', refit);
  map.on('load', refit);

  // A person turning the globe by hand stops the spin.
  var touched = false;
  if (cfg.interactive) {
    ['mousedown', 'touchstart', 'wheel'].forEach(function (t) {
      el.addEventListener(t, function () { touched = true; }, { passive: true });
    });
  }

  var last = performance.now();
  function tick(now) {
    var dt = Math.min(0.1, (now - last) / 1000);
    last = now;
    if (document.visibilityState === 'visible') {
      if (cfg.spin && !touched) {
        var c = map.getCenter();
        // Eastward spin, like the web: the view's longitude decreases.
        c.lng -= dt * cfg.speed;
        map.jumpTo({ center: c });
      }
      updateCards();
    }
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
})();
</script>
</body>
</html>
''';
}
