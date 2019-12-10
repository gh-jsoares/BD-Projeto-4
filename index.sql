-- B-Tree e o default type de indice de Postgre SQL

-- Index 1.1

CREATE INDEX proposta_index ON proposta_de_correcao (data_hora);
CLUSTER proposta_de_correcao USING proposta_index;

-- Index 1.2

CREATE INDEX proposta_index ON proposta_de_correcao (data_hora);

-- Index 2

CREATE INDEX incidencia_index ON incidencia USING HASH(anomalia_id);


-- Index 3.1

CREATE INDEX correcao_index ON correcao (anomalia_id);
CLUSTER correcao USING correcao_index;

-- Index 3.2

CREATE INDEX correcao_index ON correcao (anomalia_id);

-- Index 4

CREATE INDEX anomalia_index ON anomalia(tem_anomalia_redacao, ts, lingua);