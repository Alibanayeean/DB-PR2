WITH RECURSIVE ShortestPathCTE AS (
    SELECT
        sid AS node,
        0 AS cost,
        ARRAY[sid] AS path
    FROM
        station
    WHERE
        sid = 1  -- Replace 1 with the actual source station ID

    UNION ALL

    -- Recursive member - Explore the neighboring nodes to find the shortest path
    SELECT
        CASE WHEN adj.stid_firs = sp.node THEN adj.stid_sec ELSE adj.stid_firs END AS node,
        sp.cost + adj.distance AS cost,
        sp.path || (CASE WHEN adj.stid_firs = sp.node THEN adj.stid_sec ELSE adj.stid_firs END) AS path
    FROM
        ShortestPathCTE sp
    JOIN
        adj_station adj ON sp.node = adj.stid_firs OR sp.node = adj.stid_sec
    WHERE
        adj.stid_firs <> ALL (sp.path)
        AND adj.stid_sec <> ALL (sp.path)  -- Avoid cycles
)
-- Select the shortest path by ordering based on total cost
SELECT
    path,
    cost
FROM
    ShortestPathCTE
WHERE
    node = 2  -- Replace 2 with the actual target station ID
ORDER BY
    cost
LIMIT 1;