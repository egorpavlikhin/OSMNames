DROP MATERIALIZED VIEW IF EXISTS mv_polygons;
CREATE MATERIALIZED VIEW mv_polygons AS
SELECT
  name,
  alternative_names,
  CASE WHEN osm_id > 0 THEN 'way' ELSE 'relation' END AS osm_type,
  abs(osm_id)::VARCHAR as osm_id,
  determine_class(type) AS class,
  type,
  cast(
        case
            when coalesce(osm_polygon.lon, '') = '' then round(ST_X(ST_PointOnSurface(ST_Buffer(ST_Transform(osm_polygon.geometry, 4326), 0.0)))::numeric::numeric, 5)
            else osm_polygon.lon::numeric
        end
        as float
    ) as lon,
  cast(
        case
            when coalesce(osm_polygon.lat, '') = '' then round(ST_Y(ST_PointOnSurface(ST_Buffer(ST_Transform(osm_polygon.geometry, 4326), 0.0)))::numeric::numeric, 5)
            else osm_polygon.lat::numeric
        end
        as float
    ) as lat,
  place_rank,
  get_importance(place_rank, wikipedia, parentInfo.country_code) AS importance,
  NULL::TEXT AS street,
  parentInfo.city AS city,
  parentInfo.county AS county,
  parentInfo.state AS state,
  get_country_name(parentInfo.country_code) AS country,
  parentInfo.country_code AS country_code,
  parentInfo.displayName  AS display_name,
  bounding_box[1] AS west,
  bounding_box[2] AS south,
  bounding_box[3] AS east,
  bounding_box[4] AS north,
  NULLIF(wikidata, '') AS wikidata,
  NULLIF(wikipedia, '') AS wikipedia,
  NULL::VARCHAR AS housenumbers
FROM
  osm_polygon,
  get_parent_info(id, '') as parentInfo,
  get_bounding_box(geometry, parentInfo.country_code, admin_level) AS bounding_box;
