import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {logger} from "firebase-functions";

initializeApp();

const googleMapsApiKey = defineSecret("GOOGLE_MAPS_API_KEY");
const db = getFirestore();
const cacheTtlMs = 6 * 60 * 60 * 1000;

type PlaceType = "hotel" | "restaurant";

type RankedPlace = {
  id: string;
  name: string;
  rating: number;
  reviewCount: number;
  distance: number;
  lat: number;
  lng: number;
  openNow?: boolean | null;
  photoReference?: string | null;
  score: number;
  priceLevel?: number | null;
};

export const searchDestination = onCall(
  {secrets: [googleMapsApiKey]},
  async (request) => {
    const query = cleanString(request.data?.query);
    if (!query) throw new HttpsError("invalid-argument", "Destination is required.");

    const cacheKey = `destination_${slug(query)}`;
    const cached = await getCache(cacheKey);
    if (cached) return cached;

    const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
    url.searchParams.set("address", query);
    url.searchParams.set("key", googleMapsApiKey.value());

    const json = await fetchJson(url);
    const first = json.results?.[0];
    if (!first) throw new HttpsError("not-found", "Destination not found.");

    const payload = {
      name: first.formatted_address as string,
      lat: Number(first.geometry.location.lat),
      lng: Number(first.geometry.location.lng),
    };
    await setCache(cacheKey, payload);
    return payload;
  },
);

export const searchHotels = onCall(
  {secrets: [googleMapsApiKey]},
  async (request) => {
    const destination = cleanString(request.data?.destination);
    const lat = Number(request.data?.lat);
    const lng = Number(request.data?.lng);
    validateLatLng(lat, lng);

    const cacheKey = `hotel_v2_${slug(destination || `${lat}_${lng}`)}`;
    const cached = await getCache(cacheKey);
    if (cached) return cached;

    const places = await nearbySearch({
      lat,
      lng,
      radius: 5000,
      type: "lodging",
    });
    const payload = rankPlaces(normalizePlaces(places, lat, lng), "hotel");
    await setCache(cacheKey, payload);
    return payload;
  },
);

export const searchRestaurants = onCall(
  {secrets: [googleMapsApiKey]},
  async (request) => {
    const hotelName = cleanString(request.data?.hotelName);
    const lat = Number(request.data?.lat);
    const lng = Number(request.data?.lng);
    validateLatLng(lat, lng);

    const cacheKey = `restaurant_v2_${slug(hotelName || `${lat}_${lng}`)}`;
    const cached = await getCache(cacheKey);
    if (cached) return cached;

    const places = await nearbySearch({
      lat,
      lng,
      radius: 1000,
      type: "restaurant",
      rankByDistance: true,
    });
    const payload = rankPlaces(normalizePlaces(places, lat, lng), "restaurant");
    await setCache(cacheKey, payload);
    return payload;
  },
);

async function nearbySearch(input: {
  lat: number;
  lng: number;
  radius: number;
  type: string;
  rankByDistance?: boolean;
}) {
  const url = new URL("https://maps.googleapis.com/maps/api/place/nearbysearch/json");
  url.searchParams.set("location", `${input.lat},${input.lng}`);
  url.searchParams.set("type", input.type);
  url.searchParams.set("key", googleMapsApiKey.value());
  if (input.rankByDistance) {
    url.searchParams.set("rankby", "distance");
  } else {
    url.searchParams.set("radius", String(input.radius));
  }
  const json = await fetchJson(url);
  return json.results ?? [];
}

function normalizePlaces(
  places: Record<string, any>[],
  originLat: number,
  originLng: number,
): Omit<RankedPlace, "score">[] {
  return places.slice(0, 12).map((place) => {
    const lat = Number(place.geometry?.location?.lat);
    const lng = Number(place.geometry?.location?.lng);
    return {
      id: String(place.place_id),
      name: String(place.name ?? "Unknown place"),
      rating: Number(place.rating ?? 0),
      reviewCount: Number(place.user_ratings_total ?? 0),
      distance: distanceMeters(originLat, originLng, lat, lng),
      lat,
      lng,
      openNow: place.opening_hours?.open_now ?? null,
      photoReference: place.photos?.[0]?.photo_reference ?? null,
      priceLevel: place.price_level ?? null,
    };
  });
}

export const getPlaceReviews = onCall(
  {secrets: [googleMapsApiKey]},
  async (request) => {
    const placeId = cleanString(request.data?.placeId);
    if (!placeId) throw new HttpsError("invalid-argument", "placeId is required.");

    const cacheKey = `reviews_${placeId}`;
    const cached = await getCache(cacheKey);
    if (cached) return cached;

    const url = new URL("https://maps.googleapis.com/maps/api/place/details/json");
    url.searchParams.set("place_id", placeId);
    url.searchParams.set("fields", "reviews,price_level,editorial_summary,formatted_address,website");
    url.searchParams.set("language", "id");
    url.searchParams.set("reviews_sort", "newest");
    url.searchParams.set("key", googleMapsApiKey.value());

    const json = await fetchJson(url);
    const result = json.result ?? {};

    const reviews = (result.reviews ?? []).slice(0, 10).map((r: Record<string, any>) => ({
      authorName: String(r.author_name ?? ""),
      authorPhoto: String(r.profile_photo_url ?? ""),
      rating: Number(r.rating ?? 0),
      text: String(r.text ?? ""),
      relativeTime: String(r.relative_time_description ?? ""),
    }));

    const payload = {
      priceLevel: result.price_level ?? null,
      editorialSummary: result.editorial_summary?.overview ?? null,
      address: result.formatted_address ?? null,
      website: result.website ?? null,
      reviews,
    };

    await setCache(cacheKey, payload);
    return payload;
  },
);

export const placePhoto = onRequest(
  {secrets: [googleMapsApiKey]},
  async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    response.set("Access-Control-Allow-Headers", "Content-Type");

    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }

    const ref = cleanString(request.query.ref);
    if (!ref) {
      response.status(400).send("Missing photo reference.");
      return;
    }

    const url = new URL("https://maps.googleapis.com/maps/api/place/photo");
    url.searchParams.set("maxwidth", "900");
    url.searchParams.set("photo_reference", ref);
    url.searchParams.set("key", googleMapsApiKey.value());

    const googleResponse = await fetch(url, {redirect: "follow"});
    if (!googleResponse.ok) {
      logger.error("Google photo error", {
        status: googleResponse.status,
        statusText: googleResponse.statusText,
      });
      response.status(googleResponse.status).send("Photo unavailable.");
      return;
    }

    const contentType =
      googleResponse.headers.get("content-type") ?? "image/jpeg";
    const bytes = Buffer.from(await googleResponse.arrayBuffer());
    response.set("Cache-Control", "public, max-age=21600");
    response.set("Content-Type", contentType);
    response.status(200).send(bytes);
  },
);

function rankPlaces(
  places: Omit<RankedPlace, "score">[],
  type: PlaceType,
): RankedPlace[] {
  const weights = type === "hotel"
    ? {rating: 0.5, review: 0.2, distance: 0.3, maxDistance: 5000}
    : {rating: 0.6, review: 0.3, distance: 0.1, maxDistance: 1000};

  return places
    .map((place) => {
      const ratingScore = (place.rating / 5) * 100;
      const reviewScore = (Math.min(place.reviewCount, 1500) / 1500) * 100;
      const distanceScore =
        Math.max(0, (weights.maxDistance - place.distance) / weights.maxDistance) * 100;
      const score =
        ratingScore * weights.rating +
        reviewScore * weights.review +
        distanceScore * weights.distance;
      return {...place, score};
    })
    .sort((a, b) => b.score - a.score);
}

async function fetchJson(url: URL) {
  const response = await fetch(url);
  if (!response.ok) {
    logger.error("Google API HTTP error", {
      status: response.status,
      statusText: response.statusText,
      url: redactKey(url),
    });
    throw new HttpsError("unavailable", "Google API request failed.");
  }
  const json = await response.json() as Record<string, any>;
  if (json.status && !["OK", "ZERO_RESULTS"].includes(json.status)) {
    logger.error("Google API status error", {
      status: json.status,
      errorMessage: json.error_message,
      url: redactKey(url),
    });
    throw new HttpsError("unavailable", String(json.error_message ?? json.status));
  }
  return json;
}

async function getCache(key: string) {
  const snapshot = await db.collection("cached_places").doc(key).get();
  const data = snapshot.data();
  if (!data?.expiresAt || data.expiresAt.toMillis() < Date.now()) return null;
  return data.payload;
}

async function setCache(key: string, payload: unknown) {
  await db.collection("cached_places").doc(key).set({
    payload,
    expiresAt: Timestamp.fromMillis(Date.now() + cacheTtlMs),
    updatedAt: Timestamp.now(),
  });
}

function cleanString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function slug(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");
}

function validateLatLng(lat: number, lng: number) {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new HttpsError("invalid-argument", "Valid coordinates are required.");
  }
}

function distanceMeters(lat1: number, lng1: number, lat2: number, lng2: number) {
  const radius = 6371000;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return Math.round(radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

function toRadians(value: number) {
  return value * Math.PI / 180;
}

function redactKey(url: URL) {
  const safeUrl = new URL(url.toString());
  safeUrl.searchParams.set("key", "REDACTED");
  return safeUrl.toString();
}
