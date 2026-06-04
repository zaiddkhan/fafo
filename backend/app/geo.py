import geohash
from math import cos, radians


GEOHASH_PRECISION = 5


def encode_geohash(lat: float, lng: float) -> str:
    return geohash.encode(lat, lng, precision=GEOHASH_PRECISION)


def geohash_bounds_for_radius(lat: float, lng: float, radius_km: float) -> list[tuple[str, str]]:
    """Return geohash range pairs that cover a bounding box around the point."""
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * max(cos(radians(lat)), 0.01))

    min_lat = lat - lat_delta
    max_lat = lat + lat_delta
    min_lng = lng - lng_delta
    max_lng = lng + lng_delta

    corners = [
        (min_lat, min_lng),
        (min_lat, max_lng),
        (max_lat, min_lng),
        (max_lat, max_lng),
        (lat, lng),
    ]

    hashes = set()
    for clat, clng in corners:
        h = geohash.encode(clat, clng, precision=GEOHASH_PRECISION)
        hashes.add(h)
        for neighbor in geohash.neighbors(h):
            hashes.add(neighbor)

    sorted_hashes = sorted(hashes)
    if not sorted_hashes:
        return []

    ranges = []
    start = sorted_hashes[0]
    prev = sorted_hashes[0]

    for h in sorted_hashes[1:]:
        if h[:GEOHASH_PRECISION - 1] == prev[:GEOHASH_PRECISION - 1]:
            prev = h
        else:
            ranges.append((start, prev + "~"))
            start = h
            prev = h
    ranges.append((start, prev + "~"))

    return ranges
