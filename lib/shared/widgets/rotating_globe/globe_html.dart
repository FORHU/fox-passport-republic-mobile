import 'dart:convert';

/// The JavaScript escape for "<" (backslash, u, 0, 0, 3, c). Replacing every
/// "<" inside the embedded JSON with it keeps a value such as
/// `</script>` from closing the page's script tag. Built from character codes
/// so the backslash sequence is not written out in this source file.
final String _jsLessThan = '${String.fromCharCode(0x5c)}u003c';

/// Mapbox GL JS release the globe page loads. Pinned so a CDN update can't
/// change how the globe looks or behaves underneath the app.
const mapboxGlVersion = '3.9.0';

/// How the globe is painted.
enum GlobeLook {
  /// The web hero's dusk sky and grey land, with the NASA city lights.
  standard,

  /// A navy sphere with a cyan edge glow, faint graticule lines, pulsing
  /// pins named on the map, and dashed routes from the first stop to the
  /// others (the welcome reel's globe).
  neon,
}

/// One place on the globe: a pin, and (for the busiest few) a callout card.
class GlobeStop {
  const GlobeStop({
    required this.city,
    required this.lat,
    required this.lng,
    required this.eventCount,
    this.title = '',
    this.imageUrl,
    this.rgb,
  });

  final String city;
  final double lat;
  final double lng;

  /// How many events happen here — the card's "38 EVENTS".
  final int eventCount;

  /// The headline event's name, shown on the card.
  final String title;
  final String? imageUrl;

  /// The pin's colour as `0xRRGGBB` (the neon look); lime when null.
  final int? rgb;

  Map<String, Object?> toJson() => {
        'city': city,
        'lat': lat,
        'lng': lng,
        'count': eventCount,
        'title': title,
        'img': imageUrl,
        'rgb': rgb,
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
/// - [spin] false stops the globe turning; [animate] false also stills the
///   pulsing pins (reduced-motion users get both off).
/// - The page tells its host when the map has drawn (the `FoxGlobe` channel on
///   a phone, a `{fox: 'ready'}` message on Flutter web), and obeys
///   `foxSetRunning(false / true)` (or a `{fox: 'run', on}` message) to freeze
///   and resume its motion without reloading.
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
  GlobeLook look = GlobeLook.standard,
  bool animate = true,
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
    'look': look.name,
    'animate': animate,
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

  var neon = cfg.look === 'neon';

  // A pin's colour: the stop's own (0xRRGGBB), else the web's lime.
  function pinColor(rgb) {
    return rgb == null ? '#CCFF00' : '#' + ('000000' + rgb.toString(16)).slice(-6);
  }

  // Latitude and longitude lines every 30 degrees, for the neon look.
  function graticule() {
    var lines = [], lat, lng, pts;
    for (lng = -180; lng < 180; lng += 30) {
      pts = [];
      for (lat = -80; lat <= 80; lat += 4) pts.push([lng, lat]);
      lines.push({ type: 'Feature', properties: {},
                   geometry: { type: 'LineString', coordinates: pts } });
    }
    for (lat = -60; lat <= 60; lat += 30) {
      pts = [];
      for (lng = -180; lng <= 180; lng += 4) pts.push([lng, lat]);
      lines.push({ type: 'Feature', properties: {},
                   geometry: { type: 'LineString', coordinates: pts } });
    }
    return { type: 'FeatureCollection', features: lines };
  }

  map.on('style.load', function () {
    if (neon) {
      // A navy sphere with a cyan glow along its edge and no stars.
      map.setFog({
        color: 'rgb(6,12,30)',
        'high-color': 'rgb(0,120,160)',
        'horizon-blend': 0.22,
        'space-color': cfg.background,
        'star-intensity': 0
      });
      // Land a shade lighter than the sea, so the islands read.
      paint('land', 'background-color', '#111c40');
      paint('water', 'fill-color', '#060a1c');
      paint('national-park', 'fill-color', '#111c40');
      paint('landuse', 'fill-color', '#0f1b42');
      // Keep the names of countries, provinces and seas, softly; hide the
      // rest (roads, shops and the like), which would only add noise.
      var all = (map.getStyle() || {}).layers || [];
      for (var j = 0; j < all.length; j++) {
        if (all[j].type !== 'symbol') continue;
        if (/^(country-label|state-label|water-point-label|natural-point-label)/.test(all[j].id)) {
          paint(all[j].id, 'text-color', '#8ca7cf');
          paint(all[j].id, 'text-halo-color', '#050914');
          paint(all[j].id, 'text-halo-width', 1.2);
        } else {
          map.setLayoutProperty(all[j].id, 'visibility', 'none');
        }
      }
      // A thin glowing coastline around every island.
      try {
        map.addLayer({ id: 'coast', type: 'line', source: 'composite',
          'source-layer': 'water', paint: {
            'line-color': '#6fd8ff', 'line-opacity': 0.4,
            'line-width': ['interpolate', ['linear'], ['zoom'], 1, 0.5, 5, 1.2]
          } });
      } catch (e) { /* a style without the water layer simply has no coast */ }
      map.addSource('graticule', { type: 'geojson', data: graticule() });
      map.addLayer({ id: 'graticule', type: 'line', source: 'graticule',
        paint: { 'line-color': 'rgba(159,216,255,0.1)', 'line-width': 1 } });
    } else {
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
    }

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
      return { type: 'Feature',
               properties: { name: s.city, color: pinColor(s.rgb) },
               geometry: { type: 'Point', coordinates: [s.lng, s.lat] } };
    });
    map.addSource('stops', { type: 'geojson',
      data: { type: 'FeatureCollection', features: features } });
    map.addLayer({ id: 'stop-halo', type: 'circle', source: 'stops', paint: {
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 1, 8, 5, 14],
      'circle-color': ['get', 'color'],
      'circle-opacity': neon ? 0.6 : 0.16 } });
    map.addLayer({ id: 'stop-dot', type: 'circle', source: 'stops', paint: {
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 1, 2.6, 5, 5],
      'circle-color': ['get', 'color'],
      'circle-stroke-color': neon ? ['get', 'color'] : '#fff',
      'circle-stroke-width': neon ? 0 : 1.2,
      'circle-blur': neon ? 0.4 : 0 } });
    if (neon) {
      // Dashed routes from the first stop (the hub) to each of the others.
      if (cfg.stops.length > 1) {
        var hub = cfg.stops[0];
        map.addSource('routes', { type: 'geojson', data: {
          type: 'FeatureCollection',
          features: cfg.stops.slice(1).map(function (s) {
            return { type: 'Feature', properties: {}, geometry: {
              type: 'LineString',
              coordinates: [[hub.lng, hub.lat], [s.lng, s.lat]] } };
          }) } });
        map.addLayer({ id: 'routes', type: 'line', source: 'routes', paint: {
          'line-color': '#CCFF00', 'line-opacity': 0.5,
          'line-width': 1.2, 'line-dasharray': [3, 4] } }, 'stop-halo');
      }
      // The place names, drawn here because the base labels are hidden.
      map.addLayer({ id: 'stop-label', type: 'symbol', source: 'stops',
        layout: {
          'text-field': ['get', 'name'],
          'text-font': ['DIN Pro Medium', 'Arial Unicode MS Regular'],
          'text-size': 10, 'text-letter-spacing': 0.1,
          'text-transform': 'uppercase', 'text-anchor': 'left',
          'text-offset': [0.9, 0], 'text-allow-overlap': true },
        paint: { 'text-color': '#cfe6ff', 'text-halo-color': '#050914',
                 'text-halo-width': 1.5 } });
    }

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

  // The host can freeze and resume the motion (pause, or a finger held down)
  // without reloading the page.
  var running = true;
  window.foxSetRunning = function (on) { running = !!on; };
  window.addEventListener('message', function (e) {
    try {
      var m = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
      if (m && m.fox === 'run') window.foxSetRunning(m.on);
    } catch (err) { /* some other page's message */ }
  });

  // Tell the host once the map has drawn, so it can swap its still picture
  // for this globe.
  map.once('load', function () {
    if (window.FoxGlobe && window.FoxGlobe.postMessage) {
      window.FoxGlobe.postMessage('ready');
    } else {
      window.parent.postMessage(JSON.stringify({ fox: 'ready' }), '*');
    }
  });

  // Route dashes flow along their lines: Mapbox cannot animate a dash offset,
  // so step through the dash patterns that shift it.
  var DASHES = [
    [0, 4, 3], [0.5, 4, 2.5], [1, 4, 2], [1.5, 4, 1.5], [2, 4, 1],
    [2.5, 4, 0.5], [3, 4, 0], [0, 0.5, 3, 3.5], [0, 1, 3, 3],
    [0, 1.5, 3, 2.5], [0, 2, 3, 2], [0, 2.5, 3, 1.5], [0, 3, 3, 1],
    [0, 3.5, 3, 0.5]
  ];
  var dashStep = -1;

  var last = performance.now();
  function tick(now) {
    var dt = Math.min(0.1, (now - last) / 1000);
    last = now;
    if (document.visibilityState === 'visible') {
      if (running && cfg.spin && !touched) {
        var c = map.getCenter();
        // Eastward spin, like the web: the view's longitude decreases.
        c.lng -= dt * cfg.speed;
        map.jumpTo({ center: c });
      }
      updateCards();
      if (neon && running && cfg.animate && map.getLayer('routes')) {
        var step = Math.floor(now / 60) % DASHES.length;
        if (step !== dashStep) {
          dashStep = step;
          map.setPaintProperty('routes', 'line-dasharray', DASHES[step]);
        }
      }
      if (neon && running && cfg.animate && map.getLayer('stop-halo')) {
        // Each pin's halo opens up and fades, over 2.4 seconds.
        var p = (now / 2400) % 1;
        map.setPaintProperty('stop-halo', 'circle-radius',
          ['interpolate', ['linear'], ['zoom'],
           1, 6 + 14 * p, 5, 10 + 22 * p]);
        map.setPaintProperty('stop-halo', 'circle-opacity', 0.6 * (1 - p));
      }
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
