
-- etldoc: layer_highway_name[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_highway_name | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14_" ] ;

CREATE OR REPLACE FUNCTION layer_highway_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, ref text, ref_length int, class highway_class, subclass text) AS $$
    SELECT osm_id, geometry, name,
      NULLIF(ref, ''), NULLIF(LENGTH(ref), 0) AS ref_length,
      to_highway_class(highway) AS class, highway AS subclass
    FROM (

        -- etldoc: osm_highway_name_linestring_gen3 ->  layer_highway_name:z8
        SELECT * FROM osm_highway_name_linestring_gen3
        WHERE zoom_level = 8
        UNION ALL

        -- etldoc: osm_highway_name_linestring_gen2 ->  layer_highway_name:z9
        SELECT * FROM osm_highway_name_linestring_gen2
        WHERE zoom_level = 9
        UNION ALL

        -- etldoc: osm_highway_name_linestring_gen1 ->  layer_highway_name:z10 
        -- etldoc: osm_highway_name_linestring_gen1 ->  layer_highway_name:z11          
        SELECT * FROM osm_highway_name_linestring_gen1
        WHERE zoom_level BETWEEN 10 AND 11
        UNION ALL

        -- etldoc: osm_highway_name_linestring ->  layer_highway_name:z12        
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level = 12
            AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
            AND to_highway_class(highway) < 'minor_road'::highway_class
            AND NOT highway_is_link(highway)
        UNION ALL

        -- etldoc: osm_highway_name_linestring ->  layer_highway_name:z13
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level = 13
            AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
            AND to_highway_class(highway) < 'path'::highway_class
        UNION ALL

        -- etldoc: osm_highway_name_linestring ->  layer_highway_name:z14_
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level >= 14

    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;