-- =====================================================================
-- Cola de distribución (línea de fibra)
-- Pregunta: ¿en qué orden se reparten los leads disponibles?
--
-- La regla, en orden de prioridad:
--   1. menos intentos sin respuesta (k) primero: los leads frescos venden más
--   2. con celular primero: dos canales de contacto en vez de uno
--   3. más cerca del vencimiento del contrato primero
--
-- En producción esta regla corre dentro de la aplicación; acá está escrita
-- en SQL para que se lea completa en un solo lugar.
-- =====================================================================

WITH estado_actual AS (
    SELECT DISTINCT ON (lead_id) lead_id, new_state, operator_id
    FROM lead_events
    WHERE channel IN ('call', 'system')
    ORDER BY lead_id, date_time DESC, id DESC
),
pool AS (
    -- disponibles, sin operador asignado y fuera del registro No Me Llame
    SELECT l.*
    FROM leads l
    JOIN estado_actual ea ON ea.lead_id = l.id
    WHERE ea.new_state IN ('disponible', 'no_contesta', 'a_y_c')
      AND ea.operator_id IS NULL
      AND l.no_me_llame <> 'esta'
),
k AS (
    SELECT lead_id, COUNT(*) AS k
    FROM lead_events
    WHERE channel = 'call' AND new_state = 'no_contesta'
    GROUP BY lead_id
)
SELECT p.id                                   AS lead_id,
       COALESCE(k.k, 0)                       AS k,
       (p.mobilephone <> '')                  AS tiene_celular,
       ABS(p.contract_exp - CURRENT_DATE)     AS dias_al_vencimiento,
       ROW_NUMBER() OVER (
           ORDER BY COALESCE(k.k, 0) ASC,
                    (p.mobilephone <> '') DESC,
                    ABS(p.contract_exp - CURRENT_DATE) ASC NULLS LAST
       )                                      AS posicion
FROM pool p
LEFT JOIN k ON k.lead_id = p.id
ORDER BY posicion;

-- Después, el reparto es round-robin: se recorre la cola en este orden y cada
-- lead va al próximo operador del ciclo que todavía tenga cupo y que no haya
-- recibido ese mismo lead en el día.
