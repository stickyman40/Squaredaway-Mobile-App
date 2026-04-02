import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const OFF_BASE = "https://world.openfoodfacts.org/api/v2/product";
const OFF_FIELDS = [
  "product_name",
  "brands",
  "image_url",
  "categories_tags",
  "serving_size",
  "serving_quantity",
  "nutriments",
  "ingredients_text",
].join(",");

type IngredientFlag = {
  name: string;
  concern: string;
  severity: string;
};

type NormalizedProduct = {
  barcode: string;
  name: string;
  brand: string | null;
  image_url: string | null;
  category: string;
  serving_size: string;
  serving_size_g: number;
  nutrition: Record<string, number>;
  flags: IngredientFlag[];
  ingredients_text: string;
  data_source: string;
};

type DietagramFoodMatch = {
  id: string;
  name: string;
  kind: string;
  kind_label: string;
  category_id: string | null;
  nutrition: Record<string, number>;
};

type DietagramScannerContext = {
  source: string;
  search_term: string;
  exact_match: DietagramFoodMatch | null;
  top_match: DietagramFoodMatch | null;
  matches: DietagramFoodMatch[];
};

type USDAFoodMatch = {
  id: string;
  name: string;
  brand: string | null;
  data_type: string;
  nutrition: Record<string, number>;
};

type USDAScannerContext = {
  source: string;
  search_term: string;
  exact_match: USDAFoodMatch | null;
  top_match: USDAFoodMatch | null;
  matches: USDAFoodMatch[];
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);
const rapidApiKey = Deno.env.get("RAPIDAPI_KEY") ?? "";
const rapidApiHost = Deno.env.get("RAPIDAPI_HOST") ?? "big-product-data.p.rapidapi.com";
const rapidApiBaseUrl = Deno.env.get("RAPIDAPI_BASE_URL") ?? `https://${rapidApiHost}`;
const rapidApiProductPathTemplate = Deno.env.get("RAPIDAPI_PRODUCT_PATH_TEMPLATE") ?? "/gtin/{barcode}";
const rapidApiFoodPathTemplate = Deno.env.get("RAPIDAPI_FOOD_PATH_TEMPLATE")
  ?? (rapidApiHost === "dietagram.p.rapidapi.com" ? "/apiFood.php?name={query}" : "");
const usdaApiKey = Deno.env.get("USDA_API_KEY") ?? "";
const usdaSearchBaseUrl = Deno.env.get("USDA_SEARCH_BASE_URL") ?? "https://api.nal.usda.gov/fdc/v1/foods/search";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { barcode, user_id } = await req.json();
    if (!barcode || typeof barcode !== "string") {
      return jsonResponse({ error: "barcode is required" }, 400);
    }

    const cleanBarcode = barcode.trim();

    const { data: cached } = await supabase
      .from("fuel_products")
      .select("*, fuel_product_scores(*)")
      .eq("barcode", cleanBarcode)
      .maybeSingle();

    if (cached) {
      const preferredRefresh = await preferredProductForBarcode(cleanBarcode);
      if (preferredRefresh && shouldReplaceCachedProduct(cached, preferredRefresh)) {
        const merged = mergeNormalizedProduct(cached, preferredRefresh);
        const scores = computeScores(merged.nutrition, merged.category, merged.flags);
        const saved = await persistNormalizedProduct(cleanBarcode, merged, scores, cached.id);
        const scanId = await recordScan(user_id, cleanBarcode, saved?.id ?? cached.id);
        const baseProduct = saved
          ? {
              ...normalizeDbProduct(saved),
              scores,
            }
          : {
              id: cached.id,
              ...merged,
              created_at: cached.created_at ?? new Date().toISOString(),
              scores,
            };
        return jsonResponse({
          found: true,
          product: await enrichScannerProduct(baseProduct),
          scan_id: scanId,
        });
      }

      const scanId = await recordScan(user_id, cleanBarcode, cached.id);
      const freshScores = computeScores(
        isRecord(cached.nutrition) ? cached.nutrition as Record<string, number> : {},
        String(cached.category ?? "Other"),
        Array.isArray(cached.flags) ? cached.flags as Array<{ severity: string }> : [],
      );
      await persistProductScores(cached.id, freshScores);
      return jsonResponse({
        found: true,
        product: await enrichScannerProduct({
          ...normalizeDbProduct(cached),
          scores: freshScores,
        }),
        scan_id: scanId,
      });
    }

    const normalized = await preferredProductForBarcode(cleanBarcode);
    if (!normalized) {
      return jsonResponse({ found: false, product: null, scan_id: null }, 200);
    }

    const scores = computeScores(normalized.nutrition, normalized.category, normalized.flags);
    const inserted = await persistNormalizedProduct(cleanBarcode, normalized, scores);

    if (!inserted) {
      const scanId = await recordScan(user_id, cleanBarcode, null);
      return jsonResponse({
        found: true,
        product: await enrichScannerProduct({
          id: crypto.randomUUID(),
          ...normalized,
          created_at: new Date().toISOString(),
          data_source: normalized.data_source,
          scores,
        }),
        scan_id: scanId,
      });
    }

    const scanId = await recordScan(user_id, cleanBarcode, inserted.id);
    return jsonResponse({
      found: true,
      product: await enrichScannerProduct({
        ...normalizeDbProduct(inserted),
        scores,
      }),
      scan_id: scanId,
    });
  } catch (error) {
    console.error("barcode-lookup error", error);
    return jsonResponse({ error: "Internal error. Please try again." }, 500);
  }
});

async function recordScan(userId: string | undefined, barcode: string, productId: string | null) {
  if (!userId) return null;
  const { data } = await supabase
    .from("fuel_scans")
    .insert({ user_id: userId, barcode, product_id: productId })
    .select("id")
    .single();
  return data?.id ?? null;
}

async function enrichScannerProduct(product: Record<string, any>) {
  const searchTerm = String(product.name ?? "");
  const [dietagram, usda] = await Promise.all([
    fetchDietagramScannerContext(searchTerm),
    fetchUSDAScannerContext(searchTerm),
  ]);

  let enriched: Record<string, any> = {
    ...product,
    dietagram: dietagram ?? null,
    usda: usda ?? null,
  };

  if (dietagram) {
    enriched = applyDietagramScannerFallback(enriched, dietagram);
  }
  if (usda) {
    enriched = applyUSDAFallback(enriched, usda);
  }

  return {
    ...enriched,
    dietagram: enriched.dietagram ?? dietagram ?? null,
    usda: enriched.usda ?? usda ?? null,
  };
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
    status,
  });
}

async function persistNormalizedProduct(
  barcode: string,
  normalized: NormalizedProduct,
  scores: ReturnType<typeof computeScores>,
  existingId?: string,
) {
  const payload = {
    barcode,
    name: normalized.name,
    brand: normalized.brand,
    image_url: normalized.image_url,
    category: normalized.category,
    serving_size: normalized.serving_size,
    serving_size_g: normalized.serving_size_g,
    nutrition: normalized.nutrition,
    flags: normalized.flags,
    ingredients_text: normalized.ingredients_text,
    data_source: normalized.data_source,
  };

  const query = existingId
    ? supabase.from("fuel_products").update(payload).eq("id", existingId)
    : supabase.from("fuel_products").insert(payload);
  const { data, error } = await query.select().single();
  if (error || !data) return null;

  await persistProductScores(data.id, scores);

  return data;
}

async function persistProductScores(
  productId: string,
  scores: ReturnType<typeof computeScores>,
) {
  await supabase.from("fuel_product_scores").upsert({
    product_id: productId,
    overall: scores.overall,
    fat_loss: scores.fat_loss,
    muscle_gain: scores.muscle_gain,
    performance: scores.performance,
    convenience: scores.convenience,
    fuel_rating: scores.rating,
    primary_reason: scores.primary_reason,
    factors: scores.factors,
    goal_guidance: scores.goal_guidance,
  });
}

function needsMetadataHydration(product: Record<string, any>) {
  return !product.brand || !product.image_url || !product.category || product.category === "Other";
}

async function preferredProductForBarcode(barcode: string): Promise<NormalizedProduct | null> {
  const [offProduct, rapidProduct] = await Promise.all([
    fetchOFFProduct(barcode),
    fetchRapidApiProduct(barcode),
  ]);

  if (offProduct) {
    return rapidProduct ? mergeNormalizedProduct(offProduct, sanitizeRapidOverlay(rapidProduct)) : offProduct;
  }

  return rapidProduct;
}

async function fetchDietagramScannerContext(searchTerm: string): Promise<DietagramScannerContext | null> {
  if (!searchTerm.trim() || !rapidApiKey || !rapidApiFoodPathTemplate) return null;

  for (const query of buildDietagramQueries(searchTerm)) {
    try {
      const response = await fetch(buildRapidApiFoodUrl(query), {
        headers: {
          "X-RapidAPI-Key": rapidApiKey,
          "X-RapidAPI-Host": rapidApiHost,
          "Accept": "application/json",
        },
      });

      if (!response.ok) {
        console.warn("RapidAPI food search failed", response.status, query);
        continue;
      }

      const payload = await response.json();
      const matches = normalizeDietagramFoodMatches(payload);
      if (matches.length === 0) continue;

      const exactMatch = findExactDietagramMatch(query, matches);
      return {
        source: "dietagram_food_search",
        search_term: query,
        exact_match: exactMatch,
        top_match: matches[0] ?? null,
        matches: matches.slice(0, 5),
      };
    } catch (error) {
      console.warn("RapidAPI food search error", error);
    }
  }

  return null;
}

async function fetchUSDAScannerContext(searchTerm: string): Promise<USDAScannerContext | null> {
  if (!searchTerm.trim() || !usdaApiKey) return null;

  for (const query of buildDietagramQueries(searchTerm)) {
    try {
      const response = await fetch(buildUSDASearchUrl(query));
      if (!response.ok) {
        console.warn("USDA food search failed", response.status, query);
        continue;
      }

      const payload = await response.json();
      const matches = normalizeUSDAFoodMatches(payload);
      if (matches.length === 0) continue;

      const exactMatch = findExactUSDAMatch(query, matches);
      return {
        source: "usda_food_search",
        search_term: query,
        exact_match: exactMatch,
        top_match: matches[0] ?? null,
        matches: matches.slice(0, 5),
      };
    } catch (error) {
      console.warn("USDA food search error", error);
    }
  }

  return null;
}

function applyDietagramScannerFallback(
  product: Record<string, any>,
  dietagram: DietagramScannerContext,
) {
  const selectedMatch = dietagram.exact_match
    ?? (shouldUseDietagramTopMatch(product, dietagram.top_match) ? dietagram.top_match : null);

  if (!selectedMatch || !shouldApplyDietagramFallback(product, selectedMatch)) {
    return {
      ...product,
      dietagram,
    };
  }

  const currentNutrition = isRecord(product.nutrition) ? product.nutrition as Record<string, number> : {};
  const mergedNutrition = mergeDietagramNutrition(currentNutrition, selectedMatch.nutrition);
  const resolvedCategory = resolveDietagramCategory(String(product.category ?? "Other"), selectedMatch);
  const flags = Array.isArray(product.flags) ? product.flags as Array<{ severity: string }> : [];

  return {
    ...product,
    category: resolvedCategory,
    nutrition: mergedNutrition,
    scores: computeScores(mergedNutrition, resolvedCategory, flags),
    dietagram: {
      ...dietagram,
      source: "dietagram_food_fallback",
    },
  };
}

function applyUSDAFallback(
  product: Record<string, any>,
  usda: USDAScannerContext,
) {
  const selectedMatch = usda.exact_match
    ?? (shouldUseUSDATopMatch(product, usda.top_match) ? usda.top_match : null);

  if (!selectedMatch || !shouldApplyUSDAFallback(product, selectedMatch)) {
    return {
      ...product,
      usda,
    };
  }

  const currentNutrition = isRecord(product.nutrition) ? product.nutrition as Record<string, number> : {};
  const mergedNutrition = mergeUSDANutrition(currentNutrition, selectedMatch.nutrition);
  const resolvedCategory = resolveUSDACategory(String(product.category ?? "Other"), selectedMatch);
  const flags = Array.isArray(product.flags) ? product.flags as Array<{ severity: string }> : [];

  return {
    ...product,
    category: resolvedCategory,
    nutrition: mergedNutrition,
    scores: computeScores(mergedNutrition, resolvedCategory, flags),
    usda: {
      ...usda,
      source: "usda_food_fallback",
    },
  };
}

function shouldReplaceCachedProduct(
  cached: Record<string, any>,
  incoming: NormalizedProduct,
) {
  if (cached.data_source !== incoming.data_source) return true;
  if (needsMetadataHydration(cached)) return true;

  const existingNutrition = isRecord(cached.nutrition) ? cached.nutrition as Record<string, number> : {};
  return ["calories", "protein_g", "carbs_g", "fat_g"].some((key) => {
    const previous = Number(existingNutrition[key] ?? 0);
    const next = Number(incoming.nutrition[key] ?? 0);
    return Math.abs(previous - next) > 0.5;
  });
}

function sanitizeRapidOverlay(product: NormalizedProduct): NormalizedProduct {
  return {
    ...product,
    brand: null,
    image_url: null,
    category: "Other",
    flags: [],
    ingredients_text: "",
    data_source: "openfoodfacts",
  };
}

function mergeNormalizedProduct(
  existing: Record<string, any>,
  incoming: NormalizedProduct,
): NormalizedProduct {
  const existingNutrition = isRecord(existing.nutrition) ? existing.nutrition as Record<string, number> : {};
  const existingFlags = Array.isArray(existing.flags) ? existing.flags as IngredientFlag[] : [];

  return {
    barcode: incoming.barcode,
    name: incoming.name || existing.name || "Unknown Product",
    brand: incoming.brand || existing.brand || null,
    image_url: incoming.image_url || existing.image_url || null,
    category: incoming.category !== "Other" ? incoming.category : (existing.category || "Other"),
    serving_size: incoming.serving_size || existing.serving_size || "100g",
    serving_size_g: incoming.serving_size_g || existing.serving_size_g || 100,
    nutrition: mergeNutrition(existingNutrition, incoming.nutrition),
    flags: incoming.flags.length > 0 ? incoming.flags : existingFlags,
    ingredients_text: incoming.ingredients_text || existing.ingredients_text || "",
    data_source: incoming.data_source,
  };
}

function mergeNutrition(
  existing: Record<string, number>,
  incoming: Record<string, number>,
) {
  const primaryKeys = new Set([
    "calories",
    "protein_g",
    "carbs_g",
    "fat_g",
    "cal_per_100g",
    "protein_per_100g",
    "carbs_per_100g",
    "fat_per_100g",
  ]);

  const merged: Record<string, number> = { ...existing };
  for (const [key, value] of Object.entries(incoming)) {
    if (primaryKeys.has(key)) {
      merged[key] = value;
      continue;
    }

    if (value > 0 || merged[key] === undefined) {
      merged[key] = value;
    }
  }

  return merged;
}

async function fetchRapidApiProduct(barcode: string): Promise<NormalizedProduct | null> {
  if (!rapidApiKey) return null;

  try {
    const response = await fetch(buildRapidApiProductUrl(barcode), {
      headers: {
        "X-RapidAPI-Key": rapidApiKey,
        "X-RapidAPI-Host": rapidApiHost,
        "Accept": "application/json",
      },
    });

    if (!response.ok) {
      console.warn("RapidAPI lookup failed", response.status, barcode);
      return null;
    }

    const payload = await response.json();
    return normalizeRapidApiProduct(barcode, payload);
  } catch (error) {
    console.warn("RapidAPI lookup error", error);
    return null;
  }
}

async function fetchOFFProduct(barcode: string): Promise<NormalizedProduct | null> {
  const offRes = await fetch(`${OFF_BASE}/${barcode}.json?fields=${OFF_FIELDS}`, {
    headers: { "User-Agent": "SquaredAway/1.0 (Fuel Check)" },
  });

  if (!offRes.ok) return null;

  const offData = await offRes.json();
  if (offData.status !== 1 || !offData.product) return null;

  return normalizeOFFProduct(barcode, offData.product);
}

function buildRapidApiProductUrl(barcode: string) {
  const path = rapidApiProductPathTemplate.replaceAll("{barcode}", encodeURIComponent(barcode));
  return new URL(path, rapidApiBaseUrl).toString();
}

function buildRapidApiFoodUrl(query: string) {
  const path = rapidApiFoodPathTemplate.replaceAll("{query}", encodeURIComponent(query));
  return new URL(path, rapidApiBaseUrl).toString();
}

function buildUSDASearchUrl(query: string) {
  const url = new URL(usdaSearchBaseUrl);
  url.searchParams.set("query", query);
  url.searchParams.set("pageSize", "5");
  url.searchParams.set("api_key", usdaApiKey);
  return url.toString();
}

function normalizeOFFProduct(barcode: string, product: Record<string, unknown>) {
  const name = String(product.product_name ?? "").trim();
  if (!name) return null;

  const nutriments = (product.nutriments ?? {}) as Record<string, unknown>;
  const servingG = parseFloat(String(product.serving_quantity ?? "100")) || 100;
  const factor = servingG / 100;

  const nutrition = {
    calories: round(get100(nutriments, "energy-kcal") * factor),
    protein_g: round(get100(nutriments, "proteins") * factor),
    carbs_g: round(get100(nutriments, "carbohydrates") * factor),
    fat_g: round(get100(nutriments, "fat") * factor),
    saturated_fat_g: round(get100(nutriments, "saturated-fat") * factor),
    fiber_g: round(get100(nutriments, "fiber") * factor),
    sugar_g: round(get100(nutriments, "sugars") * factor),
    sodium_mg: round(get100(nutriments, "sodium") * factor * 1000),
    potassium_mg: round(get100(nutriments, "potassium") * factor * 1000),
    cal_per_100g: round(get100(nutriments, "energy-kcal")),
    protein_per_100g: round(get100(nutriments, "proteins")),
    carbs_per_100g: round(get100(nutriments, "carbohydrates")),
    fat_per_100g: round(get100(nutriments, "fat")),
    sugar_per_100g: round(get100(nutriments, "sugars")),
    sodium_per_100g: round(get100(nutriments, "sodium") * 1000),
  };

  const ingredientsText = String(product.ingredients_text ?? "");
  const flags = flagIngredients(ingredientsText);

  return {
    barcode,
    name,
    brand: String(product.brands ?? "").split(",")[0].trim() || null,
    image_url: product.image_url ? String(product.image_url) : null,
    category: mapCategory((product.categories_tags as string[] | undefined) ?? []),
    serving_size: String(product.serving_size ?? `${servingG}g`),
    serving_size_g: servingG,
    nutrition,
    flags,
    ingredients_text: ingredientsText,
    data_source: "openfoodfacts",
  };
}

function normalizeRapidApiProduct(barcode: string, payload: unknown): NormalizedProduct | null {
  const product = extractRapidApiProduct(payload);
  if (!product) return null;

  const name = firstText(product, [
    "product_name",
    "name",
    "title",
    "item_name",
    "description_short",
  ]).trim();
  if (!name) return null;

  const nutritionSource = firstRecord(product, [
    "nutrition",
    "nutriments",
    "nutrients",
    "nutrition_facts",
    "nutritionFacts",
  ]) ?? product;

  const servingSizeText = firstText(product, ["serving_size", "serving", "size", "servingSize"]).trim();
  const servingSizeG = parseServingSizeGrams(servingSizeText)
    ?? firstNumber(product, ["serving_size_g", "serving_g", "serving_grams"])
    ?? 100;

  const calories = firstNumber(nutritionSource, [
    "calories",
    "caloric",
    "energy-kcal",
    "energy_kcal",
    "energyKcal",
    "kcal",
  ]) ?? 0;
  const protein = firstNumber(nutritionSource, [
    "protein_g",
    "protein",
    "proteins",
  ]) ?? 0;
  const carbs = firstNumber(nutritionSource, [
    "carbs_g",
    "carbon",
    "carbohydrates",
    "carbs",
  ]) ?? 0;
  const fat = firstNumber(nutritionSource, [
    "fat_g",
    "fat",
    "total_fat",
  ]) ?? 0;
  const saturatedFat = firstNumber(nutritionSource, [
    "saturated_fat_g",
    "saturated-fat",
    "saturated_fat",
  ]) ?? 0;
  const fiber = firstNumber(nutritionSource, [
    "fiber_g",
    "fiber",
    "fibre",
  ]) ?? 0;
  const sugar = firstNumber(nutritionSource, [
    "sugar_g",
    "sugars",
    "sugar",
  ]) ?? 0;
  const sodium = firstNumber(nutritionSource, [
    "sodium_mg",
    "sodium",
  ]) ?? 0;
  const potassium = firstNumber(nutritionSource, [
    "potassium_mg",
    "potassium",
  ]) ?? 0;

  const calPer100g = firstNumber(nutritionSource, ["cal_per_100g", "energy-kcal_100g", "energy_kcal_100g"]) ?? calories;
  const proteinPer100g = firstNumber(nutritionSource, ["protein_per_100g", "proteins_100g", "protein_100g"]) ?? protein;
  const carbsPer100g = firstNumber(nutritionSource, ["carbs_per_100g", "carbohydrates_100g", "carbs_100g"]) ?? carbs;
  const fatPer100g = firstNumber(nutritionSource, ["fat_per_100g", "fat_100g", "total_fat_100g"]) ?? fat;
  const sugarPer100g = firstNumber(nutritionSource, ["sugar_per_100g", "sugars_100g", "sugar_100g"]) ?? sugar;
  const sodiumPer100g = firstNumber(nutritionSource, ["sodium_per_100g", "sodium_100g"]) ?? sodium;

  const ingredientsText = firstText(product, [
    "ingredients_text",
    "ingredients",
    "ingredient_statement",
    "description",
  ]);
  const flags = flagIngredients(ingredientsText);

  return {
    barcode,
    name,
    brand: firstText(product, ["brand", "brand_name", "manufacturer"]) || null,
    image_url: firstImageUrl(product),
    category: mapRapidApiCategory(product),
    serving_size: servingSizeText || `${servingSizeG}g`,
    serving_size_g: servingSizeG,
    nutrition: {
      calories: round(calories),
      protein_g: round(protein),
      carbs_g: round(carbs),
      fat_g: round(fat),
      saturated_fat_g: round(saturatedFat),
      fiber_g: round(fiber),
      sugar_g: round(sugar),
      sodium_mg: round(normalizeMilligrams(sodium)),
      potassium_mg: round(normalizeMilligrams(potassium)),
      cal_per_100g: round(calPer100g),
      protein_per_100g: round(proteinPer100g),
      carbs_per_100g: round(carbsPer100g),
      fat_per_100g: round(fatPer100g),
      sugar_per_100g: round(sugarPer100g),
      sodium_per_100g: round(normalizeMilligrams(sodiumPer100g)),
    },
    flags,
    ingredients_text: ingredientsText,
    data_source: "rapidapi",
  };
}

function normalizeDbProduct(row: Record<string, any>) {
  const relation = row.fuel_product_scores;
  const scores = Array.isArray(relation) ? relation[0] : relation;

  return {
    id: row.id,
    barcode: row.barcode,
    name: row.name,
    brand: row.brand,
    image_url: row.image_url,
    category: row.category,
    serving_size: row.serving_size,
    serving_size_g: row.serving_size_g,
    nutrition: row.nutrition,
    flags: row.flags ?? [],
    data_source: row.data_source ?? "cached",
    created_at: row.created_at ?? new Date().toISOString(),
    scores: scores
      ? {
          overall: scores.overall,
          fat_loss: scores.fat_loss,
          muscle_gain: scores.muscle_gain,
          performance: scores.performance,
          convenience: scores.convenience,
          rating: scores.fuel_rating,
          primary_reason: scores.primary_reason,
          factors: scores.factors ?? [],
          goal_guidance: scores.goal_guidance ?? [],
          computed_at: scores.computed_at ?? new Date().toISOString(),
        }
      : null,
  };
}

function normalizeDietagramFoodMatches(payload: unknown): DietagramFoodMatch[] {
  if (!isRecord(payload)) return [];
  const matches = Array.isArray(payload.dishes) ? payload.dishes.filter(isRecord) : [];

  const normalized: DietagramFoodMatch[] = [];
  matches.forEach((entry, index) => {
    const name = firstText(entry, ["name", "title"]).trim();
    if (!name) return;

    const calories = firstNumber(entry, ["caloric", "calories", "kcal"]) ?? 0;
    const protein = firstNumber(entry, ["protein", "protein_g"]) ?? 0;
    const carbs = firstNumber(entry, ["carbon", "carbs", "carbs_g", "carbohydrates"]) ?? 0;
    const fat = firstNumber(entry, ["fat", "fat_g"]) ?? 0;
    const kind = firstText(entry, ["type"]).toLowerCase();

    normalized.push({
      id: firstText(entry, ["id"]) || `${index}`,
      name,
      kind,
      kind_label: dietagramKindLabel(kind),
      category_id: firstText(entry, ["category_id"]) || null,
      nutrition: {
        calories: round(calories),
        protein_g: round(protein),
        carbs_g: round(carbs),
        fat_g: round(fat),
      },
    });
  });

  return normalized;
}

function normalizeUSDAFoodMatches(payload: unknown): USDAFoodMatch[] {
  if (!isRecord(payload) || !Array.isArray(payload.foods)) return [];

  const normalized: USDAFoodMatch[] = [];
  payload.foods.filter(isRecord).forEach((entry, index) => {
    const name = firstText(entry, ["description"]).trim();
    if (!name) return;

    const nutrients = Array.isArray(entry.foodNutrients) ? entry.foodNutrients.filter(isRecord) : [];
    const nutrition = normalizeUSDANutrition(nutrients);

    normalized.push({
      id: firstText(entry, ["fdcId"]) || `${index}`,
      name,
      brand: firstText(entry, ["brandOwner", "brandName"]) || null,
      data_type: firstText(entry, ["dataType"]) || "USDA",
      nutrition,
    });
  });

  return normalized;
}

function findExactDietagramMatch(query: string, matches: DietagramFoodMatch[]) {
  const normalizedQuery = normalizeSearchText(query);
  return matches.find((match) => normalizeSearchText(match.name) === normalizedQuery) ?? null;
}

function findExactUSDAMatch(query: string, matches: USDAFoodMatch[]) {
  const normalizedQuery = normalizeSearchText(query);
  return matches.find((match) => normalizeSearchText(match.name) === normalizedQuery) ?? null;
}

function shouldUseDietagramTopMatch(
  product: Record<string, any>,
  topMatch: DietagramFoodMatch | null,
) {
  if (!topMatch) return false;
  const productName = normalizeSearchText(String(product.name ?? ""));
  const matchName = normalizeSearchText(topMatch.name);
  return Boolean(productName && matchName && (
    productName.includes(matchName)
    || matchName.includes(productName)
    || sharedSearchTokens(productName, matchName) >= 1
  ));
}

function shouldUseUSDATopMatch(
  product: Record<string, any>,
  topMatch: USDAFoodMatch | null,
) {
  if (!topMatch) return false;
  const productName = normalizeSearchText(String(product.name ?? ""));
  const matchName = normalizeSearchText(topMatch.name);
  return Boolean(productName && matchName && (
    productName.includes(matchName)
    || matchName.includes(productName)
    || sharedSearchTokens(productName, matchName) >= 1
  ));
}

function shouldApplyDietagramFallback(
  product: Record<string, any>,
  match: DietagramFoodMatch,
) {
  const currentNutrition = isRecord(product.nutrition) ? product.nutrition as Record<string, number> : {};
  const primaryCoverage = primaryMacroCoverage(currentNutrition);
  const calories = Number(currentNutrition.calories ?? 0);
  const category = String(product.category ?? "Other");
  const dataSource = String(product.data_source ?? "");

  if (calories <= 0 || primaryCoverage < 4) return true;
  if (dataSource === "rapidapi" && category === "Other" && primaryCoverage < 6) return true;
  if ((currentNutrition.protein_g ?? 0) === 0 && (match.nutrition.protein_g ?? 0) > 0) return true;
  return false;
}

function shouldApplyUSDAFallback(
  product: Record<string, any>,
  match: USDAFoodMatch,
) {
  const currentNutrition = isRecord(product.nutrition) ? product.nutrition as Record<string, number> : {};
  const primaryCoverage = primaryMacroCoverage(currentNutrition);
  const calories = Number(currentNutrition.calories ?? 0);
  const category = String(product.category ?? "Other");
  const dataSource = String(product.data_source ?? "");

  if (calories <= 0 || primaryCoverage < 4) return true;
  if (dataSource === "rapidapi" && category === "Other" && primaryCoverage < 6) return true;
  if ((currentNutrition.protein_g ?? 0) <= 0 && (match.nutrition.protein_g ?? 0) > 0) return true;
  return false;
}

function primaryMacroCoverage(nutrition: Record<string, number>) {
  return ["calories", "protein_g", "carbs_g", "fat_g"]
    .reduce((count, key) => count + (Number(nutrition[key] ?? 0) > 0 ? 1 : 0), 0);
}

function mergeDietagramNutrition(
  current: Record<string, number>,
  incoming: Record<string, number>,
) {
  const merged = { ...current };

  if ((merged.calories ?? 0) <= 0 && (incoming.calories ?? 0) > 0) merged.calories = incoming.calories;
  if ((merged.protein_g ?? 0) <= 0 && (incoming.protein_g ?? 0) > 0) merged.protein_g = incoming.protein_g;
  if ((merged.carbs_g ?? 0) <= 0 && (incoming.carbs_g ?? 0) > 0) merged.carbs_g = incoming.carbs_g;
  if ((merged.fat_g ?? 0) <= 0 && (incoming.fat_g ?? 0) > 0) merged.fat_g = incoming.fat_g;

  return merged;
}

function mergeUSDANutrition(
  current: Record<string, number>,
  incoming: Record<string, number>,
) {
  const merged = { ...current };

  if ((merged.calories ?? 0) <= 0 && (incoming.calories ?? 0) > 0) merged.calories = incoming.calories;
  if ((merged.protein_g ?? 0) <= 0 && (incoming.protein_g ?? 0) > 0) merged.protein_g = incoming.protein_g;
  if ((merged.carbs_g ?? 0) <= 0 && (incoming.carbs_g ?? 0) > 0) merged.carbs_g = incoming.carbs_g;
  if ((merged.fat_g ?? 0) <= 0 && (incoming.fat_g ?? 0) > 0) merged.fat_g = incoming.fat_g;
  if ((merged.fiber_g ?? 0) <= 0 && (incoming.fiber_g ?? 0) > 0) merged.fiber_g = incoming.fiber_g;
  if ((merged.sugar_g ?? 0) <= 0 && (incoming.sugar_g ?? 0) > 0) merged.sugar_g = incoming.sugar_g;
  if ((merged.sodium_mg ?? 0) <= 0 && (incoming.sodium_mg ?? 0) > 0) merged.sodium_mg = incoming.sodium_mg;
  if ((merged.potassium_mg ?? 0) <= 0 && (incoming.potassium_mg ?? 0) > 0) merged.potassium_mg = incoming.potassium_mg;
  if ((merged.saturated_fat_g ?? 0) <= 0 && (incoming.saturated_fat_g ?? 0) > 0) merged.saturated_fat_g = incoming.saturated_fat_g;

  return merged;
}

function resolveDietagramCategory(currentCategory: string, match: DietagramFoodMatch) {
  if (currentCategory && currentCategory !== "Other") return currentCategory;

  switch (match.kind) {
    case "f":
    case "x":
      return "Meal";
    case "s":
      return "Frozen Meal";
    default:
      return currentCategory || "Other";
  }
}

function resolveUSDACategory(currentCategory: string, match: USDAFoodMatch) {
  if (currentCategory && currentCategory !== "Other") return currentCategory;
  return mapCategory([match.data_type, match.brand ?? "", match.name]);
}

function buildDietagramQueries(searchTerm: string) {
  const cleaned = searchTerm.replace(/\s+/g, " ").trim();
  const translated = cleaned
    .replace(/joghurt/gi, "yogurt")
    .replace(/yoghurt/gi, "yogurt");
  const tokens = translated
    .split(" ")
    .map((token) => token.replace(/[^a-z0-9]/gi, ""))
    .filter(Boolean);

  const candidates = [
    cleaned,
    translated,
    tokens.slice(-2).join(" "),
    tokens.slice(-1).join(" "),
  ];

  return [...new Set(candidates.map((candidate) => candidate.trim()).filter(Boolean))];
}

function normalizeSearchText(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function sharedSearchTokens(left: string, right: string) {
  const leftTokens = new Set(left.split(" ").filter(Boolean));
  return right
    .split(" ")
    .filter(Boolean)
    .reduce((count, token) => count + (leftTokens.has(token) ? 1 : 0), 0);
}

function dietagramKindLabel(kind: string) {
  switch (kind) {
    case "f":
      return "Food";
    case "s":
      return "Recipe";
    case "x":
      return "Nutrition DB";
    default:
      return "DietaGram";
  }
}

function get100(nutriments: Record<string, unknown>, key: string) {
  return parseFloat(String(nutriments[`${key}_100g`] ?? nutriments[key] ?? "0")) || 0;
}

function extractRapidApiProduct(payload: unknown): Record<string, unknown> | null {
  if (Array.isArray(payload)) {
    return payload.find(isRecord) ?? null;
  }
  if (!isRecord(payload)) return null;

  const candidateKeys = ["product", "data", "item", "result"];
  for (const key of candidateKeys) {
    const value = payload[key];
    if (isRecord(value)) return value;
  }

  const listKeys = ["products", "results", "items", "data", "dishes"];
  for (const key of listKeys) {
    const value = payload[key];
    if (Array.isArray(value)) {
      const record = value.find(isRecord);
      if (record) return record;
    }
  }

  return payload;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function firstRecord(source: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = source[key];
    if (isRecord(value)) return value;
  }
  return null;
}

function firstText(source: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = source[key];
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return "";
}

function firstNumber(source: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = source[key];
    const parsed = parseLooseNumber(value);
    if (parsed !== null) return parsed;
  }
  return null;
}

function parseLooseNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value !== "string") return null;
  const match = value.replace(/,/g, "").match(/-?\d+(\.\d+)?/);
  return match ? parseFloat(match[0]) : null;
}

function parseServingSizeGrams(value: string) {
  const match = value.match(/(\d+(\.\d+)?)\s*g/i);
  return match ? parseFloat(match[1]) : null;
}

function normalizeUSDANutrition(nutrients: Record<string, unknown>[]) {
  const valueByNutrient = (names: string[]) => {
    for (const nutrient of nutrients) {
      const name = String(nutrient.nutrientName ?? "").toLowerCase();
      if (names.some((candidate) => name === candidate.toLowerCase())) {
        const parsed = parseLooseNumber(nutrient.value);
        if (parsed !== null) return parsed;
      }
    }
    return 0;
  };

  return {
    calories: round(valueByNutrient(["Energy"])),
    protein_g: round(valueByNutrient(["Protein"])),
    carbs_g: round(valueByNutrient(["Carbohydrate, by difference"])),
    fat_g: round(valueByNutrient(["Total lipid (fat)"])),
    saturated_fat_g: round(valueByNutrient(["Fatty acids, total saturated"])),
    fiber_g: round(valueByNutrient(["Fiber, total dietary"])),
    sugar_g: round(valueByNutrient(["Total Sugars"])),
    sodium_mg: round(valueByNutrient(["Sodium, Na"])),
    potassium_mg: round(valueByNutrient(["Potassium, K"])),
  };
}

function firstImageUrl(source: Record<string, unknown>) {
  const direct = firstText(source, ["image_url", "image", "imageUrl", "thumbnail"]);
  if (direct) return direct;

  const imageKeys = ["images", "image_urls", "imageUrls"];
  for (const key of imageKeys) {
    const value = source[key];
    if (Array.isArray(value)) {
      const first = value.find((entry) => typeof entry === "string" && entry.trim());
      if (typeof first === "string") return first;
    }
  }

  return null;
}

function mapRapidApiCategory(product: Record<string, unknown>) {
  const categoryValues = [
    firstText(product, ["category", "category_name", "department", "type"]),
    ...toStringArray(product["categories"]),
  ].filter(Boolean);
  return mapCategory(categoryValues);
}

function toStringArray(value: unknown) {
  if (Array.isArray(value)) {
    return value
      .filter((entry): entry is string => typeof entry === "string" && entry.trim().length > 0)
      .map((entry) => entry.trim());
  }
  if (typeof value === "string" && value.trim()) {
    return value.split(",").map((entry) => entry.trim()).filter(Boolean);
  }
  return [];
}

function normalizeMilligrams(value: number) {
  return value > 0 && value < 10 ? value * 1000 : value;
}

function round(value: number, precision = 2) {
  return Math.round(value * 10 ** precision) / 10 ** precision;
}

function mapCategory(tags: string[]) {
  const joined = tags.join(" ").toLowerCase();
  if (joined.includes("protein") || joined.includes("whey") || joined.includes("casein")) return "Protein";
  if (joined.includes("supplement") || joined.includes("vitamin") || joined.includes("preworkout")) return "Supplement";
  if (joined.includes("drink") || joined.includes("beverage") || joined.includes("water")) return "Drink";
  if (joined.includes("candy") || joined.includes("chocolate") || joined.includes("sweet")) return "Candy / Dessert";
  if (joined.includes("grain") || joined.includes("bread") || joined.includes("cereal")) return "Grain / Bread";
  if (joined.includes("dairy") || joined.includes("milk") || joined.includes("yogurt")) return "Dairy";
  if (joined.includes("snack") || joined.includes("chip") || joined.includes("cracker")) return "Snack";
  if (joined.includes("fruit")) return "Fruit";
  if (joined.includes("vegetable")) return "Vegetable";
  if (joined.includes("ready-meal") || joined.includes("frozen")) return "Frozen Meal";
  return "Other";
}

function flagIngredients(text: string) {
  const lower = text.toLowerCase();
  const checks = [
    { pattern: "high fructose corn syrup", name: "High Fructose Corn Syrup", concern: "A highly refined sweetener found in many processed foods", severity: "high" },
    { pattern: "partially hydrogenated", name: "Partially Hydrogenated Oils", concern: "A source of trans fats", severity: "high" },
    { pattern: "trans fat", name: "Trans Fats", concern: "Associated with poor cardiovascular outcomes in research studies", severity: "high" },
    { pattern: "monosodium glutamate", name: "MSG", concern: "Flavor enhancer that may increase sodium load", severity: "medium" },
    { pattern: "sodium nitrite", name: "Sodium Nitrite", concern: "Preservative commonly used in processed meats", severity: "medium" },
    { pattern: "artificial color", name: "Artificial Colors", concern: "Synthetic dyes with limited nutritional value", severity: "low" },
    { pattern: "artificial flavor", name: "Artificial Flavors", concern: "Synthetic flavor compounds", severity: "low" },
    { pattern: "sodium benzoate", name: "Sodium Benzoate", concern: "Preservative that contributes to sodium load", severity: "low" },
    { pattern: "aspartame", name: "Aspartame", concern: "Artificial sweetener", severity: "low" },
  ];

  return checks
    .filter((check) => lower.includes(check.pattern))
    .map((check) => ({ name: check.name, concern: check.concern, severity: check.severity }));
}

function computeScores(n: Record<string, number>, category: string, flags: Array<{ severity: string }>) {
  const overall = computeOverall(n, category, flags);
  const fat_loss = computeGoalScore(n, "fat_loss", flags);
  const muscle_gain = computeGoalScore(n, "muscle_gain", flags);
  const performance = computeGoalScore(n, "performance", flags);
  const convenience = computeConvenience(category);
  const factors = buildFactors(n, category, flags);
  const goal_guidance = buildGuidance(n, fat_loss, muscle_gain, performance);
  return {
    overall,
    fat_loss,
    muscle_gain,
    performance,
    convenience,
    rating: ratingFromScore(overall),
    primary_reason: factors[0]?.label ?? "Balanced nutritional profile",
    factors,
    goal_guidance,
  };
}

function computeOverall(n: Record<string, number>, category: string, flags: Array<{ severity: string }>) {
  let score = 50;
  score += proteinBonus(proteinRatio(n));
  if ((n.protein_g ?? 0) >= 25) score += 8;
  else if ((n.protein_g ?? 0) >= 15) score += 4;
  else if ((n.protein_g ?? 0) < 5 && (n.calories ?? 0) > 150) score -= 5;

  score += sugarPenalty(n.sugar_g ?? 0);
  score += sodiumPenalty(n.sodium_mg ?? 0);
  score += satFatPenalty(n.saturated_fat_g ?? 0);

  if ((n.fiber_g ?? 0) >= 5) score += 8;
  else if ((n.fiber_g ?? 0) >= 3) score += 5;
  else if ((n.fiber_g ?? 0) >= 1) score += 2;

  if ((n.cal_per_100g ?? 0) > 500) score -= 10;
  else if ((n.cal_per_100g ?? 0) > 400) score -= 5;

  if (category === "Supplement") score += 5;
  if (category === "Candy / Dessert") score -= 15;
  if (category === "MRE / Field Ration") score += 3;

  flags.forEach((flag) => {
    if (flag.severity === "high") score -= 12;
    if (flag.severity === "medium") score -= 5;
    if (flag.severity === "low") score -= 2;
  });

  return clamp(score);
}

function computeGoalScore(n: Record<string, number>, goal: string, flags: Array<{ severity: string }>) {
  let score = 50;
  const ratio = proteinRatio(n);

  if (goal === "fat_loss") {
    score += proteinBonus(ratio) * 1.5;
    score += sugarPenalty(n.sugar_g ?? 0) * 1.4;
    if ((n.calories ?? 0) > 300) score -= ((n.calories ?? 0) - 300) / 25;
    if ((n.protein_g ?? 0) >= 20) score += 10;
  } else if (goal === "muscle_gain") {
    score += proteinBonus(ratio) * 1.8;
    if ((n.protein_g ?? 0) >= 25) score += 15;
    else if ((n.protein_g ?? 0) >= 15) score += 8;
    else if ((n.protein_g ?? 0) < 12) score -= 18;
    if ((n.protein_g ?? 0) < 15 && (n.calories ?? 0) > 220) score -= 10;
    score += sugarPenalty(n.sugar_g ?? 0) * 0.7;
  } else {
    score += proteinBonus(ratio) * 1.2;
    score += sugarPenalty(n.sugar_g ?? 0) * 0.9;
    score += sodiumPenalty(n.sodium_mg ?? 0) * 1.2;
    if ((n.carbs_g ?? 0) > 20 && (n.carbs_g ?? 0) < 60) score += 5;
  }

  flags.forEach((flag) => {
    if (flag.severity === "high") score -= 10;
    if (flag.severity === "medium") score -= 4;
    if (flag.severity === "low") score -= 1;
  });

  return clamp(score);
}

function computeConvenience(category: string) {
  if (["MRE / Field Ration", "Snack", "Supplement"].includes(category)) return 85;
  if (category === "Drink") return 80;
  if (category === "Protein") return 75;
  if (["Fast Food", "Frozen Meal"].includes(category)) return 60;
  if (category === "Meal") return 50;
  return 40;
}

function buildFactors(n: Record<string, number>, category: string, flags: Array<{ name?: string; concern?: string; severity: string }>) {
  const factors: Array<Record<string, string>> = [];
  const ratio = proteinRatio(n);

  if (ratio >= 0.35) {
    factors.push({ label: "High protein efficiency", detail: `${n.protein_g ?? 0}g protein for ${Math.round(n.calories ?? 0)} cal.`, impact: "positive", category: "protein" });
  } else if ((n.protein_g ?? 0) < 5 && (n.calories ?? 0) > 100) {
    factors.push({ label: "Low protein for the calories", detail: "This serving is calorie-heavy without much protein.", impact: "negative", category: "protein" });
  }

  if ((n.sugar_g ?? 0) > 20) {
    factors.push({ label: "Very high sugar content", detail: `${n.sugar_g ?? 0}g sugar per serving.`, impact: "negative", category: "sugar" });
  } else if ((n.sugar_g ?? 0) <= 3) {
    factors.push({ label: "Low sugar", detail: `Only ${n.sugar_g ?? 0}g sugar per serving.`, impact: "positive", category: "sugar" });
  }

  if ((n.sodium_mg ?? 0) > 1000) {
    factors.push({ label: "Very high sodium", detail: `${Math.round(n.sodium_mg ?? 0)}mg sodium in one serving.`, impact: "negative", category: "sodium" });
  }

  if ((n.fiber_g ?? 0) >= 3) {
    factors.push({ label: "Useful fiber content", detail: `${n.fiber_g ?? 0}g fiber supports fullness and balance.`, impact: "positive", category: "fiber" });
  }

  if (category === "Candy / Dessert") {
    factors.push({ label: "Limited nutritional value", detail: "Higher sugar and lower performance value than better alternatives.", impact: "negative", category: "overall" });
  }

  flags.slice(0, 3).forEach((flag) => {
    factors.push({
      label: `Contains ${flag.name ?? "ingredient"}`,
      detail: flag.concern ?? "Ingredient note",
      impact: flag.severity === "low" ? "neutral" : "negative",
      category: "ingredients",
    });
  });

  return factors;
}

function buildGuidance(n: Record<string, number>, fatLoss: number, muscleGain: number, performance: number) {
  return [
    {
      goal: "fat_loss",
      headline: fatLoss >= 75 ? "Fits well into a fat loss plan" : fatLoss >= 50 ? "Acceptable for fat loss in moderation" : "Use sparingly during a cut",
      detail: proteinRatio(n) >= 0.3 ? "The protein content is strong for the calorie load." : "Moderate calories and macros make this manageable in a balanced plan.",
      rating: ratingFromScore(fatLoss),
    },
    {
      goal: "muscle_gain",
      headline: muscleGain >= 75 ? "Supports muscle gain goals" : muscleGain >= 50 ? "Decent option for muscle gain" : "Not optimized for muscle building",
      detail: (n.protein_g ?? 0) >= 25
        ? "High protein content supports recovery and growth."
        : (n.protein_g ?? 0) >= 15
          ? "Protein is moderate, so pair it with another source if needed."
          : "Protein is too low to make this a strong muscle-gain choice.",
      rating: ratingFromScore(muscleGain),
    },
    {
      goal: "performance",
      headline: performance >= 75 ? "Strong choice for PT performance" : performance >= 50 ? "Adequate for training and activity" : "May not support peak performance",
      detail: (n.carbs_g ?? 0) > 30 ? "Balanced carbs and protein make this useful around training." : "This can fit general training needs depending on timing and portion.",
      rating: ratingFromScore(performance),
    },
  ];
}

function proteinRatio(n: Record<string, number>) {
  const calories = n.calories ?? 0;
  if (calories <= 0) return 0;
  return ((n.protein_g ?? 0) * 4) / calories;
}

function proteinBonus(ratio: number) {
  if (ratio >= 0.5) return 25;
  if (ratio >= 0.35) return 18;
  if (ratio >= 0.25) return 12;
  if (ratio >= 0.15) return 6;
  if (ratio >= 0.08) return 2;
  return 0;
}

function sugarPenalty(sugar: number) {
  if (sugar > 25) return -20;
  if (sugar > 18) return -15;
  if (sugar > 12) return -10;
  if (sugar > 6) return -5;
  return 0;
}

function sodiumPenalty(sodium: number) {
  if (sodium > 1200) return -15;
  if (sodium > 900) return -10;
  if (sodium > 600) return -6;
  if (sodium > 400) return -3;
  return 0;
}

function satFatPenalty(satFat: number) {
  if (satFat > 12) return -12;
  if (satFat > 8) return -8;
  if (satFat > 5) return -4;
  return 0;
}

function clamp(value: number) {
  return Math.min(100, Math.max(0, Math.round(value)));
}

function ratingFromScore(score: number) {
  if (score >= 75) return "green";
  if (score >= 50) return "yellow";
  if (score >= 25) return "orange";
  return "red";
}
