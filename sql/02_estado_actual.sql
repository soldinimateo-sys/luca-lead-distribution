-- =====================================================================
-- Estado actual de cada lead
-- Pregunta: ¿en qué estado está hoy cada lead y quién lo tiene?
--
-- Como lead_events solo crece, el estado actual es el último evento del lead.
-- DISTINCT ON se queda con la primera fila de cada lead según el ORDER BY.
-- =====================================================================

WITH estado_actual AS (
    SELECT DISTINCT ON (lead_id)
           lead_id, new_state, operator_id, date_time
    FROM lead_events
    WHERE channel IN ('call', 'system')
    ORDER BY lead_id, date_time DESC, id DESC
)
-- Foto del pool: cuántos leads hay en cada estado, con y sin operador asignado
SELECT new_state,
       operator_id IS NULL AS sin_operador,
       COUNT(*)            AS leads
FROM estado_actual
GROUP BY new_state, operator_id IS NULL
ORDER BY leads DESC;
