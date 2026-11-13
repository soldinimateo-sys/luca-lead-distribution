-- =====================================================================
-- KPI diario de los últimos 7 días
-- Pregunta: ¿cuántos leads se asignaron, cuántos se trabajaron de verdad,
-- y con qué k promedio llegaban?
--
-- "Trabajado" = el evento siguiente a la asignación no es 'nuevo' ni
-- 'disponible' (el operador hizo algo con el lead). Cada redistribución
-- cuenta aparte. Si el k promedio sube, el sistema se está quedando sin
-- leads frescos: es la señal temprana de faltante.
-- =====================================================================

WITH dias AS (
    SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day')::date AS dia
),
dist_leads AS (
    SELECT le.lead_id, le.operator_id, le.date_time AS dist_time, d.date_time::date AS dia
    FROM lead_events le
    JOIN distributions d ON d.id = le.distribution_id
    WHERE le.channel = 'system'
      AND le.new_state = 'nuevo'
      AND d.date_time::date >= CURRENT_DATE - INTERVAL '6 days'
),
k_al_distribuir AS (
    SELECT dl.lead_id, dl.dia, dl.dist_time, COUNT(le2.id) AS k
    FROM dist_leads dl
    LEFT JOIN lead_events le2
           ON le2.lead_id   = dl.lead_id
          AND le2.channel   = 'call'
          AND le2.new_state = 'no_contesta'
          AND le2.date_time < dl.dist_time
    GROUP BY dl.lead_id, dl.dia, dl.dist_time
),
trabajados AS (
    -- para cada asignación, el primer evento posterior
    SELECT DISTINCT dl.lead_id, dl.dia
    FROM dist_leads dl
    JOIN LATERAL (
        SELECT new_state
        FROM lead_events
        WHERE lead_id = dl.lead_id
          AND date_time > dl.dist_time
        ORDER BY date_time
        LIMIT 1
    ) siguiente ON siguiente.new_state NOT IN ('nuevo', 'disponible')
),
resumen AS (
    SELECT dia,
           COUNT(DISTINCT lead_id)     AS asignados,
           COUNT(DISTINCT operator_id) AS operadores
    FROM dist_leads
    GROUP BY dia
)
SELECT d.dia,
       COALESCE(r.asignados, 0)                       AS asignados,
       COUNT(DISTINCT t.lead_id)                      AS trabajados,
       COALESCE(r.operadores, 0)                      AS operadores,
       ROUND(COUNT(DISTINCT t.lead_id)::numeric
             / NULLIF(r.operadores, 0), 1)            AS trabajados_por_operador,
       ROUND((SELECT AVG(k) FROM k_al_distribuir k
              WHERE k.dia = d.dia), 2)                AS k_promedio
FROM dias d
LEFT JOIN resumen r    ON r.dia = d.dia
LEFT JOIN trabajados t ON t.dia = d.dia
GROUP BY d.dia, r.asignados, r.operadores
ORDER BY d.dia DESC;
