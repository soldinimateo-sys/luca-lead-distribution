-- =====================================================================
-- Ventas según el intento en que se concretaron
-- Pregunta: ¿en qué intento de llamada se cierran las ventas?
-- Es la consulta detrás del segundo gráfico del README.
--
-- Para cada venta se cuentan los intentos sin respuesta (no_contesta)
-- ANTERIORES a la venta (le.date_time < v.venta_time): un lead puede
-- volver al pool si la venta se cancela, y ser llamado más adelante.
-- =====================================================================

WITH ventas AS (
    -- primera venta de cada lead
    SELECT lead_id, MIN(date_time) AS venta_time
    FROM lead_events
    WHERE new_state = 'venta'
    GROUP BY lead_id
),
k_previo AS (
    -- intentos fallidos antes de la venta
    SELECT v.lead_id,
           COUNT(le.id) AS k
    FROM ventas v
    LEFT JOIN lead_events le
           ON le.lead_id   = v.lead_id
          AND le.channel   = 'call'
          AND le.new_state = 'no_contesta'
          AND le.date_time < v.venta_time      -- solo el pasado
    GROUP BY v.lead_id
)
SELECT k + 1                                         AS intento,   -- k fallidos => vendió en el intento k + 1
       COUNT(*)                                      AS ventas,
       ROUND(100.0 * SUM(COUNT(*)) OVER (ORDER BY k)
                   / SUM(COUNT(*)) OVER (), 1)       AS pct_acumulado
FROM k_previo
GROUP BY k
ORDER BY intento;
